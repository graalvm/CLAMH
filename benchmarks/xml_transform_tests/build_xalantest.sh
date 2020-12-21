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

# Environment variables required:
# XALAN_DIR: the top-level xalan directory

# Arguments:
# $1: (optional) path to directory clamh-cpp

if [[ "$1" == "" ]] ; then
  if [[ "$CLAMH_HOME" == "" ]] ; then
    echo "ERROR:  CLAMH_HOME not set. You must set environment variable CLAMH_HOME "
    echo "        or specify the path to clamh-cpp as an argument."
    exit 1
  else
    CLAMH_CPP_DIR=$CLAMH_HOME/clamh-cpp
  fi
else
  CLAMH_CPP_DIR=$1
fi

if ! [[ -d $CLAMH_CPP_DIR ]] ; then
  echo "ERROR:  CLAMH-C++ directory \"$CLAMH_CPP_DIR\" does not exist or is not a directory."
  exit 1
fi

gen_file="run_xalantest.cpp"

echo "Generating benchmark harness ($gen_file)..."
"$CLAMH_CPP_DIR/cpp_parser" xalantest.cpp > "$gen_file"

echo "Building executable..."
g++ -std=c++11 -O3 "-I$CLAMH_CPP_DIR" "-I${XALAN_DIR}/include" "-L${XALAN_DIR}/lib" -lxalan-c -lxalanMsg -lxerces-c -o run_xalantest "$gen_file" || exit 1

echo "Done. run_xalantest built."

