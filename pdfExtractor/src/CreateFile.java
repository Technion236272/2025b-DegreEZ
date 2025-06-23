import java.io.BufferedReader;
import java.io.File; // Import the File class
import java.io.FileWriter;
import java.io.IOException; // Import the IOException class to handle errors
import java.io.FileReader;

public class CreateFile {

  BufferedReader reader;

  public static void createFile(String filename) {
    filename = filename + ".txt";
    try {
      File myObj = new File(filename);
      if (myObj.createNewFile()) {
        System.out.println("File created: " + myObj.getName());
      } else {
        System.out.println("File already exists.");
      }
    } catch (IOException e) {
      System.out.println("An error occurred.");
      e.printStackTrace();
    }
  }

  public static void writeFile(String filename, String content) {

    filename = filename + ".txt";
    try {
      FileWriter myWriter = new FileWriter(filename);
      myWriter.write(content);
      myWriter.close();
      System.out.println("Successfully wrote to the file.");
    } catch (IOException e) {
      System.out.println("An error occurred.");
      e.printStackTrace();
    }
  }

  public void createReader(String filename) {
    filename = filename + ".txt";
    try {
      this.reader = new BufferedReader(new FileReader(filename));
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public String readLine() {
    String line = "";
    try {
      line = this.reader.readLine();
      // System.out.println("Successfully read one line");
    } catch (IOException e) {
      System.out.println("An error occurred.");
      e.printStackTrace();
    }
    return line;
  }

  public String readFile(String filename) {
    createReader(filename);
    String page = "";
    String line = readLine();
    while (line != null) {
      page += line + '\n';
      line = readLine();
    }
    try {
      this.reader.close();
    } catch (Exception e) {
      e.printStackTrace();
    }
    return page;
  }
}