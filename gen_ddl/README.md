# Introduction

This perl script is used to create `DDL` by the first line of a csv file.

By default the ddl is for Greenplum database. All field in the table will be character type.

# Usage

Use the column names from the CSV as the column names for the database table.

```
perl gen_ddl.pl mtcars.csv original
```

This will generate ddl: 

```
CREATE TABLE IF NOT EXISTS r.mtcars (mpg VARCHAR, cyl VARCHAR, disp VARCHAR, hp VARCHAR, drat VARCHAR, wt VARCHAR, qsec VARCHAR, vs VARCHAR, am VARCHAR, gear VARCHAR, carb VARCHAR) WITH (compresstype=zstd, appendonly=true, compresslevel=5, orientation=column, blocksize=65536);
```

Automatically generate column names for the database table, with the original CSV column names used as field comments. This is suitable for cases where the CSV contains special characters.

```
perl gen_ddl.pl mtcars.csv comment
```

This will generate ddl:

```
CREATE TABLE IF NOT EXISTS r.mtcars (c_0 VARCHAR, c_1 VARCHAR, c_2 VARCHAR, c_3 VARCHAR, c_4 VARCHAR, c_5 VARCHAR, c_6 VARCHAR, c_7 VARCHAR, c_8 VARCHAR, c_9 VARCHAR, c_10 VARCHAR) WITH (compresstype=zstd, appendonly=true, compresslevel=5, orientation=column, blocksize=65536);


COMMENT ON COLUMN r.mtcars.c_0 IS 'mpg';
COMMENT ON COLUMN r.mtcars.c_1 IS 'cyl';
COMMENT ON COLUMN r.mtcars.c_2 IS 'disp';
COMMENT ON COLUMN r.mtcars.c_3 IS 'hp';
COMMENT ON COLUMN r.mtcars.c_4 IS 'drat';
COMMENT ON COLUMN r.mtcars.c_5 IS 'wt';
COMMENT ON COLUMN r.mtcars.c_6 IS 'qsec';
COMMENT ON COLUMN r.mtcars.c_7 IS 'vs';
COMMENT ON COLUMN r.mtcars.c_8 IS 'am';
COMMENT ON COLUMN r.mtcars.c_9 IS 'gear';
COMMENT ON COLUMN r.mtcars.c_10 IS 'carb';
```