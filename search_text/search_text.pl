#!/bin/perl
use strict;
use warnings;
use File::Find;
use Tie::File;

my $directory = $ARGV[0];
my $regexp = $ARGV[1];

print "Search for text...\n";

if (-e "search_result.log") {
    unlink "search_result.log";
}

open(my $fh, '>>', "search_result.log") or die $!;
find(\&search_file, $directory);
close $fh;

sub search_file {
    my $current_file = $_;
    if (-T $current_file) {
        tie my @file_lines, 'Tie::File', $_, memory => 20_000_000;
        my $line_number = 0;
        foreach (@file_lines) {
            $line_number ++;
            if ($_ =~ /$regexp/) {
                print $fh $File::Find::name, ":", $line_number, "\t", $_, "\n";
            }
        }
    }
}

