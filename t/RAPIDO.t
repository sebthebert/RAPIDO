#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib/";

use RAPIDO;

my $r = RAPIDO->new();
$r->Run();