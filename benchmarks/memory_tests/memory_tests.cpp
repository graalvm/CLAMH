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

//#include <string>
#include <vector>
#include "Blackhole.hpp"

//@BenchmarkMode(Mode.AverageTime)
//@OutputTimeUnit(TimeUnit.NANOSECONDS)
//@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Fork(1)
@State(Scope.Benchmark)
class MemoryTests {
public:

  @State(Scope.Benchmark)
  struct Values {
    // 32 KiB  =    0x8000
    // 128 KiB =   0x20000
    // 512 KiB =   0x80000
    // 2 MiB   =  0x200000
    // 8 MiB   =  0x800000
    // 32 MiB  = 0x2000000
    // 128 MiB = 0x8000000
    @Param({"0x8000", "0x20000", "0x80000", "0x200000",
	    "0x800000", "0x2000000", "0x8000000"})
    static int vec_size;

    // Flush vector size should be >= 40 MiB (~4 * 10^7 ~= 40 * 2^20 = 40 * 16^5 =
    //                                        0x2800000 or 0xa00000 ints)
    std::vector<int> flush_vec(0x1400000, 0);  // (double it, just to be sure)

    std::vector<int> test_vec;
  };

  @Setup(Level.Trial)
  void setup(Values &vals) {
    // Resize the test vector
    vals.test_vec.resize(Values::vec_size, 0);
  }

private:

  static int flush_memory_(Values &vals) {
    int sum = 0;
    for (auto &int_val : vals.flush_vec) {
      sum += int_val;
    }
    return sum;
  }

  //typedef void (*FlushFunc)(Values &vals);
  //static FlushFunc flush_memory_noinline_;

  static auto flush_memory_noinline_ = harness_utils_private::noInline(&MemoryTests::flush_memory_);

  static int getNextIdx(int idx) {
    return idx * 0x5F5E107 + 0x2FAF091;
  }

public:
  //@BenchmarkMode(Mode.AverageTime)
  //@OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 1, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int flush_mem1(Values &vals) { return flush_memory_noinline(vals); }

  @BenchmarkMode(Mode.AverageTime)
  @OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int stream_read1(Values &vals) {
    int sum = 0;
    for (auto &val : vals.test_vec) {
      sum += val;
    }
    return sum;
  }
  
  @Measurement(iterations = 1, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int flush_mem2(Values &vals) { return flush_memory_noinline(vals); }

  @BenchmarkMode(Mode.AverageTime)
  @OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int stream_write1(Values &vals) {
    int sum = 0;
    for (auto &val : vals.test_vec) {
      val = 0xcafebeef;
    }
    return sum;
  }
  
  @Measurement(iterations = 1, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int flush_mem3(Values &vals) { return flush_memory_noinline(vals); }

  @BenchmarkMode(Mode.AverageTime)
  @OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int stream_read_write1(Values &vals) {
    int sum = 0;
    for (auto &val : vals.test_vec) {
      ++val;
    }
    return sum;
  }
  

  @Measurement(iterations = 1, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int flush_mem4(Values &vals) { return flush_memory_noinline(vals); }

  @BenchmarkMode(Mode.AverageTime)
  @OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int random_read1(Values &vals) {
    int sum = 0;

    const int vec_size = vals.test_vec.size();
    // Note:  depends on vec_size being a power of 2
    const int mask = vec_size - 1;
    int idx = 0;
    for (int i = 0; i < vec_size; ++i) {
      idx = getNextIdx(idx, vec_size);
      auto &val = vals.test_vec[idx & mask];
      sum += val;
    }
    return sum;
  }
  
  @Measurement(iterations = 1, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int flush_mem5(Values &vals) { return flush_memory_noinline(vals); }

  @BenchmarkMode(Mode.AverageTime)
  @OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int random_write1(Values &vals) {
    int sum = 0;
    for (auto &val : vals.test_vec) {
      val = 0xcafebeef;
    }
    return sum;
  }
  
  @Measurement(iterations = 1, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int flush_mem6(Values &vals) { return flush_memory_noinline(vals); }

  @BenchmarkMode(Mode.AverageTime)
  @OutputTimeUnit(TimeUnit.NANOSECONDS)
  @Measurement(iterations = 3, time = 1, timeUnit = TimeUnit.MICROSECONDS)
  @Fork(1)
  @Benchmark
  static int random_read_write1(Values &vals) {
    int sum = 0;
    for (auto &val : vals.test_vec) {
      ++val;
    }
    return sum;
  }
  


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

