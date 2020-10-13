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


# Environment variables for Java benchmarks:
# (if one or more of these is not defined, no Java benchmarks will be run)
# JAVA_HOME_GRAAL: the top-level GraalVM directory
# JAVA_HOME_HOTSPOT8: the top-level HotSpot 8 directory
# JAVA_HOME_HOTSPOT11: the top-level HotSpot 11 directory

# Script arguments:
# $1: C++ executable (or '-' if none)
# $2: Java jar file (or '-' if none)
# $3: Output directory/file base name (for supplementary output)
#     (e.g., "path/to/results/run1")


echo "$0 $1 $2 $3"
echo ""

if [[ "$3" == "" ]] ; then
  echo "Error: The output directory/file base name must be specified (for supplementary output)."
  echo "Usage:  ${0##*/} <c++_executable_filename | - > <java_jar_filename | - > [path/]output_files_basename"
  echo ""
  echo "Environment variables for Java benchmarks:"
  echo "One or more must be defined to run Java benchmarks."
  echo "  JAVA_HOME_GRAAL: the top-level GraalVM directory"
  echo "  JAVA_HOME_HOTSPOT8: the top-level HotSpot 8 directory"
  echo "  JAVA_HOME_HOTSPOT11: the top-level HotSpot 11 directory"
  exit 1;
fi

echo Running benchmarks:
if ! [[ "$1" == "" || "$1" == "-" ]] ; then
  echo "  C++ benchmark $1"
fi
if ! [[ "$2" == "" || "$2" == "-" ]] ; then
  echo "  Java benchmark $2 on platforms:"
  if ! [[ "$JAVA_HOME_GRAAL" == "" ]] ; then
    echo "    GraalVM"
  fi
  if ! [[ "$JAVA_HOME_HOTSPOT8" == "" ]] ; then
    echo "    HotSpot 8"
  fi
  if ! [[ "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
    echo "    HotSpot 11"
  fi
fi
echo ""

if [[ "$3" == *"/"* ]] ; then
  # Make sure that the results directory exists
  RES_PATH=${3%/*}
  mkdir -p $RES_PATH
fi
if [[ "$RES_PATH" == "" ]] ; then
  RES_PATH="."
fi
echo Supplementary output files will be written to \"$RES_PATH\"
echo ""

if ! [[ "$1" == "" || "$1" == "-" ]] ; then
  if [[ "$1" == *"/"* ]] ; then
    CPP_EXE=$1
  else
    CPP_EXE=./$1
  fi
fi

echo "Hostname: `hostname`"
echo "Start: `date`"
echo ""

echo "================================================================================"
echo "Environment information:"
echo "================================================================================"
echo ""

echo "Processor info:"
echo "(from lscpu)"
lscpu
echo ""
echo "(from head of /proc/cpuinfo)"
cat /proc/cpuinfo | grep '.*' | grep -B 500 'processor[ ]*.[:] 1$' | grep -v 'processor[ ]*.[:] 1$'
echo ""
echo "Memory info:"
echo "(free -m)"
free -m
echo ""
echo "(vmstat -s)"
vmstat -s
echo ""
echo "Current activity:"
top -ib -n 1
echo ""
echo ""

echo "================================================================================"
echo "Benchmark results:"
echo "================================================================================"
echo ""

if ! [[ "$1" == "" || "$1" == "-" ]] ; then
  echo "================================================================================"
  echo "Run C++"
  $CPP_EXE -trendfile $3_cpp_1.trends -rf json -rff $3_cpp_1.json
  echo ""
fi

if ! [[ "$2" == "" || "$2" == "-" ]] ; then
  if ! [[ "$JAVA_HOME_GRAAL" == "" ]] ; then
    #echo "================================================================================"
    #echo "Run java (GraalVM), vectorization disabled"
    #export JAVA_HOME=$JAVA_HOME_GRAAL
    #${JAVA_HOME}/bin/java -version
    #${JAVA_HOME}/bin/java -Dgraal.Vectorization=false -jar $2 -wi 50 -rf json -rff $3_graal_1.json
    #echo ""
    echo "================================================================================"
    echo "Run java (GraalVM)"
    export JAVA_HOME=$JAVA_HOME_GRAAL
    ${JAVA_HOME}/bin/java -version
    ${JAVA_HOME}/bin/java -jar $2 -wi 50 -rf json -rff $3_graal_1.json
    echo ""
  fi
  if ! [[ "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
    echo "================================================================================"
    echo "Run java (Hotspot 11)"
    export JAVA_HOME=$JAVA_HOME_HOTSPOT11
    ${JAVA_HOME}/bin/java -version
    ${JAVA_HOME}/bin/java -jar $2 -wi 50 -rf json -rff $3_hotspot11_1.json
    echo ""
  fi
  if ! [[ "$JAVA_HOME_HOTSPOT8" == "" ]] ; then
    echo "================================================================================"
    echo "Run java (Hotspot 8)"
    export JAVA_HOME=$JAVA_HOME_HOTSPOT8
    ${JAVA_HOME}/bin/java -version
    ${JAVA_HOME}/bin/java -jar $2 -wi 50 -rf json -rff $3_hotspot8_1.json
    echo ""
  fi
fi
if ! [[ "$1" == "" || "$1" == "-" ]] ; then
  echo "================================================================================"
  echo "Run C++"
  $CPP_EXE -trendfile $3_cpp_2.trends -rf json -rff $3_cpp_2.json
  echo ""
fi
if ! [[ "$2" == "" || "$2" == "-" ]] ; then
  if ! [[ "$JAVA_HOME_HOTSPOT8" == "" ]] ; then
    echo "================================================================================"
    echo "Run java (Hotspot 8)"
    export JAVA_HOME=$JAVA_HOME_HOTSPOT8
    ${JAVA_HOME}/bin/java -version
    ${JAVA_HOME}/bin/java -jar $2 -wi 50 -rf json -rff $3_hotspot8_2.json
    echo ""
  fi
  if ! [[ "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
    echo "================================================================================"
    echo "Run java (Hotspot 11)"
    export JAVA_HOME=$JAVA_HOME_HOTSPOT11
    ${JAVA_HOME}/bin/java -version
    ${JAVA_HOME}/bin/java -jar $2 -wi 50 -rf json -rff $3_hotspot11_2.json
    echo ""
  fi
  if ! [[ "$JAVA_HOME_GRAAL" == "" ]] ; then
    echo "================================================================================"
    echo "Run java (GraalVM)"
    export JAVA_HOME=$JAVA_HOME_GRAAL
    ${JAVA_HOME}/bin/java -version
    ${JAVA_HOME}/bin/java -jar $2 -wi 50 -rf json -rff $3_graal_1.json
    echo ""
    #echo "================================================================================"
    #echo "Run java (GraalVM), vectorization disabled"
    #export JAVA_HOME=$JAVA_HOME_GRAAL
    #${JAVA_HOME}/bin/java -version
    #${JAVA_HOME}/bin/java -Dgraal.Vectorization=false -jar $2 -wi 50 -rf json -rff $3_graal_2.json
    #echo ""
  fi
fi
echo ""
echo "End: `date`"
