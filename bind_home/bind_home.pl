#!/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $create_log = "_CREATE.log";
my $delete_log = "_DELETE.log";

my $password = "9NIuQgPx8Kxx";
my $create = undef;
my $delete = undef;
my $minuid = 1000;
my $maxuid = 4294967294;
my $remove = 0;
my $help = 0;
my @exclude = ();

GetOptions(
    'create|c!' => \$create,
    'delete|d!' => \$delete,
    'exclude|e=s' => \@exclude,
    'minuid|i=i' => \$minuid,
    'maxuid|a=i' => \$maxuid,
    'remove|r!' => \$remove,
    'help|h!' => \$help, 
);

if ($minuid < 1000) {
    die "The UID must not be less than 1000.\n";
}

if ($maxuid > 4294967294) {
    die "The UID must not be grater than 4294967294.\n";
}

if (-e $create_log) {
    unlink $create_log;
}

if (-e $delete_log) {
    unlink $delete_log;
}

sub create_user($) {
    my $user_name = $_[0];
    system("cp /etc/skel/.bash_logout /home/$user_name/ 1>> $create_log 2>&1");
    system("cp /etc/skel/.bashrc /home/$user_name/ 1>> $create_log 2>&1");
    if (-e "/etc/skel/.bash_profile") {
        system("cp /etc/skel/.bash_profile /home/$user_name/ 1>> $create_log 2>&1");
    }
    if (-e "/etc/skel/.profile") {
        system("cp /etc/skel/.profile /home/$user_name/ 1>> $create_log 2>&1");
    }
    system("useradd $user_name -d /home/$user_name -s /bin/bash 1>> $create_log 2>&1");
    system("chown -R $user_name:$user_name /home/$user_name 1>> $create_log 2>&1");
    system("echo \"$user_name:$password\" | chpasswd 1>> $create_log 2>&1");
    return $? >> 8;
}

sub create_users() {
    my @dirs = ();
    chdir "/home";
    foreach my $dir (<"*">) {
        if (-d $dir && $dir =~ /^[a-zA-Z]+[0-9_]*/ && !grep {$dir eq $_} @exclude) {
            push @dirs, $dir;
        }
    }

    my @users = `getent passwd {1000..6000} | cut -d: -f1`;
    map(chomp, @users);

    chdir;
    open(my $LOG, ">>", $create_log) or die $!, "\n";
    select $LOG;

    foreach my $dir (@dirs) {
        if (grep {$dir eq $_} @users) {
            print "$0: User $dir already exists.\n";
        } else {
            if (create_user($dir) eq 0) {
                print "$0: User $dir created successfully.\n";
            } else {
                print "$0: User $dir create failed.\n";
            }
        }
    }

    close($LOG);
    select STDOUT;
    print "$0: Please check the $create_log file for details.\n";
}

sub delete_user($) {
    my $user_name = $_[0];
    if ($remove) {
        system("userdel -r $user_name 1>> $delete_log 2>&1");
    } else {
        system("userdel $user_name 1>> $delete_log 2>&1");
    }
    return $? >> 8;
}

sub delete_users() {
    open(FILE, "<", "/etc/passwd") or die $!, "\n";
    my @lines = <FILE>;
    close FILE;
    
    open(my $LOG, ">>", $delete_log) or die $!, "\n";
    select $LOG;
    
    my @users = ();
    foreach my $line (@lines) {
        my @userinfo = split /:/, $line;
        if ($userinfo[0] ne "nobody" && $userinfo[2] >= $minuid && $userinfo[2] <= $maxuid && !grep {$userinfo[0] eq $_} @exclude) {
            push @users, $userinfo[0];
        }
    }
    
    foreach my $user (@users) {
        if (delete_user($user) eq 0) {
            print "$0: User $user droped successfully.\n";
        } else {
            print "$0: User $user drop failed.\n";
        }
    }
    
    close($LOG);
    select STDOUT;
    print "$0: Please check the $delete_log file for details.\n";
}

=head1 Description

    This perl script is used to create or delete users in batches.
    When choose to create(--create or -c), it will search all directories in /home,
    create users using the directory names. When choose to delete(--delete or -d),
    it will delete all users with UID >= 1000. You can also choose whether to remove
    home directories plus data of these users(--remove or -r, be cautious to use this option).
    The minimum and maximum UID can also be specified by --minuid(-i) and --maxuid(-a).
    In this case, The script will delete users with UID in the [minuid, maxuid] range.

=head1 Parameters

    -c  Default. Create users using directory names in /home in batches.
    -d  Delete all common users(with UID >= 1000).
    -r  Optional. When choose -d, also remove home directories of these users. 
    -i  [int]  The minimum UID of user to delete. 
    -a  [int]  The maximum UID of user to delete.
    -e  [str]  The users in exclude list will not be created or deleted. This can be specified by multiple times.
    -h  Display this help.
    
-head1 Examples
    
    perl bind_home.pl
    
    perl bind_home.pl -d
    
    perl bind_home.pl -d -i 1001 -a 1003 -e user2 -e user3
    
=cut

if ($help) {
    die `pod2text $0`;
}

if (!defined($create) && !defined($delete)) {
    create_users();
}

if ($create && !defined($delete)) {
    create_users();
}

if (!defined($create) && $delete) {
    delete_users();
}

if ($create && $delete) {
    die "The --create(-c) and --delete(-d) can't be specified at the same time.\n";
}


