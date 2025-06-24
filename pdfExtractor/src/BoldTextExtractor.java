
import java.io.IOException;

import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.font.PDFontDescriptor;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;

public class BoldTextExtractor extends PDFTextStripper {

    public BoldTextExtractor() throws IOException {
        super();
    }

    // @Override
    // public void processPage(PDPage arg0) throws IOException {
    // int currentPage = getCurrentPageNo();
    // System.out.println("Processing page: " + currentPage);
    // super.processPage(arg0);
    // }

    @Override
    protected void processTextPosition( TextPosition text )
    {
        boolean isBold = false;

        String fontName = text.getFont().getName().toLowerCase();
            if (fontName.contains("bold")) {
                isBold = true;
            }

        PDFontDescriptor descriptor = text.getFont().getFontDescriptor();
if (descriptor != null) {
    float weight = descriptor.getFontWeight();
    if (weight >= 600) {
        isBold = true;
    }
}

            
        if (isBold) {
            super.processTextPosition(text);
                }

    }

}
