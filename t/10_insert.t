#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 51 }

$ref = new Text::Scan;

ok($ref->nodes(), 0);
ok($ref->terminals(), 0);
ok($ref->btrees(), 0);

ok($ref->insert("firewater", "~"));
ok($ref->nodes(), 9);
ok($ref->terminals(), 1);
ok($ref->btrees(), 9);

ok($ref->insert("firewater", "~"));
ok($ref->nodes(), 9);
ok($ref->terminals(), 1);
ok($ref->btrees(), 9);

ok($ref->insert("stereolab", "~"));
ok($ref->nodes(), 18);
ok($ref->terminals(), 2);
ok($ref->btrees(), 17);

ok($ref->insert("tirewater", "~"));
ok($ref->nodes(), 27);
ok($ref->terminals(), 3);
ok($ref->btrees(), 25);

ok($ref->insert("tidewater", "~"));
ok($ref->nodes(), 34);
ok($ref->terminals(), 4);
ok($ref->btrees(), 31);

ok($ref->insert("tidewader", "~"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 5);
ok($ref->btrees(), 33);

ok($ref->insert("firewater", "~"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 5);
ok($ref->btrees(), 33);

ok($ref->insert("","~")); # This is a special case, makes a new node.
ok($ref->nodes(), 37);
ok($ref->terminals(), 6);
ok($ref->btrees(), 33);

ok($ref->insert("stereo","~"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 7);
ok($ref->btrees(), 33);

ok($ref->insert("","~"));
ok($ref->nodes(), 37);
ok($ref->terminals(), 7);
ok($ref->btrees(), 33);

for ($i = 1;$i < 256;$i++) { $big .= chr($i); }
ok($ref->insert($big,"~"));
ok($ref->nodes(), 292);
ok($ref->terminals(), 8);
ok($ref->btrees(), 287);

ok($ref->insert($big,"~"));
ok($ref->nodes(), 292);
ok($ref->terminals(), 8);
ok($ref->btrees(), 287);


