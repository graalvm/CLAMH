Quick links
-----------

[Full *CLAMH User's Guide* (md)](documentation/CLAMH_Users_Guide.md)


What is CLAMH?
=============

CLAMH is

1.  A language-independent benchmark harness design

2.  The implementation of that design for different languages.

The CLAMH design closely follows the design of JMH, the preeminent benchmark harness
for Java. Since the Java Micro-benchmark Harness (JMH) already achieves the goals of
CLAMH for the Java language, the runnable benchmark files generated by CLAMH for
other languages are designed to be directly comparable to JMH benchmarks for Java.


Quick Start
===========

See the "Quick Start" section in the CLAMH User's Guide (links above) to get started.


Language Support
================

At the moment, CLAMH supports C++, Java, and Javascript.


Platform/Compiler/VM Support
============================

CLAMH has been tested on RedHat Enterprise Linux, Ubuntu Linux, Windows cygwin, and MacOS,
on x86 and aarch64 hardware.

CLAMH-C++ has been tested with gcc and clang.

CLAMH-Java has been tested with HotSpot JDKs 8, 11, 15, and 16, and GraalVM.

CLAMH-JS has been tested with node.js.
