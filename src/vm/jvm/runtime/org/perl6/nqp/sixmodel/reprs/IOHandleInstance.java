package org.perl6.nqp.sixmodel.reprs;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

import jline.ConsoleReader;

import java.nio.file.DirectoryStream;
import java.nio.file.Path;

import java.util.Iterator;

import org.perl6.nqp.sixmodel.SixModelObject;

public class IOHandleInstance extends SixModelObject {
	
    /* The input stream; if null, we can't read from this. */
    public InputStream is;
    
    /* EOF gets marked by read operations */
    public boolean eof;

    /* The output stream; if null, we can't write to this. */
    public OutputStream os;
    
    /* The (Java) encoding name to use. */
    public String encoding = "UTF-8";
    
    /* These wrap the above streams and knows about encodings. If they
     * are still null, the encoding can still be set.
     */
    public InputStreamReader isr;
    public OutputStreamWriter osw;
    
    /*
     * This further wraps the input stream reader for the case of doing
     * line-based I/O.
     */
    public BufferedReader br;
    
    /* This wraps the input stream for interactive readline */
    public ConsoleReader cr;
    
    /* This wraps directories that were opened for lazy file listings */
    public DirectoryStream<Path> dirstrm;
    
    /* This is the iterator from the dirstrm */
    public Iterator<Path> diri;
}
