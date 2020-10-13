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
class FibonacciTests {
public:

   //@State(Scope.Thread)
   //class InputValue {
   //public:
   //   //@Param({"1", "2", "3"})
   //   @Param({"1"})
   //   static int rep;
   //
   //   @Param({"25"})
   //   volatile static long number;
   //   //static long number;
   //};

  @State(Scope.Benchmark)
  struct Values {
     int a{0};
     int b{0};
     int c{0};
     int d{0};
     int e{0};
     //int f{0};
  };

  @Setup(Level.Iteration)
  void setup(Values &vals) {
     vals.a = 0x10023a41;
     vals.b = 0x0139fc27;
  }

private:

public:
   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int fibonacci_local(Values &vals) {
      int a = vals.a;
      int b = vals.b;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      a += b;
      b += a;
      return b;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int fibonacci_nonlocal(Values &vals) {
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      vals.a += vals.b;
      vals.b += vals.a;
      return vals.b;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int fibonacci_para2(Values &vals) {
      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.a = vals.c + vals.d;
      vals.b = vals.c + (vals.d << 1);

      return vals.b;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int fibonacci_para3(Values &vals) {
      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.e = (vals.a << 1) + 3*vals.b;

      vals.a = vals.d + vals.e;
      vals.b = vals.d + (vals.e << 1);
      vals.c = (vals.d << 1) + 3*vals.e;

      vals.d = vals.b + vals.c;
      vals.e = vals.b + (vals.c << 1);
      vals.a = (vals.b << 1) + 3*vals.c;

      vals.b = vals.e + vals.a;
      vals.c = vals.e + (vals.a << 1);
      vals.d = (vals.e << 1) + 3*vals.a;

      vals.e = vals.c + vals.d;
      vals.a = vals.c + (vals.d << 1);
      vals.b = (vals.c << 1) + 3*vals.d;

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.e = (vals.a << 1) + 3*vals.b;

      vals.a = vals.d + vals.e;
      vals.b = vals.d + (vals.e << 1);
      vals.c = (vals.d << 1) + 3*vals.e;

      vals.d = vals.b + vals.c;
      vals.e = vals.b + (vals.c << 1);
      vals.a = (vals.b << 1) + 3*vals.c;

      vals.b = vals.e + vals.a;
      vals.c = vals.e + (vals.a << 1);
      vals.d = (vals.e << 1) + 3*vals.a;

      vals.e = vals.c + vals.d;
      vals.a = vals.c + (vals.d << 1);
      vals.b = (vals.c << 1) + 3*vals.d;

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.e = (vals.a << 1) + 3*vals.b;

      vals.a = vals.d + vals.e;
      vals.b = vals.d + (vals.e << 1);
      vals.c = (vals.d << 1) + 3*vals.e;

      vals.d = vals.b + vals.c;
      vals.e = vals.b + (vals.c << 1);
      vals.a = (vals.b << 1) + 3*vals.c;

      vals.b = vals.e + vals.a;
      vals.c = vals.e + (vals.a << 1);
      vals.d = (vals.e << 1) + 3*vals.a;

      vals.e = vals.c + vals.d;
      vals.a = vals.c + (vals.d << 1);
      vals.b = (vals.c << 1) + 3*vals.d;

      vals.c = vals.a + vals.b;
      vals.d = vals.a + (vals.b << 1);
      vals.e = (vals.a << 1) + 3*vals.b;

      vals.a = vals.d + vals.e;
      vals.b = vals.d + (vals.e << 1);
      vals.c = (vals.d << 1) + 3*vals.e;

      vals.d = vals.b + vals.c;
      vals.e = vals.b + (vals.c << 1);
      vals.a = (vals.b << 1) + 3*vals.c;

      vals.b = vals.e + vals.a;
      vals.c = vals.e + (vals.a << 1);
      vals.d = (vals.e << 1) + 3*vals.a;

      vals.e = vals.c + vals.d;
      vals.a = vals.c + (vals.d << 1);
      vals.b = (vals.c << 1) + 3*vals.d;

      return vals.b;
   }

};

//int FibonacciTests::InputValue::rep;
//volatile long FibonacciTests::InputValue::number = 25;
//long FibonacciTests::InputValue::number = 25;

