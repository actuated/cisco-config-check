# cisco-config-check
Shell script to check Cisco config files, such as those downloaded with Smart Install, for sensitive information.

# Usage
```
./cisco-config-check.sh [target mode] [target] [-o outfile] [options]
```
* You must specify one target mode and target:
  - **--file [target]** lets you specify a single file to parse.
  - **--folder [target]** lets you specify a folder containing files to parse.
* **-o [outfile]** lets you optionally specify an output file.
* **--line-num** lets you optionally include line numbers at the beginning of results.
* **--no-line** optionally skips the check for "line"/vty settings.

# Function
If a folder is specified, the script will find each file in that directory and treat it as a target.

For each target, the script will search that file for:
* "enable" passwords
* Local user credentials
* RADIUS and TACACS host settings
* SNMP community names and host settings
* "line"/vty settings
