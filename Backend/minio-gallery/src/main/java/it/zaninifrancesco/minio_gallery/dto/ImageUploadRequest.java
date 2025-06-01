package it.zaninifrancesco.minio_gallery.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * DTO per la richiesta di upload di un'immagine
 * Contiene i metadati da associare all'immagine
 */
public class ImageUploadRequest {
    
    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;
    
    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;
    
    private List<String> tags;
    
    // Constructors
    public ImageUploadRequest() {}
    
    public ImageUploadRequest(String title, String description, List<String> tags) {
        this.title = title;
        this.description = description;
        this.tags = tags;
    }
    
    // Getters and Setters
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public List<String> getTags() {
        return tags;
    }
    
    public void setTags(List<String> tags) {
        this.tags = tags;
    }
    
    @Override
    public String toString() {
        return "ImageUploadRequest{" +
                "title='" + title + '\'' +
                ", description='" + description + '\'' +
                ", tags=" + tags +
                '}';
    }
}
