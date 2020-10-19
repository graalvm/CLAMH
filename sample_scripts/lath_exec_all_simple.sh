#!/bin/bash

# Copyright (c) 2019 Oracle
# 
# The Universal Permissive License (UPL), Version 1.0
# 
# Subject to the condition set forth below, permission is hereby granted to any person
# obtaining a copy of this software, associated documentation and/or data (collectively the
# "Software"), free of charge and under any and all copyright rights in the Software, and
# any and all patent rights owned or freely licensable by each licensor hereunder covering
# either (i) the unmodified Software as contributed to or provided by such licensor, or (ii)
# the Larger Works (as defined below), to deal in both
# 
# (a) the Software, and
# 
# (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if one is
# included with the Software (each a “Larger Work” to which the Software is contributed by
# such licensors),
# 
# without restriction, including without limitation the rights to copy, create derivative
# works of, display, perform, and distribute the Software and make, use, sell, offer for
# sale, import, export, have made, and have sold the Software and the Larger Work(s), and to
# sublicense the foregoing rights on either these or other terms.
# 
# This license is subject to the following condition:
# 
# The above copyright notice and either this complete permission notice or at a minimum a
# reference to the UPL must be included in all copies or substantial portions of the
# Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.


# Script options:
#
# --cpp=<C++ executable>
# --java=<Java jar file>
# --js=<Javascript file> (future - not yet implemented)
# -o <output directory/file base name>
#
# Command line processing based on Adam Katz's answer to
# https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options/7948533

print_usage() {
    echo "Usage:"
    echo "${0##*/} -h"
    echo "${0##*/} [--cpp=<C++ executable>] [--java=<Java jar file>] -o <output directory/file base name>"
}
die() { echo "$*" >&2; print_usage; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

echo "$0 $@"
echo ""

while getopts ho:-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"      # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    cpp )    needs_arg; cpp_exe="$OPTARG" ;;
    java )   needs_arg; java_jar="$OPTARG" ;;
    o )      needs_arg; obase="$OPTARG" ;;
    h )      print_usage; exit 0 ;;
    ??* )    die "Illegal option --$OPT" ;;  # bad long option
    ? )      print_usage; exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list



if [[ "${obase}" == "" ]] ; then
  echo "Error: The output directory/file base name must be specified (for supplementary output)."
  print_usage
  #echo "Usage:  ${0##*/} <c++_executable_filename | - > <java_jar_filename | - > [path/]output_files_basename"
  exit 2;
fi

echo Running benchmarks:
if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  echo "  C++ benchmark ${cpp_exe}"
fi
if ! [[ "${java_jar}" == "" || "${java_jar}" == "-" ]] ; then
    if type java &> /dev/null; then
        echo "  Java benchmark ${java_jar}"
    else
        echo "  Warning: java not available; Java benchmark ${java_jar} will not be run"
    fi
fi
echo ""

if [[ "${obase}" == *"/"* ]] ; then
  # Make sure that the results directory exists
  RES_PATH=${obase%/*}
  mkdir -p $RES_PATH
fi
if [[ "$RES_PATH" == "" ]] ; then
  RES_PATH="."
fi
echo Supplementary output files will be written to \"$RES_PATH\"
echo ""

if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  if [[ "${cpp_exe}" == *"/"* ]] ; then
    cpp_exe=${cpp_exe}
  else
    cpp_exe=./${cpp_exe}
  fi
fi

echo "Hostname: `hostname`"
echo "Start: `date`"
echo ""

echo "================================================================================"
echo "Environment information:"
echo "================================================================================"
echo ""


if type lscpu &> /dev/null; then
echo "Processor info:"
echo "(from lscpu)"
lscpu
echo ""
fi

echo "Processor info:"
echo "(from head of /proc/cpuinfo)"
cat /proc/cpuinfo | grep '.*' | grep -B 500 'processor[ ]*.[:] 1$' | grep -v 'processor[ ]*.[:] 1$'
echo ""

if type free &> /dev/null; then
echo "Memory info:"
echo "(free -m)"
free -m
echo ""
fi

if type vmstat &> /dev/null; then
echo "Memory info:"
echo "(vmstat -s)"
vmstat -s
echo ""
fi

if type top &> /dev/null; then
echo "Current activity:"
top -ib -n 1
echo ""
echo ""
fi

echo "================================================================================"
echo "Benchmark results:"
echo "================================================================================"
echo ""

if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  echo "================================================================================"
  echo "Run C++"
  echo "$cpp_exe -trendfile ${obase}_cpp_1.trends -rf json -rff ${obase}_cpp_1.json"
  $cpp_exe -trendfile ${obase}_cpp_1.trends -rf json -rff ${obase}_cpp_1.json
  echo ""
fi

if ! [[ "${java_jar}" == "" || "${java_jar}" == "-" ]] ; then
  if type java &> /dev/null; then
    echo "================================================================================"
    echo "Run java"
    which java
    java -version
    java -jar ${java_jar} -wi 50 -rf json -rff ${obase}_graal_1.json
    echo ""
  fi
fi
if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  echo "================================================================================"
  echo "Run C++"
  echo "$cpp_exe -trendfile ${obase}_cpp_2.trends -rf json -rff ${obase}_cpp_2.json"
  $cpp_exe -trendfile ${obase}_cpp_2.trends -rf json -rff ${obase}_cpp_2.json
  echo ""
fi
if ! [[ "${java_jar}" == "" || "${java_jar}" == "-" ]] ; then
  if type java &> /dev/null; then
    echo "================================================================================"
    echo "Run java"
    which java
    java -version
    java -jar ${java_jar} -wi 50 -rf json -rff ${obase}_hotspot8_2.json
    echo ""
  fi
fi
echo ""
echo "End: `date`"
