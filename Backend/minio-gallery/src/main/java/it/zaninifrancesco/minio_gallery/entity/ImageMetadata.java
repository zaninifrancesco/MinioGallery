package it.zaninifrancesco.minio_gallery.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "image_metadata")
public class ImageMetadata {
    
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;
    
    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    @Column(nullable = false)
    private String title;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @NotBlank(message = "File name is required")
    @Size(max = 255, message = "File name must not exceed 255 characters")
    @Column(name = "file_name", unique = true, nullable = false)
    private String fileName;
    
    @NotBlank(message = "Bucket name is required")
    @Size(max = 255, message = "Bucket name must not exceed 255 characters")
    @Column(name = "bucket_name", nullable = false)
    private String bucketName;
    
    @Size(max = 255, message = "Original file name must not exceed 255 characters")
    @Column(name = "original_file_name")
    private String originalFileName;
    
    @Size(max = 100, message = "Content type must not exceed 100 characters")
    @Column(name = "content_type")
    private String contentType;
    
    @Column(name = "size")
    private Long size;
    
    @Column(name = "uploaded_at", nullable = false)
    private LocalDateTime uploadedAt;
    
    // Relazione Many-to-One con User
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    // Relazione Many-to-Many con Tag
    @ManyToMany(fetch = FetchType.LAZY, cascade = {CascadeType.PERSIST, CascadeType.MERGE})
    @JoinTable(
        name = "image_tags",
        joinColumns = @JoinColumn(name = "image_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    private Set<Tag> tags = new HashSet<>();
    
    // Constructors
    public ImageMetadata() {
        this.id = UUID.randomUUID();
    }
    
    public ImageMetadata(String title, String fileName, String bucketName, User user) {
        this();
        this.title = title;
        this.fileName = fileName;
        this.bucketName = bucketName;
        this.user = user;
        this.uploadedAt = LocalDateTime.now();
    }
    
    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (uploadedAt == null) {
            uploadedAt = LocalDateTime.now();
        }
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
    
    public String getBucketName() {
        return bucketName;
    }
    
    public void setBucketName(String bucketName) {
        this.bucketName = bucketName;
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
    
    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }
    
    public void setUploadedAt(LocalDateTime uploadedAt) {
        this.uploadedAt = uploadedAt;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    public Set<Tag> getTags() {
        return tags;
    }
    
    public void setTags(Set<Tag> tags) {
        this.tags = tags;
    }
    
    // Utility methods for managing tags
    public void addTag(Tag tag) {
        this.tags.add(tag);
        tag.getImages().add(this);
    }
    
    public void removeTag(Tag tag) {
        this.tags.remove(tag);
        tag.getImages().remove(this);
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ImageMetadata)) return false;
        ImageMetadata that = (ImageMetadata) o;
        return id != null && id.equals(that.getId());
    }
    
    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
    
    @Override
    public String toString() {
        return "ImageMetadata{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", fileName='" + fileName + '\'' +
                ", bucketName='" + bucketName + '\'' +
                ", uploadedAt=" + uploadedAt +
                ", user=" + (user != null ? user.getUsername() : null) +
                ", tagsCount=" + (tags != null ? tags.size() : 0) +
                '}';
    }
}
