
import java.io.File;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.io.RandomAccessRead;
import org.apache.pdfbox.io.RandomAccessReadBufferedFile;

import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;

// import io.github.cdimascio.dotenv.Dotenv;

public class ReadPdf {

    static class NotFound extends Exception {
        public NotFound() {
            super("Not Found");
        }
    }

    public static void main(String[] args) {
        PDDocument document;
        String tableofContentPage;
        String errors = "Errors list \n";

        // try {

        // } catch (Exception e) {
        // e.printStackTrace();
        // return;
        // }

        CreateFile createfile = new CreateFile();
        // createfile.createReader("../degreez/assets/2024-2025");
        createfile.createReader("23-24");
        String line;

        do {

            line = createfile.readLine();
            if (line == null)
                break;
            System.out.println(line);

            try {
                // open catalog
                File file = new File("src/2024.pdf");

                // read file
                RandomAccessRead rar = new RandomAccessReadBufferedFile(file);
                document = Loader.loadPDF(rar);

                // search for Table of Content
                tableofContentPage = extractTableofContent(document);
                System.out.println("Found Table of Content");
                String name = line;
                // Extract page Num for a specific topic
                int pageNum = findCorrespondingPage(tableofContentPage, name);
                System.out.println("Page Number : " + pageNum);

                extractMajors(document, pageNum, name);

                // PDFTextStripper stripper = new PDFTextStripper();
                // String text = stripper.getText(document);
                // System.out.println("Extracted Text:\n");
                // System.out.println(text);

                document.close();
            } catch (Exception e) {
                errors += line + '\n';
                e.printStackTrace();
            }
        } while (line != null);
        System.out.println(errors);
    }

    public static String extractTableofContent(PDDocument document) throws NotFound {

        try {
            PDFTextStripper stripper = new PDFTextStripper();
            for (int i = 1; i < 10; i++) {
                stripper.setStartPage(i);
                stripper.setEndPage(i);
                String text = stripper.getText(document);
                if (text.indexOf("תוכן העניינים") != -1)
                    return text;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        throw new NotFound();
    }

    public static int findCorrespondingPage(String tableofContentPage, String topic) throws NotFound {

        String[] lines = tableofContentPage.split("\\r?\\n");

        for (String line : lines) {
            if (line.indexOf(topic) == -1)
                continue;

            // Regex for full integer or decimal number
            Pattern pattern = Pattern.compile("-?\\d+(\\.\\d+)?");
            Matcher matcher = pattern.matcher(line);

            while (matcher.find()) {
                String extractedNumber = matcher.group(); // full number match
                return Integer.parseInt(extractedNumber);
            }
        }

        throw new NotFound();
    }

    public static void extractMajors(PDDocument document, int pageNum, String name) throws NotFound {
        try {
            BoldTextExtractor boldStripper = new BoldTextExtractor();
            boldStripper.setStartPage(pageNum-2);
            boldStripper.setEndPage(pageNum+1);
            String boldText = boldStripper.getText(document);
            // Set the environment variable programmatically
            // The client gets the API key from the environment variable `GOOGLE_API_KEY`.
            Client client = new Client();

            CreateFile createfile = new CreateFile();

            String prompt = createfile.readFile("prompt");

            GenerateContentResponse response = client.models.generateContent(
                    "gemini-2.5-flash",
                    boldText + prompt,
                    null);

            CreateFile.createFile("../degreez/assets/Faculties2023-2024/" + name);
            CreateFile.writeFile("../degreez/assets/Faculties2023-2024/" + name, response.text());
            client.close();
            return;

        } catch (Exception e) {

            e.printStackTrace();
        }
        throw new NotFound();

    }

}
