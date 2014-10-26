package Text::Scan;

require 5.005_62;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.23';

# The following are for debugging only
#use ExtUtils::Embed;
#use Inline C => Config => CCFLAGS => "-g"; # add debug stubs to C lib
#use Inline Config => CLEAN_AFTER_BUILD => 0; # cp _Inline/build/Text/Scan/Scan.xs .

use Inline C => 'DATA',
			VERSION => '0.23',
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
	$document = 'the dog ate the bear but the dog got indigestion';
	%found = $dict->scan( $document );
	# now %found is ( dog => canine, bear => ursine )

	# Or, if you need to count number of occurrences of any given 
	# key, use an array. This will give you a countable flat list
	# of key => value pairs.
	@found = $dict->scan( $document );
	# now @found is ( dog => canine, bear => ursine, dog => canine )

	# Check for membership ($val is true)
	$val = $dict->has('pig');

	# Retrieve all keys. This returns all inserted keys in order 
	# of insertion 
	@keys = $dict->keys();
	# @keys is ( dog, bear, pig )

	# Retrieve all values (in same order as corresponding keys) 
	# (new in v0.10)
	@vals = $dict->values();
	# @vals is ( canine, ursine, porcine )

	# Get back everything you inserted
	%everything = $dict->dump();

	# "mindex"
	# Like perl's index() but with multiple patterns (new in v0.07)
	# you can scan for the starting positions of terms.
	@indices = $dict->mindex( $document );
	# @indices is ( dog => 4, bear => 16, dog => 29 ) 

	# The hash context yields the position of the last occurrences 
	# of each word 
	%indices = $dict->mindex( $document ); 
	# %indices is ( dog => 26, bear => 16 )

	# multiscan() (>= v0.23)
	# Retrieves everything scan() and mindex() does, in the form
	# of an array of references. Each reference points to a list
	# of (key, index, value)
	@result = $dict->multiscan($document);
	# @result is ([dog, 4, canine], [bear, 16, ursine], [dog, 29, canine])


	# Turn on wildcard scanning. (>= v0.09) 
	# This can be done anytime. Works for scan() and mindex(). Wildcards
	# encompass any number of non-single-space-equivalent chars.
	$dict->usewild();

	# Save a dictionary, then restore it. (serialize and restore new in v0.14)
	# This is cool but beware, all values will be converted to strings.
	# Note restore() is much faster than the original insertion of 
	# key/values. These return 0 on success, errno on failure.
	$dict->serialize("dict_name");
	$dict->restore("dict_name");

	# Place a global char equivalency class into effect. This matches all
	# these characters as if they were the same. (v0.17)
	$dict->charclass(".:;,?");
	$dict->insert("What?", "What?");
	@found = $dict->scan("Err... What, something wrong?");
	# now @found is ( "What," => "What?" );

	# Scan case-insensitively. This must be called before any insertions.
	$dict->ignorecase();

	# Set a class of chars to be the boundaries of any match, 
	# such that the chars immediately before the beginning and after the
	# ending of a match have to be in this class. Default is the single
	# space. (beginning and ending of string always count as bounds)
	# This can be called at any time, and supercedes any previous calls.
	$dict->boundary(".? ");

	# Ignore certain chars. You can define a class of chars that the
	# dictionary should pretend do not exist. You must call this before
	# any insertions.
	$dict->ignore("\n\r<>()");


=head1 DESCRIPTION

This module provides facilities for fast searching on strings with very many search keys. The basic object behaves somewhat like a perl hash, except that you can retrieve based on a superstring of any keys stored. Simply scan a string as shown above and you will get back a perl hash (or list) of all keys found in the string (along with associated values and/or positions). All keys present in the text are returned.

There are several ways to influence the behavior of the match, chiefly by the use of several types of B<global character classes>. These are different from regular expression char classes, in that they apply to the entire text and for all keys. These consist of the "ignore" class, the "boundary" class, and any user-defined classes.

Using "ignore" characters you can have the scan pretend a char in the text simply does not exist. This is useful if you want to avoid tokenizing your text. So for instance, if the period '.' is in your "ignore" class, the text will be treated exactly as if all periods had been deleted.

To define what characters may count as the delimiter of any match (single space by default) you can use the "boundary" class. For instance this way you can count punctuation as a boundary, and phrases bounded at the end by punctuation will match.

Any user-defined character classes can be used to count different chars as the same. For instance this is used internally to implement case-insensitive matching.


=head1 NEW

In v 0.19: "boundary" character class defines legal boundary characters for all matches. Default is single space for backward compatibility.

In v 0.18: Global "ignore" character classes. This, along with general global char classes and case-insensitivity, should allow you to eliminate most preprocessing.

In v 0.17: Global character classes, see example above. Also thereby case-insensitivity.

In v 0.16: Now all patterns present in the text are returned regardless of where they begin or end.

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

Ira Woodhead, textscan at sweetpota dot to

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
	char* ignore;
	char* boundary;
	char* charclasses;
	char* wild;     // all chars which match a wildcard
	AV* found_keys;
	AV* found_offsets;
	AV* found_vals;
	int position;
    bool use_wildcards;
	char* s;      // string on which to match
} Fsm;


// function declarations (prototypes) necessary for 
// mutually recursive functions
int _eat_wild_chars(fsm this, int matchlen, trans p);
int _find_match(fsm this, int matchlen, trans p);


// For vector records
#define BIT_ON(vec, offset, pos) \
		( *(vec + \
			((unsigned char) offset*32) + \
			(unsigned char)pos/8) |= \
			(1 << ((unsigned char)pos % 8)) \
		)

#define IS_BIT_ON(vec, offset, pos) \
		( *(vec+((unsigned char) offset*32) + \
			(unsigned char)pos/8) & \
			(1 << ((unsigned char)pos % 8)) \
		)



_malloc(fsm m) {
	av_clear(m->found_keys);
	av_clear(m->found_offsets);
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
//		if(*s == t->splitchar) break;
		if(IS_BIT_ON(m->charclasses, *s, t->splitchar)) break;
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


// unused, too slow
/*
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
*/


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
trans _bsearch( char* vec, char s, trans q ){

	while(q){
		if(IS_BIT_ON(vec, s, q->splitchar)) 
			break;
		else 
			q = q->next_trans;
	}
	return q;
}

void _record_match(fsm this, int matchlen, trans p){

	SV* val = (SV*) p->next_state;
	av_push(this->found_keys,    newSVpvn(this->s,matchlen+1));
	av_push(this->found_offsets, newSViv(this->position));
	av_push(this->found_vals,    val);
	SvREFCNT_inc(val);
}

int _eat_wild_chars(fsm this, int matchlen, trans p){
	char* t = this->s + matchlen;
	
	while( IS_BIT_ON( this->wild, 0, *t ) ){
		t++;
		matchlen++;
	}
	
	p = p->next_state;
	return _find_match(this, matchlen, p);
}

int _find_match(fsm this, int matchlen, trans p){

// These items are invariant through a complete recursive call.
//this->s             (document to match)
//this->position      (position in document where s starts)
//this->found_keys    (perl list of found text)
//this->found_offsets (perl list of offsets for found text)
//this->found_vals    (perl list of found values stored in fsm)

	int depth = matchlen;
	char* t = this->s + matchlen; //starting point for this match

	while(p){

		// if this is a termination state
		if(!p->splitchar){
			if( IS_BIT_ON( this->boundary, 0, *t ) ){
				matchlen = depth - 1;
				_record_match(this, matchlen, p);
			}
			p = p->next_trans;
		}

		// ignore irrelevant chars
		while( IS_BIT_ON(this->ignore, 0, *t) ){
			t++;
			depth += 1;
		}

		// find wildcard matches
		if(p && p->splitchar == '*' && this->use_wildcards)
			matchlen = _eat_wild_chars(this, depth, p);


		// search for t
		p = _bsearch( this->charclasses, *t, p );

		if(p){
			t++;
			depth++;
			p = p->next_state;
		}
	}

	return matchlen;
}


void _scan(fsm this, char *s) {

	char* t;
	int match = 0;
	int position = 0;
	
	while(*s){
		this->s = s;
		this->position = position;
		match = _find_match(this, 0, this->root); 

		// truncate s by length of match or first word...
		if(match){ s++; position++; }

		//Move to the first boundary char
		while( ! IS_BIT_ON(this->boundary, 0, *s) ) { s++; position++; }

		// chop off the first boundary
		if(*s != 0) { s++; position++; }

		// move past any irrelevant chars
		while( IS_BIT_ON(this->ignore, 0, *s) ) { s++; position++; }
		match = 0;
	}
}



void _dump(fsm m, trans p, char* k, int depth) {
  
	if (!p) return;

	_dump(m, p->next_trans, k, depth);

	if (p->splitchar){
		*(k+depth) = p->splitchar;
		_dump(m, p->next_state, k, depth+1);
	}
	else {
		av_push(m->found_keys, newSVpvn(k, depth));
		av_push(m->found_vals, (SV*)p->next_state);
		SvREFCNT_inc((SV*)p->next_state);
	}
}


void _init_charclasses(char* vecs){
	int i;
	for(i=0;i<256;i++){
		// For the ith 256-bit span, turn on bit i
		BIT_ON( vecs, i, i );
	}
}

// Default pattern boundary is EOS (null) and space (' ')
void _init_boundary(char* vec){
	BIT_ON( vec, 0, 0 );
	BIT_ON( vec, 0, (int) ' ' );
}

void _init_wild(char* vec){
	int i;
	for(i=1;i<256;i++){
		// All non-space chars match wilds by default
		if( !isspace(i) )
			BIT_ON( vec, 0, i );
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

	m->ignore   = (char*) calloc(256/sizeof(char), sizeof(char));
	m->boundary = (char*) calloc(256/sizeof(char), sizeof(char));
	m->wild     = (char*) calloc(256/sizeof(char), sizeof(char));
	m->charclasses = (char*) calloc((256*256)/sizeof(char), sizeof(char));

	_init_boundary(m->boundary);
	_init_charclasses(m->charclasses);
	_init_wild(m->wild);

	m->found_keys = (AV*) newAV(); 
	m->found_offsets = (AV*) newAV();
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
//	free(m->charclasses);
//	free(m->ignore);
//	free(m);
}

void usewild(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	m->use_wildcards = TRUE;
}


// This must be called before any insert(), but may be called
// any number of times.
void charclass(SV* obj, char* vecstring){
	fsm m = (fsm)SvIV(SvRV(obj));
	char* i = vecstring;
	char* j = vecstring;
	char* vec = m->charclasses;
	while(*i){
		while(*j){
			// For the ith 256-bit span, turn on the jth bit
			BIT_ON( vec, *i, *j);
			j++;
		}
		j = vecstring;
		i++;
	}
}

void ignore(SV* obj, char* vecstring){
	fsm m = (fsm)SvIV(SvRV(obj));
	char* i = vecstring;
	for(; *i; i++ )
		BIT_ON( m->ignore, 0, *i);

	// "ignore" chars also count as boundaries
	i = vecstring;
	for(; *i; i++ )
		BIT_ON( m->boundary, 0, *i );

	// "ignore" chars also match wildcards
	i = vecstring;
	for(; *i; i++ )
		BIT_ON( m->wild, 0, *i );
}

void ignorecase(SV* obj){
	charclass(obj, "Aa");
	charclass(obj, "Bb");
	charclass(obj, "Cc");
	charclass(obj, "Dd");
	charclass(obj, "Ee");
	charclass(obj, "Ff");
	charclass(obj, "Gg");
	charclass(obj, "Hh");
	charclass(obj, "Ii");
	charclass(obj, "Jj");
	charclass(obj, "Kk");
	charclass(obj, "Ll");
	charclass(obj, "Mm");
	charclass(obj, "Nn");
	charclass(obj, "Oo");
	charclass(obj, "Pp");
	charclass(obj, "Qq");
	charclass(obj, "Rr");
	charclass(obj, "Ss");
	charclass(obj, "Tt");
	charclass(obj, "Uu");
	charclass(obj, "Vv");
	charclass(obj, "Ww");
	charclass(obj, "Xx");
	charclass(obj, "Yy");
	charclass(obj, "Zz");
}

// define class of chars that qualify as beginning/ending of patterns
// meaning, what is allowed to occur right before or after pattern
void boundary(SV* obj, char* b){
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;

	// Reset boundary to none
	for( i=0; i<(256/sizeof(char)); i++ )
		*(m->boundary + i) = 0;

	BIT_ON( m->boundary, 0, 0 );

	// Special case: if null string specified, all chars are boundary
	if(!*b)
		for( i=0; i<256; i++ )
			BIT_ON( m->boundary, 0, i );

	// Otherwise set the specified chars as boundary
	else
		for(; *b; b++ )
			BIT_ON( m->boundary, 0, *b );
			
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

void dump(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	char *k;
	INLINE_STACK_VARS;

	k = (char*) malloc(sizeof(char) * m->maxpath);
	_malloc(m);
	_dump(m, m->root, k, 0);
	free(k);

	INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
		ptr = av_fetch(m->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
		ptr = av_fetch(m->found_vals, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;
}

void keys(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	char *k;
	INLINE_STACK_VARS;

	k = (char*) malloc(sizeof(char) * m->maxpath);
	_malloc(m);
	_dump(m, m->root, k, 0);
	free(k);

	INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
		ptr = av_fetch(m->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;
}

void values(SV* obj){
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	char *k;
	INLINE_STACK_VARS;

	k = (char*) malloc(sizeof(char) * m->maxpath);
	_malloc(m);
	_dump(m, m->root, k, 0);
	free(k);

	INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_vals); i++) {
		ptr = av_fetch(m->found_vals, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;

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



void scan(SV* obj, char *s) {
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	INLINE_STACK_VARS;
	
	_malloc(m);
	_scan(m, s);
	
	INLINE_STACK_RESET;
	for (i = 0; i <= av_len(m->found_keys); i++) {
		ptr = av_fetch(m->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
		ptr = av_fetch(m->found_vals, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
	}
	INLINE_STACK_DONE;
}

void mindex(SV* obj, char *s) {
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	INLINE_STACK_VARS;
	
	_malloc(m);
	_scan(m, s);
	
	INLINE_STACK_RESET;
	for (i = 0; i <= av_len(m->found_keys); i++) {
		ptr = av_fetch(m->found_keys, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
		ptr = av_fetch(m->found_offsets, i, 0);
		INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
	}
	INLINE_STACK_DONE;
}

void multiscan(SV* obj, char *s) {
	fsm m = (fsm)SvIV(SvRV(obj));
	int i;
	SV** ptr;
	AV* result; // holds one result (3-item array)
	INLINE_STACK_VARS;
	
	_malloc(m);
	_scan(m, s);
	
	INLINE_STACK_RESET;
	for (i = 0; i <= av_len(m->found_keys); i++) {

		result = (AV*) newAV();

		ptr = av_fetch(m->found_keys, i, 0);
		av_push(result, (SV*) newSVsv(*ptr));

		ptr = av_fetch(m->found_offsets, i, 0);
		av_push(result, (SV*) newSVsv(*ptr));

		ptr = av_fetch(m->found_vals, i, 0);
		av_push(result, (SV*) newSVsv(*ptr));

		INLINE_STACK_PUSH(sv_2mortal(newRV_noinc((SV*)result)));
	}
	INLINE_STACK_DONE;
}



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
	char *tvector = (char*) calloc(ceil(m->transitions/8), sizeof(char));
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
		BIT_ON(tvector, 0, pos);
		
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
		if(IS_BIT_ON(tvector, 0, pos)){
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
	char len;
	char *metastr;

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
			front->splitchar = (char) getc(statefp);
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





