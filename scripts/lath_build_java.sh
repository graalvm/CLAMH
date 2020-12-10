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


# Arguments:
# Optional first argument: JMH benchmark project directory ($LATH_HOME/jmh/lath_bm by default)
# Remaining argument(s):  Java source files


#if [[ "$2" == "" ]] ; then
#  if [[ "$LATH_HOME" == "" ]] ; then
#    echo "ERROR:  LATH_HOME not set. You must set environment variable LATH_HOME "
#    echo "        or specify a JMH benchmark project directory in the second argument."
#    exit 1
#  else
#    jmh_bm_dir=$LATH_HOME/jmh/lath_bm
#  fi
#else
#  jmh_bm_dir=$2
#fi
#
#if ! [[ -d "$jmh_bm_dir" ]] ; then
#  echo "ERROR:  JMH benchmark project directory \"$jmh_bm_dir\" does not exist or is not a directory."
#  exit 1
#fi


jmh_bm_dir=""
#base_name=""
base_dir=""
base_fname=""
if [[ "$LATH_HOME" != "" ]] ; then
  jmh_bm_dir=$LATH_HOME/jmh/lath_bm
fi

FIRST_ARG=1
for arg in "$@"
do
  if [ -d "$arg" ] ; then
    if [[ $FIRST_ARG == 1 ]] ; then
      jmh_bm_dir=$arg
    else
      echo "ERROR:  $arg is not a source file"
      exit 1
    fi
  else
    if [[ "$jmh_bm_dir" == "" ]] ; then
      echo "ERROR:  LATH_HOME not set. You must set environment variable LATH_HOME "
      echo "        or specify a JMH benchmark project directory as the first argument."
      exit 1
    fi
    if ! [[ -d "$jmh_bm_dir" ]] ; then
      echo "ERROR:  JMH benchmark project directory \"$jmh_bm_dir\" does not exist or is not a directory."
      exit 1
    fi
    if [[ "$base_fname" == "" ]] ; then
        #base_name=`echo $arg | sed 's/\.java$//'`
        if [[ "$arg" == *"/"* ]] ; then
            base_dir="${arg%/*}/"
            base_fname="${arg##*/}"
        else
            base_dir=""
            base_fname="$arg"
        fi
        base_fname="${base_fname%.java}"
        echo "Preparing benchmark project directory..."
        rm -rf "$jmh_bm_dir"/src/main/java/*
    fi

    if ! [[ -f "$arg" ]] ; then
        echo "ERROR:  File \"$arg\" does not exist."
        exit 1
    fi
    package_path=$(grep '^package' "$arg" | cut '-d ' -f2,2 | cut '-d;' -f1,1 | sed 's|\.|/|g')
    mkdir -p "$jmh_bm_dir/src/main/java/$package_path"
    cp "$arg" "$jmh_bm_dir/src/main/java/$package_path"
  fi
  FIRST_ARG=0
done


#package_path=$(grep '^package' "$1" | cut '-d ' -f2,2 | cut '-d;' -f1,1 | sed 's|\.|/|g')

##base_name=$(echo $1 | sed 's/\.java$//')
#if [[ "$1" == *"/"* ]] ; then
#    base_dir="${1%/*}/"
#    base_fname="${1##*/}"
#else
#    base_dir=""
#    base_fname="$1"
#fi
#base_fname="${base_fname%.java}"

#echo "Preparing benchmark project directory..."
#rm -rf "$jmh_bm_dir"/src/main/java/*
#mkdir -p "$jmh_bm_dir/src/main/java/$package_path"
#cp "$1" "$jmh_bm_dir/src/main/java/$package_path"


#echo ${base_dir} ${base_fname} $package_path

if [[ "$base_fname" == "" ]] ; then
  echo "Usage:  ${0##*/} [(optional) path to JMH project directory] <java source filenames>..."
  exit 1
fi

echo "Building jar file..."
cd "$jmh_bm_dir" || exit 2
rm -f target/benchmarks.jar
mvn clean install
cd - || exit 2

jarfilename="${base_dir}run_${base_fname}.jar"

cp "$jmh_bm_dir/target/benchmarks.jar" "$jarfilename"

echo "Done. $jarfilename built."

