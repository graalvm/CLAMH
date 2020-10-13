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

#include <unordered_map>
#include <string>
#include "Blackhole.hpp"

//@BenchmarkMode(Mode.AverageTime)
//@OutputTimeUnit(TimeUnit.NANOSECONDS)
//@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Fork(1)
@State(Scope.Benchmark)
class Autobox {
public:

  @State(Scope.Benchmark)
  struct Values {
    long start = 0;
    long max_val = 0x3fffffff;
    std::unordered_map<int, int> map;
    std::string the_string = "Hello, autoboxing!";
  };

  @Setup(Level.Iteration)
  void setup(Values &vals) {
    vals.map.clear();
  }

private:

public:
   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static long sum_baseline(Values &vals) {
       long max_val = vals.max_val;
       long sum = 0L;
       for (long i = 0; i < max_val; ++i) {
	   sum += i;
       }
       return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static long sum_baseline2(Values &vals) {
       long max_val = vals.max_val;
       long sum = 0L;
       for (long i = vals.start; i < max_val; ++i) {
	   sum += i;
       }
       return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int hash_map(Values &vals) {
       int max_loops = 2000;
       int sum = 0;
       // Insert
       for (int i = 0; i < max_loops; ++i) {
	 vals.map[i] = i;
       }
       // Read
       for (int i = 0; i < max_loops; ++i) {
	 sum += vals.map[i];
       }
       return sum;
   }

   static char getchar_baseline(const std::string &str, int idx) {
       return str[idx];
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static char string_index_baseline(Values &vals) {
       char result = 0;
       int str_len = vals.the_string.length();
       for(int i = 0; i < str_len; ++i) {
	   result += getchar_baseline(vals.the_string, i);
       }

       return result;
   }
};

