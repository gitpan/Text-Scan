#!/usr/bin/perl

use Test;
use Text::Scan;

BEGIN { plan tests => 4 }

ok($ref = new Text::Scan);
ok(ref($ref), 'Text::Scan');

ok($ref->nodes(), 0);
ok($ref->terminals(), 0);

