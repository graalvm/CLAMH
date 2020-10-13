
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


#include <iostream>
#include "Blackhole.hpp"

static const int SIZE = 64;

//@BenchmarkMode(Mode.AverageTime)
//@OutputTimeUnit(TimeUnit.NANOSECONDS)
//@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
//@Fork(1)
@State(Scope.Benchmark)
class Array2DTests {
public:

  @State(Scope.Benchmark)
  struct Arrays {
    int arr[SIZE][SIZE];
    int* arr2[SIZE][SIZE];
    //int (*arr3[SIZE])[SIZE];
    int* arr3[SIZE];
  };

  @Setup(Level.Trial)
  void setup(Arrays &arrs) {
    for (int i = 0; i < SIZE; ++i) {
      arrs.arr3[i] = new int[SIZE];
      for (int j = 0; j < SIZE; ++j) {
	arrs.arr[i][j] = i + j;
	arrs.arr2[i][j] = new int;
	*(arrs.arr2[i][j]) = i + j;
	//(*(arrs.arr3[i]))[j] = i + j;
	(arrs.arr3[i])[j] = i + j;
      }
    }

    std::cout << "Array size = " << SIZE << std::endl;
  }

private:

public:
   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int seq_by_rows(Arrays &arrs) {
     int sum = 0;
     
     for (int i = 0; i < SIZE; ++i) {
       for (int j = 0; j < SIZE; ++j) {
	 sum += arrs.arr[i][j];
       }
     }
     
     return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int seq_by_cols(Arrays &arrs) {
     int sum = 0;
     
     for (int j = 0; j < SIZE; ++j) {
       for (int i = 0; i < SIZE; ++i) {
	 sum += arrs.arr[i][j];
       }
     }
     
     return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int seq_by_rows_indirect(Arrays &arrs) {
     int sum = 0;
     
     for (int i = 0; i < SIZE; ++i) {
       for (int j = 0; j < SIZE; ++j) {
	 sum += *(arrs.arr2[i][j]);
       }
     }
     
     return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int seq_by_cols_indirect(Arrays &arrs) {
     int sum = 0;
     
     for (int j = 0; j < SIZE; ++j) {
       for (int i = 0; i < SIZE; ++i) {
	 sum += *(arrs.arr2[i][j]);
       }
     }
     
     return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int seq_by_rows_indrows(Arrays &arrs) {
     int sum = 0;
     
     for (int i = 0; i < SIZE; ++i) {
       for (int j = 0; j < SIZE; ++j) {
	 sum += (arrs.arr3[i])[j];
       }
     }
     
     return sum;
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int seq_by_cols_indrows(Arrays &arrs) {
     int sum = 0;
     
     for (int j = 0; j < SIZE; ++j) {
       for (int i = 0; i < SIZE; ++i) {
	 sum += (arrs.arr3[i])[j];
       }
     }
     
     return sum;
   }

};


//int Array2DTests::InputValue::rep;
//volatile long Array2DTests::InputValue::number = 25;
//long Array2DTests::InputValue::number = 25;

