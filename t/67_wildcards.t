#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 3 }

$ref = new Text::Scan;
$ref->usewild();

@termlist = ( 
	"marine corps expedition",
	"marine * * forces",
);
 
for my $term (@termlist) {
	$ref->insert($term, 0);
}

@longlist = ( 
	"bla marine corps expeditionary forces bla"
);

@answers = ( 
	"marine corps expeditionary forces", 0,
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


