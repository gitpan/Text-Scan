package Text::Scan;

require 5.005_62;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.03';

# The following are for debugging only
#use ExtUtils::Embed;
#use Inline C => Config => CCFLAGS => "-g"; # add debug stubs to C lib

use Inline C => 'DATA',
			VERSION => '0.03',
			NAME => 'Text::Scan';



1;

__DATA__

=pod

=head1 NAME

Text::Scan - Fast search for very large numbers of keys in a body of text.

=head1 SYNOPSIS

	use Text::Scan;

	$dict = new Text::Scan;

	%terms = ( dog  => 'canine',
	           bear => 'ursine',
	           pig  => 'porcine' );

	# load the dictionary with keys and values
	# (values can be any scalar, keys must be strings)
	while ($key, $val) = each %terms ){
		$dict->insert( $key, $val );
	}

	# Scan a document for matches
	%found = $dict->scan( $document );

	# Or, if you need to count number of occurrences of any given 
	# key, use an array. This will give you a countable flat list
	# of key => value pairs.
	@found = $dict->scan( $document );

	# Check for membership ($val is true)
	$val = $dict->has('pig');

	# Retrieve all keys
	@keys = $dict->keys();


=head1 DESCRIPTION

This module provides facilities for fast searching on arbitrarily long texts with arbitrarily many search keys. The basic object behaves somewhat like a perl hash, except that you can retrieve based on a superstring of any keys stored. Simply scan a string as shown above and you will get back a perl hash (or list) of all keys found in the string (along with associated values). Longest-first order is observed (as in perl regular expressions). 

=head1 CREDITS

Except for the actual scanning part, plus the node-rotation for self-adjusting optimization, this code is heavily borrowed from both Bentley & Sedgwick and Leon Brocard's additions to it for C<Tree::Ternary_XS>. The C code interface was created using Ingerson's C<Inline>.

Many test scripts come directly from Rogaski's C<Tree::Ternary> module.

=head1 SEE ALSO

C<Bentley & Sedgwick "Fast Algorithms for Sorting and Searching Strings", Proceedings ACM-SIAM (1997)>

C<Bentley & Sedgewick "Ternary Search Trees", Dr Dobbs Journal (1998)>

C<Sleator & Tarjan "Self-Adjusting Binary Search Trees", Journal of the ACM (1985)>

C<Tree::Ternary>

C<Tree::Ternary_XS>

=head1 AUTHOR

Ira Woodhead, bunghole@pobox.com

=cut

__C__


typedef struct tnode *Tptr;

typedef struct tnode {
  char splitchar;
  Tptr lokid, eqkid, hikid;
  SV* val;
} Tnode;

typedef struct tobj {
  Tptr root;
  int terminals;
  int nodes;
  char** searchchar;
  SV** val;
  int searchcharn;
  int searchn;
} Tobj;



_malloc(Tobj *pTernary) {
	if (pTernary->searchcharn != pTernary->terminals) {
		if (pTernary->searchcharn > 0) {
			free(pTernary->searchchar);
			free(pTernary->val);
		}
		pTernary->searchchar = 
			(char **) malloc(sizeof(char*) * (pTernary->terminals + 1));
		pTernary->val = 
			(SV **) malloc(sizeof(SV*) * (pTernary->terminals + 1));
		pTernary->searchcharn = pTernary->terminals;
	}
}




Tptr _insert(Tobj *pTernary, Tptr p, char *s, char *insertstr, SV* v) {
	if (p == 0) {
		p = (Tptr) malloc(sizeof(Tnode));
		p->splitchar = *s;
		p->lokid = p->eqkid = p->hikid = 0;
		pTernary->nodes++;
	}
	if (*s < p->splitchar)
		p->lokid = _insert(pTernary, p->lokid, s, insertstr, v);
	else if (*s == p->splitchar) {
		if (*s == 0) {
			if (p->eqkid) {
				free(p->eqkid);
				p->eqkid = (Tptr) insertstr;
				p->val = v;
			} else {
				p->eqkid = (Tptr) insertstr;
				pTernary->terminals++;
				p->val = v;
			}
		}
		else
			p->eqkid = _insert(pTernary, p->eqkid, ++s, insertstr, v);
	} else
		p->hikid = _insert(pTernary, p->hikid, s, insertstr, v);

	return p;
}

void _cleanup(Tptr p) {
	if (p) {
		_cleanup(p->lokid);
		if (p->splitchar) {
			_cleanup(p->eqkid);
		} else {
			free(p->eqkid); /* It's just a string, free the memory */
		}
		_cleanup(p->hikid);
		free(p);  
	}
}


int _search(Tptr root, char *s) {
	Tptr p;
	p = root;
	while (p) {
		if (*s < p->splitchar)
			p = p->lokid;
		else if (*s == p->splitchar)  {
			if (*s++ == 0) 
				return 1;
			p = p->eqkid;
		}
		else
			p = p->hikid;
	}
	return 0;
}

// Return the node representing the char s, if it exists, from this btree.
Tptr _bsearch( Tptr q, char s ){
	
	Tptr parent = q, grandparent = q;
	while(q){
		if(s < q->splitchar){
			grandparent = parent;
			parent = q;
			q = q->lokid;
		}
		else if (s == q->splitchar){
			_rotate( grandparent, parent, q );      //optimization
			return q;
		}
		else {
			grandparent = parent;
			parent = q;
			q = q->hikid;
		}
	}
	return NULL;
}

void _scan(Tobj *pTernary, Tptr root, char *s) {

	Tptr p;
	Tptr terminal;
	char** foo = pTernary->searchchar;
	SV**   val = pTernary->val;
	char* t;
	int depth = 0;
	int matchlen = 0;
	
	while(*s){
		p = root;
		t = s;
//printf("in while s (%u), (%s)\n", (char) *t, t);	
		// loop invariant: successful match in progress, longest
		// match stored in foo.
		while(p){

			// Check for space, allowing a successful match to be recorded.
			// If the input string has a space and the tree indicates a
			// termination of a pattern, record a successful match.
			if( *t == ' ' )
				if(terminal = _bsearch( p, 0 )){
					foo[pTernary->searchn] = (char *) terminal->eqkid;
					val[pTernary->searchn] = terminal->val;
					matchlen = depth;
				}
			// Continue to match if possible.
			// search for t, increment p 
			p = _bsearch( p, *t );

			if(p){
					// Record a match and return if input string is ended 
					// and tree indicates termination (t == 0)
				if(*t == 0){
					foo[pTernary->searchn] = (char *) p->eqkid;
					val[pTernary->searchn] = p->val;
					pTernary->searchn++;
					return;
				}
				p = p->eqkid;
				t++;
				depth++;
			}
		}
	
		// truncate s by length of match or first word...
		if(matchlen){
			s += matchlen;
			pTernary->searchn++;
		}
		while( (*s != ' ') && (*s != 0) ) s++;

		if(*s != 0) s++; // chop off the space
		matchlen = 0;
		depth = 0;
	}
}
  

void _keys(Tobj *pTernary, Tptr p) {
  
	char** key;

	if (!p) return;
	_keys(pTernary, p->lokid);
	if (p->splitchar)
		_keys(pTernary, p->eqkid);
	else {
		key = pTernary->searchchar;
		key[pTernary->searchn] = (char *) p->eqkid;
		pTernary->searchn++;
	}
	_keys(pTernary, p->hikid);
}

// Balance the tree as we go, for optimal searching
void _rotate(Tptr grandparent, Tptr parent, Tptr child){
	
	if( grandparent->hikid == parent ){
		if( parent->hikid == child ){
			parent->hikid = child->lokid;
			child->lokid  = parent;
		}
		else if ( parent->lokid == child ){
			parent->lokid = child->hikid;
			child->hikid  = parent;
		}
		grandparent->hikid = child;
	}
	else if( grandparent->lokid == parent ){
		if( parent->hikid == child ){
			parent->hikid = child->lokid;
			child->lokid  = parent;
		}
		else if ( parent->lokid == child ){
			parent->lokid = child->hikid;
			child->hikid  = parent;
		}
		grandparent->lokid = child;
	} 

}


SV* new(char* class){
	Tobj *pTernary = (Tobj *) malloc( sizeof(Tobj) );
	SV* obj_ref = newSViv(0);
	SV*	obj = newSVrv(obj_ref, class);

	pTernary->root = 0;  
	pTernary->terminals = 0;  
	pTernary->nodes = 0;  
	pTernary->searchchar = 0;  
	pTernary->searchn = 0;  
	pTernary->searchcharn = 0;  
	pTernary->val = 0;  

	sv_setiv(obj, (IV)pTernary);
	SvREADONLY_on(obj);
	return obj_ref;
}

void DESTROY(SV* obj){
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));

	_cleanup(pTernary->root);

	if (pTernary->searchcharn > 0){
		free(pTernary->searchchar);
		sv_2mortal(pTernary->val);
	}
}


int insert(SV* obj, char *s, SV* val) {
	Tobj *pTernary = (Tobj*)SvIV(SvRV(obj));
	char* t = strdup(s);
	SV* v = newSVsv(val);
	pTernary->root = _insert(pTernary, pTernary->root, t, t, v);
	return 1;
}


int has(SV* obj, char *s) {
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	return _search(pTernary->root, s);
}

void keys(SV* obj) {
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	int i;
	INLINE_STACK_VARS;

	_malloc(pTernary);
	pTernary->searchn = 0;
	_keys(pTernary, pTernary->root);
	/* now look at pTernary->searchn and pTernary->searchchar */

	INLINE_STACK_RESET;
    for (i = 0; i < pTernary->searchn; i++) {
        INLINE_STACK_PUSH(sv_2mortal(newSVpv(pTernary->searchchar[i], 0)));
    }
    INLINE_STACK_DONE;

}

int nodes(SV* obj){
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	return pTernary->nodes - pTernary->terminals;
}

int terminals(SV* obj){
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	return pTernary->terminals;
}


void scan(SV* obj, char *s) {
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	int i;
	INLINE_STACK_VARS;
	
	_malloc(pTernary);
	pTernary->searchn = 0;
	_scan(pTernary, pTernary->root, s);

	INLINE_STACK_RESET;
	for (i = 0; i < pTernary->searchn; i++) {
		INLINE_STACK_PUSH(sv_2mortal(newSVpv(pTernary->searchchar[i], 0)));
		INLINE_STACK_PUSH(pTernary->val[i]);
	}
	INLINE_STACK_DONE;

}

