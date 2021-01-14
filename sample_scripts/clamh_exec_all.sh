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
# (if one or more of these is not defined, the installed 'java' will be used)
# JAVA_HOME_GRAALVM: the top-level GraalVM directory
# JAVA_HOME_HOTSPOT8: the top-level HotSpot 8 directory
# JAVA_HOME_HOTSPOT11: the top-level HotSpot 11 directory
#
# Script options:
#
# --cpp=<C++ binary>
# --java=<Java jar file>
# --js=<Javascript file> (future - not yet implemented)
# -o <output directory/file base name>
#

print_usage() {
  echo "Usage:"
  echo "${0##*/} -h"
  echo "${0##*/} [--cpp=<C++ binary>] [--java=<Java jar file>] -o <supplementary output directory/file base name>"
  echo ""
  echo "For Java benchmarks, if any of these environment variables are defined, the benchmark will"
  echo "be run for each respective VM. If none are defined, it will just run using the installed 'java':"
  echo "  JAVA_HOME_GRAALVM: the top-level GraalVM directory"
  echo "  JAVA_HOME_HOTSPOT8: the top-level HotSpot 8 directory"
  echo "  JAVA_HOME_HOTSPOT11: the top-level HotSpot 11 directory"
}
die() { echo "$*" >&2; print_usage; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

cl_args=("$@")

#echo "$0 $@"
#echo "$0 ${cl_args[*]}"
cl_str="$0"
for arg in "${cl_args[@]}"; do
    if [[ "${arg}" == *" "* ]] ; then
        arg="\"$arg\""
    fi
    cl_str="$cl_str $arg"
done
echo "$cl_str"
echo ""

#for foo in "${cl_args[@]}"; do echo "$foo" ; done

#echo "Args = ${cl_args[*]}"
#echo ""
#
#echo "$*" | hexdump -C
#echo "$*" | hexdump -e '"%07.7_ax  " 16/1 "%03d " "\n"'
#echo ""

# Replace any Unicode dash types (endash, emdash, etc.) with a normal hyphen:
#LC_ALL=en_US.UTF-8 dash_types=$(printf "%b" "\U2010\U2011\U2012\U2013\U2014\U2015")
#cl_args="${cl_args//[$dash_types]/-}"

# Replace any Unicode dash types (endash, emdash, etc.) with a normal hyphen:
# (this seems to be more portable than the version above)
for i in "${!cl_args[@]}"; do
    cl_args[$i]="${cl_args[$i]//$(printf "%b" "\xe2\x80\x93")/-}"
    cl_args[$i]="${cl_args[$i]//$(printf "%b" "\xe2\x80\x94")/-}"
    cl_args[$i]="${cl_args[$i]//$(printf "%b" "\xe2\x80\x95")/-}"
    cl_args[$i]="${cl_args[$i]//$(printf "%b" "\xe2\x80\x96")/-}"
    cl_args[$i]="${cl_args[$i]//$(printf "%b" "\xe2\x80\x97")/-}"
    cl_args[$i]="${cl_args[$i]//$(printf "%b" "\xe2\x80\x98")/-}"
done

#echo "Args (fixed) = ${cl_args[*]}"
#echo ""
#
#echo "${cl_args[*]}" | hexdump -C
#echo "${cl_args[*]}" | hexdump -e '"%07.7_ax  " 16/1 "%03d " "\n"'
#echo ""

while getopts ho:-: OPT "${cl_args[@]}"; do
  # Command line processing based on Adam Katz's answer to
  # https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options/7948533
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"      # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning '='
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
  exit 2;
fi

echo Running benchmarks:
if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  echo "  C++ benchmark ${cpp_exe}"
fi
plain_java=false
if ! [[ "${java_jar}" == "" || "${java_jar}" == "-" ]] ; then
  if [[ "$JAVA_HOME_GRAALVM" == "" && "$JAVA_HOME_HOTSPOT8" == "" && "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
      if type java &> /dev/null; then
          plain_java=true
          echo "  Java benchmark ${java_jar}"
          echo "    will run on Java VM at $(which java)"
      else
          echo "  Warning: java not available; Java benchmark ${java_jar} will not be run"
      fi
  else
      echo "  Java benchmark ${java_jar} on VMs:"
      if ! [[ "$JAVA_HOME_GRAALVM" == "" ]] ; then
          echo "    GraalVM"
      fi
      if ! [[ "$JAVA_HOME_HOTSPOT8" == "" ]] ; then
          echo "    HotSpot 8"
      fi
      if ! [[ "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
          echo "    HotSpot 11"
      fi
  fi
fi
echo ""

if [[ "${obase}" == *"/"* ]] ; then
  # Make sure that the results directory exists
  RES_PATH="${obase%/*}"
  mkdir -p "$RES_PATH"
fi
if [[ "$RES_PATH" == "" ]] ; then
  RES_PATH="."
fi
echo Supplementary output files will be written to \"$RES_PATH\"
echo ""

if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  if [[ "${cpp_exe}" == *"/"* ]] ; then
    cpp_exe="${cpp_exe}"
  else
    cpp_exe="./${cpp_exe}"
  fi
fi

echo "Hostname: $(hostname)"
echo "Start: $(date)"
echo ""

echo "================================================================================"
echo "Environment information:"
echo "================================================================================"
echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux (probably)
    echo "OS:  Linux ($OSTYPE)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    echo "OS:  MacOS ($OSTYPE)"
elif [[ "$OSTYPE" == "cygwin" ]]; then
    # POSIX compatibility layer and Linux environment emulation for Windows
    echo "OS:  Cygwin ($OSTYPE)"
elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    echo "OS:  MinGW ($OSTYPE)"
elif [[ "$OSTYPE" == "win32" ]]; then
    # I'm not sure this can happen.
    echo "OS:  Windows32 ($OSTYPE)"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
    # FreeBSD
    echo "OS:  FreeBSD ($OSTYPE)"
elif [[ "$OSTYPE" == "openbsd"* ]]; then
    # OpenBSD
    echo "OS:  OpenBSD ($OSTYPE)"
elif [[ "$OSTYPE" == "netbsd" ]]; then
    # NetBSD
    echo "OS:  NetBSD ($OSTYPE)"
elif [[ "$OSTYPE" == "solaris"* ]]; then
    # Solaris
    echo "OS:  Solaris ($OSTYPE)"
elif [[ "$OSTYPE" == "linux-android" ]]; then
    # Android (termux)
    echo "OS:  Android ($OSTYPE)"
elif [[ "$OSTYPE" == "haiku" ]]; then
    # Haiku OS
    echo "OS:  Haiku OS ($OSTYPE)"
else
    # Unknown.
    if [[ "$OSTYPE" == "" ]]; then
        echo "OS:  unknown"
    else
        echo "OS:  $OSTYPE"
    fi
fi
echo ""


if type uname &> /dev/null; then
echo "System info:"
echo "(from uname)"
uname -a
echo ""
fi

if type lscpu &> /dev/null; then
echo "Processor info:"
echo "(from lscpu)"
lscpu
echo ""
fi

if [[ -f "/proc/cpuinfo" ]]; then
echo "Processor info:"
echo "(from head of /proc/cpuinfo)"
cat /proc/cpuinfo | grep '.*' | grep -B 500 'processor[ ]*.[:] 1$' | grep -v 'processor[ ]*.[:] 1$'
echo ""
fi

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
#if ! top -ib -n 1; then echo "Failure"; fi
top_out="$(top -ib -n 1 2>&1)"
if [[ "$?" == "0" ]]; then
    echo "Current activity:"
    echo "(top -ib -n 1)"
    echo "${top_out}"
    echo ""
fi
top_out=""
fi

echo ""
echo "================================================================================"
echo "Benchmark results:"
echo "================================================================================"
echo ""

if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  echo "================================================================================"
  echo "Run C++"
  echo "$cpp_exe -trendfile \"${obase}_cpp_1.trends\" -rf json -rff \"${obase}_cpp_1.json\""
  "$cpp_exe" -trendfile "${obase}_cpp_1.trends" -rf json -rff "${obase}_cpp_1.json"
  echo ""
fi

if ! [[ "${java_jar}" == "" || "${java_jar}" == "-" ]] ; then
    if [ "$plain_java" = true ] ; then
        echo "================================================================================"
        echo "Run Java"
        which java
        java -version
        java -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_java_1.json"
        echo ""
    else
        if ! [[ "$JAVA_HOME_GRAALVM" == "" ]] ; then
            #echo "================================================================================"
            #echo "Run Java (GraalVM), vectorization disabled"
            #export JAVA_HOME=$JAVA_HOME_GRAALVM
            #echo "$JAVA_HOME"
            #"${JAVA_HOME}/bin/java" -version
            #"${JAVA_HOME}/bin/java" -Dgraal.Vectorization=false -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_graalvm_novec_1.json"
            #echo ""
            echo "================================================================================"
            echo "Run Java (GraalVM)"
            export JAVA_HOME=$JAVA_HOME_GRAALVM
            echo "$JAVA_HOME"
            "${JAVA_HOME}/bin/java" -version
            "${JAVA_HOME}/bin/java" -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_graalvm_1.json"
            echo ""
        fi
        if ! [[ "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
            echo "================================================================================"
            echo "Run Java (Hotspot 11)"
            export JAVA_HOME=$JAVA_HOME_HOTSPOT11
            echo "$JAVA_HOME"
            "${JAVA_HOME}/bin/java" -version
            "${JAVA_HOME}/bin/java" -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_hotspot11_1.json"
            echo ""
        fi
        if ! [[ "$JAVA_HOME_HOTSPOT8" == "" ]] ; then
            echo "================================================================================"
            echo "Run Java (Hotspot 8)"
            export JAVA_HOME=$JAVA_HOME_HOTSPOT8
            echo "$JAVA_HOME"
            "${JAVA_HOME}/bin/java" -version
            "${JAVA_HOME}/bin/java" -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_hotspot8_1.json"
            echo ""
        fi
    fi
fi
if ! [[ "${cpp_exe}" == "" || "${cpp_exe}" == "-" ]] ; then
  echo "================================================================================"
  echo "Run C++"
  echo "$cpp_exe -trendfile \"${obase}_cpp_2.trends\" -rf json -rff \"${obase}_cpp_2.json\""
  "$cpp_exe" -trendfile "${obase}_cpp_2.trends" -rf json -rff "${obase}_cpp_2.json"
  echo ""
fi
if ! [[ "${java_jar}" == "" || "${java_jar}" == "-" ]] ; then
    if [ "$plain_java" = true ] ; then
        echo "================================================================================"
        echo "Run Java"
        which java
        java -version
        java -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_java_2.json"
        echo ""
    else
        if ! [[ "$JAVA_HOME_HOTSPOT8" == "" ]] ; then
            echo "================================================================================"
            echo "Run Java (Hotspot 8)"
            export JAVA_HOME=$JAVA_HOME_HOTSPOT8
            echo "$JAVA_HOME"
            "${JAVA_HOME}/bin/java" -version
            "${JAVA_HOME}/bin/java" -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_hotspot8_2.json"
            echo ""
        fi
        if ! [[ "$JAVA_HOME_HOTSPOT11" == "" ]] ; then
            echo "================================================================================"
            echo "Run Java (Hotspot 11)"
            export JAVA_HOME=$JAVA_HOME_HOTSPOT11
            echo "$JAVA_HOME"
            "${JAVA_HOME}/bin/java" -version
            "${JAVA_HOME}/bin/java" -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_hotspot11_2.json"
            echo ""
        fi
        if ! [[ "$JAVA_HOME_GRAALVM" == "" ]] ; then
            echo "================================================================================"
            echo "Run Java (GraalVM)"
            export JAVA_HOME=$JAVA_HOME_GRAALVM
            echo "$JAVA_HOME"
            "${JAVA_HOME}/bin/java" -version
            "${JAVA_HOME}/bin/java" -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_graalvm_1.json"
            echo ""
            #echo "================================================================================"
            #echo "Run Java (GraalVM), vectorization disabled"
            #export JAVA_HOME=$JAVA_HOME_GRAALVM
            #echo "$JAVA_HOME"
            #"${JAVA_HOME}/bin/java" -version
            #"${JAVA_HOME}/bin/java" -Dgraal.Vectorization=false -jar "${java_jar}" -wi 50 -rf json -rff "${obase}_graalvm_novec_2.json"
            #echo ""
        fi
    fi
fi
echo ""
echo "End: $(date)"
