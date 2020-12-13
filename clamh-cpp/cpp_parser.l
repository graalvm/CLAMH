%option noyywrap

%{
/* Lexical tokens for C and C++ code parsing */

///////////////////////////////////////////////////////////

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
#include <string>
#include <vector>
#include <cstdint>
#include <cstdio>
#include <cassert>
#include <sstream>
#include "CommandOptionHandler.h"
#include "string_utils.hpp"


// XXX Uncomment to turn on debugging prints for annotation parsing:
//#define DEBUG 1

// We'll be parsing files only
#define YY_NEVER_INTERACTIVE 1


// XXX Put other class declarations here


class FileLine {
public:
   FileLine(uint32_t linenum, const char *aline)
      : n(linenum), line(aline)
   {}

   FileLine(uint32_t linenum, const string &aline)
      : n(linenum), line(aline)
   {}

   bool operator==(const FileLine& other) const
   {
      return (line == other.line);
   }
   
   bool operator!=(const FileLine& other) const
   {
      return (line != other.line);
   }

   bool operator<(const FileLine& other) const
   {
      return (line < other.line);
   }
   
   uint32_t n;
   string line;
};

vector<FileLine> *pFileVector;

struct AnnArgInfo {
   std::string arg_str;
   std::string key;
   std::string val;

   AnnArgInfo(const std::string &as) :
      arg_str(as)
   {
      // Trim the arg string whitespace
      string_utils::trim(arg_str);

      // Split the string argument into the key and value:
      std::string left;
      std::string right;
      string_utils::splitStringOnFirst(arg_str, '=', left, right);
      // ...and trim them
      string_utils::trim(left);
      string_utils::trim(right);
      // Check to see if the key is implied:
      if (right.size() == 0) {
         val = left;
      } else {
         key = left;
         val = right;
      }
#ifdef DEBUG
      std::cout << "//             key = \"" << key << "\", val = \"" << val << "\"" << std::endl;
#endif
   }
};

struct AnnotationInfo {
   std::string name;
   vector<AnnArgInfo> args;
   
   AnnotationInfo(const std::string n) :
      name(n)
   {}
};

std::vector<AnnotationInfo> ann_vec;

struct ParentNSOrClass {
public:
   std::string name;
   uint32_t bl_lvl;
   bool is_class; // True if this is a class or struct (and not just a namespace)

   ParentNSOrClass(const char *s, int cur_blk_lvl, bool is_cl) :
      name(s),
      bl_lvl(cur_blk_lvl),
      is_class(is_cl)
   {}
};

vector<ParentNSOrClass> ns_class_stack;

struct TargArgInfo {
   std::string base_type_name;
   std::string alt_type_name;
   bool is_const;

   TargArgInfo(const std::string &nm1, const std::string &nm2, bool isc) :
      base_type_name(nm1),
      alt_type_name(nm2),
      is_const(isc)
   {}
};

enum MethodLevel {
   TRIAL,
   ITERATION,
   INVOCATION
};

enum BenchmarkMode {
   AVERAGE_TIME,
   THROUGHPUT,
   SINGLE_SHOT_TIME,
   SAMPLE_TIME
};

// This is a "fat" class that includes info for all types of annotation targets
// (since we don't necessarily know what kind of target we have until the annotations have been
// fully parsed and processed)
struct TargetInfo {
   std::string name;
   std::string full_name; // Fully qualified name
   std::string parent_name; // Parent
   std::string instance_name; // Used by State targets
   std::string pvec_name; // Used by Param targets

   bool is_class{false}; // True if the target is a class or struct
   bool type_is_void{false}; // True if this is a method/function and the return type is void
   bool is_static{false}; // True if the target is a static data member
   bool may_be_object_method{false}; // True if the parent is a class and this is not static
   
   std::vector<AnnotationInfo> annotations;

   // Used while processing annotations
   bool must_be_data{false};   // Set to true for Params
   std::string must_be_data_trigger;
   bool cannot_be_data{false}; // Set to true for all other annotations
   std::string cannot_be_data_trigger;
   
   // Used by method/function targets
   std::vector<TargArgInfo> targ_args;
   std::string arg_str; // Ditto
   std::string ob_str; // object for non-static method targets
   
   // Used by param targets
   std::string pval_str;
   std::string pval_list_str;
   std::vector<std::string> pvals;

   // Used by setup/teardown targets
   MethodLevel level;

   // Used by benchmark targets
   int bm_iters{1};
   double bm_time{1.0};
   uint64_t bm_batchsize{1};
   uint64_t bm_timeunit_mult{1000ull*1000ull*1000ull}; // TimeUnit.SECONDS by default
   std::string bm_timeunit_str{"sec"}; // TimeUnit.SECONDS by default
   std::string bm_timeunit_short_str{"s"}; // TimeUnit.SECONDS by default

   int warmup_iters{1};
   double warmup_time{1.0};
   uint64_t warmup_batchsize{1};
   uint64_t warmup_timeunit_mult{1000ull*1000ull*1000ull}; // TimeUnit.SECONDS by default
   std::string warmup_timeunit_str{"sec"}; // TimeUnit.SECONDS by default
   std::string warmup_timeunit_short_str{"s"}; // TimeUnit.SECONDS by default

   uint64_t output_timeunit_mult{1000ull*1000ull*1000ull}; // TimeUnit.SECONDS by default
   std::string output_timeunit_str{"sec"}; // TimeUnit.SECONDS by default
   std::string output_timeunit_short_str{"s"}; // TimeUnit.SECONDS by default

   BenchmarkMode mode{AVERAGE_TIME};
   std::string mode_str{"avgt"};

   std::string units_str{"s/op"};

   void updateStrings() {
      // Set the units string
      switch(mode) {
      case AVERAGE_TIME:
      case SINGLE_SHOT_TIME:
      case SAMPLE_TIME:
         units_str = output_timeunit_short_str + "/op";
         break;
      case THROUGHPUT:
         units_str = "ops/" + output_timeunit_short_str;
         break;
      default:
         // We should never get here
         abort();
      };
   }

   void setName(const std::string &nm, const std::vector<ParentNSOrClass> &ns_cl_st) {
      name = nm;

      // Compute the fully qualified name
      bool start = true;
      for (int i = (ns_cl_st.size() - 1); i >= 0; --i) {
         if (start) {
            parent_name = ns_cl_st[i].name;
            start = false;
         } else {
            parent_name = ns_cl_st[i].name + "::" + parent_name;
         }
      }
      if (parent_name.size() > 0) {
         full_name = parent_name + "::" + name;
      } else {
         full_name = name;
      }
   }

   void setMode(BenchmarkMode md) {
      mode = md;
      switch(md) {
      case AVERAGE_TIME:
         mode_str = "avgt";
         break;
      case THROUGHPUT:
         mode_str = "thrpt";
         break;
      case SINGLE_SHOT_TIME:
         mode_str = "ss";
         break;
      case SAMPLE_TIME:
         mode_str = "sample";
         break;
      default:
         // We should never get here
         abort();
      };
      
      updateStrings();
   }

   // Constructor
   TargetInfo(const std::string &nm, bool targ_is_class, bool targ_type_is_void, bool targ_is_static,
              const std::vector<AnnotationInfo> &anns, const std::vector<ParentNSOrClass> &ns_cl_st) :
      name(nm),
      is_class(targ_is_class),
      type_is_void(targ_type_is_void),
      is_static(targ_is_static),
      annotations(anns)
   {
      setName(nm, ns_cl_st);

      // Figure out if this could be an object method
      if ((ns_cl_st.size() > 0) && (ns_cl_st.back().is_class) && (is_static == false)) {
         may_be_object_method = true;
      }

      updateStrings();
   }
};

vector<TargetInfo> targets;

//struct BenchmarkInfo {
//   std::string name;
//   std::string full_name; // Fully qualified name
//};

vector<TargetInfo> benchmarks;
vector<TargetInfo> setups;
vector<TargetInfo> teardowns;

vector<TargetInfo> state_targets;
vector<TargetInfo> params;


// XXX
string curLine;
uint32_t curLineNum; // The number of the line we're currently building
uint32_t col_num; // The column number in the line (used for error reporting)

uint32_t block_level;
//std::string ann_targ;
bool targ_is_class;
bool targ_type_is_void;
bool targ_is_static;
bool targ_arg_is_const;

bool in_typedef;
uint32_t typedef_struct_blk_lvl;
uint32_t typedef_struct_target_idx;
uint32_t typedef_struct_class_stack_idx;

inline void addToLine(const char *s)
{
   curLine += s;
   // XXX Want to fix this later so it matches the unstripped file
   col_num = curLine.size();
}

inline void completeLine()
{
   pFileVector->push_back(FileLine(curLineNum, curLine));
   curLine = "";
   ++curLineNum;
   col_num = 0;
}

inline void parseError(std::string errmsg) {
   std::cout << "Error: " << curLineNum << "," << col_num << ": " << errmsg << std::endl;
   abort(); /* XXX - increment an error count instead */
}

inline void addAnn(const char *s) {
   ann_vec.emplace_back(s);

#ifdef DEBUG
   std::cout << "//Found annotation:  " << s << std::endl;
#endif
}

inline void clearAnns() {
   ann_vec.clear();

#ifdef DEBUG
   std::cout << "//Clear annotations" << std::endl;
#endif
}

std::string list_arg;

inline void startListArg(const char *s) {
   list_arg = s;

#ifdef DEBUG
   std::cout << "//    List arg found" << std::endl;
#endif
}

inline void addToListArg(const char *s) {
   list_arg += s;
}

inline void finishListArg(const char *s) {
   addToListArg(s);
#ifdef DEBUG
   std::cout << "//    Ann arg (list arg): " << list_arg << std::endl;
#endif

   assert(ann_vec.size() > 0);
   ann_vec.back().args.emplace_back(list_arg);
}

inline void addAnnArg(const char *s) {
#ifdef DEBUG
   std::cout << "//    Ann arg: " << s << std::endl;
   if (s[0] == '{') {
      std::cout  << "//    ERROR! Failed to parse list arg" << s << std::endl;
   }
#endif

   assert(ann_vec.size() > 0);
   ann_vec.back().args.emplace_back(s);
}

inline void setTargIsClass(bool val) {
   targ_is_class = val;
}

inline bool isTargClass() { return targ_is_class; }

inline void setTargTypeIsVoid(bool val) {
   targ_type_is_void = val;
}

inline bool isTargTypeVoid() { return targ_type_is_void; }

inline void setTargIsStatic(bool val) {
   targ_is_static = val;
}

inline bool isTargStatic() { return targ_is_static; }

inline void setInTypedef(bool val) {
   in_typedef = val;
}

inline bool IsInTypedef() {
   return in_typedef;
}

inline void saveTypedefIndices() {
   // Save off the indices that we'll need to update with the "typdef struct" name later
   typedef_struct_target_idx = targets.size() - 1;
   typedef_struct_class_stack_idx = ns_class_stack.size() - 1;
   typedef_struct_blk_lvl = block_level;
}

inline void saveTypedefStructName(char *name) {
   targets[typedef_struct_target_idx].setName(name, ns_class_stack);
   if (typedef_struct_class_stack_idx < ns_class_stack.size()) {
      ns_class_stack[typedef_struct_class_stack_idx].name = name;
   }
}

inline bool isUnnamedClassInStack() {
   for (auto &entry : ns_class_stack) {
      if (entry.name == "") { return true; }
   }
   return false;
}

inline void setAnnTarg(const char *s) {
   //ann_targ = s;

   if (isUnnamedClassInStack()) {
      parseError("Annotations within unnamed class/struct definitions are not allowed");
   }

   // Add to target list
   targets.emplace_back(s, isTargClass(), isTargTypeVoid(), isTargStatic(),
                        ann_vec, ns_class_stack);

#ifdef DEBUG
   std::cout << "//  target: " << s << (isTargClass() ? "[class]" : "[not class]")
             << (isTargTypeVoid() ? "[void]" : "[not void]")
             << (isTargStatic() ? "[static]" : "[not static]")
             << "[possible "
             << (targets.back().may_be_object_method ? "method]" : "function]")
             << ", block_level = " << block_level << std::endl;
   std::cout << "//          " << "full name: " << targets.back().full_name << std::endl;
#endif
}

inline void setTargArgIsConst(bool val) {
   targ_arg_is_const = val;
}

bool isTargArgConst() { return targ_arg_is_const; }

inline void setTargArgType(const char *s) {
   auto &targ = targets.back();

   // Construct full name for target type search:
   std::string full_name(s);
   for (int i = (ns_class_stack.size() - 1); i >= 0; --i) {
      full_name = ns_class_stack[i].name + "::" + full_name;
   }

   targ.targ_args.emplace_back(s, full_name, isTargArgConst());

#ifdef DEBUG
   std::cout << "//    target arg type: " << s << std::endl;
   if (isTargArgConst()) {
      std::cout << "//    (target arg is const)" << std::endl;
   } else {
      std::cout << "//    (target arg is not const)" << std::endl;
   }
#endif
}

inline void popStackIfLevel(int cur_blk_lvl) {
   if (ns_class_stack.size() > 0) {
      if (cur_blk_lvl == ns_class_stack.back().bl_lvl) {
         ns_class_stack.pop_back();
      }
   }

#ifdef DEBUG
   std::cout << "//                                                possible pop (block_level = "
             << cur_blk_lvl << ")" << std::endl;
#endif
}

inline void pushNamespace(const char *s, int cur_blk_lvl) {
   /* If the bottom of the stack already has the current block level, then
      it was just a declaration or something - replace it */
   popStackIfLevel(cur_blk_lvl);
   ns_class_stack.emplace_back(s, cur_blk_lvl, false); // false = not a class

#ifdef DEBUG
   std::cout << "//                                                push namespace "
             << s << "(block_level = " << cur_blk_lvl << ")" << std::endl;
#endif
}

inline void pushClass(const char *s, int cur_blk_lvl) {
   /* If the bottom of the stack already has the current block level, then
      it was just a declaration or something - replace it */
   popStackIfLevel(cur_blk_lvl);
   ns_class_stack.emplace_back(s, cur_blk_lvl, true); // true = is a class (or struct)

#ifdef DEBUG
   std::cout << "//                                                push class "
             << s << "(block_level = " << cur_blk_lvl << ")" << std::endl;
#endif
}



%}

%x IN_C_COMMENT
%x IN_CPP_COMMENT
%x IN_PREPROCESSOR_COMMAND
%x IN_PREPROC_C_COMMENT
%x IN_PREPROC_CPP_COMMENT
%x IN_QUOTE
%x GET_ANNOTATION_NAME
%x GET_AFTER_ANN
%x GET_ANN_ARGS
%x GET_ANN_LIST_ARG
%x GET_ANN_TARG_TYPE
%x GET_ANN_TARG
%x GET_AFTER_TARG
%x GET_ANN_TARG_ARGS
%x GET_ANN_TARG_ARGS2
%x GET_ANN_TARG_ARGS3
%x GET_NAMESPACE
%x GET_CLASS
%x GET_ANN_TARG_OLD_STRUCT_TYPE
%x GET_ANN_TARG_OLD_STRUCT_NAME

%%

"/*"                                     { BEGIN IN_C_COMMENT; addToLine(yytext); }
<IN_C_COMMENT>\n                         { completeLine(); }
<IN_C_COMMENT>.                          { /* Ignore comments */ addToLine(yytext); }
<IN_C_COMMENT>"*/"                       { BEGIN INITIAL; addToLine(yytext); }

"//"                                     { BEGIN IN_CPP_COMMENT; addToLine(yytext); }
<IN_CPP_COMMENT>\n                       { BEGIN INITIAL;  completeLine(); }
<IN_CPP_COMMENT>.                        { /* Ignore comments */ addToLine(yytext); }

^[ \t]*#                                 { BEGIN IN_PREPROCESSOR_COMMAND;
                                           addToLine(yytext);
                                         }
<IN_PREPROCESSOR_COMMAND>\\\n            { /* Ignore 'escaped' newline */
                                            addToLine("\\");
                                            completeLine();
                                         }
<IN_PREPROCESSOR_COMMAND>\n              { BEGIN INITIAL;
                                           completeLine();  /* Increment after we've completed the code token */
                                         }
<IN_PREPROCESSOR_COMMAND>[ \t]           { /* Ignore whitespace (we'll re-insert a space
                                            * between alphanumeric lextokens) */
                                           addToLine(yytext);
                                         }
<IN_PREPROCESSOR_COMMAND>[a-zA-Z0-9_]+   { /* Found an alphanumeric lextoken */
                                           addToLine(yytext);
                                         }
<IN_PREPROCESSOR_COMMAND>.               { /* Print all other chars (XXX - for now) */
                                           addToLine(yytext);
                                         }

<IN_PREPROCESSOR_COMMAND>"/*"            { BEGIN IN_PREPROC_C_COMMENT;  addToLine(yytext);}
<IN_PREPROC_C_COMMENT>\\\n               {  addToLine("\\");  completeLine(); }
<IN_PREPROC_C_COMMENT>.                  { /* Ignore comments */  addToLine(yytext); }
<IN_PREPROC_C_COMMENT>\n                 {  /* XXX Not sure what else to do here */
                                            BEGIN INITIAL;
                                            completeLine();
                                         }
<IN_PREPROC_C_COMMENT>"*/"               { BEGIN IN_PREPROCESSOR_COMMAND;  addToLine(yytext); }

<IN_PREPROCESSOR_COMMAND>"//"            { BEGIN IN_PREPROC_CPP_COMMENT;  addToLine(yytext); }
<IN_PREPROC_CPP_COMMENT>\n               { BEGIN INITIAL;
                                           completeLine();  /* Increment after we've completed the code token */
                                         }
<IN_PREPROC_CPP_COMMENT>.                { /* Ignore comments */ addToLine(yytext); }

\"                                       {  /* \" - Starting a quoted string */
                                            BEGIN IN_QUOTE;
                                            addToLine(yytext);
                                         }

<IN_QUOTE>\"                             {  /* \" - End a quoted string */
                                            BEGIN INITIAL;
                                            addToLine(yytext);
                                         }

<IN_QUOTE>\\\"                           {  /* \" - Escaped double-quote does not end string */
                                            addToLine(yytext);
                                         }

<IN_QUOTE>\\\n                           {  /* Ignore escaped newline */
                                            addToLine("\\");
                                            completeLine();
                                         }

<IN_QUOTE>\n                             {  /* Newline in a quoted string - not a good idea */
                                            completeLine();
                                         }

<IN_QUOTE>.                              {  /* Ignore what's in a quoted string literal */
                                            addToLine(yytext);
                                         }

"//@@"                                   |
"@"                                      { /* '//@@' is alternate annotation syntax for convenience in C++ */
                                           BEGIN GET_ANNOTATION_NAME;
                                           addToLine(" /* ");
                                           addToLine(yytext);
                                         }

<GET_ANNOTATION_NAME>[a-zA-Z0-9_]+       { /* BEGIN GET_ANN_ARGS; XXX Assume no args for now */
                                           BEGIN GET_AFTER_ANN;
                                           /* Found the annotation name */
                                           /* last_was_annotation = true; */
                                           /* ann_args_found = false; */
                                           /* ann_target_type_found = false; */
                                           /* ann_target_name_found = false; */

                                           addAnn(yytext);
                                           
                                           addToLine(yytext);
                                           addToLine(" */ ");
                                         }
<GET_ANNOTATION_NAME>.                   { BEGIN INITIAL;
                                           parseError("'@' not followed by annotation name");
                                           addToLine(" */ ");
                                           unput(yytext[0]); /* Put the character back */
                                           clearAnns();
                                         }

<GET_AFTER_ANN>[ \t]                     { /* Ignore whitespace */
                                           addToLine(yytext);
                                         }
<GET_AFTER_ANN>\n                        { completeLine(); }
<GET_AFTER_ANN>"("                       { BEGIN GET_ANN_ARGS;
                                           addToLine(" /* ");
                                           addToLine(yytext);
                                         }
<GET_AFTER_ANN>.                         { /* If no '(', then no annotation arguments */
                                           BEGIN GET_ANN_TARG_TYPE;
                                           unput(yytext[0]); /* Put the character back */
                                         }

<GET_ANN_ARGS>[ \t]                      { /* Ignore whitespace */
                                           addToLine(yytext);
                                         }
<GET_ANN_ARGS>\n                         { completeLine(); }
<GET_ANN_ARGS>"{"                        { /* This arg is a list */
                                           BEGIN GET_ANN_LIST_ARG;
                                           startListArg(yytext);
                                           addToLine(yytext);
                                         }
<GET_ANN_ARGS>[^{,)\n][^,)\n]*           { /* Pass along the argument string */
                                           /* For some reason, the above is not picking up the '{' */
                                           /* so we had to add this kluge: */
                                           /* Never mind. Adding the leading "[^{,)\n]" fixed it. */
                                           //if (yytext[0] == '{') {
                                           //   BEGIN GET_ANN_LIST_ARG;
                                           //   std::cout << "Kluge, kluge, kluge!" << std::endl;
                                           //   startListArg(yytext);
                                           //   std::string arg_str(yytext);
                                           //   for (auto c : arg_str) {
                                           //      if (c == '}') {
                                           //         BEGIN GET_ANN_ARGS;
                                           //         finishListArg("");
                                           //         break;
                                           //      }
                                           //   }
                                           //} else {
                                           addAnnArg(yytext);
                                           //}
                                           addToLine(yytext);
                                         }
<GET_ANN_ARGS>","                        { /* separates annotation arguments */
                                           addToLine(yytext);
                                         }
<GET_ANN_ARGS>")"                        { /* end of annotation arguments */
                                           BEGIN GET_ANN_TARG_TYPE;
                                           addToLine(yytext);
                                           addToLine(" */ ");
                                         }

<GET_ANN_LIST_ARG>\n                     { completeLine(); }
<GET_ANN_LIST_ARG>[^}]+                  { /* Build the list argument string */
                                           /* XXX Need to handle nested lists? */
                                           addToListArg(yytext);
                                           addToLine(yytext);
                                         }
<GET_ANN_LIST_ARG>"}"                    { /* Complete the list argument string */
                                           BEGIN GET_ANN_ARGS;
                                           finishListArg(yytext);
                                           addToLine(yytext);
                                         }

<GET_ANN_TARG_TYPE>[ \t]                 { /* Ignore whitespace */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>\n                    { completeLine(); }
<GET_ANN_TARG_TYPE>"//@@"                |
<GET_ANN_TARG_TYPE>"@"                   { /* '//@@' is alternate annotation syntax for convenience in C++ */
                                           BEGIN GET_ANNOTATION_NAME; /* There can be more than one annotation */
                                           addToLine(" /* ");
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>static                { setTargIsStatic(true);
                                           /* We don't need to parse the target type - we'll use decltype to infer */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>[*&]                  |
<GET_ANN_TARG_TYPE>const                 |
<GET_ANN_TARG_TYPE>constexpr             |
<GET_ANN_TARG_TYPE>volatile              |
<GET_ANN_TARG_TYPE>mutable               |
<GET_ANN_TARG_TYPE>register              |
<GET_ANN_TARG_TYPE>inline                |
<GET_ANN_TARG_TYPE>typename              { /* Skip these */
                                           /* We don't need to parse the target type - we'll use decltype to infer */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>signed                |
<GET_ANN_TARG_TYPE>unsigned              |
<GET_ANN_TARG_TYPE>short                 |
<GET_ANN_TARG_TYPE>long                  |
<GET_ANN_TARG_TYPE>int                   |
<GET_ANN_TARG_TYPE>char                  |
<GET_ANN_TARG_TYPE>double                { /* Combinations of these may specify a target type (possible implied 'int') */
                                           BEGIN GET_ANN_TARG;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>template              |
<GET_ANN_TARG_TYPE>private               |
<GET_ANN_TARG_TYPE>public                |
<GET_ANN_TARG_TYPE>protected             |
#<GET_ANN_TARG_TYPE>typedef               |
<GET_ANN_TARG_TYPE>typeid                { BEGIN INITIAL;
                                           parseError("Unexpected keyword found while looking for target type");
                                           addToLine(yytext);
                                           clearAnns();
                                         }
<GET_ANN_TARG_TYPE>class                 |
<GET_ANN_TARG_TYPE>struct                { /* Target is a class or struct declaration - look for the name */
                                           BEGIN GET_ANN_TARG;
                                           setTargIsClass(true);
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>typedef               { /* Check for old school struct typedef */
                                           BEGIN GET_ANN_TARG_OLD_STRUCT_TYPE;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>void                  { /* The target returns void - look for the target name */
                                           BEGIN GET_ANN_TARG;
                                           setTargTypeIsVoid(true);
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>[a-zA-Z0-9_]+         { /* Any other alphanumeric must be the base type - look for the target name */
                                           BEGIN GET_ANN_TARG;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_TYPE>.                     { BEGIN INITIAL;
                                           parseError("Annotation target not found");
                                           unput(yytext[0]); /* Put the character back */
                                           clearAnns();
                                         }

<GET_ANN_TARG>[ \t]                      { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }
<GET_ANN_TARG>\n                         { completeLine(); }
<GET_ANN_TARG>"::"                       { /* Continue looking for the rest of the type name */
                                           BEGIN GET_ANN_TARG_TYPE;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG>[*]                        { /* Differentiate between "void" and "void *" */
                                           setTargTypeIsVoid(false);
                                           /* Otherwise, a leftover piece of the target type */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG>[&]                        |
<GET_ANN_TARG>const                      |
<GET_ANN_TARG>signed                     |
<GET_ANN_TARG>unsigned                   |
<GET_ANN_TARG>short                      |
<GET_ANN_TARG>long                       |
<GET_ANN_TARG>int                        |
<GET_ANN_TARG>char                       |
<GET_ANN_TARG>double                     { /* Skip these as leftover pieces of the target type */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG>[a-zA-Z0-9_]+              {
                                           BEGIN GET_AFTER_TARG;
                                           setAnnTarg(yytext); /* and complete the annotation(s) */
                                           clearAnns();
                                           if (isTargClass()) {
                                              pushClass(yytext, block_level);
                                           }
                                           setTargIsClass(false); /* Clear the class flag */
                                           setTargTypeIsVoid(false); /* Clear the void flag */
                                           setTargIsStatic(false); /* Clear the static flag */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG>.                          { BEGIN INITIAL;
                                           parseError("Annotation target not found");
                                           setTargIsClass(false); /* Clear the class flag */
                                           setTargTypeIsVoid(false); /* Clear the void flag */
                                           setTargIsStatic(false); /* Clear the static flag */
                                           unput(yytext[0]); /* Put the character back */
                                           clearAnns();
                                         }

<GET_AFTER_TARG>[ \t]                    { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }
<GET_AFTER_TARG>\n                       { completeLine(); }
<GET_AFTER_TARG>"("                      { BEGIN GET_ANN_TARG_ARGS;
                                           addToLine(yytext);
                                         }
<GET_AFTER_TARG>.                        { /* If no '(', then no arg list */
                                           BEGIN INITIAL;
                                           unput(yytext[0]); /* Put the character back */
                                         }

<GET_ANN_TARG_ARGS>[ \t]                 { /* Ignore whitespace */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS>\n                    { completeLine(); }
<GET_ANN_TARG_ARGS>const                 { setTargArgIsConst(true); /* Note: Control references must be const */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS>[a-zA-Z0-9_:]+        { BEGIN GET_ANN_TARG_ARGS2; /* XXX Might want to parse out "::" here */
                                           setTargArgType(yytext);
                                           setTargArgIsConst(false);
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS>")"                   { /* End of target arguments */
                                           BEGIN INITIAL;
                                           setTargArgIsConst(false);
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS>.                     { BEGIN INITIAL;
                                           parseError("Target method argument not found");
                                           unput(yytext[0]); /* Put the character back */
                                           setTargArgIsConst(false);
                                         }

<GET_ANN_TARG_ARGS2>[ \t]                { /* Ignore whitespace */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS2>\n                   { completeLine(); }
<GET_ANN_TARG_ARGS2>"&"                  { BEGIN GET_ANN_TARG_ARGS3;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS2>.                    { BEGIN INITIAL;
                                           parseError("Target method arguments must be passed by reference");
                                           unput(yytext[0]); /* Put the character back */
                                         }

<GET_ANN_TARG_ARGS3>[ \t]                { /* Ignore whitespace */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS3>\n                   { completeLine(); }
<GET_ANN_TARG_ARGS3>[a-zA-Z0-9_:]+       { /* This is the argument name, we don't need it */
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS3>","                  { /* Look for the next argument */
                                           BEGIN GET_ANN_TARG_ARGS;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS3>")"                  { /* End of target arguments */
                                           BEGIN INITIAL;
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_ARGS3>.                    { BEGIN INITIAL;
                                           parseError("Unexpected non-alphanumeric character in target argument");
                                           unput(yytext[0]); /* Put the character back */
                                         }
<GET_ANN_TARG_OLD_STRUCT_TYPE>[ \t]      { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }
<GET_ANN_TARG_OLD_STRUCT_TYPE>\n         { completeLine(); }
<GET_ANN_TARG_OLD_STRUCT_TYPE>struct     { /* Check for old school struct typedef */
                                           BEGIN INITIAL;
                                           setTargIsClass(true);
                                           setAnnTarg(""); /* and complete the annotation(s) */
                                           clearAnns();
                                           pushClass("", block_level);

                                           setTargIsClass(false); /* Clear the class flag */
                                           setTargTypeIsVoid(false); /* Clear the void flag */
                                           setTargIsStatic(false); /* Clear the static flag */

                                           /* Save indices so we can update the struct "name" later */
                                           setInTypedef(true);
                                           saveTypedefIndices();
                                           addToLine(yytext);
                                         }
<GET_ANN_TARG_OLD_STRUCT_TYPE>[a-zA-Z0-9_]+  { /* Check for old school struct typedef */
                                               BEGIN INITIAL;
                                               parseError("Unexpected keyword found while looking for old school struct target");
                                               addToLine(yytext);
                                               clearAnns();
                                             }
<GET_ANN_TARG_OLD_STRUCT_NAME>[ \t]      { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }
<GET_ANN_TARG_OLD_STRUCT_NAME>\n         { completeLine(); }
<GET_ANN_TARG_OLD_STRUCT_NAME>[a-zA-Z0-9_]+  { /* Get the old school struct typedef name */
                                               BEGIN INITIAL;
                                               setInTypedef(false);
                                               saveTypedefStructName(yytext);
                                               addToLine(yytext);
                                             }
<GET_ANN_TARG_OLD_STRUCT_NAME>.          { BEGIN INITIAL;
                                           parseError("Unexpected non-alphanumeric character looking for struct name");
                                           unput(yytext[0]); /* Put the character back */
                                         }



\n                                       { completeLine(); }

[ \t]                                    { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }

\{                                       { block_level++;
                                           addToLine(yytext);
                                         }
\}                                       { if (block_level == 0) { parseError("Unbalanced curly brackets"); }
                                           else {
                                              block_level--;
                                              // If block_level == bottom of ns_class_stack, pop the stack
                                              popStackIfLevel(block_level);

                                              if (IsInTypedef() && (typedef_struct_blk_lvl == block_level)) {
                                                 BEGIN GET_ANN_TARG_OLD_STRUCT_NAME;
                                              }
                                           }
                                           addToLine(yytext);
                                         }

namespace                                { /* Look for namespace name */
                                           BEGIN GET_NAMESPACE;
                                           addToLine(yytext);
                                         }

<GET_NAMESPACE>[ \t]                     { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }
<GET_NAMESPACE>\n                        { completeLine(); }
<GET_NAMESPACE>[a-zA-Z0-9_]+             { /* Push namespace name and the block_level onto ns_class_stack */
                                           BEGIN INITIAL;
                                           /* If the bottom of the stack already has the current block level, then
                                              it was just a declaration or something - replace it */
                                           pushNamespace(yytext, block_level);
                                           addToLine(yytext);
                                         }
<GET_NAMESPACE>.                         { BEGIN INITIAL;
                                           parseError("Syntax error looking for namespace name");
                                           unput(yytext[0]); /* Put the character back */
                                         }

class                                    |
struct                                   { /* Look for class name */
                                           BEGIN GET_CLASS;
                                           addToLine(yytext);
                                         }

<GET_CLASS>[ \t]                         { /* Ignore whitespace */
                                            addToLine(yytext);
                                         }
<GET_CLASS>\n                            { completeLine(); }
<GET_CLASS>[a-zA-Z0-9_]+                 { /* Push class name and the block_level onto ns_class_stack */
                                           BEGIN INITIAL;
                                           pushClass(yytext, block_level);
                                           addToLine(yytext);
                                         }
<GET_CLASS>\{                            { // We've found an unnamed struct definition; push an empty class name
                                           BEGIN INITIAL;
                                           pushClass("", block_level);
                                           unput(yytext[0]); /* Put the character back */
                                         }
<GET_CLASS>.                             { BEGIN INITIAL;
                                           parseError("Syntax error looking for class name");
                                           unput(yytext[0]); /* Put the character back */
                                         }

[a-zA-Z0-9_]+                            { /* Found an alphanumeric lextoken */
                                           addToLine(yytext); /* Nothing else we need to do here */
                                         }

.                                        { /* Print all other (non-alphanumeric) chars */
                                           addToLine(yytext); /* Nothing else we need to do here */
                                         }

%%


void parseFile(const char *filename, vector<FileLine>& fileV)
{
   // Set up global pointers (used by the flex-generated code)
   pFileVector = &fileV;
   //pCodeVector = &codeV;
   
   yyin = fopen(filename, "r");
   if (yyin == NULL)
   {
      printf("Cannot open file %s\n", filename);
      exit(1); // ERROR
   }

   // Set up initial conditions
   pFileVector->clear();
   //pCodeVector->clear();
   curLine = "";
   curLineNum = 1;
   col_num = 0;
   block_level = 0;
   targ_is_class = false;
   targ_type_is_void = false;
   targ_is_static = false;
   targ_arg_is_const = false;
   in_typedef = false;
   YY_NEW_FILE;

   // and parse the file
   yylex();

   fclose(yyin);
}


void gen_setup_teardown(const std::string &indent, vector<TargetInfo> &meth_vec,
                        MethodLevel level, const std::string &desc)
{
   int cnt = 0;
   for (auto &meth : meth_vec) {
      if (meth.level == level) {
         // XXX We need to handle either function or non-static method:
         if (meth.may_be_object_method) {
            std::cout << indent << meth.ob_str << meth.name << "(" << meth.arg_str << ");" << std::endl;
         } else {
            // otherwise, it's a function or static method
            std::cout << indent << meth.full_name << "(" << meth.arg_str << ");" << std::endl;
         }
         ++cnt;
      }
   }
   if (cnt == 0) {
      std::cout << indent << "// (no " << desc << " methods)" << std::endl;
   } else if (level == INVOCATION) {
      std::cout << indent << "assert(min_loop_count == batch_size);" << std::endl;
   }
}

void gen_innermost_loop(const std::string &indent, TargetInfo &benchmark) {
   std::cout << indent << "// Call the benchmark method (consume any return value)" << std::endl;
   if (benchmark.type_is_void) {
      std::cout << indent << "(" << benchmark.ob_str << "*noinline_bm_func)("
                << benchmark.arg_str << ");" << std::endl;
   } else {
      // Returns non-void - consume the return value
      std::cout << indent << "bh_return_.consume((" << benchmark.ob_str << "*noinline_bm_func)("
                << benchmark.arg_str << "));" << std::endl;
   }
}

void gen_bm_loop(const std::string &indent, TargetInfo &benchmark, bool warmup=false) {
   std::string loop_type = "bm";
   if (warmup) {
      loop_type = "warmup";
   }
   // Invocation-level setup:
   std::cout << indent << "// Invocation-level setup:" << std::endl;
   gen_setup_teardown(indent, setups, INVOCATION, "invocation-level setup");
   
   std::cout << indent << "// Run a \"timing loop\":" << std::endl;
   std::cout << indent << "typename Clock::time_point start = Clock::now();" << std::endl;
   //if (benchmark.mode == SINGLE_SHOT_TIME) {
   //   // We don't actually "loop"
   //   gen_innermost_loop(indent, benchmark);
   //} else {
      std::cout << indent << "for (uint64_t cnt = 0; cnt < min_loop_count; ++cnt) {" << std::endl;
      gen_innermost_loop(indent + "   ", benchmark);
      std::cout << indent << "}" << std::endl;
   //}
   std::cout << indent << "typename Clock::time_point end = Clock::now();" << std::endl;
   std::cout << indent << "// Evaluate relative cpu speed (and save the data)" << std::endl;
   std::cout << indent << "double cpu_speed_metric = clock_info.getRelativeCPUSpeed<Clock>();" << std::endl;
   // Invocation-level teardown:
   std::cout << indent << "// Invocation-level teardown:" << std::endl;
   gen_setup_teardown(indent, teardowns, INVOCATION, "invocation-level teardown");
   
   std::cout << indent << "uint64_t elapsed_time_nsec =" << std::endl;
   std::cout << indent << "   std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();" << std::endl;
   std::cout << indent << "// Aggregate the time and loop count" << std::endl;
//   if (benchmark.mode == SAMPLE_TIME) {
//      std::cout << indent << "effective_time_nsec += std::max(elapsed_time_nsec, cutoff_time_nsec);" << std::endl;
//   }
   if (benchmark.mode != SINGLE_SHOT_TIME) {
      std::cout << indent << "total_time_nsec += elapsed_time_nsec;" << std::endl;
      std::cout << indent << "total_loop_count += min_loop_count;" << std::endl;
   }
   std::cout << indent << "grand_total_loop_count += min_loop_count;" << std::endl;
   if (benchmark.mode == SAMPLE_TIME) {
      std::cout << indent << "effective_time_nsec += std::max(elapsed_time_nsec, cutoff_time_nsec);" << std::endl;
      std::cout << indent << "++operations;" << std::endl;
      std::cout << indent << "sum += ((double)elapsed_time_nsec)";
      if (benchmark.output_timeunit_mult != 1) {
         std::cout << "/" << benchmark.output_timeunit_mult << "ull";
      }
      std::cout << ";" << std::endl;
      std::cout << indent << "sum_sq += elapsed_time_nsec*((double)elapsed_time_nsec)";
      if (benchmark.output_timeunit_mult != 1) {
         std::cout << "/(" << benchmark.output_timeunit_mult << "ull * ((double)"
                   << benchmark.output_timeunit_mult << "ull))";
      }
      std::cout << ";" << std::endl;
      if (warmup == false) {
         std::cout << indent << "iter_sample_times.emplace_back(((double)elapsed_time_nsec)";
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << "/" << benchmark.output_timeunit_mult << "ull";
         }
         std::cout << ");" << std::endl;
      }
   }
   std::cout << indent << "// Calibrate the minimum loop count" << std::endl;
   std::cout << indent << "if (elapsed_time_nsec < cutoff_time_nsec) {" << std::endl;
   std::cout << indent << "   // The elapsed time was too short";
   
   switch(benchmark.mode) {
   case AVERAGE_TIME:
   case THROUGHPUT:
      std::cout << " - ";
      if (warmup == false) {
         std::cout << "print a warning and ";
      }
      std::cout << "double the minimum loop count";
      break;
   case SAMPLE_TIME:
      break;
   case SINGLE_SHOT_TIME:
      if (warmup == false) {
         std::cout << " - print a warning";
      }
      break;
   default:
      // We should never get here
      abort();
   };
   
   std::cout << std::endl;
   
   switch(benchmark.mode) {
   case AVERAGE_TIME:
   case THROUGHPUT:
      std::cout << indent << "   // XXX If there are method-level setup or teardown, print a stern warning instead" << std::endl;
      if (warmup == false) {
         std::cout << indent << "   std::cout << \"Warning: benchmark \" << benchmark_name << \", iteration \" << (iter + 1)" << std::endl;
         std::cout << indent << "             << \", timing run fell below the minimum timing interval \"" << std::endl;
         std::cout << indent << "             << \"for this clock - increasing the minimum loop count.\" << std::endl;" << std::endl;
      }
      std::cout << indent << "   min_loop_count *= 2;" << std::endl;
      break;
   case SAMPLE_TIME:
      std::cout << indent << "   // Keep a count of the operations that were too short to measure:" << std::endl;
      std::cout << indent << "   ++problem_timing_count;" << std::endl;
      std::cout << indent << "   // Sample time mode, loop count must remain at batch_size" << std::endl;
      break;
   case SINGLE_SHOT_TIME:
      if (warmup == false) {
         std::cout << indent << "   std::cout << \"Warning: benchmark \" << benchmark_name << \", iteration \" << (iter + 1)" << std::endl;
         std::cout << indent << "             << \", single-shot timing run fell below the minimum timing interval \"" << std::endl;
         std::cout << indent << "             << \"for this clock.\" << std::endl;" << std::endl;
      }
      std::cout << indent << "   // Single-shot, loop count must remain at batch_size" << std::endl;
      break;
   default:
      // We should never get here
      abort();
   };
   std::cout << indent << "}" << std::endl;
   std::cout << indent << "// Collect any other metrics" << std::endl;
   std::cout << indent << "// Collect data for timing trend (to detect insufficient warmup)" << std::endl;
   //std::cout << indent << loop_type << "_timing_trend.emplace_back(grand_total_loop_count, ((double)elapsed_time_nsec)/min_loop_count);" << std::endl;
   //std::cout << indent << loop_type << "_cpu_speed_trend.emplace_back(grand_total_loop_count, cpu_speed_metric/baseline_cpu_speed_metric);" << std::endl;

   std::cout << indent << loop_type << "_cpu_and_timing_trend.update(grand_total_loop_count," << std::endl;
   std::cout << indent << "                               ((double)elapsed_time_nsec)/min_loop_count," << std::endl;
   std::cout << indent << "                               cpu_speed_metric/baseline_cpu_speed_metric);" << std::endl;
}

const bool WARMUP = true;

void gen_benchmark_calls(const std::string &indent) {
   std::cout << indent << std::endl;
   if (benchmarks.size() == 1) {
      std::cout << indent << "// " << benchmarks.size() << " benchmark\n" << std::endl;
   } else {
      std::cout << indent << "// " << benchmarks.size() << " benchmarks\n" << std::endl;
   }
   for (int i = 0; i < benchmarks.size(); ++i) {
      auto &benchmark = benchmarks[i];
      std::cout << indent << "//  Benchmark " << (i+1) << ":" << std::endl;
      std::cout << indent << "{" << std::endl;
      std::cout << indent << "   std::string benchmark_name = \"" << benchmark.full_name << "\";" << std::endl;
      std::cout << indent << "   const int operations_per_loop_count = 1;" << std::endl;
      // XXX Need to get this from annotation
      std::cout << indent << "   const uint64_t batch_size = 1;" << std::endl;
      std::cout << indent << "   int warmup_iters = " << benchmark.warmup_iters << "; // How many times to run this benchmark for warmup" << std::endl;
      std::cout << indent << "   int bm_iters = " << benchmark.bm_iters << ";     // How many times to run this benchmark" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << indent << "   double warmup_time_per_it = " << benchmark.warmup_time
                   << ";  // Time to run warmup (per iteration)" << std::endl;
         std::cout << indent << "   double bm_time_per_it = " << benchmark.bm_time
                   << ";  // Time to run the benchmark (per iteration)" << std::endl;
         std::cout << indent << "   std::string warmup_time_units(\""
                   << benchmark.warmup_timeunit_short_str << "\");" << std::endl;
         std::cout << indent << "   std::string bm_time_units(\""
                   << benchmark.bm_timeunit_short_str << "\");" << std::endl;
         std::cout << indent << "" << std::endl;
         //if (benchmark.warmup_timeunit_mult != 1) {
            std::cout << indent << "   uint64_t warmup_time_nsec = "
                      << benchmark.warmup_timeunit_mult << "ull * warmup_time_per_it;" << std::endl;
         //}
         //if (benchmark.bm_timeunit_mult != 1) {
            std::cout << indent << "   uint64_t bm_time_nsec = "
                      << benchmark.bm_timeunit_mult << "ull * bm_time_per_it;" << std::endl;
         //}
         break;
      case SINGLE_SHOT_TIME:
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << indent << std::endl;
      std::cout << indent << "   int num_threads = 1;" << std::endl;
      std::cout << indent << std::endl;

      std::cout << indent << "   // Check for command-line overrides" << std::endl;
      std::cout << indent << "   if (cl_options.warmup_it != -1) { warmup_iters = cl_options.warmup_it; }" << std::endl;
      std::cout << indent << "   if (cl_options.bm_it != -1) { bm_iters = cl_options.bm_it; }" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << indent << "   if (cl_options.warmup_time.value != -1) {" << std::endl;
         std::cout << indent << "      warmup_time_per_it  = cl_options.warmup_time.value;" << std::endl;
         std::cout << indent << "      warmup_time_units = cl_options.warmup_time.unit_str;" << std::endl;
         std::cout << indent << "      warmup_time_nsec  = cl_options.warmup_time.time_nsec;" << std::endl;
         std::cout << indent << "   }" << std::endl;
         std::cout << indent << "   if (cl_options.bm_time.value != -1) {" << std::endl;
         std::cout << indent << "      bm_time_per_it  = cl_options.bm_time.value;" << std::endl;
         std::cout << indent << "      bm_time_units = cl_options.bm_time.unit_str;" << std::endl;
         std::cout << indent << "      bm_time_nsec  = cl_options.bm_time.time_nsec;" << std::endl;
         std::cout << indent << "   }" << std::endl;
      case SINGLE_SHOT_TIME:
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << indent << "" << std::endl;

      std::cout << indent << "   std::cout << std::endl;" << std::endl;
      std::cout << indent << "   std::cout << \"Benchmark: \" << benchmark_name << std::endl;" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
         std::cout << indent << "   std::cout << \"Benchmark mode: Average time, time/op\" << std::endl;" << std::endl;
         break;
      case THROUGHPUT:
         std::cout << indent << "   std::cout << \"Benchmark mode: Throughput, ops/time\" << std::endl;" << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "   std::cout << \"Benchmark mode: Sample time, time/op\" << std::endl;" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         std::cout << indent << "   std::cout << \"Benchmark mode: Single-shot time, time/op\" << std::endl;" << std::endl;
         break;
      default:
         // We should never get here
         abort();
      };
      //if (num_threads == 1) {
         std::cout << indent << "   std::cout << \"Threads: \" << num_threads << \" thread\" << std::endl;" << std::endl;
      //} else {
      //   std::cout << indent << "   std::cout << \"Threads: \" << num_threads << \" threads\" << std::endl;" << std::endl;
      //}
      
      std::cout << indent << "   std::cout << \"Warmup: \" << warmup_iters << \" iterations";
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << ", \" << warmup_time_per_it << \" \"" << std::endl;
         std::cout << indent << "             << warmup_time_units << \" each";
         break;
      case SINGLE_SHOT_TIME:
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << "\" << std::endl;" << std::endl;
      
      std::cout << indent << "   std::cout << \"Measurement: \" << bm_iters << \" iterations";
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << ", \" << bm_time_per_it << \" \"" << std::endl;
         std::cout << indent << "             << bm_time_units << \" each";
         break;
      case SINGLE_SHOT_TIME:
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << "\" << std::endl;" << std::endl;

      if (params.size() > 0) {
         std::cout << indent << "   std::cout << \"Parameters: (\";" << std::endl;
         bool first = true;
         for (auto &param : params) {
            std::cout << indent << "   std::cout << \"";
            if (first) { first = false; }
            else       { std::cout << ",\\n             "; }
            std::cout << param.full_name << " = \" << "
                      << param.full_name << ";" << std::endl;
         }
         std::cout << indent << "   std::cout << \")\" << std::endl;" << std::endl;
      }
      std::cout << indent << std::endl;
      std::cout << indent << "   harness_utils_private::CPUAndTimingTrend warmup_cpu_and_timing_trend(cl_options.postream_trends," << std::endl;
      std::cout << indent << "                                                                        cl_options.winnow_thresh," << std::endl;
      std::cout << indent << "                                                                        cl_options.winnow_thresh);" << std::endl;
      std::cout << indent << "   harness_utils_private::CPUAndTimingTrend bm_cpu_and_timing_trend(cl_options.postream_trends," << std::endl;
      std::cout << indent << "                                                                    cl_options.winnow_thresh," << std::endl;
      std::cout << indent << "                                                                    cl_options.winnow_thresh);" << std::endl;

      std::cout << indent << std::endl;
      std::cout << indent << "   uint64_t min_loop_count = batch_size;  // Minimum loop count for this benchmark to match the" << std::endl;
      std::cout << indent << "                                          // available clock precision (calibrated during warmup)" << std::endl;
      std::cout << indent << std::endl;
      std::cout << indent << "   // Get a non-inlinable pointer to the benchmark method/function:" << std::endl;
      std::cout << indent << "   auto noinline_bm_func = harness_utils_private::noInline(&" << benchmark.full_name << ");" << std::endl;
      std::cout << indent << std::endl;
      std::cout << indent << "   // Instantiate group/thread scope state:" << std::endl;
      std::cout << indent << "   // XXX With memory layout control, re-construct \"in-place\"" << std::endl;
      std::cout << indent << "   // (no group/thread scope state)" << std::endl;
      std::cout << indent << std::endl;
      std::cout << indent << "   // Iterations:" << std::endl;
      std::cout << indent << "   uint64_t grand_total_loop_count = 0; // Loop count total over all iterations" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
         std::cout << indent << "   std::vector<double> av_time_per_op_per_iteration;" << std::endl;
         std::cout << indent << "   std::vector<double> &stats_data = av_time_per_op_per_iteration;" << std::endl;
         break;
      case THROUGHPUT:
         std::cout << indent << "   std::vector<double> throughput_per_iteration;" << std::endl;
         std::cout << indent << "   std::vector<double> &stats_data = throughput_per_iteration;" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         std::cout << indent << "   std::vector<double> ss_time_per_iteration;" << std::endl;
         std::cout << indent << "   std::vector<double> &stats_data = ss_time_per_iteration;" << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "   std::vector<double> av_time_per_op_per_iteration;" << std::endl;
         std::cout << indent << "   std::vector<double> &stats_data = av_time_per_op_per_iteration;" << std::endl;
         std::cout << indent << "   std::vector<double> sample_times;" << std::endl;
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << indent << std::endl;
      std::cout << indent << "   std::cout << std::endl;" << std::endl;
      std::cout << indent << std::endl;
      std::cout << indent << "   // First, loop over warmup iterations" << std::endl;
      std::cout << indent << "   for (int iter = 0; iter < warmup_iters; ++iter) {" << std::endl;
      // Iteration-level setup:
      std::cout << indent << "      // Iteration-level setup:" << std::endl;
      gen_setup_teardown(indent + "      ", setups, ITERATION, "iteration-level setup");
      std::cout << indent << std::endl;

      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << indent << "      // Time-limited" << std::endl;
         std::cout << indent << "      // For each, run until the end time has been reached" << std::endl;
         std::cout << indent << "      uint64_t total_time_nsec = 0;" << std::endl;
         std::cout << indent << "      uint64_t total_loop_count = 0;" << std::endl;
      case SINGLE_SHOT_TIME:
         break;
      default:
         // We should never get here
         abort();
      };
         
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
         std::cout << indent << "      while (total_time_nsec < warmup_time_nsec) {" << std::endl;
         gen_bm_loop(indent + "         ", benchmark, WARMUP);
         std::cout << indent << "      }" << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "      uint64_t effective_time_nsec = 0;" << std::endl;
         std::cout << indent << "      uint64_t problem_timing_count = 0;" << std::endl;
         std::cout << indent << "      uint64_t operations = 0;" << std::endl;
         std::cout << indent << "      double sum = 0.0;" << std::endl;
         std::cout << indent << "      double sum_sq = 0.0;" << std::endl;
         std::cout << indent << "      while (effective_time_nsec < warmup_time_nsec) {" << std::endl;
         gen_bm_loop(indent + "         ", benchmark, WARMUP);
         std::cout << indent << "      }" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         std::cout << indent << "      // Single-shot" << std::endl;
         gen_bm_loop(indent + "      ", benchmark, WARMUP);
         break;
      default:
         // We should never get here
         abort();
      };

      // Iteration-level teardown:
      std::cout << indent << "      // Iteration-level teardown:" << std::endl;
      gen_setup_teardown(indent + "      ", teardowns, ITERATION, "iteration-level teardown");

      std::cout << indent << "      " << std::endl;
      switch(benchmark.mode) {
      case SAMPLE_TIME:
         std::cout << indent << "      if (problem_timing_count > 0) {" << std::endl;
         std::cout << indent << "         std::cout << \"Warning: benchmark \" << benchmark_name" << std::endl;
         std::cout << indent << "                   << \", warmup iteration \" << (iter + 1)" << std::endl;
         std::cout << indent << "                   << \", for \" << problem_timing_count << \" of \" << operations" << std::endl;
         std::cout << indent << "                   << \" operations, timing fell below the minimum timing interval \"" << std::endl;
         std::cout << indent << "                   << \"for this clock.\" << std::endl;" << std::endl;
         std::cout << indent << "      }" << std::endl;
         std::cout << indent << "      " << std::endl;
         // No break - it also shares the following lines with AVERAGE_TIME mode
      case AVERAGE_TIME:
         std::cout << indent << "      uint64_t total_op_count = total_loop_count * operations_per_loop_count;" << std::endl;
         std::cout << indent << "      double av_time_per_op_" << benchmark.output_timeunit_str
                   << " = (((double)total_time_nsec)";
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << "/" << benchmark.output_timeunit_mult << "ull";
         }
         std::cout << ")/total_op_count;" << std::endl;
         break;
      case THROUGHPUT:
         std::cout << indent << "      uint64_t total_op_count = total_loop_count * operations_per_loop_count;" << std::endl;
         std::cout << indent << "      double throughput_" << benchmark.output_timeunit_str
                   << " = ((double)total_op_count)/(((double)total_time_nsec)";
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << "/" << benchmark.output_timeunit_mult << "ull";
         }
         std::cout << ");" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << indent << "      double elapsed_time_" << benchmark.output_timeunit_str
                      << " = ((double)elapsed_time_nsec)/"
                      << benchmark.output_timeunit_mult << "ull;" << std::endl;
         }
         break;
      default:
         // We should never get here
         abort();
      };
      if (benchmark.mode == SAMPLE_TIME) {
         std::cout << indent << "      // Compute iteration stats" << std::endl;
         std::cout << indent << "      int N = operations;" << std::endl;
         std::cout << indent << "      double avg = sum/N;" << std::endl;
         std::cout << indent << "      double avg_sq = sum_sq/N;" << std::endl;
         std::cout << indent << "      double std_dev = std::sqrt(avg_sq - avg*avg);" << std::endl;
         std::cout << std::endl;
         std::cout << indent << "      double conf_int;" << std::endl;
         std::cout << indent << "      if (N > 1) {" << std::endl;
         std::cout << indent << "         conf_int = std_dev * harness_utils_private::getT999(N-1) / std::sqrt(N);" << std::endl;
         std::cout << indent << "      } else {" << std::endl;
         std::cout << indent << "         conf_int = 483.9 * avg;  // Wall, Boen, and Tweedie, The American Statistician, vol. 55, no. 2 (May,2001)" << std::endl;
         std::cout << indent << "      }" << std::endl;
      }
      std::cout << indent << std::endl;
      std::cout << indent << "      std::cout << \"Benchmark \" << benchmark_name << \", warmup iteration \" << (iter + 1)" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
         std::cout << indent << "                << \": \" << av_time_per_op_"
                   << benchmark.output_timeunit_str
                   << " << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         break;
      case THROUGHPUT:
         std::cout << indent << "                << \": \" << throughput_" << benchmark.output_timeunit_str
                   << " << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         std::cout << indent << "                << \": \" << elapsed_time_"
                   << benchmark.output_timeunit_str << " << \" "
                   << benchmark.output_timeunit_short_str << "\" << std::endl;" << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "                << \": \" << avg << \" ±(99.9%) \" << conf_int << \" "
                   << benchmark.units_str << "\" << std::endl;" << std::endl;
         break;
      default:
         // We should never get here
         abort();
      };
      
      std::cout << indent << "   }" << std::endl;
      std::cout << indent << "   warmup_cpu_and_timing_trend.finish();" << std::endl;
      std::cout << indent << "   " << std::endl;
      std::cout << indent << "   // Then, loop over timing iterations" << std::endl;
      std::cout << indent << "   for (int iter = 0; iter < bm_iters; ++iter) {" << std::endl;
      // Iteration-level setup:
      std::cout << indent << "      // Iteration-level setup:" << std::endl;
      gen_setup_teardown(indent + "      ", setups, ITERATION, "iteration-level setup");
      std::cout << indent << std::endl;


      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << indent << "      // Time-limited" << std::endl;
         std::cout << indent << "      // For each, run until the end time has been reached" << std::endl;
         std::cout << indent << "      uint64_t total_time_nsec = 0;" << std::endl;
         std::cout << indent << "      uint64_t total_loop_count = 0;" << std::endl;
      case SINGLE_SHOT_TIME:
         break;
      default:
         // We should never get here
         abort();
      };
         
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
         std::cout << indent << "      while (total_time_nsec < bm_time_nsec) {" << std::endl;
         gen_bm_loop(indent + "         ", benchmark);
         std::cout << indent << "      }" << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "      uint64_t effective_time_nsec = 0;" << std::endl;
         std::cout << indent << "      uint64_t problem_timing_count = 0;" << std::endl;
         std::cout << indent << "      uint64_t operations = 0;" << std::endl;
         std::cout << indent << "      double sum = 0.0;" << std::endl;
         std::cout << indent << "      double sum_sq = 0.0;" << std::endl;
         std::cout << indent << "      std::vector<double> iter_sample_times;" << std::endl;
         std::cout << indent << "      while (effective_time_nsec < bm_time_nsec) {" << std::endl;
         gen_bm_loop(indent + "         ", benchmark);
         std::cout << indent << "      }" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         std::cout << indent << "      // Single-shot" << std::endl;
         gen_bm_loop(indent + "      ", benchmark);
         break;
      default:
         // We should never get here
         abort();
      };

      // Iteration-level teardown:
      std::cout << indent << "      // Iteration-level teardown:" << std::endl;
      gen_setup_teardown(indent + "      ", teardowns, ITERATION, "iteration-level teardown");

      std::cout << indent << "      " << std::endl;
      if (benchmark.mode == SAMPLE_TIME) {
         std::cout << indent << "      if (problem_timing_count > 0) {" << std::endl;
         std::cout << indent << "         std::cout << \"Warning: benchmark \" << benchmark_name << \", iteration \" << (iter + 1)" << std::endl;
         std::cout << indent << "                   << \", for \" << problem_timing_count << \" of \" << operations" << std::endl;
         std::cout << indent << "                   << \" operations, timing fell below the minimum timing interval \"" << std::endl;
         std::cout << indent << "                   << \"for this clock - these measurements should not be trusted.\"" << std::endl;
         std::cout << indent << "                   << std::endl;" << std::endl;
         std::cout << indent << "      }" << std::endl;
         std::cout << indent << "      " << std::endl;
      }
      std::cout << indent << "      // Aggregate the measurements per iteration:" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case SAMPLE_TIME:
         std::cout << indent << "      uint64_t total_op_count = total_loop_count * operations_per_loop_count;" << std::endl;
         std::cout << indent << "      double av_time_per_op_" << benchmark.output_timeunit_str
                   << " = (((double)total_time_nsec)";
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << "/" << benchmark.output_timeunit_mult << "ull";
         }
         std::cout << ")/total_op_count;" << std::endl;
         std::cout << indent << "      av_time_per_op_per_iteration.emplace_back(av_time_per_op_"
                   << benchmark.output_timeunit_str << ");" << std::endl;
         break;
      case THROUGHPUT:
         std::cout << indent << "      uint64_t total_op_count = total_loop_count * operations_per_loop_count;" << std::endl;
         std::cout << indent << "      double throughput_" << benchmark.output_timeunit_str
                   << " = ((double)total_op_count)/(((double)total_time_nsec)";
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << "/" << benchmark.output_timeunit_mult << "ull";
         }
         std::cout << ");" << std::endl;
         std::cout << indent << "      throughput_per_iteration.emplace_back(throughput_" << benchmark.output_timeunit_str
                   << ");" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         if (benchmark.output_timeunit_mult != 1) {
            std::cout << indent << "      double elapsed_time_" << benchmark.output_timeunit_str
                      << " = ((double)elapsed_time_nsec)/"
                      << benchmark.output_timeunit_mult << "ull;" << std::endl;
         }
         std::cout << indent << "      ss_time_per_iteration.emplace_back(elapsed_time_"
                   << benchmark.output_timeunit_str << ");" << std::endl;
         break;
      default:
         // We should never get here
         abort();
      };
      if (benchmark.mode == SAMPLE_TIME) {
         std::cout << indent << "      // Compute iteration stats" << std::endl;
         std::cout << indent << "      int N = operations;" << std::endl;
         std::cout << indent << "      double avg = sum/N;" << std::endl;
         std::cout << indent << "      double avg_sq = sum_sq/N;" << std::endl;
         std::cout << indent << "      double std_dev = std::sqrt(avg_sq - avg*avg);" << std::endl;
         std::cout << std::endl;
         std::cout << indent << "      double conf_int;" << std::endl;
         std::cout << indent << "      if (N > 1) {" << std::endl;
         std::cout << indent << "         conf_int = std_dev * harness_utils_private::getT999(N-1) / std::sqrt(N);" << std::endl;
         std::cout << indent << "      } else {" << std::endl;
         std::cout << indent << "         conf_int = 483.9 * avg;  // Wall, Boen, and Tweedie, The American Statistician, vol. 55, no. 2 (May,2001)" << std::endl;
         std::cout << indent << "      }" << std::endl;
      }
      std::cout << indent << std::endl;
      std::cout << indent << "      std::cout << \"Benchmark \" << benchmark_name << \", iteration \" << (iter + 1)" << std::endl;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
         std::cout << indent << "                << \": \" << av_time_per_op_"
                   << benchmark.output_timeunit_str
                   << " << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         break;
      case THROUGHPUT:
         std::cout << indent << "                << \": \" << throughput_" << benchmark.output_timeunit_str
                   << " << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         break;
      case SINGLE_SHOT_TIME:
         std::cout << indent << "                << \": \" << elapsed_time_"
                   << benchmark.output_timeunit_str << " << \" "
                   << benchmark.output_timeunit_short_str << "\" << std::endl;" << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "                << \": \" << avg << \" ±(99.9%) \" << conf_int << \" "
                   << benchmark.units_str << "\" << std::endl;" << std::endl;
         std::cout << std::endl;
         std::cout << indent << "      // Compute quantiles for this iteration" << std::endl;
         std::cout << indent << "      harness_utils_private::HistQuant hist_quant(iter_sample_times);" << std::endl;
         std::cout << indent << "      for (auto &quant : hist_quant.getQuant()) {" << std::endl;
         std::cout << indent << "         std::cout << \"                 \" << benchmark_name << \": p\" << quant.q" << std::endl;
         std::cout << indent << "                   << \":\\t\" << quant.val << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         std::cout << indent << "      }" << std::endl;
         std::cout << std::endl;
         std::cout << indent << "      // Add the sample times for this iteration to the list for all iterations:" << std::endl;
         std::cout << indent << "      sample_times.insert(sample_times.end()," << std::endl;
         std::cout << indent << "                          iter_sample_times.begin(), iter_sample_times.end());" << std::endl;
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << indent << "   }" << std::endl;
      std::cout << indent << "   bm_cpu_and_timing_trend.finish();" << std::endl;

      // Stat computation
      std::cout << indent << std::endl;
      std::cout << indent << "   // Compute stats" << std::endl;
      std::cout << indent << "   //harness_utils_private::StatComputer stats(stats_data);" << std::endl;
      std::cout << indent << "   double sum = 0.0;" << std::endl;
      std::cout << indent << "   double sum_sq = 0.0;" << std::endl;
      std::cout << indent << "   double minval = DBL_MAX;" << std::endl;
      std::cout << indent << "   double maxval = 0.0;" << std::endl;
      std::cout << indent << "   for (double avt : stats_data) {" << std::endl;
      std::cout << indent << "      sum += avt;" << std::endl;
      std::cout << indent << "      sum_sq += avt*avt;" << std::endl;
      std::cout << indent << "      minval = (avt < minval) ? (avt) : (minval);" << std::endl;
      std::cout << indent << "      maxval = (avt > maxval) ? (avt) : (maxval);" << std::endl;
      std::cout << indent << "   }" << std::endl;
      std::cout << indent << "   int N = stats_data.size();" << std::endl;
      std::cout << indent << "   double avg = sum/N;" << std::endl;
      std::cout << indent << "   double avg_sq = sum_sq/N;" << std::endl;
      std::cout << indent << "   double std_dev = std::sqrt(avg_sq - avg*avg);" << std::endl;
      std::cout << indent << std::endl;
      std::cout << indent << "   double conf_int;" << std::endl;
      std::cout << indent << "   if (N > 1) {" << std::endl;
      std::cout << indent << "      conf_int = std_dev * harness_utils_private::getT999(N-1) / std::sqrt(N);" << std::endl;
      std::cout << indent << "   } else {" << std::endl;
      std::cout << indent << "      conf_int = 483.9 * avg;  // Wall, Boen, and Tweedie, The American Statistician, vol. 55, no. 2 (May,2001)" << std::endl;
      std::cout << indent << "   }" << std::endl;
      std::cout << indent << std::endl;
      std::cout << indent << "   std::cout << std::endl;" << std::endl;
      std::cout << indent << "   std::cout << \"Result for \" << benchmark_name << \":\" << std::endl;" << std::endl;
      
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SINGLE_SHOT_TIME:
         std::cout << indent << "   std::cout << \"  \" << avg << \" ±(99.9%) \" << conf_int << \" ";
         std::cout << benchmark.units_str << "\" << std::endl;" << std::endl;
         std::cout << indent << "   std::cout << \"  (min, avg, max) = (\" << minval << \", \" << avg << \", \" << maxval" << std::endl;
         std::cout << indent << "             << \"), stdev = \" << std_dev << std::endl;" << std::endl;
         std::cout << indent << std::endl;
         break;
      case SAMPLE_TIME:
         std::cout << indent << "   std::cout << \"  N = \" << sample_times.size() << std::endl;" << std::endl;
         std::cout << indent << "   std::cout << \"  mean = \" << avg << \" ±(99.9%) \" << conf_int << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         std::cout << indent << std::endl;
         std::cout << indent << "   harness_utils_private::HistQuant hist_quant(sample_times);" << std::endl;
         std::cout << indent << "   std::cout << std::endl;" << std::endl;
         std::cout << indent << "   std::cout << \"  Histogram, " << benchmark.units_str << ":\" << std::endl;" << std::endl;
         std::cout << indent << "   for (auto &bin : hist_quant.getHist()) {" << std::endl;
         std::cout << indent << "      std::cout << \"    [\" << bin.bin_start << \", \" << bin.bin_end << \"] = \"" << std::endl;
         std::cout << indent << "                << bin.cnt << std::endl;" << std::endl;
         std::cout << indent << "   }" << std::endl;
         std::cout << indent << "   std::cout << std::endl;" << std::endl;
         std::cout << indent << "   std::cout << \"  Percentiles, " << benchmark.units_str << ":\" << std::endl;" << std::endl;
         std::cout << indent << "   for (auto &quant : hist_quant.getQuant()) {" << std::endl;
         std::cout << indent << "      std::cout << \"    p(\" << 100.0*quant.q" << std::endl;
         std::cout << indent << "                << \") = \\t\" << quant.val << \" " << benchmark.units_str << "\" << std::endl;" << std::endl;
         std::cout << indent << "   }" << std::endl;
         break;
      default:
         // We should never get here
         abort();
      };

      std::cout << indent << std::endl;
      std::cout << indent << "   // Dump out information:" << std::endl;
      std::cout << indent << "   if (cl_options.postream_trends) {" << std::endl;
      std::cout << indent << "      (*cl_options.postream_trends) << \"Warmup and CPU speed trends\" << std::endl;" << std::endl;
      std::cout << indent << "      (*cl_options.postream_trends) << \"benchmark: \" << benchmark_name << std::endl;" << std::endl;
      if (params.size() > 0) {
         std::cout << indent << "      (*cl_options.postream_trends) << \"Parameters:\" << std::endl;" << std::endl;
         for (auto &param : params) {
            std::cout << indent << "      (*cl_options.postream_trends) << \"    " << param.full_name
                      << " = \" << " << param.full_name << " << std::endl;" << std::endl;
         }
      }
      std::cout << indent << "      " << std::endl;
      std::cout << indent << "      (*cl_options.postream_trends) << \"Warmup:\" << std::endl;" << std::endl;
      std::cout << indent << "      warmup_cpu_and_timing_trend.dumpOutput(\"W\", operations_per_loop_count);" << std::endl;
      std::cout << indent << "      (*cl_options.postream_trends) << \"Timing runs:\" << std::endl;" << std::endl;
      std::cout << indent << "      bm_cpu_and_timing_trend.dumpOutput(\"T\", operations_per_loop_count);" << std::endl;
      std::cout << indent << "   }" << std::endl;
      
      std::cout << indent << std::endl;
      std::string cnt_str = "N";
      if (benchmark.mode == SAMPLE_TIME) { cnt_str = "sample_times.size()"; }
      std::cout << indent << "   // Save info for master summary:" << std::endl;
      std::cout << indent << "   master_summary.add(benchmark_name, \"" << benchmark.mode_str
                << "\", " << cnt_str << ", avg, conf_int, \"" << benchmark.units_str << "\"";
      bool first = true;
      for (auto &param : params) {
         std::cout << ",\n" << indent << "                      ";
         if (first) { std::cout << "{" << param.pval_str; first = false; }
         else       { std::cout << " " << param.pval_str; }
      }
      if (params.size() > 0) { std::cout << "}"; }
      std::cout << ");" << std::endl;
      if (benchmark.mode == SAMPLE_TIME) {
         std::cout << indent << "   for (auto &quant : hist_quant.getQuant()) {" << std::endl;
         std::cout << indent << "      std::string name_str = (MakeStr() << benchmark_name << \"|p\" << std::setw(4) << std::left << quant.q);" << std::endl;
         std::cout << indent << "      master_summary.add(name_str, \"" << benchmark.mode_str
                   << "\", -1, quant.val, -1, \"" << benchmark.units_str << "\"";
         bool first = true;
         for (auto &param : params) {
            std::cout << ",\n" << indent << "                         ";
            if (first) { std::cout << "{" << param.pval_str; first = false; }
            else       { std::cout << " " << param.pval_str; }
         }
         if (params.size() > 0) { std::cout << "}"; }
         std::cout << ");" << std::endl;
         std::cout << indent << "   }" << std::endl;
      }

      std::cout << indent << std::endl;
      std::cout << indent << "   // JSON stuff" << std::endl;
      std::cout << indent << "   res_out_info.saveResults(benchmark_name, \"" << benchmark.mode_str;
      switch(benchmark.mode) {
      case AVERAGE_TIME:
      case THROUGHPUT:
      case SAMPLE_TIME:
         std::cout << "\", num_threads," << std::endl;
         std::cout << indent << "                            warmup_iters, warmup_time_per_it, warmup_time_units," << std::endl;
         std::cout << indent << "                            bm_iters, bm_time_per_it, bm_time_units," << std::endl;
         std::cout << indent << "                            avg, std_dev, stats_data, \"";
         break;
      case SINGLE_SHOT_TIME:
         std::cout << "\", num_threads, warmup_iters, 0, \"\", " << std::endl;
         std::cout << indent << "                            bm_iters, 0, \"\""
                   << ", avg, std_dev, stats_data, \"";
         break;
      default:
         // We should never get here
         abort();
      };
      std::cout << benchmark.units_str << "\");" << std::endl;
      std::cout << indent << "}" << std::endl;
      std::cout << indent << std::endl;
   }
}

void gen_instantiate_state(const std::string &indent) {
   std::cout << indent << "// Instantiate state objects:" << std::endl;
   std::cout << indent << "//" << std::endl;
   std::cout << indent << "// XXX For now, just instantiate on the stack (we'll implement the memory layout control later)" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "// benchmark scope:" << std::endl;

   // std::cout << indent << "Benchmarks state_obj1__Benchmarks_;" << std::endl;
   for (auto &state : state_targets) {
      std::cout << indent << state.full_name << " " << state.instance_name << ";" << std::endl;
   }

   std::cout << indent << std::endl;
   std::cout << indent << "// XXX group/thread scope:" << std::endl;
   std::cout << indent << "// [Note: with memory layout control, these will be placeholders and will be re-constructed later]" << std::endl;
   // std::cout << indent << "Benchmarks::InputValue state_obj2__InputValue_;" << std::endl;
}

// Recursively generate the enclosing parameter loops
void gen_param_loops(const std::string &indent, int param_idx) {
   if (params.size() > param_idx) {
      if (param_idx == 0) {
         // Before the first loop, generate the parameter value vectors
         std::cout << indent << "// Default parameter value vectors:" << std::endl;
         std::cout << indent << "harness_utils_private::ParamHandler param_handler;" << std::endl;
         int pidx = 0;
         for (auto &param : params) {
            std::stringstream ss;
            ss << "pvec" << (pidx+1) << "__" << param.name << "_";
            param.pvec_name = ss.str();

            std::cout << indent << "param_handler.addParam(\"" << param.name << "\", \""
                      << param.full_name << "\", " << param.pval_list_str << ");" << std::endl;
            
            //std::cout << indent << "std::vector<std::string> " << param.pvec_name << " = "
            //          << param.pval_list_str << ";" << std::endl;
            ++pidx;
         }
         std::cout << indent << std::endl;
         std::cout << indent << "// Check for parameter overrides:" << std::endl;
         std::cout << indent << "param_handler.setOverrides(cl_options.param_overrides);" << std::endl;
         std::cout << indent << std::endl;
         std::cout << indent << "// Master summary object:" << std::endl;
         std::cout << indent << "harness_utils_private::MasterSummary master_summary(param_handler);" << std::endl;
         std::cout << indent << std::endl;
         std::cout << indent << "// Print out the parameter sets:" << std::endl;
         std::cout << indent << "param_handler.printParams();" << std::endl;
         std::cout << indent << std::endl;
      }
      // Generate the next parameter loop
      auto &param = params[param_idx];
      std::stringstream ss;
      ss << (param_idx+1);
      std::string num_str = ss.str();
      std::string val_str = "param" + num_str + "__" + param.name + "_valstr";
      param.pval_str = val_str;
      std::cout << indent << "const auto &" << param.pvec_name << " = param_handler.getParamVals(\"" << param.full_name << "\");" << std::endl;
      std::cout << indent << "for (auto &" << val_str << " : " << param.pvec_name << ") {" << std::endl;
      std::cout << indent << "   if (harness_utils_private::setParam(" << param.full_name << ", " << val_str << ") == false) {" << std::endl;
      std::cout << indent << "      std::cerr << \"Error: invalid value specified for parameter " << param.full_name
                << ": \" << " << val_str << " << std::endl;" << std::endl;
      std::cout << indent << "      abort();" << std::endl;
      std::cout << indent << "   }" << std::endl;
      std::cout << indent << std::endl;
      gen_param_loops(indent + "   ", param_idx + 1);
      std::cout << indent << "}" << std::endl;
   } else {
      // We've found the last loop...
      if (params.size() == 0) {
         std::cout << indent << "// No parameter(s) specified" << std::endl;
         std::cout << indent << std::endl;
         std::cout << indent << "// Master summary object:" << std::endl;
         std::cout << indent << "harness_utils_private::MasterSummary master_summary;" << std::endl;
         std::cout << indent << std::endl;
      } else {
         // Dump the current parameter values
         std::cout << indent << "std::cout << std::endl;" << std::endl;
         std::cout << indent << "std::cout << \"-----\\nUsing parameter values:\" << std::endl;" << std::endl;
         for (auto &param : params) {
            std::cout << indent << "std::cout << \"    " << param.full_name
                      << " = \" << " << param.full_name << " << std::endl;" << std::endl;
         }
      }
      // XXX Benchmarks:
      gen_benchmark_calls(indent);
   }
}

void gen_main_body(const std::string &indent) {
   // Include files:
   std::cout << indent << "#include <vector>" << std::endl;
   std::cout << indent << "#include <string>" << std::endl;
   std::cout << indent << "#include <inttypes.h>" << std::endl;
   std::cout << indent << "#include <iostream>" << std::endl;
   std::cout << indent << "#include <cassert>" << std::endl;
   std::cout << indent << "#include <cfloat>" << std::endl;
   //std::cout << indent << "#include <sstream>" << std::endl;
   std::cout << indent << "#include \"harness_utilities_private.hpp\"" << std::endl;
   std::cout << indent << "#include \"MakeStr.hpp\"" << std::endl;
   std::cout << indent << std::endl;
   // Start namespace:
   std::cout << indent << "namespace harness_gen_code {" << std::endl;
   std::cout << indent << std::endl;
   // runWithClock function:
   std::cout << indent << "// Run the benchmark with the selected clock" << std::endl;
   std::cout << indent << "template<class Clock>" << std::endl;
   std::cout << indent << "void runWithClock(const harness_utils_private::ClockCalibrationInfo &clock_info," << std::endl;
   std::cout << indent << "                  harness_utils_private::CLOptions &cl_options)" << std::endl;
   std::cout << indent << "{" << std::endl;
   std::cout << indent << "   uint64_t cutoff_time_nsec = clock_info.cutoff_time_nsec;" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "   // Evaluate baseline cpu speed (and save)" << std::endl;
   std::cout << indent << "   double baseline_cpu_speed_metric = clock_info.getRelativeCPUSpeed<Clock>();" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "   // Instantiate Control object:" << std::endl;
   std::cout << indent << "   // XXX harness_utils::Control control_;" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "   // Instantiate Blackhole object(s):" << std::endl;
   std::cout << indent << "   harness_utils::Blackhole bh_return_;" << std::endl;
   std::cout << indent << "   harness_utils::Blackhole bh_arg1_;" << std::endl;
   std::cout << indent << std::endl;
   // Trial-level state:
   gen_instantiate_state(indent + "   ");
   std::cout << indent << std::endl;
   std::cout << indent << std::endl;

   std::cout << indent << "   // Create JSON containers" << std::endl;
   std::cout << indent << "   harness_utils_private::ResultOutputInfo res_out_info(cl_options);" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << std::endl;

   // Trial-level setup:
   std::cout << indent << "   // Trial-level setup:" << std::endl;
   gen_setup_teardown(indent + "   ", setups, TRIAL, "trial-level setup");

   std::cout << indent << std::endl;
   std::cout << indent << std::endl;
   // XXX Outer loops:
   std::cout << indent << "   // Outer loops:" << std::endl;
   std::cout << indent << std::endl;
   // Params:
   gen_param_loops(indent + "   ", 0);

   std::cout << indent << "   // Output JSON file:" << std::endl;
   std::cout << indent << "   res_out_info.writeOutput();" << std::endl;
   std::cout << indent << std::endl;

   std::cout << indent << "   // Print master summary:" << std::endl;
   std::cout << indent << "   master_summary.print();" << std::endl;
   std::cout << indent << std::endl;

   // Trial-level teardown:
   std::cout << indent << "   // Trial-level teardown:" << std::endl;
   gen_setup_teardown(indent + "   ", teardowns, TRIAL, "trial-level teardown");

   std::cout << indent << "}" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << std::endl;

   // Generic start method and main:
   std::cout << indent << "// This is the starting point for running the benchmark." << std::endl;
   std::cout << indent << "// (it tests the precision of the available clocks and then calls \"runWithClock\", above)" << std::endl;
   std::cout << indent << "void runEverything(harness_utils_private::CLOptions &cl_options) {" << std::endl;
   // Calibrate clocks:
   std::cout << indent << "   // Calibrate the clocks and pick the best" << std::endl;
   std::cout << indent << "   harness_utils_private::ClockCalibrationInfo hr_info;" << std::endl;
   std::cout << indent << "   harness_utils_private::findCutoff<std::chrono::high_resolution_clock>(\"high-resolution clock\", 1, hr_info);" << std::endl;
   std::cout << indent << "   if (hr_info.found) {" << std::endl;
   std::cout << indent << "      std::cout << hr_info.clock_name << \": estimated precision: \" << hr_info.inferred_precision << std::endl;" << std::endl;
   std::cout << indent << "   } else {" << std::endl;
   std::cout << indent << "      std::cout << hr_info.clock_name << \" exceeds precision limit\" << std::endl;" << std::endl;
   std::cout << indent << "   }" << std::endl;
   std::cout << indent << "   harness_utils_private::ClockCalibrationInfo sys_info;" << std::endl;
   std::cout << indent << "   harness_utils_private::findCutoff<std::chrono::system_clock>(\"system clock\", 2, sys_info);" << std::endl;
   std::cout << indent << "   if (sys_info.found) {" << std::endl;
   std::cout << indent << "      std::cout << sys_info.clock_name << \": estimated precision: \" << sys_info.inferred_precision << std::endl;" << std::endl;
   std::cout << indent << "   } else {" << std::endl;
   std::cout << indent << "      std::cout << sys_info.clock_name << \" exceeds precision limit\" << std::endl;" << std::endl;
   std::cout << indent << "   }" << std::endl;
   std::cout << indent << "   harness_utils_private::ClockCalibrationInfo st_info;" << std::endl;
   std::cout << indent << "   harness_utils_private::findCutoff<std::chrono::steady_clock>(\"steady clock\", 3, st_info);" << std::endl;
   std::cout << indent << "   if (st_info.found) {" << std::endl;
   std::cout << indent << "      std::cout << st_info.clock_name << \": estimated precision: \" << st_info.inferred_precision << std::endl;" << std::endl;
   std::cout << indent << "   } else {" << std::endl;
   std::cout << indent << "      std::cout << st_info.clock_name << \" exceeds precision limit\" << std::endl;" << std::endl;
   std::cout << indent << "   }" << std::endl;
   std::cout << indent << "   " << std::endl;
   std::cout << indent << "   harness_utils_private::ClockCalibrationInfo best_clock;" << std::endl;
   std::cout << indent << "   best_clock.cutoff_time_nsec = std::numeric_limits<int>::max();" << std::endl;
   std::cout << indent << "   if (hr_info.found) { best_clock = hr_info; }" << std::endl;
   std::cout << indent << "   if (sys_info.found && (sys_info.cutoff_time_nsec < best_clock.cutoff_time_nsec)) { best_clock = sys_info; }" << std::endl;
   std::cout << indent << "   if (st_info.found && (st_info.cutoff_time_nsec < best_clock.cutoff_time_nsec)) { best_clock = st_info; }" << std::endl;
   std::cout << indent << "   " << std::endl;
   std::cout << indent << "   if (best_clock.found) {" << std::endl;
   std::cout << indent << "      std::cout << \"Using the \" << best_clock.clock_name << std::endl;" << std::endl;
   std::cout << indent << "      std::cout << \"Minimum trusted timing interval for this clock is \"" << std::endl;
   std::cout << indent << "                << best_clock.cutoff_time_nsec << \" ns\" << std::endl;" << std::endl;
   std::cout << indent << "      switch (best_clock.clock_id) {" << std::endl;
   std::cout << indent << "      case 1:" << std::endl;
   std::cout << indent << "         runWithClock<std::chrono::high_resolution_clock>(best_clock, cl_options);" << std::endl;
   std::cout << indent << "         break;" << std::endl;
   std::cout << indent << "      case 2:" << std::endl;
   std::cout << indent << "         runWithClock<std::chrono::system_clock>(best_clock, cl_options);" << std::endl;
   std::cout << indent << "         break;" << std::endl;
   std::cout << indent << "      case 3:" << std::endl;
   std::cout << indent << "         runWithClock<std::chrono::steady_clock>(best_clock, cl_options);" << std::endl;
   std::cout << indent << "         break;" << std::endl;
   std::cout << indent << "      default:" << std::endl;
   std::cout << indent << "         std::cout << \"Error: Invalid clock ID (this shouldn't happen)\" << std::endl;" << std::endl;
   std::cout << indent << "         break;" << std::endl;
   std::cout << indent << "      }" << std::endl;
   std::cout << indent << "   } else {" << std::endl;
   std::cout << indent << "      std::cout << \"All clocks were too unstable. Try to eliminate excess timing 'noise'.\" << std::endl;" << std::endl;
   std::cout << indent << "   }" << std::endl;
   std::cout << indent << "}" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "} // namespace harness_gen_code" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << std::endl;
   // main:
   std::cout << indent << "int main(int argc, char **argv) {" << std::endl;
   std::cout << indent << "   harness_utils_private::CLOptions cl_options;" << std::endl;
   std::cout << indent << "   harness_utils_private::parseCommandLine(cl_options, argc, argv);" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "   if (cl_options.no_run == false) {" << std::endl;
   std::cout << indent << "      harness_utils_private::printVersion();" << std::endl;
   std::cout << indent << "      harness_gen_code::runEverything(cl_options);" << std::endl;
   std::cout << indent << "   }" << std::endl;
   std::cout << indent << std::endl;
   std::cout << indent << "   return 0;" << std::endl;
   std::cout << indent << "}" << std::endl;
}


void createTargArgString(TargetInfo &func_targ) {
   std::string arg_string;
   // Go through the arguments
   bool needs_comma = false;
   for (auto &arg : func_targ.targ_args) {
      if (needs_comma) { arg_string += ", "; }
      else             { needs_comma = true; }
      
      // Find the object corresponding to this type
      // XXX add Control
      if ((arg.base_type_name == "harness_utils::Blackhole") || (arg.base_type_name == "Blackhole")) {
         arg_string += "bh_arg1_";
      }
      else {
         // Search the State objects
         bool found = false;
         for (auto &state : state_targets) {
            if ((arg.base_type_name == state.name) || (arg.base_type_name == state.full_name) ||
                (arg.alt_type_name == state.name) || (arg.alt_type_name == state.full_name))
            {
               arg_string += state.instance_name;
               found = true;
               break;
            }
         }
         if (found == false) {
            std::cout << "Error: unable to find a matching state object for method "
                      << func_targ.full_name << ", argument of type "
                      << arg.base_type_name << std::endl;
            abort();
         }
      }
   }
   func_targ.arg_str = arg_string;

   // If this is a non-static method, then it will also need the object string
   if (func_targ.may_be_object_method) {
      // Search the State objects
      bool found = false;
      for (auto &state : state_targets) {
         if ((func_targ.parent_name == state.name) || (func_targ.parent_name == state.full_name)) {
            func_targ.ob_str = state.instance_name + ".";
            found = true;
            break;
         }
      }
      if (found == false) {
         std::cout << "Error: unable to find a matching state object for method "
                   << func_targ.full_name << " parent class of type "
                   << func_targ.parent_name << std::endl;
         abort();
      }
   }
}

// Set a value from a value string (will work even if the variable is volatile)
template <typename T>
inline void valFromStr(T &var, const std::string &val_str) {
   std::istringstream iss(val_str);

   typedef typename std::remove_volatile<T>::type nv_T;
   nv_T nv_var;

   iss >> nv_var;
   var = nv_var;
}

// Annotation classes used during post-processing

class AnnBenchmark {
public:
   static const std::string &get_name() {
      static std::string name("Benchmark");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if ((target.is_class == false) && (target.cannot_be_data == false)) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }

         // This annotation takes no arguments
         if (ann.args.size() > 0) {
            std::cout << "Error: annotation " << get_name() << " should not have arguments" << std::endl;
            abort(); // XXX
         }
      }
      
      return match;
   }
};

class AnnSetup {
public:
   static const std::string &get_name() {
      static std::string name("Setup");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if (target.cannot_be_data == false) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.is_class) {
            std::cout << "Error: classes cannot be annotated as " << ann.name << ": "
                      << target.full_name << std::endl;
            abort(); // XXX
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }

         // This annotation takes one optional argument
         if (ann.args.size() > 1) {
            std::cout << "Error: annotation " << get_name() << " has at most one (optional) argument" << std::endl;
            abort(); // XXX
         }
         else if (ann.args.size() == 1) {
            const std::string &val = ann.args[0].val;
            if (val == "Level.Trial") { target.level = TRIAL; }
            else if (val == "Level.Iteration") { target.level = ITERATION; }
            else if (val == "Level.Invocation") { target.level = INVOCATION; }
            else {
               std::cout << "Error: annotation " << get_name() << ", unknown argument value: " << val << std::endl;
            }
         }
         else {
            // No args (set the default)
            target.level = TRIAL;
         }
      }
      
      return match;
   }
};

class AnnTeardown {
public:
   static const std::string &get_name() {
      static std::string name("Teardown");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if (target.cannot_be_data == false) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.is_class) {
            std::cout << "Error: classes cannot be annotated as " << ann.name << ": "
                      << target.full_name << std::endl;
            abort(); // XXX
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }

         // This annotation takes one optional argument
         if (ann.args.size() > 1) {
            std::cout << "Error: annotation " << get_name() << " has at most one (optional) argument" << std::endl;
            abort(); // XXX
         }
         else if (ann.args.size() == 1) {
            const std::string &val = ann.args[0].val;
            if (val == "Level.Trial") { target.level = TRIAL; }
            else if (val == "Level.Iteration") { target.level = ITERATION; }
            else if (val == "Level.Invocation") { target.level = INVOCATION; }
            else {
               std::cout << "Error: annotation " << get_name() << ", unknown argument value: " << val << std::endl;
            }
         }
         else {
            // No args (set the default)
            target.level = TRIAL;
         }
      }
      
      return match;
   }
};

class AnnState {
public:
   static const std::string &get_name() {
      static std::string name("State");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if (target.is_class == false) {
            std::cout << "Error: only classes/structs can be annotated as State: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }
         
         // XXX The annotation arguments only matter with threading
         if (ann.args.size() == 0) {
            std::cout << "Error: annotation " << get_name() << " requires one argument" << std::endl;
            abort(); // XXX
         }
      }
      
      return match;
   }
};

class AnnParam {
public:
   static const std::string &get_name() {
      static std::string name("Param");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if (target.must_be_data == false) {
            target.must_be_data = true;
            target.must_be_data_trigger = ann.name;
         }
         if (target.is_class) {
            std::cout << "Error: classes cannot be annotated as " << ann.name << ": "
                      << target.full_name << std::endl;
            abort(); // XXX
         }
         else if (target.cannot_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.cannot_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }
         
         // One argument is required
         if (ann.args.size() != 1) {
            std::cout << "Error: annotation " << get_name() << " requires exactly one argument"
                      << " (which should be a list of parameter values, e.g.: {\"0\", \"3\", \"12\"})" << std::endl;
            abort(); // XXX
         } else {
            // Trim off the leading and trailing "{}" and split into the separate values
            target.pval_list_str = ann.args[0].val;
            std::string plist = target.pval_list_str;
            string_utils::ltrim(string_utils::rtrim(plist, "}"),"{");
            string_utils::splitString(plist, ',', target.pvals);
            // Now trim off the quotemark (and any surrounding whitespace)
            for (auto &val : target.pvals) {
               string_utils::ltrim(string_utils::rtrim(string_utils::trim(val), "\""), "\"");
            }
            if (target.pvals.size() == 0) {
               std::cout << "Error: annotation " << get_name() << ", the parameter value list must be non-empty" << std::endl;
               abort(); // XXX
            }
         }
      }
      
      return match;
   }
};

class AnnMeasurement {
public:
   static const std::string &get_name() {
      static std::string name("Measurement");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if ((target.is_class == false) && (target.cannot_be_data == false)) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }

         // This annotation can take several optional arguments
         for (auto &arg : ann.args) {
            if (arg.key == "iterations") { valFromStr(target.bm_iters, arg.val); }
            else if (arg.key == "time") { valFromStr(target.bm_time, arg.val); }
            else if (arg.key == "batchSize") { valFromStr(target.bm_batchsize, arg.val); }
            else if (arg.key == "timeUnit") {
               if (arg.val == "TimeUnit.NANOSECONDS")       {
                  target.bm_timeunit_mult = 1ull;
                  target.bm_timeunit_str = "nsec";
                  target.bm_timeunit_short_str = "ns";
               }
               else if (arg.val == "TimeUnit.MICROSECONDS") {
                  target.bm_timeunit_mult = 1000ull;
                  target.bm_timeunit_str = "usec";
                  target.bm_timeunit_short_str = "us";
               }
               else if (arg.val == "TimeUnit.MILLISECONDS") {
                  target.bm_timeunit_mult = 1000ull*1000ull;
                  target.bm_timeunit_str = "msec";
                  target.bm_timeunit_short_str = "ms";
               }
               else if (arg.val == "TimeUnit.SECONDS")      {
                  target.bm_timeunit_mult = 1000ull*1000ull*1000ull;
                  target.bm_timeunit_str = "sec";
                  target.bm_timeunit_short_str = "s";
               }
               else if (arg.val == "TimeUnit.MINUTES")      {
                  target.bm_timeunit_mult = 60ull*1000ull*1000ull*1000ull;
                  target.bm_timeunit_str = "min";
                  target.bm_timeunit_short_str = "m";
               }
               else if (arg.val == "TimeUnit.HOURS")        {
                  target.bm_timeunit_mult = 60ull*60ull*1000ull*1000ull*1000ull;
                  target.bm_timeunit_str = "hr";
                  target.bm_timeunit_short_str = "h";
               }
               else if (arg.val == "TimeUnit.DAYS")         {
                  target.bm_timeunit_mult = 24ull*60ull*60ull*1000ull*1000ull*1000ull;
                  target.bm_timeunit_str = "day";
                  target.bm_timeunit_short_str = "d";
               }
               else {
                  std::cout << "Error: annotation " << get_name() << ", arg " << arg.key
                            << ", unknown argument value: " << arg.val << std::endl;
                  abort(); // XXX
               }
            }
            else if (arg.key == "") {
               std::cout << "Error: for annotation " << get_name()
                         << ", arguments must be specified in \"key = value\" format" << std::endl;
               abort(); // XXX
            }
            else {
               std::cout << "Error: annotation " << get_name()
                         << ", unknown argument \"" << arg.key << "\"" << std::endl;
               abort(); // XXX
            }
         }
      }
      
      return match;
   }
};

class AnnWarmup {
public:
   static const std::string &get_name() {
      static std::string name("Warmup");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if ((target.is_class == false) && (target.cannot_be_data == false)) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }

         // This annotation can take several optional arguments
         for (auto &arg : ann.args) {
            if (arg.key == "iterations") { valFromStr(target.warmup_iters, arg.val); }
            else if (arg.key == "time") { valFromStr(target.warmup_time, arg.val); }
            else if (arg.key == "batchSize") { valFromStr(target.warmup_batchsize, arg.val); }
            else if (arg.key == "timeUnit") {
               if (arg.val == "TimeUnit.NANOSECONDS")       {
                  target.warmup_timeunit_mult = 1ull;
                  target.warmup_timeunit_str = "nsec";
                  target.warmup_timeunit_short_str = "ns";
               }
               else if (arg.val == "TimeUnit.MICROSECONDS") {
                  target.warmup_timeunit_mult = 1000ull;
                  target.warmup_timeunit_str = "usec";
                  target.warmup_timeunit_short_str = "us";
               }
               else if (arg.val == "TimeUnit.MILLISECONDS") {
                  target.warmup_timeunit_mult = 1000ull*1000ull;
                  target.warmup_timeunit_str = "msec";
                  target.warmup_timeunit_short_str = "ms";
               }
               else if (arg.val == "TimeUnit.SECONDS")      {
                  target.warmup_timeunit_mult = 1000ull*1000ull*1000ull;
                  target.warmup_timeunit_str = "sec";
                  target.warmup_timeunit_short_str = "s";
               }
               else if (arg.val == "TimeUnit.MINUTES")      {
                  target.warmup_timeunit_mult = 60ull*1000ull*1000ull*1000ull;
                  target.warmup_timeunit_str = "min";
                  target.warmup_timeunit_short_str = "m";
               }
               else if (arg.val == "TimeUnit.HOURS")        {
                  target.warmup_timeunit_mult = 60ull*60ull*1000ull*1000ull*1000ull;
                  target.warmup_timeunit_str = "hr";
                  target.warmup_timeunit_short_str = "h";
               }
               else if (arg.val == "TimeUnit.DAYS")         {
                  target.warmup_timeunit_mult = 24ull*60ull*60ull*1000ull*1000ull*1000ull;
                  target.warmup_timeunit_str = "day";
                  target.warmup_timeunit_short_str = "d";
               }
               else {
                  std::cout << "Error: annotation " << get_name() << ", arg " << arg.key
                            << ", unknown argument value: " << arg.val << std::endl;
                  abort(); // XXX
               }
            }
            else if (arg.key == "") {
               std::cout << "Error: for annotation " << get_name()
                         << ", arguments must be specified in \"key = value\" format" << std::endl;
               abort(); // XXX
            }
            else {
               std::cout << "Error: annotation " << get_name()
                         << ", unknown argument \"" << arg.key << "\"" << std::endl;
               abort(); // XXX
            }
         }
      }
      
      return match;
   }
};

class AnnBenchmarkMode {
public:
   static const std::string &get_name() {
      static std::string name("BenchmarkMode");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         if ((target.is_class == false) && (target.cannot_be_data == false)) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }

         // One argument is required
         if (ann.args.size() != 1) {
            std::cout << "Error: annotation " << get_name() << " requires exactly one argument" << std::endl;
            abort(); // XXX
         } else {
            auto &arg = ann.args[0];
#ifdef DEBUG
            //std::cout << "//        mode = " << arg.val << std::endl;
            //std::cout << "//        tgt.mode(before) = " << target.mode << std::endl;
#endif
            if (arg.val == "Mode.AverageTime") { target.setMode(AVERAGE_TIME); }
            else if (arg.val == "Mode.Throughput") { target.setMode(THROUGHPUT); }
            else if (arg.val == "Mode.SingleShotTime") { target.setMode(SINGLE_SHOT_TIME); }
            else if (arg.val == "Mode.SampleTime") { target.setMode(SAMPLE_TIME); }
            else {
               std::cout << "Error: annotation " << get_name()
                         << ", unknown argument value: " << arg.val << std::endl;
               abort(); // XXX
            }
#ifdef DEBUG
            //std::cout << "//        mode = " << arg.val << std::endl;
            //std::cout << "//        tgt.mode(after) = " << target.mode << std::endl;
#endif
         }
      }
      
      return match;
   }
};

class AnnOutputTimeUnit {
public:
   static const std::string &get_name() {
      static std::string name("OutputTimeUnit");
      return name;
   }

   static bool check(TargetInfo &target, const AnnotationInfo &ann)
   {
#ifdef DEBUG
   //std::cout << "//      checking " << get_name() << ":  " << std::endl;
#endif
      bool match = false;
      if (ann.name == get_name()) {
         match = true;
         
         // OutputTimeUnit
         if ((target.is_class == false) && (target.cannot_be_data == false)) {
            target.cannot_be_data = true;
            target.cannot_be_data_trigger = ann.name;
         }
         if (target.must_be_data) {
            std::cout << "Error: the same target cannot have both " << ann.name << " and "
                      << target.must_be_data_trigger << " annotations: "
                      << target.full_name << std::endl;
            abort(); // XXX
         }
         
         if (ann.args.size() != 1) {
            std::cout << "Error: annotation " << get_name() << " requires one argument" << std::endl;
            abort(); // XXX
         } else {
            const std::string &val = ann.args[0].val;
            if (val == "TimeUnit.NANOSECONDS")       {
               target.output_timeunit_mult = 1ull;
               target.output_timeunit_str = "nsec";
               target.output_timeunit_short_str = "ns";
            }
            else if (val == "TimeUnit.MICROSECONDS") {
               target.output_timeunit_mult = 1000ull;
               target.output_timeunit_str = "usec";
               target.output_timeunit_short_str = "us";
            }
            else if (val == "TimeUnit.MILLISECONDS") {
               target.output_timeunit_mult = 1000ull*1000ull;
               target.output_timeunit_str = "msec";
               target.output_timeunit_short_str = "ms";
            }
            else if (val == "TimeUnit.SECONDS")      {
               target.output_timeunit_mult = 1000ull*1000ull*1000ull;
               target.output_timeunit_str = "sec";
               target.output_timeunit_short_str = "s";
            }
            else if (val == "TimeUnit.MINUTES")      {
               target.output_timeunit_mult = 60ull*1000ull*1000ull*1000ull;
               target.output_timeunit_str = "min";
               target.output_timeunit_short_str = "m";
            }
            else if (val == "TimeUnit.HOURS")        {
               target.output_timeunit_mult = 60ull*60ull*1000ull*1000ull*1000ull;
               target.output_timeunit_str = "hr";
               target.output_timeunit_short_str = "h";
            }
            else if (val == "TimeUnit.DAYS")         {
               target.output_timeunit_mult = 24ull*60ull*60ull*1000ull*1000ull*1000ull;
               target.output_timeunit_str = "day";
               target.output_timeunit_short_str = "d";
            }
            else {
               std::cout << "Error: annotation " << get_name()
                         << ", unknown argument value: " << val << std::endl;
               abort(); // XXX
            }
            target.updateStrings();
         }
      }
      
      return match;
   }
};


void postProcess() {
   // XXX We need to make sure that any class containing a benchmark method is implicitly
   //     a state class.
#ifdef DEBUG
   //std::cout << "//Postprocessing:  " << std::endl;
#endif

   // Go through the targets, build the lists of state classes, benchmark methods, etc.
   for (auto &target : targets) {
#ifdef DEBUG
      //std::cout << "//  Target:  " << target.name << std::endl;
#endif
      //bool must_be_data = false;   // Set to true for Params
      //std::string must_be_data_trigger;
      //bool cannot_be_data = false; // Set to true for all other annotations
      //std::string cannot_be_data_trigger;

      bool push_benchmark = false;
      bool push_state = false;
      bool push_param = false;
      bool push_setup = false;
      bool push_teardown = false;

      // Go through the annotations for this target:
      for (auto &ann : target.annotations) {
#ifdef DEBUG
         //std::cout << "//    Annotation:  " << ann.name << std::endl;
#endif

         if (AnnBenchmark::check(target, ann)) {
            // Add to benchmarks list
            push_benchmark = true;
         }
         else if (AnnState::check(target, ann)) {
            // Add to State list
            push_state = true;
         }
         else if (AnnParam::check(target, ann)) {
            // Add to params list
            push_param = true;
         }
         else if (AnnSetup::check(target, ann)) {
            // Add to setups list
            push_setup = true;
         }
         else if (AnnTeardown::check(target, ann)) {
            // Add to teardowns list
            push_teardown = true;
         }
         else if (AnnMeasurement::check(target, ann)) {
            // Nothing else to do
         }
         else if (AnnWarmup::check(target, ann)) {
            // Nothing else to do
         }
         else if (AnnBenchmarkMode::check(target, ann)) {
            // Nothing else to do
         }
         else if (AnnOutputTimeUnit::check(target, ann)) {
            // Nothing else to do
         }

         // XXX add the others later...
         // BenchmarkMode
         // OperationsPerInvocation
         //
         // Fork (needed?)
         // 
         // For multithreading:
         // Group
         // GroupThreads
         // Threads

         else {
            std::cout << "//Warning: unknown annotation " << ann.name << std::endl;
         }
      }
      if (push_benchmark) { benchmarks.push_back(target); }
      if (push_state)     { state_targets.push_back(target); }
      if (push_param)     { params.push_back(target); }
      if (push_setup)     { setups.push_back(target); }
      if (push_teardown)  { teardowns.push_back(target); }
   }

   // Create the instance names for the state objects
   for (int i = 0; i < state_targets.size(); ++i) {
      std::stringstream ss;
      ss << "state_obj" << (i+1) << "__" << state_targets[i].name << "_";
      state_targets[i].instance_name = ss.str();
   }

   // Create the argument strings for the Benchmark, Setup, and Teardown methods/functions
   for (auto &benchmark : benchmarks) {
      createTargArgString(benchmark);
   }
   for (auto &setup : setups) {
      createTargArgString(setup);
   }
   for (auto &teardown : teardowns) {
      createTargArgString(teardown);
   }
}


int main(int argc, char **argv)
{
   vector<FileLine>  file_lines;

   // Create a command option handler
   const char *validOptions = "";
   // const char *validOptions = "v, h, help";
   //  v = version     h, help = usage information    
   OptionAndFilenameHandler COH(validOptions, 1);
   
   try
   {
      // Parse the command-line options
      COH.parseOptions(argc, argv);
   }
   catch (CommandOptionHandler::UnknownOption uO)
   {
      cerr << "Don't understand option \"-" << uO.option << "\"" << endl;
      /* usage(); */
      return 1;
   }
   catch (CommandOptionHandler::UnknownArg uA)
   {
      cerr << "Too many filename arguments" << endl;
      /* usage(); */
      return 1;
   }

   //if ((COH.fileCount < 1) &&
   //    (!COH.opCheck("v")) &&
   //    (!COH.opCheck("h")) && (!COH.opCheck("help")))
   if (COH.fileCount < 1)
   {
      cerr << "One filename argument required" << endl;
      //usage();
      return 1;
   }

   //if (COH.opCheck("v"))
   //{
   //   version();
   //}
   //
   //if ((COH.opCheck("h")) || (COH.opCheck("help")))
   //{
   //   usage();
   //   return 0;
   //}

   // Parse the file
   parseFile(COH.files[0].c_str(), file_lines);


   // Do some post-processing:
   postProcess();


   // Output the stripped benchmark file:
   std::cout << "\n#define CLAMH" << std::endl;
   std::cout << "\n// ========== Stripped file ===========\n" << std::endl;

   for (auto &file_line : file_lines) {
      std::cout << file_line.line << std::endl;
   }


   // Output the generated code:
   std::cout << "\n// ========== Generated code ===========\n" << std::endl;
   
   gen_main_body("");


   return 0;
}


