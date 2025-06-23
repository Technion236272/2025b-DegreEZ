
import java.io.IOException;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;

public class BoldTextExtractor extends PDFTextStripper {

    public BoldTextExtractor() throws IOException {
        super();
    }

    @Override
    protected void processTextPosition( TextPosition text )
    {
        boolean isBold = false;

        String fontName = text.getFont().getName().toLowerCase();
            if (fontName.contains("bold")) {
                isBold = true;
            }

            
        if (isBold) {
            super.processTextPosition(text);
                }

    }

}
