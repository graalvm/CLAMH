/*
Copyright (c) 2021 Oracle

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

#ifndef __STRING_UTILS_HPP__
#define __STRING_UTILS_HPP__

#include <string>
#include <vector>

namespace string_utils {


// Split a string into a vector of substrings, based on a delimiter
std::vector<std::string> &splitString(const std::string &s, char delim,
                                      std::vector<std::string> &res_vec)
{
   std::stringstream ss(s);
   std::string sval;
   while (std::getline(ss, sval, delim)) {
      res_vec.push_back(sval);
   }
   return res_vec;
}


// Split a string into two strings, based on the first occurrence of a delimiter.
// The "left" string will be replaced with the substring before the first occurrence of the
// delimiter, and the remainder of the original string after the delimiter will be placed in
// the "right" string.
// A reference to the first ("left") substring will also be returned (as a convenience).
// If the delimiter does not occur in the original string, the "right" string will be empty.
std::string &splitStringOnFirst(const std::string &s, char delim,
                                std::string &left, std::string &right)
{
   std::stringstream ss(s);
   std::string sval;

   std::getline(ss, left, delim);
   ss >> right;

   return left;
}


// Trimming strings
// Note: these all trim the string "in place"
// (they return a reference to the modified string as a convenience. This allows operations
// to be "chained", as you can see in the implementation of trim below.)

std::string &ltrim(std::string &str, const std::string &ws_chars = "\t\n\v\f\r ")
{
   str.erase(0, str.find_first_not_of(ws_chars));
   return str;
}
 
std::string &rtrim(std::string &str, const std::string &ws_chars = "\t\n\v\f\r ")
{
   str.erase(str.find_last_not_of(ws_chars) + 1);
   return str;
}
 
std::string &trim(std::string &str, const std::string &ws_chars = "\t\n\v\f\r ")
{
   return ltrim(rtrim(str, ws_chars), ws_chars);
}


// Match two strings, where the first may contain wildcards, with the following rules:
// ? will match any one character
// * will match zero or more characters
bool wildMatch(const char *wild, const char *normal) {
   // If we've reached the end of both, success!
   if ((*wild == '\0') && (*normal == '\0')) { return true; }

   // If the wild string contains '*', then either we can skip the '*' and the rest of both
   // strings match, or we skip the next character in the normal string and try again.
   // (we need to do this here, before the comparison below, just in case the normal string
   // happens to contain a '*' character.)
   if (*wild == '*') {
      // But, first need to check to see if there are any characters left in the normal string
      if (*normal == '\0') { return wildMatch(wild+1, normal); }
      else                 { return (wildMatch(wild+1, normal) || wildMatch(wild, normal+1)); }
   }

   // If the characters match, or the wild string contains "?", continue
   if ((*wild == '?') || (*wild == *normal)) { return wildMatch(wild+1, normal+1); }

   // The strings don't match
   return false;
}

bool wildMatch(const std::string &wild_str, const std::string &normal_str) {
   return wildMatch(wild_str.c_str(), normal_str.c_str());
}


}; // namespace string_utils


#endif // __STRING_UTILS_HPP__
