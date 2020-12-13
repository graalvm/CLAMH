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

#ifndef __HARNESS_UTILS_BLACKHOLE__
#define __HARNESS_UTILS_BLACKHOLE__


//#include <inttypes.h>
//#include <limits>

namespace harness_utils {

// Blackhole utility class. It can safely "consume" any object (in as lightweight a manner
// as possible) to prevent undesired optimizations such as "dead code" elimination.
class Blackhole {
private:
   // local sink targets (for low-overhead consumption)
   char csink {0};
   short ssink {0};
   int isink {0};
   long lsink {0};
   long long llsink {0};
   signed char scsink {0};
   unsigned char ucsink {0};
   unsigned short ussink {0};
   unsigned int uisink {0};
   unsigned long ulsink {0};
   unsigned long long ullsink {0};
   float fsink {0.0};
   double dsink {0.0};
   
   // volatile "final" sink targets (to prevent the local sinks from getting compiled out)
   static volatile char csink_final;
   static volatile short ssink_final;
   static volatile int isink_final;
   static volatile long lsink_final;
   static volatile long long llsink_final;
   static volatile signed char scsink_final;
   static volatile unsigned char ucsink_final;
   static volatile unsigned short ussink_final;
   static volatile unsigned int uisink_final;
   static volatile unsigned long ulsink_final;
   static volatile unsigned long long ullsink_final;
   static volatile float fsink_final;
   static volatile double dsink_final;

public:
   // Destructor
   ~Blackhole() {
      // sink all of the local sink targets to the volatile final sinks to prevent a *really*
      // smart compiler from compiling out the local sinks.
      csink_final = csink;
      ssink_final = ssink;
      isink_final = isink;
      lsink_final = lsink;
      llsink_final = llsink;
      scsink_final = scsink;
      ucsink_final = ucsink;
      ussink_final = ussink;
      uisink_final = uisink;
      ulsink_final = ulsink;
      ullsink_final = ullsink;
      fsink_final = fsink;
      dsink_final = dsink;
   }

   // Type-specific consume methods for the built-in types:
   void consume(char val) { csink += val; }
   void consume(short val) { ssink += val; }
   void consume(int val) { isink += val; }
   void consume(long val) { lsink += val; }
   void consume(long long val) { llsink += val; }
   void consume(signed char val) { scsink += val; }
   void consume(unsigned char val) { ucsink += val; }
   void consume(unsigned short val) { ussink += val; }
   void consume(unsigned int val) { uisink += val; }
   void consume(unsigned long val) { ulsink += val; }
   void consume(unsigned long long val) { ullsink += val; }
   void consume(float val) { fsink += val; }
   void consume(double val) { dsink += val; }

   // Generic consume methods for any other types
   // (generally, don't do this - it's slower. Better to only consume the built-in types)
   template <typename T>
   void consume(const T& val) {
      //isink += *(static_cast<const int*>(&val));

      //void *temp_ptr = static_cast<void*>(&val);
      //isink += *(static_cast<int*>(temp_ptr));

      isink += *(reinterpret_cast<const int*>(&val));
   }
};


// XXX Move these to a Blackhole_volatile.hpp (only included once)
volatile char Blackhole::csink_final;
volatile short Blackhole::ssink_final;
volatile int Blackhole::isink_final;
volatile long Blackhole::lsink_final;
volatile long long Blackhole::llsink_final;
volatile signed char Blackhole::scsink_final;
volatile unsigned char Blackhole::ucsink_final;
volatile unsigned short Blackhole::ussink_final;
volatile unsigned int Blackhole::uisink_final;
volatile unsigned long Blackhole::ulsink_final;
volatile unsigned long long Blackhole::ullsink_final;
volatile float Blackhole::fsink_final;
volatile double Blackhole::dsink_final;



} // namespace harness_utils

#endif
// __HARNESS_UTILS_BLACKHOLE__

