package Text::Scan;

require 5.005_62;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.14';

# The following are for debugging only
#use ExtUtils::Embed;
#use Inline C => Config => CCFLAGS => "-g"; # add debug stubs to C lib
#use Inline Config => CLEAN_AFTER_BUILD => 0; # cp _Inline/build/Text/Scan/Scan.xs .

use Inline C => 'DATA',
			VERSION => '0.14',
			NAME => 'Text::Scan';

sub serialize {
	my ($self, $filename) = @_;
	return _serialize( $self, "$filename.trie", "$filename.vals" );
}

sub restore {
	my ($self, $filename) = @_;
	return _restore( $self, "$filename.trie", "$filename.vals");
}

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

	# Retrieve all keys. This returns all inserted keys in ascending 
	# char value, substrings first.
	@keys = $dict->keys();

	# Retrieve all values (in same order as corresponding keys) 
	# (new in v0.10)
	@vals = $dict->values();
	
	# Like perl's index() but with multiple patterns (new in v0.07)
	# Scan for the starting positions of terms.
	@indices = $dict->mindex( $document );

	# The hash version of mindex() records the position of the first 
	# occurrences of each word
	%indices = $dict->mindex( $document ); 

	# Turn on wildcard scanning. (New in v0.09) 
	# This can be done anytime. Works for scan() and mindex()
	$dict->usewild();

	# Save a dictionary, then restore it. (serialize and restore new in v0.14)
	# This is cool but beware, all values will be converted to strings.
	# Note restore() is much faster than the original insertion of 
	# key/values. These return 0 on success, errno on failure.
	$dict->serialize("dict_name");
	$dict->restore("dict_name");

	
=head1 DESCRIPTION

This module provides facilities for fast searching on arbitrarily long texts with very many search keys. The basic object behaves somewhat like a perl hash, except that you can retrieve based on a superstring of any keys stored. Simply scan a string as shown above and you will get back a perl hash (or list) of all keys found in the string (along with associated values (or positions if you use mindex() instead of scan(), see examples above)). All keys present in the text are returned, except in the case where one or more keys are present but are prefixes of another longer key. In these cases only the longest key is returned. 

NOTE: This is a behavioral change from previous versions where keys could never overlap. Now they may overlap and still be detected.

IMPORTANT: A B<single space> is used as a delimiter for purposes of recognizing key boundaries. That's right, there is a bias in favor of processing natural language! In other words, if 'my dog' is a key and 'my dogs bite' is the text, 'my dog' will B<not> be recognized. I plan to make this more configurable in the future, to have a different delimiter or none at all. For now, recognize that the key 'drunk' will not be found in the text 'gedrunk' or 'drunken' (or 'drunk.' for that matter). Properly tokenizing your corpus is essential. I know there is probably a better solution to the problem of substrings, and if anyone has suggestions, by all means contact me.

=head1 COMMENTARY

What I am leaning toward is simply having no implicit delimiter at all, and relying on the programmer to use a chosen delimiter when inserting keys, then tokenizing the target text properly so that the delimiter is present at boundaries as defined by your application. This would leave you free to have no delimiter if you really want "drunk" to match "gedrunk", "drunken", "drunk." etc. The chore of tokenizing the target would be mitigated by pattern matching capabilities (hmm..)

=head1 NEW

In v 0.13: A more-or-less complete rewrite of Text::Scan uses a more traditional finite-state machine rather than a ternary trie for the basic data structure. This results in an average 20% savings in memory and 10% savings in runtime, besides being much simpler to implement, thus less prone to bugs.

In v 0.09: Wildcards! A limited wildcard functionality is available. call usewild() to turn it on. Thereafter any asterisk (*) followed by a space (' ') will be treated as "zero or more non-space characters". Once this function is turned on, the scan will be approximately 50% slower than with literal strings. If you include '*' in any key without calling usewild(), the '*' will be treated literally.

=head1 TO DO

Some obvious things have not been implemented. Deletion of key/values, patterns as keys (kind of a big one), the abovementioned elimination of the default boundary marker ' ', possibility of calling scan() with a filehandle instead of a string scalar. There is also an optimization I've been thinking about, call it "continuation reentrancy", that would greatly speed up matches on literal strings by never examining the same input char more than once.

Another optimization that might help is a transition reordering scheme for the sequential searches within states. This was shown by Sleator to reduce the strict number of comparisons over time.

=head1 CREDITS

Chad, Tara, Dan, Kim, love ya sweethearts.

Many test scripts come directly from Rogaski's C<Tree::Ternary> module.

The C code interface was created using Ingerson's C<Inline>.


=head1 OLD CREDITS (versions prior to 0.13)

The basic data structure used to be a ternary trie, but I changed it starting with version 0.13 to a finite state machine, for the sake of performance and simplicity. However, it was a lot of fun working with these ideas, so I'm including the old credits here.

The basic framework for this code is borrowed from both Bentley & Sedgwick, and Leon Brocard's additions to it for C<Tree::Ternary_XS>. The differences are in the modified search algorithm to allow for scanning, the storage of keys/values, and an extra node-rotation for gradual self-adjusting optimization to the statistical characteristics of the target text.

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

Copyright 2001, 2002 Ira Woodhead. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=head1 AUTHOR

Ira Woodhead, ira at foobox dot com

=cut


__C__


// The transition. There are no explicit states, just linked
// lists of transitions.
typedef struct TRANS *trans;
typedef struct TRANS {
	char splitchar;
	trans next_trans;
	trans next_state;
} Trans;

typedef struct FSM *fsm;
typedef struct FSM {
	trans root;
	int terminals;
	int transitions;
	int states;
	int maxpath;
	AV* found_keys;
	AV* found_vals;
	bool use_wildcards;
} Fsm;


// A link in a list of pending matches, for use with wildcards.
typedef struct pmatch *pmPtr;
typedef struct pmatch { 
	int depth; 
	pmPtr next;
	trans p;
	char *t;
	bool inWild;
} pMatch;


_malloc(fsm m) {
	av_clear(m->found_keys);
	av_clear(m->found_vals);
}


// Place the top transition where it belongs (in the order \0,*,[others])
trans _demote(trans parent){
	
	trans child, top = parent;
	
	if( !(child = parent->next_trans) ) return top;
	if( !parent->splitchar ) return top;
	if( !child->splitchar ){
		parent->next_trans = child->next_trans;
		child->next_trans = parent;
		top = child;
	}
	if( !(child = parent->next_trans) ) return top;

	if( child->splitchar == '*' ){
		parent->next_trans = child->next_trans;
		child->next_trans = parent;
		if( top != parent ) top->next_trans = child;
		else top = child;
	}
	return top;
}


trans _insert_(fsm m, trans p, char *s, SV* val) {
	
	trans t = p;
	
	// going to be a new state with one transition.
	//if (p == 0 && *s) m->states++;
	if(p == 0) m->states++;
	
	// search for *s in transition list (state) t
	while(t){
		if(*s == t->splitchar) break;
		else t = t->next_trans;
	}

	// *s transition not in current state? Make a new one, place
	// it at the top of the list. (but keep terminals, wilds at top)
	if(!t){
		m->transitions++;
		t = (trans) malloc(sizeof(Trans));
		t->splitchar = *s;
		t->next_state = 0;
		t->next_trans = p;
		// flip terminal state and/or wildcard p to top
		p = _demote(t); 
	}

	// continue inserting the rest of the string. If there is no more
	// string, place the SV* val into this termination transition.
	if(*s)
		t->next_state = _insert_(m, t->next_state, ++s, val);
	else {
		if(t->next_state) 
			sv_2mortal((SV*)t->next_state);
		else
			m->terminals++;
		t->next_state = (trans) val;
	}

	return p;
}



void _cleanup_(trans p) {

	if (p) {
			
		_cleanup_(p->next_trans);

		if(!p->splitchar){
			sv_2mortal( (SV*) p->next_state);
		}
		else 
			_cleanup_(p->next_state);
	}
	//free(p);
}


int _search(trans root, char *s) {

	trans p = root;
	while (p) {
		while(p)
			if(p->splitchar == *s) break;
			else p = p->next_trans;
		if(!p) return 0;
		if(!p->splitchar) return 1;
		p = p->next_state;
		s++;
	}
	return 0;
}


// Return the node representing the char s, if it exists, from this list.
trans _bsearch( trans q, char s ){

//	trans parent = q;
	while(q){
		if(s == q->splitchar) break;
		else {
//			parent = q;
			q = q->next_trans;
		}
	}
//	_rotate(parent);
	return q;
}




int _find_literal_match(trans root, char *s, SV** champaddr){

	int matchlen = 0;
	int depth = 0;

	trans p = root;
	char* t = s;

	while(p){

		// if this is a termination state
		if(!p->splitchar){
			if( *t == ' ' || *t == 0 ){
				*champaddr = (SV*) p->next_state;
				matchlen = depth - 1;
			}
			p = p->next_trans;
		}

		// search for t
		p = _bsearch( p, *t );

		if(p){
			t++;
			depth++;
			p = p->next_state;
		}
	}

	return matchlen;
}



int _find_wild_match(trans root, char *s, SV** champaddr){

	trans wildp;
	pmPtr tm;
	pmPtr temptm;
	char wild = '*';
//	char* wp = &wild;
	
	int matchlen = 0;
	
	tm  = (pmPtr) malloc(sizeof(pMatch));
	tm->depth = 0;
	tm->next = 0;
	tm->p = root;
	tm->t = s;
	tm->inWild = FALSE;

	// successful match in progress, longest
	// match stored in "champaddr".
	while(tm && tm->p){
		if( tm->inWild ){
			if( *(tm->t) == ' ' || *(tm->t) == 0 ){
				// record a match if possible
				if( !tm->p->splitchar && tm->depth > matchlen ){
					*champaddr = (SV*) tm->p->next_state;
					matchlen = tm->depth - 1;
				}
				// advance p out of wildcard, loop with same char ' '
				tm->p = tm->p->next_state;
				tm->inWild = FALSE;
			}
			else {
				// eat next char, stay on same p
				tm->t++;
				tm->depth++;
			}
		}
		else { // Not on a wildcard

			if( !tm->p->splitchar ){
				if( tm->depth > matchlen && 
					(*(tm->t) == ' ' || *(tm->t) == 0) ){
					*champaddr = (SV*) tm->p->next_state;
					matchlen = tm->depth - 1;
				}
				tm->p = tm->p->next_trans;
			}

			// Check for a wildcards (There's got to be a better way!)
			// Insert new match state in next pos in linked list.
			if( tm->p && tm->p->splitchar == wild ){ //Branch off 
				temptm = (pmPtr) malloc(sizeof(pMatch));
				temptm->p = tm->p;
				temptm->t = tm->t;
				temptm->depth = tm->depth;
				temptm->next = tm->next;
				temptm->inWild = TRUE;
				tm->next = temptm;

				tm->p = tm->p->next_trans;
			}

			// search for t, increment p
			tm->p = _bsearch( tm->p, *tm->t );

			if(tm->p){
				tm->t++;
				tm->depth++;
				tm->p = tm->p->next_state;
			}
		}
		// fall back on previous match state, if any
		if(!tm->p){
			temptm = tm->next;
			free(tm);
			tm = temptm; 
		} //Go back to last branch
	}

	while(tm){
		temptm = tm->next;
		free(tm);
		tm = temptm;
	}

	return matchlen;
}



void _scan(fsm m, trans root, char *s, bool isMindex) {

	AV* keys = m->found_keys;
	AV* vals = m->found_vals;
	SV* champ = 0;
	char* t;
	int matchlen = 0;
	int position = 0;

	
	while(*s){
		
		if(m->use_wildcards){
			matchlen = _find_wild_match(root, s, &champ);
		}
		else {
			matchlen = _find_literal_match(root, s, &champ);
		}
		// truncate s by length of match or first word...
		if(matchlen){

			av_push(keys, newSVpvn(s,matchlen+1));

			if(isMindex){
				av_push(vals, newSViv(position));
			}
			else {
				av_push(vals, champ);
				SvREFCNT_inc(champ);
			}

// The following substitution makes the scan start at every word,
// not just after the last match.
			s++;
			position++;
//			s += matchlen;
//			position += matchlen;
		}

		while( (*s != ' ') && (*s != 0) ) { s++; position++; }

		if(*s != 0) { s++; position++; } // chop off the space
		matchlen = 0;
	}

}




void _keys(fsm m, trans p, char* k, int depth) {
  
	if (!p) return;

	_keys(m, p->next_trans, k, depth);

	if (p->splitchar){
		*(k+depth) = p->splitchar;
		_keys(m, p->next_state, k, depth+1);
	}
	else
		av_push(m->found_keys, newSVpvn(k, depth));
}


void _values(fsm m, trans p){

	if (!p) return;

	_values(m, p->next_trans);
	
	if(p->splitchar)
		_values(m, p->next_state);
	else {
		av_push(m->found_keys, (SV*)p->next_state);
		SvREFCNT_inc((SV*)p->next_state);
	}
}


SV* new(char* class){
	fsm m = (fsm) malloc( sizeof(Fsm) );
	SV* obj_ref = newSViv(0);
	SV*	obj = newSVrv(obj_ref, class);

	m->root = 0;  
	m->terminals = 0;  
	m->transitions = 0;  
	m->states = 0;  
	m->maxpath = 0;
	
	m->found_keys = (AV*) newAV(); 
	m->found_vals = (AV*) newAV();

	m->use_wildcards = FALSE;
	
	sv_setiv(obj, (IV)m);
	SvREADONLY_on(obj);
	return obj_ref;
}

void DESTROY(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));

// takes *far* too long compared to OS garbage collection.
//	_cleanup_(m->root);
	free(m);
}

void usewild(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	m->use_wildcards = TRUE;
}

int insert(SV* obj, SV* key, SV* val) {
	fsm m = (fsm)SvIV(SvRV(obj));

	//Don't make a copy of the key, but do make one of the value
	SV* v = newSVsv( val );
	char* s = SvPV_nolen( key );
	int keylen = strlen(s);
	if(keylen > m->maxpath) m->maxpath = keylen;
	if(keylen == 0) return 1;
	m->root = _insert_(m, m->root, s, v);
	return 1;
}


int has(SV* obj, char *s) {
	fsm m = (fsm)SvIV(SvRV(obj));
	return _search(m->root, s);
}

// This handles keys() and values()
void _traverse(SV* obj, bool isKeys){
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	char *k;
	INLINE_STACK_VARS;

	k = (char*) malloc(sizeof(char) * m->maxpath);

	_malloc(m);
	if(isKeys){
		_keys(m, m->root, k, 0);
	}
	else {
		_values(m, m->root);
	}
	
	free(k);
	/* now look at m->found_keys */

	INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
		ptr = av_fetch(m->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;

}

void keys(SV* obj){
	_traverse(obj, TRUE);
}

void values(SV* obj){
	_traverse(obj, FALSE);
}


// Deprecated, use states()
int btrees(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	return m->states;
}

// Deprecated and inaccurate, use transitions()
int nodes(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	return m->transitions - m->terminals;
}


int states(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	return m->states;
}

int transitions(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	return m->transitions;
}

int terminals(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	return m->terminals;
}



void _relay(SV* obj, char *s, bool isMindex) {
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	INLINE_STACK_VARS;
	
	_malloc(m);
	_scan(m, m->root, s, isMindex);
	
	INLINE_STACK_RESET;
	for (i = 0; i <= av_len(m->found_keys); i++) {
		ptr = av_fetch(m->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
		ptr = av_fetch(m->found_vals, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
	}
	INLINE_STACK_DONE;

}


void mindex(SV* obj, char *s){
	_relay(obj, s, TRUE);
}

void scan(SV* obj, char *s){
	_relay(obj, s, FALSE);
}


// Vector records
#define BIT_ON(vec, pos) \
		*(vec+(int)pos/8) |= (1 << (pos % 8))

#define IS_BIT_ON(vec, pos) \
		*(vec+(int)pos/8) &  (1 << (pos % 8))

// This inline uses variables in context
#define RECORD_STATE \
	i = 1; \
	if(front->splitchar == 0){ \
		s = (char *)SvPV_nolen( (SV*)front->next_state ); \
		len = strlen(s); \
		fwrite( &len, sizeof(unsigned int), 1, valfp ); \
		fwrite( s, sizeof(char), len, valfp ); \
	} \
	while(front->next_trans){ \
		*(tlist+i) = front->splitchar; \
		i++; \
		front = front->next_trans; \
		pos++; \
	} \
	*(tlist+i) = front->splitchar; \
	*tlist = i; \
	fwrite(tlist, sizeof(char), (size_t) i+1, statefp); \

	
	// Record the trie and its values to disk, to be reloaded
// at another time. For this to work, all values must be either 
// numbers or strings, ie Perl scalars but no references.
// tlist - String to record the transition list for each state
// tvector - bit vector of transition positions, to record the 
// 		end-of-state position so the trie can be recreated.
int _serialize(SV* obj, char *triename, char *valsname){
	fsm m = (fsm)SvIV(SvRV(obj));
	trans front, back, last;
	FILE *statefp, *valfp;
	unsigned int pos, len, i;
	char *tlist = (char*) malloc(sizeof(char) * 255);
	char *tvector = (char*) calloc(lround(m->transitions/8), sizeof(char));
	char *s;
	
	if( !(statefp = fopen(triename, "wb"))){ return errno; }
	if( !(valfp =   fopen(valsname, "wb"))){ return errno; }

	fwrite( &m->terminals,   sizeof(int), 1, statefp );
	fwrite( &m->transitions, sizeof(int), 1, statefp );
	fwrite( &m->states,      sizeof(int), 1, statefp );
	fwrite( &m->maxpath,     sizeof(int), 1, statefp );
	fwrite( &m->use_wildcards, sizeof(bool), 1, statefp );
	
	// execute breadth-first traversal of the trie
	// recording the positions of state-ending transitions
	// in the bit vector for later reconstruction.
	front = back = m->root;
	pos = 0;
	while( front ){
		// record state [and value if present] at front, 
		// move front to end of state. Increment pos by len of state
		RECORD_STATE;
		BIT_ON(tvector, pos);
		
		if(!back){ break; } //the end
		
		front->next_trans = back->next_state;
		front = front->next_trans; 
		pos++;
		back = back->next_trans;
		while(back && back->splitchar == 0){ 
			back = back->next_trans;
		}
	}

// Now repair the trie, severing horizontal links between states
	front = m->root;
	for( pos=0; pos < m->transitions; pos++ ){
		if(IS_BIT_ON(tvector, pos)){
			back = front;
			front = front->next_trans;
			back->next_trans = 0;
		}
		else {
			front = front->next_trans;
		}
	}
	
	fclose(statefp);
	fclose(valfp);

	return 0;
}


// Add a value back into the trie. Called from restore()
void _restore_val(trans t, FILE* valfp){	
	unsigned int len = 0;
	char* s;
	
	fread(&len, sizeof(unsigned int), 1, valfp);
	s = (char*) malloc(len * sizeof(char));
	fread(s, sizeof(char), len, valfp);

	t->next_state = (trans)	newSVpvn(s, len);	 
}

// Restore the serialized trie.
int _restore( SV* obj, char *triename, char *valsname ){
	fsm m = (fsm)SvIV(SvRV(obj));
	trans front, back, last, linker, restorer;
	FILE *statefp, *valfp;
	int i, j, transitions = 0, states = 0, terminals = 0;
	char len, splitchar;

	if( !(statefp = fopen(triename, "rb")) ){ return errno; }
	if( !(valfp =   fopen(valsname, "rb")) ){ return errno; }

	
/* Read in metadata */
	fread( &m->terminals,   sizeof(int), 1, statefp );
	fread( &m->transitions, sizeof(int), 1, statefp );
	fread( &m->states,      sizeof(int), 1, statefp );
	fread( &m->maxpath,     sizeof(int), 1, statefp );
	fread( &m->use_wildcards, sizeof(bool), 1, statefp );
	
	// create transitions
	m->root = (trans) malloc(sizeof(Trans));
	front = m->root;
	while( !feof(statefp) ){
		states++;
		fread( &len, sizeof(char), 1, statefp );
		for( j=0; j < len; j++ ){
			splitchar = (char) getc(statefp);
			front->splitchar = splitchar;
			front->next_state = 0;
			front->next_trans = (trans) malloc(sizeof(Trans));
			transitions++;
			last = front;
			front = front->next_trans;
		}
		front->next_trans = 0; 
		front->next_state = 0;
		last->next_state = front;
		last->next_trans = 0;
	}
	last->next_state = 0;
	free(front);
	
	// link transitions appropriately
	front = back = m->root;
	while(back){
		linker = back;
		while(front->next_trans)
			front = front->next_trans;
		front = front->next_state;

		back = back->next_trans ? back->next_trans : back->next_state;
		while(back && !back->splitchar){
			restorer = back;
			back = back->next_trans ? back->next_trans : back->next_state;
			_restore_val(restorer, valfp);
			terminals++;
		}
		linker->next_state = front;
	}

	m->transitions = transitions - 1;
	m->states = states - 1;
	m->terminals = terminals;
	
	fclose(valfp);
	fclose(statefp);

	return 0;
}





