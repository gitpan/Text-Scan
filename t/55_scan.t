#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 17 }

$ref = new Text::Scan;

@termlist = ( 
	"banana boat",
	"banana boat in the mist",
	"pajamas are in",
	"pajamas are in the party",
	"pajamas are in the party at my house",
	"words",
	"words are words",
	"form",
	"form of an ice waterslide",
	"tirewater",
	"tirewater in my soup",
	"tidewater",
	"tidewater shellfish",
	"telephone",
	"telephone me"
);
 
my $i = 0;
for my $term (@termlist) {
	$ref->insert($term, $i++);
}

@longlist = ( 
	"banana boat in the mist", 1,
	"pajamas are in the party", 3,
	"pajamas are in the party at my house", 4,
	"words are words", 6,
	"form of an ice waterslide", 8,
	"tirewater in my soup", 10,
	"tidewater shellfish", 12,
	"telephone", 13
);

for my $line ( @longlist ){
	push @result, $ref->scan( $line );
}

# @result should be exactly @longlist.


ok( $#result, $#longlist );

for my $i ( 0..$#longlist ){
#print "$result[$i] == $longlist[$i]\n";
	ok($result[$i], $longlist[$i] );
}


