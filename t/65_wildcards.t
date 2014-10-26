#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 11 }

$ref = new Text::Scan;
$ref->usewild();

@termlist = ( 
	"banana boat * the mist",
	"pajamas are in",
	"pajamas * * * party",
	"pajamas are in the party at my house",
	"words",
	"words are words",
	"form",
	"form of an * waterslide",
	"tirewater",
	"tirewater * my soup",
	"telephone",
);
 
for my $term (@termlist) {
	$ref->insert($term, '');
}

@longlist = ( 
	"any business risk in the pajamas are in the party tomorrow with words to the contrary form of an ice weasel telephone tirewater in my soup jackass"
);

@answers = ( 
	"pajamas * * * party", '',
	"words", '',
	"form", '',
	"telephone", '',
	"tirewater * my soup", ''
);

for my $line ( @longlist ){
	push @result, $ref->scan( $line );
}

# @result should be exactly @answers.

print "results contain ", scalar @result, " items\n";
print join("\n", @result), "\n";

ok( $#result == $#answers );

for my $i ( 0..$#answers ){
	ok($result[$i] eq $answers[$i] );
	print "($result[$i] cmp $answers[$i])\n";
}


