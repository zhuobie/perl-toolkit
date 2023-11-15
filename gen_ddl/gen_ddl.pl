#!/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0];
my $schemaname = $ARGV[1];
my $colsflag = $ARGV[2];

my $tablename = undef;
if($filename =~ /[a-zA-Z0-9\_]+(?=\.csv)/) {
    $tablename = $&;
}
open(FILE, "<".$filename) or die $!;
my $line1 = <FILE>;
my @line1s = split //, $line1;

my $quote_idx = 0;
for(my $i = 0; $i < $#line1s; $i += 1) {
    if($line1s[$i] eq "\"") {
        $quote_idx += 1;
        if($quote_idx % 2 ne 0) {
            my $j = 1;
            while($line1s[$i + $j] ne "\"") {
                if($line1s[$i + $j] eq "\,") {
                    $line1s[$i + $j] = "";
                }
                $j += 1;
            }
        }
    }
}

$line1 = join "", @line1s;

my @cols = split /\,/, $line1;
close(FILE);
map{$_ =~ s/[\r\n\s]//g} @cols;
map{$_ =~ s/[\"\'\.]//g} @cols;

if($colsflag eq "original") {
    my $ddl_cols = join ", ", map{$_." VARCHAR"} @cols; 
    my $ddl = "\nCREATE TABLE IF NOT EXISTS ".$schemaname."\.".$tablename." (".$ddl_cols.") WITH (compresstype=zstd, appendonly=true, compresslevel=5, orientation=column, blocksize=65536);\n\n";
    print $ddl;
} elsif($colsflag eq "comment") {
    my $ddl_cols = join ", ", map{"c_".$_." VARCHAR"} (0..$#cols);
    my $ddl = "\nCREATE TABLE IF NOT EXISTS ".$schemaname."\.".$tablename." (".$ddl_cols.") WITH (compresstype=zstd, appendonly=true, compresslevel=5, orientation=column, blocksize=65536);\n\n";
    my $comments = "\n";
    foreach my $i (0..$#cols) {
        my $comment = "COMMENT ON COLUMN ".$schemaname."\.".$tablename."\.c_".$i." IS \'".$cols[$i]."\';\n";
        $comments = $comments.$comment;
    }
    print $ddl;
    print $comments;
}
