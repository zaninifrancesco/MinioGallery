package it.zaninifrancesco.minio_gallery.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "image_likes", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"image_id", "user_id"})
})
public class ImageLike {
    
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "image_id", nullable = false)
    private ImageMetadata image;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(name = "liked_at", nullable = false)
    private LocalDateTime likedAt;
    
    // Constructors
    public ImageLike() {
        this.id = UUID.randomUUID();
    }
    
    public ImageLike(ImageMetadata image, User user) {
        this();
        this.image = image;
        this.user = user;
        this.likedAt = LocalDateTime.now();
    }
    
    @PrePersist
    protected void onCreate() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (likedAt == null) {
            likedAt = LocalDateTime.now();
        }
    }
    
    // Getters and Setters
    public UUID getId() {
        return id;
    }
    
    public void setId(UUID id) {
        this.id = id;
    }
    
    public ImageMetadata getImage() {
        return image;
    }
    
    public void setImage(ImageMetadata image) {
        this.image = image;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    public LocalDateTime getLikedAt() {
        return likedAt;
    }
    
    public void setLikedAt(LocalDateTime likedAt) {
        this.likedAt = likedAt;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ImageLike)) return false;
        ImageLike imageLike = (ImageLike) o;
        return id != null && id.equals(imageLike.id);
    }
    
    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
    
    @Override
    public String toString() {
        return "ImageLike{" +
                "id=" + id +
                ", image=" + (image != null ? image.getId() : null) +
                ", user=" + (user != null ? user.getId() : null) +
                ", likedAt=" + likedAt +
                '}';
    }
}
