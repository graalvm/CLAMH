#!/bin/bash

# Copyright (c) 2019-2021 Oracle
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


# If clamh_exec_all.sh is used for the script,
# then one or more of these environment variables may be defined
# (if none of these are defined, then the installed 'java' will be used):
# JAVA_HOME_GRAAL: the top-level GraalVM directory
# JAVA_HOME_HOTSPOT8: the top-level HotSpot 8 directory
# JAVA_HOME_HOTSPOT11: the top-level HotSpot 11 directory


print_usage() {
    echo "Usage:"
    echo "${0##*/} -h"
    echo "${0##*/} [--cpp=<C++ binary>] [--java=<Java jar file>] [--js=<Javascript file>] --exec=<script to be run>"
    echo "                  -q <queue name> -o <output directory base name> [-t <time_limit ('00:15:00' by default)>]"
    echo "                  [--reps=<number of repetitions (3 by default)>]"
    echo "[The -q option may be specified multiple times. The script will be run for each specified queue.]"
    echo ""
    echo "For Java benchmarks, if any of these environment variables are defined, the benchmark will"
    echo "be run on each of the respective VMs. If none are defined, it will just run using the installed 'java':"
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

time_limit="00:15:00"
reps=3
while getopts ho:q:t:-: OPT "${cl_args[@]}"; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"      # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    cpp )    needs_arg; cpp_exe="$OPTARG" ;;
    java )   needs_arg; java_jar="$OPTARG" ;;
    js )     needs_arg; js_file="$OPTARG" ;;
    exec )   needs_arg; exec_script="$OPTARG" ;;
    reps )   needs_arg; reps="$OPTARG" ;;
    q )      needs_arg; queues="$queues $OPTARG" ;;
    o )      needs_arg; obasedir="$OPTARG" ;;
    t )      needs_arg; time_limit="$OPTARG" ;;
    h )      print_usage; exit 0 ;;
    ??* )    die "Illegal option --$OPT" ;;  # bad long option
    ? )      print_usage; exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

if [[ "${exec_script}" == "" ]] ; then
    die "Error: the script to be run must be specified (e.g., '--exec=clamh_exec_all.sh')"
fi
if [[ "${queues}" == "" ]] ; then
    die "Error: at least one slurm queue must be specified (Use 'sinfo' to see the available queues)"
fi

if [[ "${obasedir}" == "" ]] ; then
    die "Error: The output directory base name must be specified"
fi

if ! [[ "${cpp_exe}" == "" ]] ; then
    # strip off the ".exe" if running in a Windows environment, e.g., cygwin:
    label="${cpp_exe%%.exe}"
else
    if ! [[ "${java_jar}" == "" ]] ; then
        label="${java_jar%%.jar}"
    else
        if ! [[ "${js_file}" == "" ]] ; then
            # strip off the ".js"
            label="${js_file%%.js}"
        else
            die "Error: a benchmark to run must be specified (via --cpp, --java, or --js)"
        fi
    fi
fi

if ! [[ "${cpp_exe}" == "" ]] ; then
    exec_options="${exec_options} --cpp=./${cpp_exe}"
fi
if ! [[ "${java_jar}" == "" ]] ; then
    exec_options="${exec_options} --java=${java_jar}"
fi
if ! [[ "${js_file}" == "" ]] ; then
    exec_options="${exec_options} --js=${js_file}"
fi

for queue in ${queues}
do

resultdir="${obasedir}_${queue}"
if ! [[ ${obasedir:0:1} == "/" ]] ; then
    resultdir="$(pwd)/${resultdir}"
fi

mkdir -p "${resultdir}"



#for rep in 1 2 3
for ((rep=1;rep<=reps;rep++))
do

FileBase="${label}_test_rep${rep}"
sbatch -p ${queue} -t ${time_limit} "--comment=benchmark:${FileBase}" \
    --exclusive \
    -e "${resultdir}/${FileBase}.err" -o "${resultdir}/${FileBase}.result" \
    --wrap="${exec_script}${exec_options} -o \"${resultdir}/${FileBase}\""

done

done
