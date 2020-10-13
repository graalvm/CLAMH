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
public class Array2D {

    static final int SIZE = 64;

    @State(Scope.Benchmark)
    public static class Arrays {
	int[][] arr = new int[SIZE][SIZE];
	
	@Setup(Level.Iteration)
        public void setup() {
	    for (int i = 0; i < SIZE; i++) {
		for (int j = 0; j < SIZE; j++) {
		    arr[i][j] = i + j;
		}
	    }
	}
    };


   @Benchmark
   public int seq_by_rows(Arrays arrs) {
       int sum = 0;
       
       //for (int i = 0; i < SIZE; i++) {
       //	   for (int j = 0; j < SIZE; j++) {
       //	       assert i < arrs.arr.length : " seq_by_rows, i oob";
       //	       assert j < arrs.arr[i].length : " seq_by_rows, j oob";
       //	       sum += arrs.arr[i][j];
       //	   }
       //}
       
       for (int i = 0; i < arrs.arr.length; i++) {
       	   for (int j = 0; j < arrs.arr[i].length; j++) {
       	       sum += arrs.arr[i][j];
       	   }
       }
       
       return sum;
   }

   @Benchmark
   public int seq_by_cols(Arrays arrs) {
       int sum = 0;
       
       //for (int j = 0; j < SIZE; j++) {
       //	   for (int i = 0; i < SIZE; i++) {
       //	       assert i < arrs.arr.length : " seq_by_cols, i oob";
       //	       assert j < arrs.arr[i].length : " seq_by_cols, j oob";
       //	       sum += arrs.arr[i][j];
       //	   }
       //}
       
       for (int j = 0; j < arrs.arr[0].length; j++) {
       	   for (int i = 0; i < arrs.arr.length; i++) {
       	       sum += arrs.arr[i][j];
       	   }
       }
       
       return sum;
   }

}

