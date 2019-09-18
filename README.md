# get-dp

The goal of the script is to have a simple way to assess iostat output data on the fly. The focus is to find 
- the top values per column with full lines to check the related other values at this time
- list top values per column with full lines again
- percentage of values above a certain limit 

Required is a standard iostat file with headers as usual, produced by using the

```
    iostat -xNk 1 >/$somewhere/$iostat_output_file
``` 

command.

The number of lines for the first output that gives the average values since SOD could be skipped to get proper values. If this is a need then manual removal of these lines is required prior of using the tool. 
However, for the most of the actions, one wouldn't care about those avg numbers: Those are equal or below the top values, anyway.

Note: Since it's a quick shell based hack it's not very intelligent in the way it works with awk to inspect and count the values. For now, it's taking some time on larger files to find all the values about a certain watermark set for inspection and to calculate the percentage of occurances. This might be improved using awk directly.
