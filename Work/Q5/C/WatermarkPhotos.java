import java.awt.AlphaComposite;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;

public class WatermarkPhotos {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Usage: java WatermarkPhotos <photos_directory>");
            System.exit(1);
        }
        
        String directoryPath = args[0];
        File directory = new File(directoryPath);
        
        // Check if directory exists
        if (!directory.exists() || !directory.isDirectory()) {
            System.out.println("Error: Directory '" + directoryPath + "' does not exist.");
            System.exit(1);
        }
        
        // Get all PNG files in directory
        File[] files = directory.listFiles((dir, name) -> name.toLowerCase().endsWith(".png"));
        
        if (files == null || files.length == 0) {
            System.out.println("No PNG files found in directory '" + directoryPath + "'.");
            System.exit(0);
        }
        
        // Set watermark text
        String watermarkText = "Ariel Feinstein - ID: 212033906";
        
        // Process each PNG file
        for (File file : files) {
            try {
                addWatermark(file, watermarkText);
                System.out.println("Added watermark to: " + file.getName());
            } catch (IOException e) {
                System.out.println("Error processing file: " + file.getName() + " - " + e.getMessage());
            }
        }
        
        System.out.println("All files processed successfully.");
    }
    
    private static void addWatermark(File inputFile, String watermarkText) throws IOException {
        BufferedImage image = ImageIO.read(inputFile);
        
        // Create graphics context
        Graphics2D g2d = (Graphics2D) image.getGraphics();
        
        // Set rendering quality
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        
        // Set font properties - much smaller size
        int fontSize = Math.max(image.getWidth() / 30, 12); // Smaller text that scales with image
        Font font = new Font("Arial", Font.PLAIN, fontSize); // Using PLAIN instead of BOLD
        g2d.setFont(font);
        
        // Calculate text width and height
        int textWidth = g2d.getFontMetrics().stringWidth(watermarkText);
        int textHeight = g2d.getFontMetrics().getHeight();
        
        // Position text in center of image
        int x = (image.getWidth() - textWidth) / 2;
        int y = (image.getHeight() + textHeight / 2) / 2;
        
        // Add semi-transparent watermark
        g2d.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 0.25f)); // More transparent
        g2d.setPaint(Color.BLACK);
        g2d.drawString(watermarkText, x, y);
        
        g2d.dispose();
        
        // Save the watermarked image (overwriting the original)
        ImageIO.write(image, "png", inputFile);
    }
}