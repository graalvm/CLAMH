
/*
This software is released under MIT License:

Copyright (c) 2002 Leick Robinson (leick.robinson@gmail.com)

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


//
// The comments in this file contain special comments for generating documentation
// with Doxygen.  Please do not remove the special characters and keywords in these
// comments (e.g., !, \file, etc.)
//
/*! \file
 * This file defines the basic command-line parser class, CommandOptionHandler.
 * Its constructor is passed an option definition string.
 *   Option definition string:
 *   Options are comma-separated.
 *   Each option is alphanumeric only.
 *   Each option may be followed by one or more of the following:
 *        ':' -- indicates that it takes an argument
 *        '+' -- indicates that it may be repeated on the command line
 *
 * Options on the command line are expected to be preceded by a dash ('-').
 *
 * After parsing, the accessors opCheck, opCount, and opValue can be used to check
 * to see if an option was present, the number of times it appears on the command line,
 * and the last value assigned to it (if the option takes an argument).
 * 
 * By default, CommandOptionHandler takes no special action during parsing,
 * and unknown options and command-line arguments cause an exception to be thrown.
 *
 * \author Leick Robinson
 */
//
#ifndef _INCLUDE_COMMANDOPTIONHANDLER_H_
#define _INCLUDE_COMMANDOPTIONHANDLER_H_

#pragma warning(disable: 4786)  // disable this warning because <map> includes VERY long identifiers
#include <iostream>
#include <map>
#include <string>
using namespace std;

static const bool CommandOptionHandler_DEBUG = false;

//! Basic command-line option handler class
class CommandOptionHandler {
public:
    //! unknown option exception class
    class UnknownOption {
    public:
        std::string option;
        UnknownOption(const char *op) : option(op) {}
        UnknownOption(std::string op)      : option(op) {}
    };

    //! unknown argument exception class
    class UnknownArg {
    public:
        std::string arg;
        UnknownArg(const char *a) : arg(a) {}
        UnknownArg(std::string a)      : arg(a) {}
    };

    //! Parse and handle the command line options
    /*!
     * Option definition string:
     * Options are comma-separated.
     * Each option is alphanumeric only.
     * Each option may be followed by one or more of the following:
     *      ':' -- indicates that it takes an argument.
     *      '+' -- indicates that it may be repeated on the command line.
     */
    CommandOptionHandler(const char *opdef)
    {
        std::string op;  // Initially, empty string
        bool takes_arg = false;
        bool repeatable = false;

        // Parse the option definition string
        while (true)
        {
            if (isalnum(*opdef)) { op += *opdef; }  // add alphanumeric to end of string
            else if (*opdef == '_') { op += *opdef; }  // add '_' to end of string
            else if (*opdef == '-') { op += *opdef; }  // add '-' to end of string
            else if (*opdef == ':') { takes_arg = true; } // option can take an argument
            else if (*opdef == '+') { repeatable = true; } // option can be repeated
            else if ((*opdef == ',') || (*opdef == '\0')) // end of this option, process the next
            {
                if (CommandOptionHandler_DEBUG)
                {
                    cout << " allowable option:  " << op;
                    if (takes_arg)  cout << ", takes argument";
                    if (repeatable) cout << ", repeatable";
                    cout << std::endl;
                }

                // store the option info...
                opTraits opT;
                opT.takes_arg = takes_arg;
                opT.repeatable = repeatable;
                validOps[op] = opT;

                //std::cout << "Added command-line option \"" << op << "\"" << std::endl;

                // ...and reset for the next option
                op.erase();
                takes_arg = false;
                repeatable = false;
            }

            if (*opdef == '\0') break;  // end of option definition string

            // Advance to next character
            ++opdef;
        }
    }

   // Silly Leick, virtual destructors are virtual classes
   virtual ~CommandOptionHandler() {}

    void parseOptions(const int argc, const char* const argv[])
    {
        int i;
        for (i=1; i<argc; ++i)
        {
            const char *arg = argv[i];
            if (arg[0] == '-')
            {
                // see if it matches an option
                std::string sarg(arg + 1);
                opMapT::iterator p;

                p = validOps.find(sarg);
                if (p != validOps.end())
                {
                    // increment the count for this option
                    ++(parsedOps[sarg].count);
                    // Check to see if this op takes an argument
                    if (validOps[sarg].takes_arg)
                    {
                        ++i;
                        if (i < argc)  parsedOps[sarg].last_value = argv[i];  // grab next arg
                        else           parsedOps[sarg].last_value = "";  // (no args remaining)
                    }
                    // call option handler
                    handleOption(arg + 1, parsedOps[sarg].last_value.c_str());
                }
                else
                {
                    // unknown option
                    if (CommandOptionHandler_DEBUG)
                    {
                        cout << "  Unknown option = " << sarg << std::endl;
                    }
                    handleUnknownOption(sarg.c_str()); // since sarg is a local variable
                }
            }
            else
            {
                // not option syntax
                if (CommandOptionHandler_DEBUG)
                {
                    cout << "  Bad option syntax = " << arg << std::endl;
                }
                handleUnknownArg(arg);
            }
        }
    }

    const char *opValue(const char *op) // const (doesn't work because [] not defined for const map<>)
    {
        std::string s = op;
        return parsedOps[s].last_value.c_str();
    }

    int opCount(const char *op) // const (doesn't work because [] not defined for const map<>)
    {
        std::string s = op;
        return ((parsedOps[s]).count);
    }

    bool opCheck(const char *op)
    {
        std::string s = op;
        return ((parsedOps[s]).count != 0);
    }

protected:
    //! option trait flags
    struct opTraits {
        bool takes_arg;     ///< if true, option takes an argument (example:  "-f <filename>")
        bool repeatable;    ///< if true, the option may be repeated more than once on the command line
    };
    typedef std::map<std::string, opTraits> opMapT;
    opMapT validOps;

    //! option information
    struct opInfo {
        int count;              ///< number of times the option appeared on the command line
        std::string last_value; ///< the value of the argument (if any) for the last occurence of this option on the command line
        opInfo() : count(0) {}
    };
    typedef std::map<std::string, opInfo> opInfoMapT;
    opInfoMapT parsedOps;

    //! base option handler - by default, do nothing during command-line parsing.
    virtual void handleOption(const char *op, const char *value)
    { (void) op, (void) value;}

    //! base unknown option handler - by default, throws an UnknownOption exception.
    virtual void handleUnknownOption(const char *op)
    {
        if (CommandOptionHandler_DEBUG)
        {
            cout << "  (default handler)" << std::endl;
        }
        // By default, throw an exception
        UnknownOption uO(op);
        throw (uO);
    }

    //! base unknown argument handler - by default, throws an UnknownArg exception
    virtual void handleUnknownArg(const char *arg)
    {
        if (CommandOptionHandler_DEBUG)
        {
            cout << "  (default handler)" << std::endl;
        }
        // XXX By default, throw an exception
        UnknownArg uA(arg);
        throw (uA);
    }
};


/*!  Extension to CommandOptionHandler class to read options and filenames.
 */
class OptionAndFilenameHandler : public CommandOptionHandler {
public:
   /*! Constructor */
   OptionAndFilenameHandler(const char *opdef,    ///< Option definition string
                            int maxNumberOfFiles) ///< Maximum number of files to look for
      : CommandOptionHandler(opdef), fileCount(0), fileMax(maxNumberOfFiles)
   { }

   vector<string> files;
   int fileCount;
   
protected:
   int fileMax;
   
   //! Special argument handler to parse command-line parameters
   virtual void handleUnknownArg(const char *arg)
   {
      // Unknown argument is assumed to be a file name
      // XXX We could put tests for file existence here, if we want (leick)
      if (fileCount < fileMax)
      {
         files.push_back(arg);
         ++fileCount;
      }
      else
      {
         // Too many filenames found on the command line - fall back on the default behavior
         CommandOptionHandler::handleUnknownArg(arg);
      }
   }
};


#endif // _INCLUDE_COMMANDOPTIONHANDLER_H_
