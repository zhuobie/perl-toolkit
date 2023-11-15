# Introduction

This perl script is used to create or delete users in batches.

When choose to create(--create or -c), it will search all directories in /home, create users using the directory names. When choose to delete(--delete or -d), it will delete all users with UID >= 1000. You can also choose whether to remove home directories plus data of these users(--remove or -r, be cautious to use this option).

The minimum and maximum UID can also be specified by --minuid(-i) and --maxuid(-a). In this case, The script will delete users with UID in the [minuid, maxuid] range.

# Parameters

-c  Default. Create users using directory names in /home in batches.

-d  Delete all common users(with UID >= 1000).

-r  Optional. When choose -d, also remove home directories of these users. 

-i  [int]  The minimum UID of user to delete. 

-a  [int]  The maximum UID of user to delete.

-e  [str]  The users in exclude list will not be created or deleted. This can be specified by multiple times.

-h  Display this help.

# Examples

Create users using directory names in /home in batches:

```
perl bind_home.pl
```

Delete all common users(with UID >= 1000):

```
perl bind_home.pl -d
```

Delete all common users(with UID >= 1001 and UID <= 1003, except user2 and user3)

```
perl bind_home.pl -d -i 1001 -a 1003 -e user2 -e user3
```