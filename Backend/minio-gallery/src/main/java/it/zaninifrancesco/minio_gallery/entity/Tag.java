package it.zaninifrancesco.minio_gallery.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "tags")
public class Tag {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Tag name is required")
    @Size(min = 1, max = 100, message = "Tag name must be between 1 and 100 characters")
    @Column(unique = true, nullable = false, length = 100)
    private String name;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    // Relazione Many-to-Many con ImageMetadata
    @ManyToMany(mappedBy = "tags", fetch = FetchType.LAZY)
    private Set<ImageMetadata> images = new HashSet<>();
    
    // Constructors
    public Tag() {}
    
    public Tag(String name) {
        this.name = name;
        this.createdAt = LocalDateTime.now();
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public Set<ImageMetadata> getImages() {
        return images;
    }
    
    public void setImages(Set<ImageMetadata> images) {
        this.images = images;
    }
    
    // Utility methods
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Tag)) return false;
        Tag tag = (Tag) o;
        return name != null && name.equals(tag.getName());
    }
    
    @Override
    public int hashCode() {
        return name != null ? name.hashCode() : 0;
    }
    
    @Override
    public String toString() {
        return "Tag{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
}
