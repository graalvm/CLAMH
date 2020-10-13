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
# $1: Java source file
# $2: (optional) JMH benchmark project directory ($LATH_HOME/jmh/lath_bm by default)


if [[ "$1" == "" ]] ; then
  echo "Usage:  ${0##*/} <java source filename> [(optional) path to JMH project directory]"
  exit 1
fi

if [[ "$2" == "" ]] ; then
  if [[ "$LATH_HOME" == "" ]] ; then
    echo "ERROR:  LATH_HOME not set. You must set environment variable LATH_HOME "
    echo "        or specify a JMH benchmark project directory in the second argument."
    exit 1
  else
    JMH_BM_DIR=$LATH_HOME/jmh/lath_bm
  fi
else
  JMH_BM_DIR=$2
fi

if ! [[ -d $JMH_BM_DIR ]] ; then
  echo "ERROR:  JMH benchmark project directory \"$JMH_BM_DIR\" does not exist or is not a directory."
  exit 1
fi


package_path=`grep '^package' $1 | cut '-d ' -f2,2 | cut '-d;' -f1,1 | sed 's|\.|/|g'`

base_name=`echo $1 | sed 's/\.java$//'`


#echo $base_name $package_path

echo "Preparing benchmark project directory..."
rm -rf $JMH_BM_DIR/src/main/java/*
mkdir -p $JMH_BM_DIR/src/main/java/$package_path
cp $1 $JMH_BM_DIR/src/main/java/$package_path

echo "Building jar file..."
cd $JMH_BM_DIR
rm -f target/benchmarks.jar
mvn clean install
cd -

cp $JMH_BM_DIR/target/benchmarks.jar run_${base_name}.jar

echo "Done. run_${base_name}.jar built."

