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
# Optional first argument: path to directory clamh-cpp ($CLAMH_HOME/clamh-cpp by default)
# Remaining argument: C++ source file
#
# The compiler specified in environment variable "CPP" will be used. If CPP is not defined,
# then "g++" will be used by default.

print_usage() {
    echo "Usage:  ${0##*/} [(optional) path to clamh-cpp] <c++ source filename>"
    echo "        Note: will use the compiler specified in environment variable CPP."
    echo "        [If CPP is not set, will use g++ by default.]"
}

if [[ "$CPP" == "" ]] ; then
    # g++ by default
    CPP=g++
fi

if [[ "$1" == "" ]] ; then
    print_usage
    exit 1
fi

if [ -d "$1" ] ; then
    CLAMH_CPP_DIR="$1"
    source_file="$2"
else
    source_file="$1"
fi

if [[ "$CLAMH_CPP_DIR" == "" ]] ; then
  if [[ "$CLAMH_HOME" == "" ]] ; then
    echo "ERROR:  CLAMH_HOME not set. You must set environment variable CLAMH_HOME "
    echo "        or specify the path to clamh-cpp in the first argument."
    exit 1
  else
    CLAMH_CPP_DIR="$CLAMH_HOME/clamh-cpp"
  fi
fi

if [[ "$source_file" == "" ]] ; then
    echo "ERROR:  No source file specified."
    print_usage
    exit 1
fi

if ! [[ -d "$CLAMH_CPP_DIR" ]] ; then
  echo "ERROR:  CLAMH-cpp directory \"$CLAMH_CPP_DIR\" does not exist or is not a directory."
  exit 1
fi

if ! [[ -f "$source_file" ]] ; then
    echo "ERROR:  File \"$source_file\" does not exist."
    exit 1
fi

if ! [[ -f "$CLAMH_CPP_DIR/cpp_parser" ]] ; then
    echo "ERROR:  \"$CLAMH_CPP_DIR/cpp_parser\" does not exist."
    echo "(You may need to run \"make\" in the top-level CLAMH directory or in $CLAMH_CPP_DIR)"
    exit 1
fi

#base_name=$(echo $source_file | sed 's/\.cpp$//')
#base_name="${source_file//\.cpp$/}"
if [[ "$source_file" == *"/"* ]] ; then
    base_dir="${source_file%/*}/"
    base_fname="${source_file##*/}"
else
    base_dir=""
    base_fname="$source_file"
fi
base_fname="${base_fname%.cpp}"

gen_file="${base_dir}run_${base_fname}.cpp"

echo "Generating benchmark harness ($gen_file)..."
"$CLAMH_CPP_DIR/cpp_parser" "$source_file" > "$gen_file" || exit 1

echo "Building executable..."
echo "Using compiler:  $CPP"
"$CPP" -std=c++11 -O3 "-I$CLAMH_CPP_DIR" -o "${base_dir}run_${base_fname}" "$gen_file" || exit 1

if [[ -f "${base_dir}run_${base_fname}" ]] ; then
    echo "Done. ${base_dir}run_${base_fname} built."
else
    echo "Build failed"
fi
