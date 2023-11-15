#!/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Find;

my $search_path = '.';
my $file_bytes_max = 104857600; 
my $cpu_cores = 16;

my $compress = undef;
my $remove = undef;

GetOptions(
    'dir|d=s' => \$search_path, 
    'compress|c!' => \$compress,
    'remove|r!' => \$remove,
);

if (!(-e $search_path)) {
    die "The specified path $search_path does not exist!\n";
}

sub compress_xz($) {
    my $file_name = $File::Find::name;
    my @file_stats = stat($file_name);
    my $file_bytes = $file_stats[7];
    if ($file_name =~ /^.+\.csv$/) {
        if ($file_bytes >= $file_bytes_max) {
            system("xz -zkv $file_name -T$cpu_cores");
            my $signal = $? >> 8;
            if ($signal eq 0) {
                print "$file_name compressed and original file deleted.\n";
                system("rm -rf $file_name");
            }
        } else {
            print "$file_name skipped.\n";
        }
    }
}

sub delete_csv($) {
    my $file_name = $File::Find::name;
    my @file_stats = stat($file_name);
    my $file_bytes = $file_stats[7];
    if ($file_name =~ /^.+\.csv$/) {
        if ($file_bytes >= $file_bytes_max) {
            unlink $file_name;
            print "$file_name deleted.\n";
        } else {
            print "$file_name skipped.\n";
        }
    }
}

if ($compress && $remove) {
    die "The options compress and delete cannot be used together!\n";
} 

if (!defined($compress) && !defined($remove)) {
    finddepth(\&compress_xz, $search_path);
}

if ($compress && !defined($remove)) {
    finddepth(\&compress_xz, $search_path);
}

if (!defined($compress) && $remove) {
    finddepth(\&delete_csv, $search_path);
}

