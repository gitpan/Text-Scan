package Text::Scan;

require 5.005_62;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.05';

# The following are for debugging only
use ExtUtils::Embed;
use Inline C => Config => CCFLAGS => "-g"; # add debug stubs to C lib
use Inline Config => CLEAN_AFTER_BUILD => 0; # cp _Inline/Text/Scan/Scan.xs .

use Inline C => 'DATA',
			VERSION => '0.05',
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
	while( ($key, $val) = each %terms ){
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

This module provides facilities for fast searching on arbitrarily long texts with arbitrarily many search keys. The basic object behaves somewhat like a perl hash, except that you can retrieve based on a superstring of any keys stored. Simply scan a string as shown above and you will get back a perl hash (or list) of all keys found in the string (along with associated values). Longest/first order is observed (as in perl regular expressions).

IMPORTANT: As of this version, a B<single space> is used as a delimiter for purposes of recognizing key boundaries. That's right, there is a bias in favor of processing natural language! In other words, if 'my dog' is a key and 'my dogs bite' is the text, 'my dog' will B<not> be recognized. I plan to make this more configurable in the future, to have a different delimiter or none at all. For now, recognize that the key 'drunk' will not be found in the text 'gedrunk' or 'drunken' (or 'drunk.' for that matter). Properly tokenizing your corpus is essential. I know there is probably a better solution to the problem of substrings, and if anyone has suggestions, by all means contact me.


=head1 CREDITS

Except for the actual scanning part, plus the node-rotation for self-adjusting optimization, this code is heavily borrowed from both Bentley & Sedgwick and Leon Brocard's additions to it for C<Tree::Ternary_XS>. 

Many test scripts come directly from Rogaski's C<Tree::Ternary> module.

The C code interface was created using Ingerson's C<Inline>.

=head1 SEE ALSO

C<Bentley & Sedgwick "Fast Algorithms for Sorting and Searching Strings", Proceedings ACM-SIAM (1997)>

C<Bentley & Sedgewick "Ternary Search Trees", Dr Dobbs Journal (1998)>

C<Sleator & Tarjan "Self-Adjusting Binary Search Trees", Journal of the ACM (1985)>

C<Tree::Ternary>

C<Tree::Ternary_XS>

C<Inline>

=head1 COPYRIGHT

Copyright 2001 Ira Woodhead, H5 Technologies. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=head1 AUTHOR

Ira Woodhead, bunghole@pobox.com

=cut

__C__


typedef struct tnode *Tptr;

typedef struct tnode {
	char splitchar;
	Tptr lokid, eqkid, hikid;
	SV** keyval;
} Tnode;

typedef struct tobj {
  Tptr root;
  int terminals;
  int nodes;
  AV* found_keys;
  AV* found_vals;
} Tobj;


_malloc(Tobj *pTernary) {
	av_clear(pTernary->found_keys);
	av_clear(pTernary->found_vals);
}

Tptr _insert(Tobj *pTernary, Tptr p, char *s, SV* key, SV* val) {
	if (p == 0) {
		p = (Tptr) malloc(sizeof(Tnode));
		p->splitchar = *s;
		p->lokid = p->eqkid = p->hikid = p->keyval = 0;
		pTernary->nodes++;
	}
	if (*s < p->splitchar)
		p->lokid = _insert(pTernary, p->lokid, s, key, val);
	else if (*s == p->splitchar) {
		if (*s == 0) {
			if (p->keyval) {
				free(p->keyval);
				p->keyval = (SV**) malloc(sizeof(SV*) * 2); 
				p->keyval[0] = key;
				p->keyval[1] = val;
			} else {
				p->keyval = (SV**) malloc(sizeof(SV*) * 2); 
				p->keyval[0] = key;
				p->keyval[1] = val;
				pTernary->terminals++;
			}
		}
		else
			p->eqkid = _insert(pTernary, p->eqkid, ++s, key, val);
	} else
		p->hikid = _insert(pTernary, p->hikid, s, key, val);

	return p;
}

void _cleanup_(Tptr p) {
	if (p) {
		_cleanup_(p->lokid);
		if (p->splitchar) {
			_cleanup_(p->eqkid);
		} else {
			free(p->keyval); /* It's a SV**, free the memory */
		}
		_cleanup_(p->hikid);
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


//BROKEN!
void _scan(Tobj *pTernary, Tptr root, char *s) {

	Tptr p;
	Tptr terminal;
	AV* keys = pTernary->found_keys;
	AV* vals = pTernary->found_vals;
	SV** champ = 0;
	char* t;
	int depth = 0;
	int matchlen = 0;
	
	while(*s){
		p = root;
		t = s;
//printf("in while s (%u), (%s)\n", (char) *t, t);	
		// loop invariant: successful match in progress, longest
		// match stored in "keys".
		while(p){

			// Check for space, allowing a successful match to be recorded.
			// If the input string has a space and the tree indicates a
			// termination of a pattern, record a successful match.
			if( *t == ' ' )
				if(terminal = _bsearch( p, 0 )){
					champ = terminal->keyval;
					matchlen = depth;
				}
			// Continue to match if possible.
			// search for t, increment p 
			p = _bsearch( p, *t );

			if(p){
					// Record a match and return if input string is ended 
					// and tree indicates termination (t == 0)
				if(*t == 0){
					av_push(keys, p->keyval[0]);
					av_push(vals, p->keyval[1]);
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
			av_push(keys, champ[0]);
			av_push(vals, champ[1]);
		}
		while( (*s != ' ') && (*s != 0) ) s++;

		if(*s != 0) s++; // chop off the space
		matchlen = 0;
		depth = 0;
	}

}
  

void _keys(Tobj *pTernary, Tptr p) {
  
	AV* keys;

	if (!p) return;
	_keys(pTernary, p->lokid);
	if (p->splitchar)
		_keys(pTernary, p->eqkid);
	else {
		keys = pTernary->found_keys;
		av_push(keys, p->keyval[0]);
	}
	_keys(pTernary, p->hikid);
}




SV* new(char* class){
	Tobj *pTernary = (Tobj *) malloc( sizeof(Tobj) );
	SV* obj_ref = newSViv(0);
	SV*	obj = newSVrv(obj_ref, class);

	pTernary->root = 0;  
	pTernary->terminals = 0;  
	pTernary->nodes = 0;  

		pTernary->found_keys = (AV*) newAV(); 
		pTernary->found_vals = (AV*) newAV();

	sv_setiv(obj, (IV)pTernary);
	SvREADONLY_on(obj);
	return obj_ref;
}

void DESTROY(SV* obj){
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));

	_cleanup_(pTernary->root);

}


int insert(SV* obj, SV* key, SV* val) {
	Tobj *pTernary = (Tobj*)SvIV(SvRV(obj));
	SV* k = newSVsv( key );
	SV* v = newSVsv( val );
	char* s = SvPV_nolen( k );
	pTernary->root = _insert(pTernary, pTernary->root, s, k, v);
	return 1;
}


int has(SV* obj, char *s) {
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	return _search(pTernary->root, s);
}

void keys(SV* obj) {
	Tobj* pTernary = (Tobj*)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	INLINE_STACK_VARS;

	_malloc(pTernary);
	_keys(pTernary, pTernary->root);
	/* now look at pTernary->found_keys */

	INLINE_STACK_RESET;
    for (i = 0; i <= av_len(pTernary->found_keys); i++) {
		ptr = av_fetch(pTernary->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
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
	SV** ptr;
	INLINE_STACK_VARS;
	
	_malloc(pTernary);
	_scan(pTernary, pTernary->root, s);

	INLINE_STACK_RESET;
	for (i = 0; i <= av_len(pTernary->found_keys); i++) {
		ptr = av_fetch(pTernary->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
		ptr = av_fetch(pTernary->found_vals, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
	}
	INLINE_STACK_DONE;

}

