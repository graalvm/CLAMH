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
public class Factorial {

    @State(Scope.Thread)
    public static class InputValue {
	@Param({"25", "30"})
        long number;
    }


    private static long javaFactorialRecursive_(long n) {
        if (n <= 1)
            return 1;
        else
            return n * javaFactorialRecursive_(n - 1);
    }

    @Benchmark
    public void JavaFactorialRecursive(Blackhole bh, InputValue iv) {
        bh.consume(javaFactorialRecursive_(iv.number));
    }

    private static long javaFactorialIterative_(long n) {
        long result=1;

        for (int i = 1; i <= n; i++) {
            result = result * i;
        }

        return result;
    }

    @Benchmark
    public void javaFactorialIterative(Blackhole bh, InputValue iv) {
        bh.consume(javaFactorialIterative_(iv.number));
    }

    @Benchmark
    public long javaFactorialIterative2(InputValue iv) {
        return javaFactorialIterative_(iv.number);
    }

    @Benchmark
    public void javaDoNothing() {
    }
}
