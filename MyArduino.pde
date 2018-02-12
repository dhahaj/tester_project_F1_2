static public String getContents(File aFile) {
   //...checks on aFile are elided
   StringBuilder contents = new StringBuilder();

   try {
      //use buffering, reading one line at a time
      //FileReader always assumes default encoding is OK!
      BufferedReader input =  new BufferedReader(new FileReader(aFile));
      try {
         String line = null; //not declared within while loop
         /*
        * readLine is a bit quirky :
          * it returns the content of a line MINUS the newline.
          * it returns null only for the END of the stream.
          * it returns an empty String if two newlines appear in a row.
          */
         while ( ( line = input.readLine ()) != null) {
            contents.append(line);
            contents.append(System.getProperty("line.separator"));
         }
      }
      finally {
         input.close();
      }
   }
   catch (IOException ex) {
      ex.printStackTrace();
   }

   return contents.toString();
}

static public StringBuilder getContentsBuilder(File aFile){
   return new StringBuilder(getContents(aFile));
}


static public void setContents(File aFile, String aContents)
    throws FileNotFoundException, IOException {
         if (aFile == null) {
                throw new IllegalArgumentException("File should not be null.");
         }
         if (!aFile.exists()) {
                throw new FileNotFoundException ("File does not exist: " + aFile);
         }
         if (!aFile.isFile()) {
                throw new IllegalArgumentException("Should not be a directory: " + aFile);
         }
         if (!aFile.canWrite()) {
                throw new IllegalArgumentException("File cannot be written: " + aFile);
         }

         //use buffering
         Writer output = new BufferedWriter(new FileWriter(aFile));
         try {
                //FileWriter always assumes default encoding is OK!
                output.write( aContents );
         }
         finally {
                output.close();
         }
    }
    
static public String replaceChars(String source, String replacement, int startPoint) {
    StringBuilder src = new StringBuilder(source);
    char[] rplChars = new char[replacement.length()];
    replacement.getChars(0, replacement.length(), rplChars, 0);
    for(int i = startPoint ; i<(rplChars.length+startPoint) ; i++) {
        src.setCharAt(i, rplChars[i-startPoint]);
    }
    return src.toString();
}

static public String toHex(String orig) {
   byte[] bytes = orig.getBytes();
   String hexString = "";
   for (int i=0;i<bytes.length;i++)
      hexString += hex(bytes[i], 4);
   return hexString;
}


