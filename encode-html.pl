#!/usr/bin/perl

use strict;
use warnings;

use HTML::Entities;

$|++;

while(my $line = <STDIN>) {
   chomp $line;
   print encode_entities($line)."\n";
}
