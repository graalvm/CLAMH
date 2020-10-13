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

#include <xalanc/Include/PlatformDefinitions.hpp>
#include <cassert>

#include <fstream>
#include <iostream>
//#include <strstream>
#include <random>

#include <xercesc/util/PlatformUtils.hpp>
#include <xalanc/XalanTransformer/XalanTransformer.hpp>

//#include <iostream>
#include <queue>
#include <string>
#include "Blackhole.hpp"
#include "MakeStr.hpp"

XALAN_USING_XERCES(XMLPlatformUtils)
XALAN_USING_XERCES(XMLException)

XALAN_USING_XALAN(XalanTransformer)
XALAN_USING_XALAN(XalanCompiledStylesheet)

//@BenchmarkMode(Mode.AverageTime)
//@OutputTimeUnit(TimeUnit.NANOSECONDS)
//@Warmup(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
//@Measurement(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
//@Fork(1)
@State(Scope.Benchmark)
class XalanTest {
public:

    /*
     * A simple queue of filenames that the worker threads pull jobs from.
     */
    class WorkQueue {
      std::queue<std::string> _queue;
  
    public:
      void push(const std::string &filename) {
        _queue.push(filename);
      }
  
      std::string pop() {
	std::string ret_str = _queue.front();
	_queue.pop();	
        return ret_str;
      }

      bool isEmpty() { return _queue.empty(); }
    };

  @State(Scope.Benchmark)
  struct InputValue {
    // What version of XALAN should we have
    const std::string XALAN_VERSION = "Xalan C 1.11";
    
    // Pointer to the transformer
    XalanTransformer *transformer {nullptr};

    // Pointer to the compiled stylesheet
    const XalanCompiledStylesheet *compiled_stylesheet {nullptr};

    // The queue used to hold jobs to be processed
    WorkQueue _workQueue;
	
    std::string outfilename;
    std::string blfilename;
  };

  @Setup(Level.Trial)
  void setup(InputValue &state) {
    //XALAN_USING_XERCES(XMLPlatformUtils)
    //XALAN_USING_XERCES(XMLException)
    //
    //XALAN_USING_XALAN(XalanTransformer)
    //XALAN_USING_XALAN(XalanCompiledStylesheet)

    // Call the static initializer for Xerces.
    try
    {
         XMLPlatformUtils::Initialize();
    }

    catch (const XMLException& toCatch)
    {
         std::cerr << "Error during Xerces initialization.  Error code was "
              << toCatch.getCode()
              << "."
              << std::endl;
            
         abort();
    }
    
    // Initialize Xalan.
    XalanTransformer::initialize();

    // Create the Xalan transformer
    state.transformer = new XalanTransformer;
    // Compile the stylesheet
    int result = state.transformer->compileStylesheet("xalan/xmlspec.xsl", state.compiled_stylesheet);

    if (result == 0) {
      assert(state.compiled_stylesheet != nullptr);
    } else {
      std::cerr << "Error compiling stylesheet." << std::endl;
      abort();
    }
    
    unsigned int seed = (std::random_device())();

    std::mt19937 ran_gen_;
    ran_gen_.seed(seed);
    int rint = std::uniform_int_distribution<int>(1, 1000)(ran_gen_);

    state.outfilename = MakeStr() << "xalan_out/xalan" << rint << ".out";
    std::cout << "Xalan output data will be written to " << state.outfilename << std::endl;
    state.blfilename = MakeStr() << "xalan_out/baseline" << rint << ".out";
    std::cout << "Baseline output data will be written to " << state.blfilename << std::endl;
  }

private:

public:
   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int xalan_all(InputValue &state) {
      state._workQueue.push("xalan/acks.xml");
      state._workQueue.push("xalan/binding.xml");
      state._workQueue.push("xalan/changes.xml");
      state._workQueue.push("xalan/concepts.xml");
      state._workQueue.push("xalan/controls.xml");
      state._workQueue.push("xalan/datatypes.xml");
      state._workQueue.push("xalan/expr.xml");
      state._workQueue.push("xalan/intro.xml");
      state._workQueue.push("xalan/model.xml");
      state._workQueue.push("xalan/prod-notes.xml");
      state._workQueue.push("xalan/references.xml");
      state._workQueue.push("xalan/rpm.xml");
      state._workQueue.push("xalan/schema.xml");
      state._workQueue.push("xalan/structure.xml");
      state._workQueue.push("xalan/template.xml");
      state._workQueue.push("xalan/terms.xml");
      state._workQueue.push("xalan/ui.xml");
      
      while (!state._workQueue.isEmpty()) {
	std::string fileName = state._workQueue.pop();
	// An empty string is the end of life signal	//if (fileName.equals(""))
	//  break;

	xalanc_1_11::XSLTInputSource xslt_in(fileName.c_str());
	xalanc_1_11::XSLTResultTarget xslt_targ(state.outfilename.c_str());
	int result = state.transformer->transform(xslt_in, state.compiled_stylesheet, xslt_targ);
	if (result != 0) {
	  std::cerr << "Transform error for file " << fileName << std::endl;
	}
      }
   }

   @BenchmarkMode(Mode.AverageTime)
   @OutputTimeUnit(TimeUnit.NANOSECONDS)
   @Warmup(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
   @Measurement(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
   @Fork(1)
   @Benchmark
   static int baseline_all(InputValue &state) {
      state._workQueue.push("xalan/acks.xml");
      state._workQueue.push("xalan/binding.xml");
      state._workQueue.push("xalan/changes.xml");
      state._workQueue.push("xalan/concepts.xml");
      state._workQueue.push("xalan/controls.xml");
      state._workQueue.push("xalan/datatypes.xml");
      state._workQueue.push("xalan/expr.xml");
      state._workQueue.push("xalan/intro.xml");
      state._workQueue.push("xalan/model.xml");
      state._workQueue.push("xalan/prod-notes.xml");
      state._workQueue.push("xalan/references.xml");
      state._workQueue.push("xalan/rpm.xml");
      state._workQueue.push("xalan/schema.xml");
      state._workQueue.push("xalan/structure.xml");
      state._workQueue.push("xalan/template.xml");
      state._workQueue.push("xalan/terms.xml");
      state._workQueue.push("xalan/ui.xml");
      
      std::ofstream file_out(state.outfilename.c_str());
      while (!state._workQueue.isEmpty()) {
	std::string fileName = state._workQueue.pop();
	// An empty string is the end of life signal
	//if (fileName.equals(""))
	//  break;

	// Just copy the file
	std::string line;
	std::ifstream file_in(fileName.c_str());
	while (std::getline(file_in, line)) {
	  file_out << line << '\n';
	}
	file_in.close();
      }
      file_out.close();
   }

};


//int Array2DTests::InputValue::rep;
//volatile long Array2DTests::InputValue::number = 25;
//long Array2DTests::InputValue::number = 25;

