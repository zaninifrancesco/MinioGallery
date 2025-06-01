package it.zaninifrancesco.minio_gallery.dto;

import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * DTO per la risposta contenente i dettagli di un'immagine
 * Include i metadati e l'URL per accedere all'immagine
 */
public class ImageResponse {
    
    private UUID id;
    private String title;
    private String description;
    private String fileName;
    private String originalFileName;
    private String contentType;
    private Long size;
    private String imageUrl; // URL presigned per accedere all'immagine
    private List<String> tags;
    private String uploaderUsername;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime uploadedAt;
    
    // Constructors
    public ImageResponse() {}
    
    public ImageResponse(UUID id, String title, String description, String fileName, 
                        String originalFileName, String contentType, Long size, 
                        String imageUrl, List<String> tags, String uploaderUsername, 
                        LocalDateTime uploadedAt) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.fileName = fileName;
        this.originalFileName = originalFileName;
        this.contentType = contentType;
        this.size = size;
        this.imageUrl = imageUrl;
        this.tags = tags;
        this.uploaderUsername = uploaderUsername;
        this.uploadedAt = uploadedAt;
    }
    
    // Getters and Setters
    public UUID getId() {
        return id;
    }
    
    public void setId(UUID id) {
        this.id = id;
    }
    
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
    
    public String getFileName() {
        return fileName;
    }
    
    public void setFileName(String fileName) {
        this.fileName = fileName;
    }
    
    public String getOriginalFileName() {
        return originalFileName;
    }
    
    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }
    
    public String getContentType() {
        return contentType;
    }
    
    public void setContentType(String contentType) {
        this.contentType = contentType;
    }
    
    public Long getSize() {
        return size;
    }
    
    public void setSize(Long size) {
        this.size = size;
    }
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    
    public List<String> getTags() {
        return tags;
    }
    
    public void setTags(List<String> tags) {
        this.tags = tags;
    }
    
    public String getUploaderUsername() {
        return uploaderUsername;
    }
    
    public void setUploaderUsername(String uploaderUsername) {
        this.uploaderUsername = uploaderUsername;
    }
    
    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }
    
    public void setUploadedAt(LocalDateTime uploadedAt) {
        this.uploadedAt = uploadedAt;
    }
    
    @Override
    public String toString() {
        return "ImageResponse{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", fileName='" + fileName + '\'' +
                ", uploaderUsername='" + uploaderUsername + '\'' +
                ", uploadedAt=" + uploadedAt +
                ", tagsCount=" + (tags != null ? tags.size() : 0) +
                '}';
    }
}
