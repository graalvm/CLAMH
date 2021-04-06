/*
 * Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

package clamh;

import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Param;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.TimeUnit;
import java.util.HashMap;


@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
public class Autobox {

    // We want to do the following autoboxing/unboxing tests:
    //
    // - baseline:
    // long sum = 0L;
    // for (long i = 0; i < Integer.MAX_VALUE; i++) {
    //    sum += i;
    // }
    //
    // - autoboxing:
    // Long sum = 0L;
    // for (long i = 0; i < Integer.MAX_VALUE; i++) {
    //    sum += i; // i is autoboxed
    // }
    //
    //
    //    private static final int MAX_SIZE = 2_000_000;
    //    
    //    @Benchmark
    //    public int[] testPrimitiveIntegers() {
    //	int[] ints = new int[MAX_SIZE];
    //	for (int i=0; i < MAX_SIZE; i++) {
    //	    ints[i] = i;
    //	}
    //	return ints;
    //    }
    //    
    //    @Benchmark
    //    public Integer[] testIntegerBoxing() {
    //	Integer[] ints = new Integer[MAX_SIZE];
    //	for (int i=0; i < MAX_SIZE; i++) {
    //	    //boxing here -> object instantiation
    //	    ints[i] = i;
    //	}
    //	return ints;
    //    }
    //    
    //    @Benchmark
    //    public int[] testIntegerInclUnboxing() {
    //	int[] ints = new int[MAX_SIZE];
    //	for (int i=0; i < MAX_SIZE; i++) {
    //	    //manual boxing here, after that automatic unboxing
    //	    ints[i] = Integer.valueOf(i);
    //	}
    //	return ints;
    //    }
    //    
    //    public static void main(String[] args) throws RunnerException {
    //        Options opt = new OptionsBuilder()
    //	    .include(IntegerBoxingArray.class.getSimpleName())
    //	    .warmupIterations(15)
    //	    .measurementIterations(10)
    //	    .forks(1)
    //	    .shouldDoGC(true)
    //	    .build();
    //	
    //        new Runner(opt).run();
    //    }
    //
    // Look at autoboxing vs. explicit boxing example (java can better optimize latter in past):
    // https://tavianator.com/java-autoboxing-performance/
    //
    // Work on "box elision":
    // http://mail.openjdk.java.net/pipermail/valhalla-dev/2014-November/000380.html
    //
    //
    // Autoboxing on put and get:
    // HashMap<Integer, String> map = new HashMap< >();
    // // Put the value in the map where key is primitive type.
    // map.put(1, “TestValue”); // expected key is Integer type
    // // Get the value from the map where key is primitive type.
    // map.get(1); // expected key is Integer type
    // 
    //
    // Each loop has to unbox count and then rebox the result:
    //    private static Integer count = 1000;
    //
    //    public static void main(String[] args) {
    //
    //      for (int i = 0; i < 1000; i++) {
    //        count += 1;
    //      }
    //
    //    }
    //
    // Same here:
    // Integer counter = 0;
    // for(int i=0; i < 1000; i++) {
    //     counter++;
    // }
    //
    //
    // This code only needs to autobox:
    // List<Integer> li = new ArrayList<>();
    // for (int i = 1; i < 50; i += 2)
    //     li.add(i);
    //
    //


    //@State(Scope.Thread)
    //public static class InputValue {
    //    volatile static long number = 25;
    //}

    @State(Scope.Benchmark)
    public static class Values {
	long start = 0;
	long max_val = 0x3fffffff;
	HashMap<Integer, Integer> map = new HashMap< >();
	String the_string = "Hello, autoboxing!";

	@Setup(Level.Iteration)
        public void setup() {
	    map.clear();
	}
    };


   @Benchmark
   public long sum_baseline(Values vals) {
       long max_val = vals.max_val;
       long sum = 0L;
       for (long i = 0; i < max_val; i++) {
	   sum += i;
       }
       return sum;
   }

   @Benchmark
   public long sum_baseline2(Values vals) {
       long max_val = vals.max_val;
       long sum = 0L;
       for (long i = vals.start; i < max_val; i++) {
	   sum += i;
       }
       return sum;
   }

   @Benchmark
   public long sum_box_unbox(Values vals) {
       long max_val = vals.max_val;
       Long sum = 0L;
       for (long i = 0; i < max_val; i++) {
	   sum += i;
       }
       return sum.longValue();
   }

   @Benchmark
   public int hash_map(Values vals) {
       int max_loops = 2000;
       int sum = 0;
       // Insert
       for (int i = 0; i < max_loops; i++) {
	   vals.map.put(i,i);
       }
       // Read
       for (int i = 0; i < max_loops; i++) {
	   sum += vals.map.get(i);
       }
       return sum;
   }

   private char getchar_baseline(String str, int idx) {
       return str.charAt(idx);
   }

   private Character getchar_cached(String str, int idx) {
       return str.charAt(idx); // autoboxed
   }

   private Character getchar_nocache(String str, int idx) {
       return new Character(str.charAt(idx));
   }

   @Benchmark
   public char string_index_baseline(Values vals) {
       char result = 0;
       int str_len = vals.the_string.length();
       for(int i = 0; i < str_len; i++) {
	   result += getchar_baseline(vals.the_string, i);
       }

       return result;
   }

   @Benchmark
   public char string_index_cached(Values vals) {
       char result = 0;
       int str_len = vals.the_string.length();
       for(int i = 0; i < str_len; i++) {
	   result += getchar_cached(vals.the_string, i);
       }

       return result;
   }

   @Benchmark
   public char string_index_nocache(Values vals) {
       char result = 0;
       int str_len = vals.the_string.length();
       for(int i = 0; i < str_len; i++) {
	   result += getchar_nocache(vals.the_string, i);
       }

       return result;
   }

}

