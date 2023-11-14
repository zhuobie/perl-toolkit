#/bin/perl
use strict;
use warnings;
use DBI;
use Excel::Writer::XLSX;
use utf8;

#### modify these parameters ####
my $host = '127.0.0.1';
my $port = '5432';
my $dbname = 'postgres';
my $username = 'user';
my $password = 'password';
my $schema_name_1 = 'demo1';
my $schema_name_2 = 'demo2';
#### modify these parameters ####

my $dbh = DBI->connect("dbi:Pg:dbname = $dbname; host = $host; port = $port", $username, $password, {RaiseError => 1, AutoCommit => 0});

sub get_query(@) {
    my $schema_name_1 = $_[0];
    my $schema_name_2 = $_[1];
    my $table_name = $_[2];
    my $query = <<EOF;
select 
case when table_schema_1 is null then '' else table_schema_1 end, 
case when table_name_1 is null then '' else table_name_1 end, 
case when column_name_1 is null then '' else column_name_1 end, 
case when data_type_1 is null then '' else data_type_1 end, 
case when ordinal_position_1 is null then '' else ordinal_position_1::varchar end, 
case when table_schema_2 is null then '' else table_schema_2 end, 
case when table_name_2 is null then '' else table_name_2 end, 
case when column_name_2 is null then '' else column_name_2 end, 
case when data_type_2 is null then '' else data_type_2 end, 
case when ordinal_position_2 is null then '' else ordinal_position_2::varchar end
from 
(select 
t1.table_schema table_schema_1, 
t1.table_name table_name_1, 
t1.column_name column_name_1, 
t1.data_type data_type_1, 
t1.ordinal_position ordinal_position_1 
from information_schema.columns t1 
where t1.table_schema = '$schema_name_1'
and t1.table_name = '$table_name') tt1 
full join (select 
t1.table_schema table_schema_2, 
t1.table_name table_name_2, 
t1.column_name column_name_2, 
t1.data_type data_type_2, 
t1.ordinal_position ordinal_position_2 
from information_schema.columns t1 
where t1.table_schema = '$schema_name_2'
and t1.table_name = '$table_name') tt2 
on tt1.column_name_1 = tt2.column_name_2
order by tt1.ordinal_position_1, tt2.ordinal_position_2
EOF
    return $query;
}

sub get_query_not_exist(@) {
    my $schema_name = $_[0];
    my $table_name = $_[1];
    my $query = <<EOF;
select 
t1.table_schema table_schema_1, 
t1.table_name table_name_1, 
t1.column_name column_name_1, 
t1.data_type data_type_1, 
t1.ordinal_position ordinal_position_1, 
'' table_schema_2, 
'' table_name_2,
'' column_name_2, 
'' data_type_2, 
'' ordinal_position_2
from information_schema.columns t1 
where t1.table_schema = '$schema_name'
and t1.table_name = '$table_name'
order by t1.ordinal_position
EOF
    return $query;
}

sub get_schema_tables($) {
    my $schema_name = $_[0];
    my $query = <<EOF;
select tablename from pg_tables where schemaname = '$schema_name'
EOF
    my @schema_tables;
    my @array = $dbh->selectall_array($query);
    foreach my $i (0..$#array) {
        foreach my $j (0..$#{$array[$i]}) {
            push @schema_tables, $array[$i][$j];
        }
    }
    return @schema_tables;
}

sub get_table_columns(@) {
    my $schema_name = $_[0];
    my $table_name = $_[1];
    my $query = <<EOF;
select * from information_schema.columns where table_schema = '$schema_name' and table_name = '$table_name'
EOF
    my @table_columns;
    my @array = $dbh->selectall_array($query);
    foreach my $i (0..$#array) {
        foreach my $j (0..$#{$array[$i]}) {
            push @table_columns, $array[$i][$j];
        }
    }
    return @table_columns;
}

my @schema_tables_1 = get_schema_tables($schema_name_1);
my @schema_tables_2 = get_schema_tables($schema_name_2);
my $report_xlsx = Excel::Writer::XLSX->new($schema_name_1.'_vs_'.$schema_name_2.'.xlsx');
my $format_body = $report_xlsx->add_format(border => 6, font => "Arial");
my $format_body_dismatch = $report_xlsx->add_format(border => 6, font => "Arial", bg_color => "yellow");
my $format_url = $report_xlsx->add_format(font => "Arial", underline => 1, color => "blue");
my $format_body_header = $report_xlsx->add_format(border => 6, font => "Arial", bold => 1);

my $index_worksheet = $report_xlsx->add_worksheet("INDEX");
$index_worksheet->set_column(0, 0, 100);
$index_worksheet->write(0, 0, "INDEX", $format_body_header);

my $current_sheet_num = 1;
foreach my $schema_table_1 (@schema_tables_1) {
    print $schema_table_1, ": ", $current_sheet_num, "/", $#schema_tables_1 + 1, "\n";
    my $current_worksheet = $report_xlsx->add_worksheet($schema_table_1);
    
    $current_worksheet->set_column(0, 20, 20);
    my $query = undef;
    if (grep {$_ eq $schema_table_1} @schema_tables_2) {
        $query = get_query($schema_name_1, $schema_name_2, $schema_table_1);
    } else {
        $query = get_query_not_exist($schema_name_1, $schema_table_1);
    }
    my $sth = $dbh->prepare($query);
        $sth->execute();
        my $col_names = $sth->{NAME};
        for my $i (0..$#$col_names) {
            $current_worksheet->write(0, $i, $$col_names[$i], $format_body_header);
        }
        my $is_match = 1;
        my $nrow = 1;
        while (my $record = $sth->fetchrow_hashref()) {
            my $table_schema_1 = $record->{"table_schema_1"};
            my $table_name_1 = $record->{"table_name_1"};
            my $column_name_1 = $record->{"column_name_1"};
            my $data_type_1 = $record->{"data_type_1"};
            my $ordinal_position_1 = $record->{"ordinal_position_1"};
            my $table_schema_2 = $record->{"table_schema_2"};
            my $table_name_2 = $record->{"table_name_2"};
            my $column_name_2 = $record->{"column_name_2"};
            my $data_type_2 = $record->{"data_type_2"};
            my $ordinal_position_2 = $record->{"ordinal_position_2"};

            $current_worksheet->write($nrow, 0, $table_schema_1, $format_body);
            $current_worksheet->write($nrow, 5, $table_schema_2, $format_body);

            if ($table_name_1 ne $table_name_2) {
                $current_worksheet->write($nrow, 1, $table_name_1, $format_body_dismatch);
                $current_worksheet->write($nrow, 6, $table_name_2, $format_body_dismatch);
            } else {
                $current_worksheet->write($nrow, 1, $table_name_1, $format_body);
                $current_worksheet->write($nrow, 6, $table_name_2, $format_body);
            }

            if ($column_name_1 ne $column_name_2) {
                $current_worksheet->write($nrow, 2, $column_name_1, $format_body_dismatch);
                $current_worksheet->write($nrow, 7, $column_name_2, $format_body_dismatch);
                
            } else {
                $current_worksheet->write($nrow, 2, $column_name_1, $format_body);
                $current_worksheet->write($nrow, 7, $column_name_2, $format_body);
            }

            if ($data_type_1 ne $data_type_2) {
                $current_worksheet->write($nrow, 3, $data_type_1, $format_body_dismatch);
                $current_worksheet->write($nrow, 8, $data_type_2, $format_body_dismatch);
            } else {
                $current_worksheet->write($nrow, 3, $data_type_1, $format_body);
                $current_worksheet->write($nrow, 8, $data_type_2, $format_body);
            }

            if ($ordinal_position_1 ne $ordinal_position_2) {
                $current_worksheet->write($nrow, 4, $ordinal_position_1, $format_body_dismatch);
                $current_worksheet->write($nrow, 9, $ordinal_position_2, $format_body_dismatch);
            } else {
                $current_worksheet->write($nrow, 4, $ordinal_position_1, $format_body);
                $current_worksheet->write($nrow, 9, $ordinal_position_2, $format_body);
            }

            if ($table_name_1 ne $table_name_2 || $column_name_1 ne $column_name_2 || $data_type_1 ne $data_type_2 || $ordinal_position_1 ne $ordinal_position_2) {
                $is_match = 0;
            }
            
            $nrow += 1;
        }
        
        $current_worksheet->write_url($nrow + 1, 0, "internal:INDEX!A1", $format_url, "BACK TO INDEX");
        my $format_match = $report_xlsx->add_format(font => "Arial", underline => 1, color => "blue", border => 6);
        my $format_dismatch = $report_xlsx->add_format(font => "Arial", color => "red", underline => 1, border => 6);
        if ($is_match) {
            $index_worksheet->write_url($current_sheet_num, 0, 'internal:'.$schema_table_1.'!A1', $format_match, $schema_table_1);
        } else {
            $index_worksheet->write_url($current_sheet_num, 0, 'internal:'.$schema_table_1.'!A1', $format_dismatch, $schema_table_1);
        }
        
    $current_sheet_num += 1;
}

print "\nTotally ".($current_sheet_num - 1)." sheets wrote.\n";

$report_xlsx->close();

$dbh->disconnect();






