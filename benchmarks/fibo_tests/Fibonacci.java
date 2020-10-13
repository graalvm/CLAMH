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

//package org.graalvm.benchmarks;
package leick;

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
//import org.graalvm.polyglot.*;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

//import java.io.File;
//import java.io.IOException;
import java.util.concurrent.TimeUnit;


@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
public class Fibonacci {

    //@State(Scope.Thread)
    //public static class InputValue {
    //    volatile static long number = 25;
    //}

    @State(Scope.Benchmark)
    public static class Values {
	int a = 0;
	int b = 0;
	int c = 0;
	int d = 0;
	int e = 0;
	//int f = 0;

	@Setup(Level.Iteration)
        public void setup() {
	    a = 0x10023a41;
	    b = 0x0139fc27;
	}
    };


   @Benchmark
   public int fibonacci_local() {
      int a = 0x10023a41;
      int b = 0x0139fc27;
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

   @Benchmark
   public int fibonacci_nonlocal(Values vals) {
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

   @Benchmark
   public int fibonacci_para2(Values vals) {
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

   @Benchmark
   public int fibonacci_para3(Values vals) {
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
}

