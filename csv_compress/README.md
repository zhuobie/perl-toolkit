# Introduction

Search for CSV files larger than 100MB in the specified directory(default current directory), and either compress or delete them in bulk. If you choose to compress (the default option), the original files will be deleted. You can modify the script's parameters to fit your needs.

# Usage

```
perl csv_compress.pl
```

This will compress all CSV files larger than 100MB in the current directory.

```
perl csv_compress.pl -r
```

This will delete all CSV files larger than 100MB in the current directory.

```
perl csv_compress.pl -d /mnt/data -c
```

This will compress all CSV files larger than 100MB in the /mnt/data directory.

```
perl csv_compress.pl -d /mnt/data -r
```

This will delete all CSV files larger than 100MB in the /mnt/data directory.
