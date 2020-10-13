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

#include "Blackhole.hpp"

//@BenchmarkMode(Mode.AverageTime)
//@OutputTimeUnit(TimeUnit.NANOSECONDS)
//@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Fork(1)
@State(Scope.Benchmark)
class Benchmarks {
public:

   @State(Scope.Thread)
   class InputValue {
   public:
      @Param({"25", "30"})
      volatile static long number;
      //static long number;
   };

private:
   static long factorialRecursive_(long n) {
      if (n <= 1) { return 1; }
      else        { return (n * factorialRecursive_(n-1)); }
   }

   static long factorialIterative_(long n) {
      long result = 1;
      for (long i = 1; i <= n; ++i) {
         result *= i;
      }
      return result;
   }

public:
   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static void factorialRecursive(harness_utils::Blackhole &bh) {
      bh.consume(factorialRecursive_(InputValue::number));
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   void factorialIterative1(harness_utils::Blackhole &bh) {
      bh.consume(factorialIterative_(InputValue::number));
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   long factorialIterative2() {
      return factorialIterative_(InputValue::number);
   }
};

//int Benchmarks::InputValue::rep;
volatile long Benchmarks::InputValue::number = 25;
//long Benchmarks::InputValue::number = 25;


namespace dummyNS1 {

namespace dummyNS2 {

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
@Benchmark
void do_nothing_avt() {
}

@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
@Benchmark
void do_nothing_thru() {
}

@BenchmarkMode(Mode.SingleShotTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
@Benchmark
void do_nothing_ss() {
}

@BenchmarkMode(Mode.SampleTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
@Benchmark
void do_nothing_samp() {
}

}

}
