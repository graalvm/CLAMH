/*
Copyright (c) 2019 Oracle

The Universal Permissive License (UPL), Version 1.0

Subject to the condition set forth below, permission is hereby granted to any person
obtaining a copy of this software, associated documentation and/or data (collectively the
"Software"), free of charge and under any and all copyright rights in the Software, and
any and all patent rights owned or freely licensable by each licensor hereunder covering
either (i) the unmodified Software as contributed to or provided by such licensor, or (ii)
the Larger Works (as defined below), to deal in both

(a) the Software, and

(b) any piece of software and/or hardware listed in the lrgrwrks.txt file if one is
included with the Software (each a “Larger Work” to which the Software is contributed by
such licensors),

without restriction, including without limitation the rights to copy, create derivative
works of, display, perform, and distribute the Software and make, use, sell, offer for
sale, import, export, have made, and have sold the Software and the Larger Work(s), and to
sublicense the foregoing rights on either these or other terms.

This license is subject to the following condition:

The above copyright notice and either this complete permission notice or at a minimum a
reference to the UPL must be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

#ifndef __TEST_HARNESS_UTILITIES_PRIVATE__
#define __TEST_HARNESS_UTILITIES_PRIVATE__


// Utility functions used only by the test harness and its generated code (hence "private")

#include <chrono>
#include <inttypes.h>
#include <limits>
#include <algorithm>
#include <cmath>
#include <string>
#include <cstring>
#include <type_traits>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <fstream>

#include "lath_version.hpp"
#include "Blackhole.hpp"
//#include "Control.hpp"
#include "CommandOptionHandler.h"
#include "MakeStr.hpp"
#include "string_utils.hpp"

#include "include/rapidjson/document.h"
#include "include/rapidjson/writer.h"
#include "include/rapidjson/prettywriter.h"
#include "include/rapidjson/stringbuffer.h"

namespace harness_utils_private {

typedef std::chrono::nanoseconds::rep IntTimeNS;


//
//  std::string true_cxx =
//#ifdef __clang__
//   "clang++";
//#else
//   "g++";
//#endif
//
//  std::string true_cxx_ver =
//#ifdef __clang__
//    VER_STRING(__clang_major__, __clang_minor__, __clang_patchlevel__);
//#else
//    VER_STRING(__GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
//#endif



#define STRINGIFY(x) #x
#define VER_STRING(major, minor, patch) STRINGIFY(major) "." STRINGIFY(minor) "." STRINGIFY(patch)

// Print LATH version and the compiler version
void printVersion() {
  cout << "LATH version: " << LATH_VERSION << std::endl;

// This should work for g++ and clang (and possibly other compilers):
#if defined(__clang__)
  cout << "Compiler version: clang++ " << VER_STRING(__clang_major__, __clang_minor__, __clang_patchlevel__)
       << std::endl;
#elif defined(_MSC_VER)
  cout << "Compiler version: VS " << _MSC_VER << std::endl;
#elif defined(__VERSION__)
#ifdef __GNUC__
  //    VER_STRING(__GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
  cout << "Compiler version: g++ " << __VERSION__ << std::endl;
#else
  cout << "Compiler version: ?? " << __VERSION__ << std::endl;
#endif
#else
  cout << "[Unfamiliar compiler version]" << std::endl;
#endif
  // Add others as needed...
}

// Print usage
void usage(const std::string &exe_full_path) {
   // Split off the path
   std::vector<std::string> split_vec;
   std::string exe_name = string_utils::splitString(exe_full_path, '/', split_vec).back();
   std::cout << exe_name << " [-h] [-v] [-p <param>=<value,...>...]" << std::endl;
   std::cout << std::setfill(' ') << std::setw(exe_name.size() + 1) << ' '
             << "[-i <int>] [-wi <int>] [-r <time>] [-w <time>]" << std::endl;
   std::cout << std::setfill(' ') << std::setw(exe_name.size() + 1) << ' '
             << "[-rf <report_format>] [-rff <report_file>] [-trendfile <filename>]" << std::endl;
   std::cout << std::endl;
   std::cout << "  -h                      Print usage (what you're reading now)" << std::endl;
   std::cout << "  -v                      Print version" << std::endl;
   std::cout << "  -i <int>                Number of measurement iterations to do. Overrides annotations." << std::endl;
   std::cout << "  -r <time>               Run time for each iteration. Overrides annotations." << std::endl;
   std::cout << "                          Time is specified as an integer followed by the units." << std::endl;
   std::cout << "                          (e.g., -r 500ms)" << std::endl;
   std::cout << "                            Units:" << std::endl;
   std::cout << "                            ns = nanoseconds" << std::endl;
   std::cout << "                            us = microseconds" << std::endl;
   std::cout << "                            ms = milliseconds" << std::endl;
   std::cout << "                            s = seconds" << std::endl;
   std::cout << "                            m = minutes" << std::endl;
   std::cout << "                            h = hours" << std::endl;
   std::cout << "                            d = days" << std::endl;
   std::cout << "  -w <time>               Run time for each warmup iteration. Overrides annotations." << std::endl;
   std::cout << "                          See \"-r\" for time formatting details." << std::endl;
   std::cout << "  -wi <int>               Number of warmup iterations to do. Overrides annotations." << std::endl;
   std::cout << "  -p <param>=<value,...>  Override the set of values for a parameter. This option" << std::endl;
   std::cout << "                          may be specified multiple times for different parameters." << std::endl;
   std::cout << "                          (Example: -p some_parm=3,4,5)" << std::endl;
   std::cout << "  -rf <report_format>     Specify the optional supplementary report format" << std::endl;
   std::cout << "                          (currently, the only valid option is 'json')" << std::endl;
   std::cout << "  -rff <filename>         Report file name. If specified, a supplementary report" << std::endl;
   std::cout << "                          will be generated." << std::endl;
   std::cout << "  -trendfile <filename>   If specified, generates detailed trend information for" << std::endl;
   std::cout << "                          warmup and CPU speed changes." << std::endl;
}

// Volatile sink to prevent unwanted "dead code" optimization:
int sink = 0;
volatile int sink_final = 0;

// Volatile boolean (used to prevent unwanted pointer elimination and inlining)
volatile bool always_true = true;


// Attach "uncertainty" to a pointer (e.g., to avoid "constant folding")
template <typename T>
inline auto makeUncertainPtr2(T ptr) -> T {
   T unc_ptr;
   if (always_true) { unc_ptr = ptr; }
   else             { unc_ptr = nullptr; }

   return unc_ptr;
}


// Attach "uncertainty" to a pointer (e.g., to avoid "constant folding")
template <typename T>
inline auto makeUncertainPtr(T *ptr) -> T* {
   T *unc_ptr;
   if (always_true) { unc_ptr = ptr; }
   else             { unc_ptr = nullptr; }

   return unc_ptr;
}


// Attach "uncertainty" to a reference (e.g., to avoid "constant folding")
template <typename T>
inline auto makeUncertainRef(T &ref) -> T& {
   return *(makeUncertainPtr(&ref));
}


// Create an "indeterminate" function pointer that cannot be inlined:
// (This is just a renaming of makeUncertainPtr that is more mnemonic for functions/methods)
template <typename FuncType>
inline auto noInline(FuncType func_ptr) -> FuncType {
   return makeUncertainPtr2(func_ptr);
}


// Set a value from a string (will work even if the variable is volatile)
// (Returns false if the attempt was unsuccessful)
template <typename T>
inline bool setVarFromString(T &var, const std::string &val_str) {
   std::istringstream iss(val_str);

   typedef typename std::remove_volatile<T>::type nv_T;
   nv_T nv_var;

   //iss >> nv_var;
   //iss >> std::boolalpha >> nv_var;
   //if (!(iss >> std::boolalpha >> nv_var)) {
   //   return false;
   //}

   if (!(iss >> nv_var)) {
      // This may have been an attempt to read an alpha boolean expression.
      // Try again with the boolalpha flag
      std::istringstream iss2(val_str);
      if (!(iss2 >> std::boolalpha >> nv_var)) {
         return false;
      }
   }

   var = nv_var;

   return true;
}


// Set a parameter value from a value string (will work even if the param is volatile)
// (convenience method, just renames setVarFromString for clarity)
// XXX should probably deprecate this and just use the above function
template <typename T>
inline bool setParam(T &param, const std::string &val_str) {
   return setVarFromString(param, val_str);
}


// This is a test function that tests that setVarFromString() is operating correctly
// (this can particularly be a problem when reading in boolean values)
void testSetVarFromString() {
   {
      int val;
      assert(setVarFromString(val, "-3"));
      assert(val == -3);
   }

   {
      double val;
      assert(setVarFromString(val, "0.5"));
      assert(val == 0.5);
   }

   {
      bool val;
      assert(setVarFromString(val, "0"));
      assert(val == false);
   }

   //{
   //   bool val;
   //   assert(setVarFromString(val, "F"));
   //   assert(val == false);
   //}

   //{
   //   bool val;
   //   assert(setVarFromString(val, "f"));
   //   assert(val == false);
   //}

   {
      bool val;
      assert(setVarFromString(val, "false"));
      assert(val == false);
   }

   {
      bool val;
      assert(setVarFromString(val, "1"));
      assert(val == true);
   }

   //{
   //   bool val;
   //   assert(setVarFromString(val, "T"));
   //   assert(val == true);
   //}

   //{
   //   bool val;
   //   assert(setVarFromString(val, "t"));
   //   assert(val == true);
   //}

   {
      bool val;
      assert(setVarFromString(val, "true"));
      assert(val == true);
   }

   {
      std::string val;
      assert(setVarFromString(val, "a_string"));
      assert(val == "a_string");
   }

   {
      long val;
      assert(setVarFromString(val, "1000000"));
      assert(val == 1000000l);
   }

   {
      long long val;
      assert(setVarFromString(val, "1000000000001"));
      assert(val == 1000000000001ll);
   }
}


// Time representation (interval and units)
struct Time {
   int value {-1};
   std::string unit_str;
   uint64_t time_nsec;
};

inline bool setTimeFromString(Time &var, const std::string &val_str) {
   // We'll use sscanf to split the value from the units:
   int value;
   char unit_str_buf[22];
   if (sscanf(val_str.c_str(), "%i%20s", &value, unit_str_buf) != 2) { return false; }
   std::string unit_str(unit_str_buf);

   if (unit_str == "ns") {
      var.time_nsec = value;
   } else if (unit_str == "us") {
      var.time_nsec = ((uint64_t)value)*1000ull;
   } else if (unit_str == "ms") {
      var.time_nsec = ((uint64_t)value)*1000ull*1000ull;
   } else if (unit_str == "s") {
      var.time_nsec = ((uint64_t)value)*1000ull*1000ull*1000ull;
   } else if (unit_str == "m") {
      var.time_nsec = ((uint64_t)value)*60ull*1000ull*1000ull*1000ull;
   } else if (unit_str == "h") {
      var.time_nsec = ((uint64_t)value)*60ull*60ull*1000ull*1000ull*1000ull;
   } else if (unit_str == "d") {
      var.time_nsec = ((uint64_t)value)*24ull*60ull*60ull*1000ull*1000ull*1000ull;
   } else {
      return false;
   }
   
   var.value = value;
   var.unit_str = unit_str;

   return true;
}


struct ParamOverride {
   std::string param;
   std::vector<std::string> val_vec;

   ParamOverride(std::string &par, std::vector<std::string> &vv) :
      param(std::move(par)),
      val_vec(std::move(vv))
   {}
};

struct ParamOverrides {
   std::vector<ParamOverride> param_override_vec;
   
   void AddOverride(const std::string &param_str) {
      std::string param;
      std::string vals;
      std::vector<std::string> val_vec;
      string_utils::splitStringOnFirst(param_str, '=', param, vals);
      if (param == "") {
         std::cerr << "Error: '-p' option: the parameter name must be specified." << std::endl;
         std::cerr << "       (e.g., '-p some_parm=3,4,5')" << std::endl;
         abort();
      }
      if (vals == "") {
         std::cerr << "Error: '-p' option: at least one parameter value must be specified." << std::endl;
         std::cerr << "       (e.g., '-p some_parm=3,4,5')" << std::endl;
         abort();
      }
      string_utils::splitString(vals, ',', val_vec);
      param_override_vec.emplace_back(param, val_vec);
   }
};

struct ParamInfo {
   std::string name;      // Short name of parameter (e.g., "number")
   std::string long_name; // Fully qualified name of parameter (e.g., "MyState::number")
   std::vector<std::string> val_vec; // The parameter values

   ParamInfo(const std::string &nm, const std::string &lnm, const std::vector<std::string> &vv) :
      name(std::move(nm)),
      long_name(std::move(lnm)),
      val_vec(std::move(vv))
   {}
};

struct ParamHandler {
   std::vector<ParamInfo> params;
   
   void addParam(const std::string &name, const std::string &long_name,
                 const std::vector<std::string> &val_vec)
   {
      params.emplace_back(name, long_name, val_vec);
   }

   // Update params with override values (e.g., from the command line)
   void setOverrides(const ParamOverrides &pos) {
      // Loop over the overrides
      for (const auto &over : pos.param_override_vec) {
         // For each, find a matching parameter (but verify that there is only one match)
         ParamInfo *match = nullptr;
         for (auto &param : params) {
            if ((over.param == param.name) || (over.param == param.long_name)) {
               if (match != nullptr) {
                  std::cerr << "Error: parameter override '" << over.param
                            << "' is ambiguous. The fully qualified parameter name is required here." << std::endl;
                  std::cerr << "       (e.g., replace '" << over.param << "' with '" << match->long_name
                            << "', '" << param.long_name << "', etc.)" << std::endl;
                  abort();
               }
               match = &param;
            }
         }
         if (match == nullptr) {
            std::cerr << "Error: parameter override '" << over.param
                      << "' is not a recognized parameter." << std::endl;
            abort();
         }
         // Overwrite the values for the matching parameter
         match->val_vec = over.val_vec;
      }
   }

   const std::vector<std::string> &getParamVals(const std::string &long_nm) {
      for (const auto &param : params) {
         if (long_nm == param.long_name) {
            return param.val_vec;
         }
      }
      // Not found - we should not get here!
      assert(0);
   }

   void printParams() {
      if (params.size() > 0) {
         std::cout << std::endl;
         std::cout << "Parameter sets:" << std::endl;
         for (const auto &param : params) {
            std::cout << "    " << param.long_name << ": (";
            bool first = true;
            for (const auto &val : param.val_vec) {
               if (first) { first = false; }
               else       { std::cout << ", "; }
               std::cout << "\"" << val << "\"";
            }
            std::cout << ")" << std::endl;
         }
      }
   }
};

// Info from the command-line options
struct CLOptions {
   bool no_run{false};
   
   double winnow_thresh{1.0};

   ParamOverrides param_overrides;

   int bm_it {-1};  // Number of iterations (override)
   int warmup_it {-1};  // Number of warmup iterations (override)
   Time bm_time;  // Time per iteration (override)
   Time warmup_time; // Time per warmup iteration (override)

   std::ofstream trendfile_stream;
   std::ostream *postream_trends{nullptr};

  std::ofstream jsonfile_stream;
  std::ostream *postream_json{nullptr};
};

class LATHOptionHandler : public CommandOptionHandler {
   CLOptions &cl_options_;
public:
   LATHOptionHandler(const char *opdef,     ///< Option definition string
                     CLOptions &cl_options) ///< Parsed command-line option data
      : CommandOptionHandler(opdef),
        cl_options_(cl_options)
   {}
   
   //! command-line option handler to pick up multiple argument overrides
   virtual void handleOption(const char *op, const char *value)
   {
      // Handle param override, e.g. "-p arg=41,42"
      if (strcmp(op,"p") == 0) {
         cl_options_.param_overrides.AddOverride(value);
      }
   }
};

// Parse the command-line options for the generated test harness code:
void parseCommandLine(CLOptions &cl_options, int argc, char **argv) {
   // Print the command line:
   for (int i=0; i<argc; ++i) { std::cout << argv[i] << " "; }
   std::cout << "\n" << std::endl;

   // Create a command option handler
   const char *validOptions = "winnow-thresh:, trendfile:, rf:, rff:, p:, i:, r:, wi:, w:, h, v";

   //OptionAndFilenameHandler COH(validOptions, 0);
   LATHOptionHandler COH(validOptions, cl_options);
   
   try
   {
      // Parse the command-line options
      COH.parseOptions(argc, argv);
   }
   catch (CommandOptionHandler::UnknownOption uO)
   {
      cerr << "Don't understand option \"-" << uO.option << "\"" << endl;
      usage(argv[0]);
      assert(0);
   }
   catch (CommandOptionHandler::UnknownArg uA)
   {
      cerr << "Unknown argument \"" << uA.arg << "\"" << endl;
      usage(argv[0]);
      assert(0);
   }

   if (COH.opCheck("v")) {
      printVersion();
      cl_options.no_run = true;
   }

   if (COH.opCheck("h")) {
      if (COH.opCheck("v")) {
         std::cout << std::endl;
      }
      usage(argv[0]);
      cl_options.no_run = true;
   }

   if (COH.opCheck("i")) {
      if (setVarFromString(cl_options.bm_it, std::string(COH.opValue("i"))) == false) {
         std::cerr << "Error: invalid value specified for option '-i': " << COH.opValue("i") << std::endl;
         abort();
      }
   }

   if (COH.opCheck("r")) {
      if (setTimeFromString(cl_options.bm_time, std::string(COH.opValue("r"))) == false) {
         std::cerr << "Error: invalid time format specified for option '-r': " << COH.opValue("r") << std::endl;
         abort();
      }
   }

   if (COH.opCheck("wi")) {
      if (setVarFromString(cl_options.warmup_it, std::string(COH.opValue("wi"))) == false) {
         std::cerr << "Error: invalid value specified for option '-wi': " << COH.opValue("wi") << std::endl;
         abort();
      }
   }

   if (COH.opCheck("w")) {
      if (setTimeFromString(cl_options.warmup_time, std::string(COH.opValue("w"))) == false) {
         std::cerr << "Error: invalid time format specified for option '-w': " << COH.opValue("w") << std::endl;
         abort();
      }
   }

   if (COH.opCheck("winnow-thresh")) {
      std::string thresh_str = COH.opValue("winnow-thresh");
      if (setVarFromString(cl_options.winnow_thresh, thresh_str) == false) {
         std::cerr << "Error: invalid value specified for the winnow-thresh option: " << thresh_str << std::endl;
         abort();
      }

      std::cout << "Winnowing threshold for CPU speed and warmup trends set to " << cl_options.winnow_thresh << std::endl;
   }

   if (COH.opCheck("trendfile")) {
      std::string trendfile_name = COH.opValue("trendfile");
      if (trendfile_name == "-") {
         cl_options.postream_trends = &(std::cout);
      } else {
         cl_options.trendfile_stream.open(trendfile_name);
         if (cl_options.trendfile_stream.is_open()) {
            cl_options.postream_trends = &(cl_options.trendfile_stream);
            std::cout << "CPU speed and warmup trends written to file " << trendfile_name << std::endl;
         } else {
            std::cerr << "Error: unable to open trends file for writing: " << trendfile_name << std::endl;
            abort();
         }
      }
   }

   if (COH.opCheck("rf")) {
     // only "json" is currently supported
     assert(std::string(COH.opValue("rf")) == "json");
   }

   if (COH.opCheck("rff")) {
      std::string jsonfile_name = COH.opValue("rff");
      if (jsonfile_name == "-") {
         cl_options.postream_json = &(std::cout);
      } else {
         cl_options.jsonfile_stream.open(jsonfile_name);
         if (cl_options.jsonfile_stream.is_open()) {
            cl_options.postream_json = &(cl_options.jsonfile_stream);
            std::cout << "Results written to JSON file: " << jsonfile_name << std::endl;
         } else {
            std::cerr << "Error: unable to open JSON file for writing: " << jsonfile_name << std::endl;
            abort();
         }
      }
   }
}


struct TimingTrend {
   uint64_t total_loop_count {0};
   double av_time_per_op {0.0};
   
   // Constructor
   TimingTrend(uint64_t lc, double av_tpo) :
      total_loop_count(lc),
      av_time_per_op(av_tpo)
   {}
};

struct CPUTrend {
   uint64_t total_loop_count {0};
   double rel_cpu_speed {0.0};
   
   // Constructor
   CPUTrend(uint64_t lc, double rcs) :
      total_loop_count(lc),
      rel_cpu_speed(rcs)
   {}
};


struct CPUAndTimingTrend {
   std::vector<uint64_t> total_loop_count_vec;
   std::vector<double> av_time_per_op_vec;
   std::vector<double> rel_cpu_speed_vec;
   std::vector<double> running_mean_av_tpo_vec;
   std::vector<double> running_var_av_tpo_vec;
   std::vector<double> running_mean_adj_av_tpo_vec;
   std::vector<double> running_var_adj_av_tpo_vec;

   double winnow_thresh_rcs;
   double winnow_thresh_avtpo;
   double cur_av_tpo{0.0};
   double cur_rcs{0.0};
   
   double cur_mean_av_tpo{0.0};
   double cur_var_av_tpo{0.0};
   double cur_mean_adj_av_tpo{0.0};
   double cur_var_adj_av_tpo{0.0};

   bool starting{true};
   uint64_t sample_count{0};
   
   uint64_t lc_run_start{0};
   uint64_t lc_run_end{0};
   double av_tpo_run_sum{0.0};
   double rcs_run_start{0.0};
   double rcs_run_end{0.0};

   double mean_av_tpo_run_start{0.0};
   double mean_av_tpo_run_end{0.0};
   double var_av_tpo_run_start{0.0};
   double var_av_tpo_run_end{0.0};

   double mean_adj_av_tpo_run_start{0.0};
   double mean_adj_av_tpo_run_end{0.0};
   double var_adj_av_tpo_run_start{0.0};
   double var_adj_av_tpo_run_end{0.0};

   double running_mean_av_tpo{0.0};
   double running_quadmean_av_tpo{0.0};
   double running_mean_adj_av_tpo{0.0};
   double running_quadmean_adj_av_tpo{0.0};

   uint64_t run_count{0};

   std::ostream *pout;
   
   // Constructor
   CPUAndTimingTrend(std::ostream *pos, double win_thr_rcs, double win_thr_avtpo) :
      winnow_thresh_rcs(win_thr_rcs),
      winnow_thresh_avtpo(win_thr_avtpo),
      pout(pos)
   {}
   
   void update(uint64_t lc, double av_tpo, double rcs) {
      // Compute the adjusted av_tpo
      double adj_av_tpo;
      if (rcs == 0.0) {
         // This should never happen, but just in case...
         adj_av_tpo = av_tpo;
      } else {
         adj_av_tpo = av_tpo/rcs;
      }

      // Compute the running average and variance of av_tpo using exponential smoothing.
      // The decay factor is slowly increasing over time (as warmup occurs),
      // and chosen such that, at sample N, it gives a weight of 0.5 at N/10.
      ++sample_count;
      if (sample_count == 1) {
         running_mean_av_tpo = av_tpo;
         running_quadmean_av_tpo = av_tpo * av_tpo;

         running_mean_adj_av_tpo = adj_av_tpo;
         running_quadmean_adj_av_tpo = adj_av_tpo * adj_av_tpo;

         //std::cout << "lambda = 1.0, running_mean_av_tpo = " << running_mean_av_tpo << std::endl;
      } else {
         // We want (1-lambda)^(N/10) = 0.5
         // or ln(1-lambda) = (10/N) * ln(0.5)
         double lambda = 1.0 - exp((10.0/sample_count) * log(0.5));
         running_mean_av_tpo = lambda * av_tpo + (1.0 - lambda) * running_mean_av_tpo;
         running_quadmean_av_tpo = lambda * av_tpo * av_tpo + (1.0 - lambda) * running_quadmean_av_tpo;

         running_mean_adj_av_tpo = lambda * adj_av_tpo + (1.0 - lambda) * running_mean_adj_av_tpo;
         running_quadmean_adj_av_tpo = lambda * adj_av_tpo * adj_av_tpo + (1.0 - lambda) * running_quadmean_adj_av_tpo;

         //std::cout << "lambda = " << lambda << ", running_mean_av_tpo = " << running_mean_av_tpo << std::endl;
      }
      double running_var_av_tpo = running_quadmean_av_tpo - (running_mean_av_tpo * running_mean_av_tpo);
      double running_var_adj_av_tpo = running_quadmean_adj_av_tpo - (running_mean_adj_av_tpo * running_mean_adj_av_tpo);

      // OK, to reduce the volume of data produced, we're going to winnow out data points
      // that don't add any useful information
      if ((winnow_thresh_rcs == 0.0) || (winnow_thresh_avtpo == 0.0)) {
         // If the threshold has been set to zero, then write out every data point
         total_loop_count_vec.push_back(lc);
         av_time_per_op_vec.push_back(av_tpo);
         rel_cpu_speed_vec.push_back(rcs);
         running_mean_av_tpo_vec.push_back(running_mean_av_tpo);
         running_var_av_tpo_vec.push_back(running_var_av_tpo);
         running_mean_adj_av_tpo_vec.push_back(running_mean_adj_av_tpo);
         running_var_adj_av_tpo_vec.push_back(running_var_adj_av_tpo);
      } else {
         bool winnow = true;
         if (starting == true) {
            winnow = false;
         } else {
            // Only keep data points where rcs varies by more than 1% (times the threshold)
            // from the "current value"
            if (std::abs(rcs - cur_rcs) > (cur_rcs * 0.03 * winnow_thresh_rcs)) {
               winnow = false;
            }

            // Only keep data points where av_tpo varies by more than 5% (times the threshold)
            // from the "current value"
            // (XXX probably need to change this to some product of the "recent" standard deviation)
            //if (std::abs(av_tpo - cur_av_tpo) > (cur_av_tpo * 0.05 * winnow_thresh_avtpo)) {
            //   winnow = false;
            //} 

            // Only keep data points where the mean or variance of av_tpo vary by more than 10%
            // (times the threshold) from the "current value"
            if (std::abs(running_mean_av_tpo - cur_mean_av_tpo) >
                (cur_mean_av_tpo * 0.1 * winnow_thresh_avtpo))
            {
               winnow = false;
            }
            if (std::abs(running_var_av_tpo - cur_var_av_tpo) >
                (cur_var_av_tpo * 0.1 * winnow_thresh_avtpo))
            {
               winnow = false;
            } 

            // Only keep data points where the mean or variance of adj_av_tpo vary by more than 10%
            // (times the threshold) from the "current value"
            if (std::abs(running_mean_adj_av_tpo - cur_mean_adj_av_tpo) >
                (cur_mean_adj_av_tpo * 0.1 * winnow_thresh_avtpo))
            {
               winnow = false;
            }
            if (std::abs(running_var_adj_av_tpo - cur_var_adj_av_tpo) >
                (cur_var_adj_av_tpo * 0.1 * winnow_thresh_avtpo))
            {
               winnow = false;
            } 
         }
         if (winnow) {
            // Just update the running values to compute the average av_tpo
            lc_run_end = lc;
            av_tpo_run_sum += av_tpo;
            rcs_run_end = rcs;
            
            mean_av_tpo_run_end = running_mean_av_tpo;
            var_av_tpo_run_end = running_var_av_tpo;
            
            mean_adj_av_tpo_run_end = running_mean_adj_av_tpo;
            var_adj_av_tpo_run_end = running_var_adj_av_tpo;
            
            ++run_count;
         } else {
            if (starting == false) {
               // Compute the average av_tpo for the last "run"
               double av_av_tpo = av_tpo_run_sum / run_count;
               // Write out the first and last values for the last "run"
               total_loop_count_vec.push_back(lc_run_start);
               av_time_per_op_vec.push_back(av_av_tpo);
               rel_cpu_speed_vec.push_back(rcs_run_start);
               running_mean_av_tpo_vec.push_back(mean_av_tpo_run_start);
               running_var_av_tpo_vec.push_back(var_av_tpo_run_start);
               running_mean_adj_av_tpo_vec.push_back(mean_adj_av_tpo_run_start);
               running_var_adj_av_tpo_vec.push_back(var_adj_av_tpo_run_start);

               //std::cout << "Pushing running_mean_av_tpo = " << mean_av_tpo_run_start << std::endl;

               if (run_count > 1) {
                  total_loop_count_vec.push_back(lc_run_end);
                  av_time_per_op_vec.push_back(av_av_tpo);
                  rel_cpu_speed_vec.push_back(rcs_run_end);
                  running_mean_av_tpo_vec.push_back(mean_av_tpo_run_end);
                  running_var_av_tpo_vec.push_back(var_av_tpo_run_end);
                  running_mean_adj_av_tpo_vec.push_back(mean_adj_av_tpo_run_end);
                  running_var_adj_av_tpo_vec.push_back(var_adj_av_tpo_run_end);

                  //std::cout << "Pushing running_mean_av_tpo = " << mean_av_tpo_run_end << std::endl;
               }
            }
            // Save the start of the new "run"
            cur_rcs = rcs;
            cur_av_tpo = av_tpo;

            cur_mean_av_tpo = running_mean_av_tpo;
            cur_var_av_tpo = running_var_av_tpo;
            cur_mean_adj_av_tpo = running_mean_adj_av_tpo;
            cur_var_adj_av_tpo = running_var_adj_av_tpo;
            
            lc_run_start = lc;
            lc_run_end = lc;
            av_tpo_run_sum = av_tpo;
            rcs_run_start = rcs;
            rcs_run_end = rcs;

            mean_av_tpo_run_start = running_mean_av_tpo;
            mean_av_tpo_run_end = running_mean_av_tpo;
            var_av_tpo_run_start = running_var_av_tpo;
            var_av_tpo_run_end = running_var_av_tpo;

            mean_adj_av_tpo_run_start = running_mean_adj_av_tpo;
            mean_adj_av_tpo_run_end = running_mean_adj_av_tpo;
            var_adj_av_tpo_run_start = running_var_adj_av_tpo;
            var_adj_av_tpo_run_end = running_var_adj_av_tpo;

            run_count = 1;
         }


         if (starting == true) {
            starting = false;
         }
      }
   }

   void finish() {
      // Compute the average av_tpo for the final "run"
      double av_av_tpo = av_tpo_run_sum / run_count;

      // Write out the first and last values for the last "run"
      total_loop_count_vec.push_back(lc_run_start);
      av_time_per_op_vec.push_back(av_av_tpo);
      rel_cpu_speed_vec.push_back(rcs_run_start);
      running_mean_av_tpo_vec.push_back(mean_av_tpo_run_start);
      running_var_av_tpo_vec.push_back(var_av_tpo_run_start);
      running_mean_adj_av_tpo_vec.push_back(mean_adj_av_tpo_run_start);
      running_var_adj_av_tpo_vec.push_back(var_adj_av_tpo_run_start);
      if (run_count > 1) {
         total_loop_count_vec.push_back(lc_run_end);
         av_time_per_op_vec.push_back(av_av_tpo);
         rel_cpu_speed_vec.push_back(rcs_run_end);
         running_mean_av_tpo_vec.push_back(mean_av_tpo_run_end);
         running_var_av_tpo_vec.push_back(var_av_tpo_run_end);
         running_mean_adj_av_tpo_vec.push_back(mean_adj_av_tpo_run_end);
         running_var_adj_av_tpo_vec.push_back(var_adj_av_tpo_run_end);
      }
   }
   
   uint64_t getSize() { return total_loop_count_vec.size(); }

   void dumpOutput(const std::string &tag, int operations_per_loop_count) {
      if (pout) {
         (*pout) << tag << ": total_op_count  av_time_per_op  rel_cpu_speed"
            " running_mean_avtpo-sigma running_mean_avtpo running_mean_avtpo+sigma"
            " running_mean_adj_avtpo-sigma running_mean_adj_avtpo running_mean_adj_avtpo+sigma"<< std::endl;
         for (uint64_t i = 0; i < getSize(); ++i) {
            double std_dev = sqrt(running_var_av_tpo_vec[i]);
            double adj_std_dev = sqrt(running_var_adj_av_tpo_vec[i]);
            (*pout) << tag << ": " << (total_loop_count_vec[i] * operations_per_loop_count)
                    << "  " << av_time_per_op_vec[i]
                    << "  " << rel_cpu_speed_vec[i]
                    << "  " << (running_mean_av_tpo_vec[i] - std_dev)
                    << "  " << running_mean_av_tpo_vec[i]
                    << "  " << (running_mean_av_tpo_vec[i] + std_dev)
                    << "  " << (running_mean_adj_av_tpo_vec[i] - adj_std_dev)
                    << "  " << running_mean_adj_av_tpo_vec[i]
                    << "  " << (running_mean_adj_av_tpo_vec[i] + adj_std_dev)
                    << std::endl;
         }
      }
   }
};


struct ResultOutputInfo {
  rapidjson::Document dom;
  rapidjson::Value bm_template;
  std::ostream *postream_json;

  // Constructor
  ResultOutputInfo(CLOptions &cl_options) :
    postream_json(cl_options.postream_json)
  {
    dom.SetArray();
    //rapidjson::Value bm_template;
    bm_template.SetObject();
    bm_template.AddMember("jmhVersion", "LATH 0.1", dom.GetAllocator());
    bm_template.AddMember("benchmark", "", dom.GetAllocator());
    bm_template.AddMember("mode", "", dom.GetAllocator());
    bm_template.AddMember("threads", 0, dom.GetAllocator());
    bm_template.AddMember("forks", 1, dom.GetAllocator());
    bm_template.AddMember("jvm", "n/a", dom.GetAllocator());
    bm_template.AddMember("jvmArgs", rapidjson::Value().SetArray(), dom.GetAllocator());
    bm_template.AddMember("jdkVersion", "n/a", dom.GetAllocator());
    bm_template.AddMember("vmName", "n/a", dom.GetAllocator());
    bm_template.AddMember("vmVersion", "n/a", dom.GetAllocator());
    bm_template.AddMember("warmupIterations", 0, dom.GetAllocator());
    bm_template.AddMember("warmupTime", "", dom.GetAllocator());
    bm_template.AddMember("warmupBatchSize", 1, dom.GetAllocator());
    bm_template.AddMember("measurementIterations", 0, dom.GetAllocator());
    bm_template.AddMember("measurementTime", "", dom.GetAllocator());
    bm_template.AddMember("measurementBatchSize", 1, dom.GetAllocator());
    
    rapidjson::Value prim_metric;
    prim_metric.SetObject();
    prim_metric.AddMember("score", 0.0, dom.GetAllocator());
    prim_metric.AddMember("scoreError", 0.0, dom.GetAllocator());
    prim_metric.AddMember("scoreConfidence", rapidjson::Value().SetArray(), dom.GetAllocator());
    prim_metric.AddMember("scorePercentiles", rapidjson::Value().SetObject(), dom.GetAllocator());
    prim_metric.AddMember("scoreUnit", "", dom.GetAllocator());
    prim_metric.AddMember("rawData", rapidjson::Value().SetArray(), dom.GetAllocator());
    
    bm_template.AddMember("primaryMetric", prim_metric, dom.GetAllocator());
    bm_template.AddMember("secondaryMetrics", rapidjson::Value().SetObject(), dom.GetAllocator());
  }

  void saveResults(const std::string &benchmark_name, const std::string &mode, int num_threads,
		   int warmup_iters, double warmup_time, const std::string &warmup_time_unit, int bm_iters, double bm_time, const std::string &bm_time_unit,
		   double avg, double std_dev, std::vector<double> &data, const std::string &unit) 
  {
    rapidjson::Value bmvals(bm_template, dom.GetAllocator());
    assert(bmvals.IsObject());
    bmvals["benchmark"].SetString(benchmark_name.c_str(), dom.GetAllocator());
    bmvals["mode"].SetString(mode.c_str(), dom.GetAllocator());
    bmvals["threads"] = num_threads;
    bmvals["warmupIterations"] = warmup_iters;
    bmvals["warmupTime"].SetString(((std::string)(MakeStr() << warmup_time << " " << warmup_time_unit)).c_str(),
				   dom.GetAllocator());
    bmvals["measurementIterations"] = bm_iters;
    bmvals["measurementTime"].SetString(((std::string)(MakeStr() << bm_time << " " << bm_time_unit)).c_str(),
					dom.GetAllocator());

    rapidjson::Value &prim = bmvals["primaryMetric"];
    assert(prim.IsObject());
    prim["score"] = avg;
    prim["scoreError"] = std_dev;
    prim["scoreConfidence"].PushBack(avg - std_dev, dom.GetAllocator())
                           .PushBack(avg + std_dev, dom.GetAllocator());

    std::vector<double> data_sorted = data;
    int N = data.size();
    std::sort(data_sorted.begin(), data_sorted.end());
    prim["scorePercentiles"].AddMember("0.0", data_sorted[0], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("50.0", data_sorted[std::ceil((N-1)*0.5)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("90.0", data_sorted[std::ceil((N-1)*0.9)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("95.0", data_sorted[std::ceil((N-1)*0.95)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("99.0", data_sorted[std::ceil((N-1)*0.99)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("99.9", data_sorted[std::ceil((N-1)*0.999)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("99.99", data_sorted[std::ceil((N-1)*0.9999)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("99.999", data_sorted[std::ceil((N-1)*0.99999)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("99.9999", data_sorted[std::ceil((N-1)*0.999999)], dom.GetAllocator());
    prim["scorePercentiles"].AddMember("100.0", data_sorted[N-1], dom.GetAllocator());
    
    prim["scoreUnit"] = "ns/op";
    rapidjson::Value raw_data;  // For this thread
    raw_data.SetArray();
    for (double val : data) {
      raw_data.PushBack(val, dom.GetAllocator());
    }
    prim["rawData"].PushBack(raw_data, dom.GetAllocator());
    dom.PushBack(bmvals, dom.GetAllocator());
  }

  void writeOutput() {
    if (postream_json) {
      rapidjson::StringBuffer buffer;
      rapidjson::PrettyWriter<rapidjson::StringBuffer> writer(buffer);
      dom.Accept(writer);
      (*postream_json) << buffer.GetString() << std::endl;
    }
  }
};


// Run for the specified loop count and return the ratio (ns per loop iteration)
template <class Clock>
inline double getClockTimingRunRatio(uint64_t loop_count) {
   double min_ratio = std::numeric_limits<double>::max();

   // To minimize the impact of transient events, do this 3 times and take the shortest time:
   for (int reps = 0; reps < 3; ++reps) {
      int boo = 0x10023a41;
      int goo = 0x0139fc27;
      typename Clock::time_point start = Clock::now();
      for (uint64_t j = 0; j < loop_count; ++j) {
         boo += goo;
         goo += boo;
      }
      typename Clock::time_point end = Clock::now();
      
      double ratio = ((double)(std::chrono::duration_cast<std::chrono::nanoseconds>
                               (end - start).count()))/loop_count;
      min_ratio = std::min(min_ratio, ratio);
      
      sink += goo;
   }

   return min_ratio;
}

struct ClockCalibrationInfo
{
   int clock_id {-1};
   std::string clock_name;
   bool found {false};
   uint64_t loop_count {0};
   uint64_t cutoff_time_nsec {0};
   double inferred_precision {0.0};

   template <class Clock>
   double getRelativeCPUSpeed() const {
      return getClockTimingRunRatio<Clock>(loop_count);
   }
};


// Clock measurement/calibration function:
template <class Clock>
void findCutoff(const std::string &clock_name, int clock_id, ClockCalibrationInfo &clock_info,
                 double prec_thresh = 0.005)
{
   // Empirically measures the clock precision
   // Specifically, finds the cutoff time period above which measurements using this clock
   // are above the specified precision threshold (by default, 0.5%)
   //
   // First, coarse search:
   // Start with a base loop count of 1
   // Double the base loop count for each trial
   // In each trial, make 10 consecutive tests, starting with the base loop count, where the
   // loop count for each subsequent test increases the loop count by a multiplier of
   // (1 + (prec_thresh/5)) [with a minimum loop count increase of 1].
   // For each test, measure the average time per loop.
   // If all 10 measurements are nonzero and within the precision threshold of the average,
   // then we've found the cutoff upper bound.
   //
   // Fine search:
   // Starting with the base loop count of the upper bound / 2, test until the loop count has
   // reached the max loop count reached in the upper bound.
   // For each test, measure the average time per loop.
   // Continue until 10 consecutive measurements are within 0.8*prec_thresh of their
   // average.
   // Take the maximum of those 10 measurements as the cutoff time period.

   clock_info.clock_id = clock_id;
   clock_info.clock_name = clock_name;

   // Coarse search:
   // std::cout << clock_name << ":    (DEBUG)Coarse search" << std::endl;
   uint64_t base_count = 1;
   bool found = false;
   uint64_t max_loop_count = 0;
   while (found == false) {
      // Start the next trial
      uint64_t loop_count = base_count;
      double total = 0.0;
      double max_ratio = 0.0;
      double min_ratio = std::numeric_limits<double>::max();
      for (int reps = 0; reps < 10; ++reps) {
         double ratio = getClockTimingRunRatio<Clock>(loop_count);
         total += ratio;
         max_ratio = std::max(max_ratio, ratio);
         min_ratio = std::min(min_ratio, ratio);

         // Check if time limit reached
         uint64_t elapsed_time_ms = (ratio * loop_count) / 1000000.0;

         // std::cout << clock_name << ":    (DEBUG)loop count: " << loop_count
         //           << ", ratio: " << ratio
         //           << ", elapsed time(ms): " << elapsed_time_ms<< std::endl;
         
         if (elapsed_time_ms > 200) {
            clock_info.found = false;
            return;
         }
         
         // Increase the loop count:
         loop_count = std::max(loop_count + 1, (uint64_t)(((double)loop_count)*(1.0+(prec_thresh/5.0))));
      }

      double av_ratio = total/10.0;

      // std::cout << clock_name << ":    (DEBUG)loop count: " << loop_count
      //           << ", min_ratio: " << min_ratio
      //           << ", max_ratio: " << max_ratio << ", av_ratio: " << av_ratio << std::endl;
      // std::cout << clock_name << ":    (DEBUG)    variation: " << (max_ratio - min_ratio)/av_ratio
      //           << ", prec_thresh: " << prec_thresh << std::endl;

      bool exceeds = false;
      if (min_ratio == 0.0) { exceeds = true; }
      if (((av_ratio - min_ratio) / av_ratio) > (0.8 * prec_thresh)) {
         exceeds = true;
      }
      if (((max_ratio - av_ratio) / av_ratio) > (0.8 * prec_thresh)) {
         exceeds = true;
      }
      if (exceeds == false) {
         // we now have the cutoff time bracketed
         found = true;
         max_loop_count = loop_count;
         break;
      }
      base_count *= 2;
   }
   
   // Fine search:
   //std::cout << clock_name << ":    (DEBUG)Fine search" << std::endl;
   double last_10[10];
   uint64_t loop_count = std::max((uint64_t)1, base_count/2);
   for (int reps = 0; reps < 9; ++reps) {
      double ratio = getClockTimingRunRatio<Clock>(loop_count);
      last_10[reps] = ratio;
      
      // std::cout << clock_name << ":    (DEBUG)loop count: " << loop_count
      //           << ", ratio: " << ratio << std::endl;
      
      // Increase the loop count:
      loop_count = std::max(loop_count + 1, (uint64_t)(((double)loop_count)*(1.0+(prec_thresh/5.0))));
   }

   // std::cout << clock_name << ":    (DEBUG)loop count: " << loop_count
   //           << ", max_loop_count: " << max_loop_count << std::endl;
   
   int next_idx = 9;
   bool cutoff_found = false;
   IntTimeNS cutoff_time_nsec = 0;
   double inferred_precision = 0.0;
   while (loop_count <= max_loop_count) {
      double ratio = getClockTimingRunRatio<Clock>(loop_count);
      last_10[next_idx] = ratio;
      
      // std::cout << clock_name << ":    (DEBUG)loop count: " << loop_count
      //           << ", ratio: " << ratio << std::endl;

      // Check the last 10 measurements
      double total = 0.0;
      double max_ratio = 0.0;
      double min_ratio = std::numeric_limits<double>::max();
      for (int i = 0; i < 10; ++i) {
         total += last_10[i];
         max_ratio = std::max(max_ratio, last_10[i]);
         min_ratio = std::min(min_ratio, last_10[i]);
      }
      double av_ratio = total/10.0;

      // std::cout << clock_name << ":    (DEBUG)loop count: " << loop_count
      //           << ", min_ratio: " << min_ratio
      //           << ", max_ratio: " << max_ratio << ", av_ratio: " << av_ratio << std::endl;

      bool exceeds = false;
      if (min_ratio == 0.0) { exceeds = true; }
      if (((av_ratio - min_ratio) / av_ratio) > (0.8 * prec_thresh)) {
         exceeds = true;
      }
      if (((max_ratio - av_ratio) / av_ratio) > (0.8 * prec_thresh)) {
         exceeds = true;
      }
      if (exceeds == false) {
         // found it!
         cutoff_found = true;
         cutoff_time_nsec = max_ratio * loop_count;
         inferred_precision = (max_ratio - min_ratio) * loop_count;
         break;
      }
      
      next_idx = (next_idx >= 9) ? (0) : (next_idx + 1);
      // Increase the loop count:
      loop_count = std::max(loop_count + 1, (uint64_t)(((double)loop_count)*(1.0+(prec_thresh/5.0))));
   }

   clock_info.found = cutoff_found;
   clock_info.loop_count = loop_count;
   clock_info.cutoff_time_nsec = cutoff_time_nsec;
   clock_info.inferred_precision = inferred_precision;
   
   // std::cout << clock_name << ": Total calibration time(sec): " << total_sec << std::endl;
   // std::cout << clock_name << ": cutoff time(ns): " << cutoff_time_nsec
   //           << ", loop count: " << loop_count
   //           << ", inferred precision: " << inferred_precision << std::endl;
   // std::cout << clock_name << ": (max loop count = " << max_loop_count << ")" << std::endl;
   // std::cout << clock_name << ":       last_10: ";
   // for (int i = 0; i < 10; ++i) {
   //    std::cout << last_10[i] << "  ";
   // }
   // std::cout << std::endl;
}



// Get the T-score for 99.9% confidence level from the degrees of freedom (# of samples - 1)
// (This is a fast approximate calculation, accurate to 4 decimal places)
double getT999(int degfree) {
  static double first30[] = {636.578, 31.6, 12.924, 8.61, 6.869, 5.959, 5.408, 5.041, 4.781, 4.587,
			     4.437, 4.318, 4.221, 4.14, 4.073, 4.015, 3.965, 3.922, 3.883, 3.85,
			     3.819, 3.792, 3.768, 3.745, 3.725, 3.707, 3.689, 3.674, 3.66, 3.646};
  assert(degfree > 0);
  if (degfree <= 30) { return first30[degfree-1]; }
  if (degfree <= 40) { return 3.291+14.1031300196705*std::pow(degfree,-1.08257); }
  return 3.291+12.7694430987769*std::pow(degfree,-1.05564);
}

// Used to compute histogram and quantiles (for sample mode)
class HistQuant {
public:
   struct QuantPoint {
      double q;   // quantile level (between 0.0 and 1.0)
      double val; // value at that quantile

      // Constructor
      QuantPoint(double newq, double newval) :
         q(newq),
         val(newval)
      {}
   };

   struct HistBin {
      double bin_start;
      double bin_end;
      uint64_t cnt;

      // Constructor
      HistBin(double st, double end) :
         bin_start(st),
         bin_end(end),
         cnt(0)
      {}
   };

   std::vector<double> quant_levels {0.0, 0.5, 0.9, 0.95, 0.99,
                                     0.999, 0.9999, 0.99999, 0.999999, 1.0};
   std::vector<QuantPoint> quants;

   std::vector<HistBin> hist;
   
   // Constructor
   HistQuant(std::vector<double> &data) {
      // Compute quantiles
      std::vector<double> data_sorted = data;
      int N = data.size();
      std::sort(data_sorted.begin(), data_sorted.end());
      for (auto level : quant_levels) {
         quants.emplace_back(level, data_sorted[std::ceil((N-1)*level)]);
      }

      // Compute histogram
      double minval = data_sorted[0];
      double maxval = data_sorted[N-1];
      // Find the interval (rounded up)
      double diff = maxval - minval;      
      double interval = diff/10.0;
      double first_bin_start = minval;
      if (interval <= 0.0) {
         hist.emplace_back(minval, maxval);
      } else {
         double cap = 1.0;
         if (interval < 1.0) {
            while (interval < cap/10.0) {
               cap = cap/10.0;
            }
         } else {
            while (interval > cap) {
               cap = cap*10.0;
            }
         }
         for (int j=0; j<3; ++j) {
            if (interval < cap/2.0) {
               cap = cap/2.0;
            } else {
               break;
            }
         }
         interval = cap;
         first_bin_start = interval*std::floor(minval/interval);
         double bin_start = first_bin_start;
         while (bin_start < maxval) {
            hist.emplace_back(bin_start, bin_start + interval);
            bin_start += interval;
         }
      }
      int hist_idx = 0;
      for (auto val : data_sorted) {
         while (val > hist[hist_idx].bin_end) {
            ++hist_idx;
            assert(hist_idx < hist.size());
         }
         ++(hist[hist_idx].cnt);
      }
   }

   // Get the quantile values
   std::vector<QuantPoint> &getQuant() { return quants; }

   // Get the histogram
   std::vector<HistBin> &getHist() { return hist; }
};


} // namespace harness_utils_private

#endif
// __TEST_HARNESS_UTILITIES_PRIVATE__
