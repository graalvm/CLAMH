
/*
This software is released under MIT License:

Copyright (c) 2014 Leick Robinson (leick.robinson@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


Note: the author kindly requests (but does not require) that, if you
make any significant and/or interesting improvements to the software,
please forward a copy to the author.

   Thanks!
   Leick
   (leick.robinson@gmail.com)
*/

#ifndef __MAKE_STR_H__
#define __MAKE_STR_H__

#include <string>
#include <sstream>

// MakeStr is a functor that allows you to easily create a string "in place".
//
// Example of how to use MakeStr:
// Suppose you have a method called log_msg that takes a string. You can easily
// create the string and pass it to log_msg all on one line, like this:
//
//    log_msg(MakeStr() << "Log some info: x = " << x << ", y = " << y);
//
// The advantages of MakeStr go beyond mere convenience. One powerful added
// benefit of using MakeStr within an expression is that the string is only
// constructed if the expression containing MakeStr is evaluated. This can be
// particularly useful with certain macros.
//
// For example, suppose that, rather than the method above, you instead have a
// macro called LOG_MSG that only logs the message if logging has been enabled.
// (Assuming it has been well written) LOG_MSG will not evaluate its string
// argument if logging has been disabled.
//
//    LOG_MSG(MakeStr() << "Log some info: x = " << x << ", y = " << y);
//
// Thus, in this example, the overhead of string construction would only be
// incurred if the logging has been enabled.
// 
class MakeStr {
private:
   std::stringstream sstr_;
   // [See the string conversion operator below for the purpose of this data member:]
   std::string str_; 

public:
   template<class T>
   MakeStr &operator<<(const T& val) {
      sstr_ << val;
      return (*this);
   }
   
   operator std::string () {
      // Note: some weirdness has been observed with stringstream if
      // the string returned by the .str() method is not used immediately.
      // So, just to be safe, we save it in the str_ data member first.
      str_ = sstr_.str();
      return str_;
   }
};

#endif  // __MAKE_STR_H__
