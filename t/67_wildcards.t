#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 7 }

$ref = new Text::Scan;
$ref->usewild();

@termlist = ( 
	"marine corps expedition",
	"marine * * forces",
	"mso 456 us*",
	"mso 4* * * mso 5*",

);
 
for my $term (@termlist) {
	$ref->insert($term, 0);
}

@longlist = ( 
	"bla marine corps expeditionary forces bla",
	"bla bla mso 456 uss adroit mso 509 bla bla",
);

@answers = ( 
	"marine corps expeditionary forces", 0,
	"mso 456 uss", 0,
	"mso 456 uss adroit mso 509", 0,
);

for my $line ( @longlist ){
	push @result, $ref->scan( $line );
}

# @result should be exactly @answers.

print "results contain ", scalar @result, " items\n";
print join("\n", @result), "\n";

ok( $#result == $#answers );

for my $i ( 0..$#answers ){
	ok($result[$i], $answers[$i] );
	print "($result[$i] cmp $answers[$i])\n";
}


