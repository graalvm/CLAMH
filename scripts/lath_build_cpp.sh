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
# $1: C++ source file
# $2: (optional) path to directory lath-cpp ($LATH_HOME/lath-cpp by default)


if [[ "$1" == "" ]] ; then
  echo "Usage:  ${0##*/} <c++ source filename> [(optional) path to lath-cpp]"
  exit 1
fi

if [[ "$2" == "" ]] ; then
  if [[ "$LATH_HOME" == "" ]] ; then
    echo "ERROR:  LATH_HOME not set. You must set environment variable LATH_HOME "
    echo "        or specify the path to lath-cpp in the second argument."
    exit 1
  else
    LATH_CPP_DIR=$LATH_HOME/lath-cpp
  fi
else
  LATH_CPP_DIR=$2
fi

if ! [[ -d $LATH_CPP_DIR ]] ; then
  echo "ERROR:  LATH-cpp directory \"$LATH_CPP_DIR\" does not exist or is not a directory."
  exit 1
fi


#base_name=$(echo $1 | sed 's/\.cpp$//')
#base_name="${1//\.cpp$/}"
if [[ "$1" == *"/"* ]] ; then
    base_dir="${1%/*}/"
    base_fname="${1##*/}"
else
    base_dir=""
    base_fname="$1"
fi
base_fname="${base_fname%.cpp}"

gen_file="${base_dir}run_${base_fname}.cpp"

echo "Generating test harness ($gen_file)..."
"$LATH_CPP_DIR/cpp_parser" "$1" > "$gen_file"

echo "Building executable..."
g++ -std=c++11 -O3 "-I$LATH_CPP_DIR" -o "${base_dir}run_${base_fname}" "$gen_file" || exit 1

echo "Done. ${base_dir}run_${base_fname} built."

