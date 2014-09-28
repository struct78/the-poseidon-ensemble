public class LogFile
{
  PrintWriter printWriter;
  int indention = 0;
  
  LogFile(String filename) {
    /*try {
      printWriter = createWriter(filename);
    }
    catch(Exception e)
    {
      println("Unable to open " + filename");
    }*/
  }
  
  void write(String logtext)
  {
    /*try {
      printWriter.println(logtext);
      printWriter.flush();
    }
    catch(Exception e)
    {
      println("Error: Unable to write to log file");
    }*/
  }
}
