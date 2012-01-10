#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Version qw( version_ok );

dies_ok { version_ok; } 'croak on bad api call';

done_testing;