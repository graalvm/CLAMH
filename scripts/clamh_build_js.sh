#!/bin/bash

# Copyright (c) 2021 Oracle
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
# Optional first argument: path to directory clamh-js ($CLAMH_HOME/clamh-js by default)
# Remaining argument: Javascript source file

print_usage() {
    echo "Usage:  ${0##*/} [(optional) path to clamh-js] <Javascript source filename>"
}

if [[ "$1" == "" ]] ; then
    print_usage
    exit 1
fi

if [ -d "$1" ] ; then
    CLAMH_JS_DIR="$1"
    source_file="$2"
else
    source_file="$1"
fi

if [[ "$CLAMH_JS_DIR" == "" ]] ; then
  if [[ "$CLAMH_HOME" == "" ]] ; then
    echo "ERROR:  CLAMH_HOME not set. You must set environment variable CLAMH_HOME "
    echo "        or specify the path to clamh-js in the first argument."
    exit 1
  else
    CLAMH_JS_DIR=$CLAMH_HOME/clamh-js
  fi
fi

if [[ "$source_file" == "" ]] ; then
    echo "ERROR:  No source file specified."
    print_usage
    exit 1
fi

if ! [[ -d "$CLAMH_JS_DIR" ]] ; then
  echo "ERROR:  CLAMH-JS directory \"$CLAMH_JS_DIR\" does not exist or is not a directory."
  exit 1
fi

if ! [[ -f "$source_file" ]] ; then
    echo "ERROR:  File \"$source_file\" does not exist."
    exit 1
fi

if ! [[ -f "$CLAMH_JS_DIR/js_parser" ]] ; then
    echo "ERROR:  \"$CLAMH_JS_DIR/js_parser\" does not exist."
    echo "(You may need to run \"make\" in the top-level CLAMH directory or in $CLAMH_JS_DIR)"
    exit 1
fi


#base_name=`echo $1 | sed 's/\.js$//'`
#gen_file=run_$1

if [[ "$source_file" == *"/"* ]] ; then
    base_dir="${source_file%/*}/"
    base_fname="${source_file##*/}"
else
    base_dir=""
    base_fname="$source_file"
fi
base_fname="${base_fname%.js}"

gen_file="${base_dir}run_${base_fname}.js"

echo "Generating benchmark harness ($gen_file)..."
$CLAMH_JS_DIR/js_parser "$source_file" > "$gen_file" || exit 1

if [[ -f "$gen_file" ]] ; then
    echo "Done. $gen_file built."
else
    echo "Build failed"
fi
