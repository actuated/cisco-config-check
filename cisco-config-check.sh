# cisco-config-check.sh (v1.0)
# v1.0 - 3/24/2018 by Ted R (http://github.com/actuated)
# Script to pull sensitive information from cisco configs (ex: configs extracted with Smart Install)
varDateCreated="3/24/2018"
varDateLastMod="3/24/2018"

varMode=""
varModeSet=0
varTarget=""
varOutFile=""
varGrepOpts="-i --color=never"
varDoLine="y"
varYMDHMS=$(date +%F-%H-%M-%S)
varTemp="ccc-temp-$varYMDHMS.txt"
varTempLine="ccc-temp-$varYMDHMS-line.txt"

# Help/Usage
function fnUsage {
  echo
  echo "================[ cisco-config-check.sh by Ted R (github: actuated) ]================"
  echo
  echo "Script to check Cisco config files, such as those downloaded with Smart Install, for"
  echo "sensitive information."
  echo
  echo "Searches for:"
  echo "^enable"
  echo "^username"
  echo "^radius-server host"
  echo "^tacacs-server host"
  echo "^snmp-server community"
  echo "^snmp-server host"
  echo "^line"
  echo  
  echo "Created $varDateCreated, last modified $varDateLastMod."
  echo
  echo "======================================[ usage ]======================================"
  echo
  echo "./cisco-config-check.sh [target mode] [target] [-o outfile] [options]"
  echo
  echo "Target Modes (Must Specify One):"
  echo "--file [target]     Specify a single config file as a target."
  echo "--folder [target]   Specify a target folder containing multiple config files."
  echo
  echo "-o [outfile]        Optionally specify an output file to copy results to."
  echo
  echo "--line-num          Optionally include the line numbers for results."
  echo
  echo "--no-line           Optionally skip checking 'line'/vty results."
  echo
  echo "=======================================[ fin ]======================================="
  echo
  exit
}

function fnCheckThisFile {
  echo
  varFileName=$(echo "$varThisFile" | awk -F/ '{print $NF}')

  varHostName=$(grep -i --color=never ^hostname "$varThisFile" | awk '{print $NF}')
  if [ "$varHostName" != "" ]; then
    echo "===[ $varFileName - $varHostName ]==================================================================================" | cut -c1-85
  else
    echo "===[ $varFileName ]==================================================================================" | cut -c1-85
  fi

  varCheckNow=$(grep $varGrepOpts ^enable "$varThisFile")
  if [ "$varCheckNow" != "" ]; then
    echo
    grep $varGrepOpts ^enable "$varThisFile"
  fi

  varCheckNow=$(grep $varGrepOpts ^username "$varThisFile")
  if [ "$varCheckNow" != "" ]; then
    echo
    grep $varGrepOpts ^username "$varThisFile"
  fi

  varCheckNow=$(grep $varGrepOpts '^radius-server host' "$varThisFile")
  if [ "$varCheckNow" != "" ]; then
    echo
    grep $varGrepOpts '^radius-server host' "$varThisFile"
  fi

  varCheckNow=$(grep $varGrepOpts '^tacacs-server host' "$varThisFile")
  if [ "$varCheckNow" != "" ]; then
    echo
    grep $varGrepOpts '^tacacs-server host' "$varThisFile"
  fi

  varCheckNow=$(grep $varGrepOpts '^snmp-server community' "$varThisFile")
  if [ "$varCheckNow" != "" ]; then
    echo
    grep $varGrepOpts '^snmp-server community' "$varThisFile"
  fi

  varCheckNow=$(grep $varGrepOpts '^snmp-server host' "$varThisFile")
  if [ "$varCheckNow" != "" ]; then
    echo
    grep $varGrepOpts '^snmp-server host' "$varThisFile"
  fi

  if [ "$varDoLine" = "y" ]; then 
    varCheckNow=$(grep ^line "$varThisFile")
    if [ "$varCheckNow" != "" ]; then
      if [ -f "$varTempLine" ]; then rm "$varTempLine"; fi
      grep $varGrepOpts ^line "$varThisFile" -A 10 > "$varTempLine"
      if [ -f "$varTempLine" ]; then
        echo
        while IFS= read -r "varThisLine"; do
          varCheckEnd=$(echo "$varThisLine" | grep '\!')
          if [ "$varCheckEnd" = "" ]; then
            echo "$varThisLine"
          else
            break
          fi
        done < "$varTempLine"
      fi    
    fi
  fi
}

# Display Starting Info and Call Function to Check File(s)
function fnRun {
  echo
  echo "================[ cisco-config-check.sh by Ted R (github: actuated) ]================"
  echo
  if [ "$varMode" = "file" ]; then
    echo "Parsing File: $varTarget (1)"
  elif [ "$varMode = folder" ]; then
    varCountFiles=$(ls -1 "$varTarget" | wc -l)
    echo "Parsing Files In: $varTarget ($varCountFiles)"
  fi
  if [ "$varOutFile" != "" ]; then echo "Output File: $varOutFile"; fi
  read -rep $'\nPress Enter to confirm:'
  if [ "$varMode" = "file" ]; then
    varThisFile="$varTarget"
    fnCheckThisFile
  elif [ "$varMode" = "folder" ]; then
    ls -al "$varTarget"/* | grep ^- | awk '{print $NF}' | sort -V > "$varTemp"
    while read varThisFile; do
      fnCheckThisFile
    done < "$varTemp"
  fi
  echo
  echo "=======================================[ fin ]======================================="
  echo
}

# Read Options
while [ "$1" != "" ]; do
  case "$1" in
  --file )
    shift
    varTarget="$1"
    varMode="file"
    let varModeSet=varModeSet+1
    ;;
  --folder )
    shift
    varTarget="$1"
    varMode="folder"
    let varModeSet=varModeSet+1
    ;;
  -o )
    shift
    varOutFile="$1"
    ;;
  --line-num )
    varGrepOpts="-i --color=never -n"
    ;;
  --no-line )
    varDoLine="n"
    ;;
  * )
    echo
    echo "Error: Input not recognized."
    fnUsage
    ;;
  esac
  shift
done

# Check Options
if [ "$varModeSet" = "0" ]; then echo; echo "Error: --file or --folder not used to set target."; fnUsage; fi
if [ "$varModeSet" -gt "1" ]; then echo; echo "Error: Only specify --file or --folder, not both."; fnUsage; fi

if [ "$varMode" = "file" ]; then
  if [ ! -f "$varTarget" ]; then
    echo; echo "Error: '$varTarget' does not exist as a file."; fnUsage
  fi
elif [ "$varMode" = "folder" ]; then
  if [ ! -d "$varTarget" ]; then
    echo; echo "Error: '$varTarget' does not exist as a folder."; fnUsage
  fi
  varCountFiles=$(ls -1 "$varTarget" | wc -l)
  if [ "$varCountFiles" = "0" ]; then
    echo; echo "Error: '$varTarget' contains no files."; fnUsage
  fi
fi

if [ -f "$varOutFile" ]; then echo; echo "Error: '$varOutFile' output file already exists."; fnUsage; fi

if [ "$varOutFile" != "" ]; then
  fnRun | tee "$varOutFile"
else
  fnRun
fi

# Clean Up Temp Files
if [ -f "$varTemp" ]; then rm "$varTemp"; fi
if [ -f "$varTempLine" ]; then rm "$varTempLine"; fi
