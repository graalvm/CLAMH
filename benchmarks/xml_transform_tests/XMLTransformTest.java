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
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.annotations.OperationsPerInvocation;
import org.openjdk.jmh.infra.Blackhole;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.LinkedList;
import java.util.Properties;

import java.util.concurrent.TimeUnit;
import java.util.Random;
import java.nio.file.Files;
import java.nio.file.Paths;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;


@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@Warmup(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(1)
public class XMLTransformTest {

    /*
     * A simple queue of filenames that the worker threads pull jobs from.
     */
   public static class WorkQueue {
      LinkedList<String> _queue = new LinkedList<String>();
      
      public synchronized void push(String filename) {
         _queue.add(filename);
      }
      
      public synchronized String pop() {
         return _queue.removeFirst();
      }
      
      public boolean isEmpty() { return _queue.isEmpty(); }
   }
   
   @State(Scope.Benchmark)
   public static class InputValue {
      @Param({""})
      public String transformer_factory_path;
      
      // The directory to which the files should be written
      public File scratch;
      
      // The rather inappropriatly named 'Templates' object for storing
      // a handle to a 'compiled' transformation stylesheet
      public Templates _template = null;
      
      // The queue used to hold jobs to be processed
      public WorkQueue _workQueue = null;
      
      public String outfilename;
      public String blfilename;
      
      
      @Setup(Level.Iteration)
      public void setup_test() {
         scratch = new File(".");
         
         Properties props = System.getProperties();
         
         // Set the JAXP transformer
         String key = "javax.xml.transform.TransformerFactory";
         if (transformer_factory_path.equals("")) {
            System.out.println("Error:  XML transformer package not specified.");
            System.out.println("Use \"-p transformer_factory_path=<tf_path>\" to specify the XML transformer package location.");
            System.exit(1);
         }
         props.put(key, transformer_factory_path);
         System.setProperties(props);
         
         Random rgen = new Random();
         int rint = rgen.nextInt(1000);
         outfilename = "xmltransform_out/xmltransform" + rint + ".out";
         System.out.println("XML transform output data will be written to " + outfilename);
         blfilename = "xmltransform_out/baseline" + rint + ".out";
         System.out.println("XML transform output data will be written to " + blfilename);
         
         try {
            // Compile the test stylesheet for later use
            Source stylesheet = new StreamSource(new File(scratch, "xmltransform_input/xmlspec.xsl"));
            TransformerFactory factory = TransformerFactory.newInstance();
            _template = factory.newTemplates(stylesheet);
         } catch (TransformerConfigurationException e) {
            e.printStackTrace();
         } catch (TransformerException e) {
            e.printStackTrace();
         }
         
          // Create the work queue for jobs
         _workQueue = new WorkQueue();
      }
   }
   
   
   @Benchmark
   public int xmltransform_all(InputValue state) {
      state._workQueue.push("xmltransform_input/acks.xml");
      state._workQueue.push("xmltransform_input/binding.xml");
      state._workQueue.push("xmltransform_input/changes.xml");
      state._workQueue.push("xmltransform_input/concepts.xml");
      state._workQueue.push("xmltransform_input/controls.xml");
      state._workQueue.push("xmltransform_input/datatypes.xml");
      state._workQueue.push("xmltransform_input/expr.xml");
      state._workQueue.push("xmltransform_input/intro.xml");
      state._workQueue.push("xmltransform_input/model.xml");
      state._workQueue.push("xmltransform_input/prod-notes.xml");
      state._workQueue.push("xmltransform_input/references.xml");
      state._workQueue.push("xmltransform_input/rpm.xml");
      state._workQueue.push("xmltransform_input/schema.xml");
      state._workQueue.push("xmltransform_input/structure.xml");
      state._workQueue.push("xmltransform_input/template.xml");
      state._workQueue.push("xmltransform_input/terms.xml");
      state._workQueue.push("xmltransform_input/ui.xml");
      try {
         FileOutputStream outputStream = new FileOutputStream(new File(state.scratch, state.outfilename));
         Result outFile = new StreamResult(outputStream);
         while (!state._workQueue.isEmpty()) {
            String fileName = state._workQueue.pop();
            Transformer transformer = state._template.newTransformer();
            FileInputStream inputStream = new FileInputStream(new File(state.scratch, fileName));
            Source inFile = new StreamSource(inputStream);
            transformer.transform(inFile, outFile);
            inputStream.close();
         }
      } catch (TransformerConfigurationException e) {
         e.printStackTrace();
      } catch (TransformerException e) {
         e.printStackTrace();
      } catch (IOException e) {
         e.printStackTrace();
      }
      return 1;
   }
   
   @Benchmark
   public int copy_all(InputValue state) {
      state._workQueue.push("xmltransform_input/acks.xml");
      state._workQueue.push("xmltransform_input/binding.xml");
      state._workQueue.push("xmltransform_input/changes.xml");
      state._workQueue.push("xmltransform_input/concepts.xml");
      state._workQueue.push("xmltransform_input/controls.xml");
      state._workQueue.push("xmltransform_input/datatypes.xml");
      state._workQueue.push("xmltransform_input/expr.xml");
      state._workQueue.push("xmltransform_input/intro.xml");
      state._workQueue.push("xmltransform_input/model.xml");
      state._workQueue.push("xmltransform_input/prod-notes.xml");
      state._workQueue.push("xmltransform_input/references.xml");
      state._workQueue.push("xmltransform_input/rpm.xml");
      state._workQueue.push("xmltransform_input/schema.xml");
      state._workQueue.push("xmltransform_input/structure.xml");
      state._workQueue.push("xmltransform_input/template.xml");
      state._workQueue.push("xmltransform_input/terms.xml");
      state._workQueue.push("xmltransform_input/ui.xml");
      try {
         FileOutputStream outputStream = new FileOutputStream(new File(state.scratch, state.blfilename));
         while (!state._workQueue.isEmpty()) {
            String fileName = state._workQueue.pop();
            String filedata = new String(Files.readAllBytes(Paths.get(fileName)));
            byte[] bytebuf = filedata.getBytes();
            outputStream.write(bytebuf);
         }
      } catch (IOException e) {
         e.printStackTrace();
      }
      return 1;
   }
}

