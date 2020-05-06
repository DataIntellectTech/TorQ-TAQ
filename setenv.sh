#!/bin/bash

# if running the kdb+tick example, change these to full paths
# some of the kdb+tick processes will change directory, and these will no longer be valid

# get absolute path to setenv.sh directory
if [ "-bash" = $0 ]; then
  dirpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  dirpath="$(cd "$(dirname "$0")" && pwd)"
fi

export TORQHOME=${dirpath}
export KDBCONFIG=${TORQHOME}/config
export KDBCODE=${TORQHOME}/code
export KDBLOG=${TORQHOME}/logs
export KDBHTML=${TORQHOME}/html
export KDBLIB=${TORQHOME}/lib
export KDBHDB=${TORQHOME}/hdb
export KDBWDB=${TORQHOME}/wdbhdb
export KDBTPLOG=${TORQHOME}/tplogs
export TORQTAQTEMPDB=${TORQHOME}/tempdb
export TORQTAQMERGED=${TORQHOME}/merged
export TORQTAQFILEDROP=${TORQHOME}/filedrop
# set rlwrap and qcon paths for use in torq.sh qcon flag functions
export RLWRAP="rlwrap"
export QCON="qcon"

# set the application specific configuration directory
export KDBAPPCONFIG=${TORQHOME}/appconfig
export KDBAPPCODE=${TORQHOME}/code
# set KDBBASEPORT to the default value for a TorQ Installationr
export KDBBASEPORT=1259
# set TORQPROCESSES to the default process csv
export TORQPROCESSES=${KDBAPPCONFIG}/process.csv