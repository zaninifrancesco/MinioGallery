package it.zaninifrancesco.minio_gallery.dto;

import java.util.UUID;

public class LeaderboardEntry {
    private UUID imageId;
    private String title;
    private String imageUrl;
    private String uploaderUsername;
    private int likeCount;
    
    public LeaderboardEntry() {}
    
    public LeaderboardEntry(UUID imageId, String title, String imageUrl, String uploaderUsername, int likeCount) {
        this.imageId = imageId;
        this.title = title;
        this.imageUrl = imageUrl;
        this.uploaderUsername = uploaderUsername;
        this.likeCount = likeCount;
    }
    
    public UUID getImageId() {
        return imageId;
    }
    
    public void setImageId(UUID imageId) {
        this.imageId = imageId;
    }
    
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
    }
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    
    public String getUploaderUsername() {
        return uploaderUsername;
    }
    
    public void setUploaderUsername(String uploaderUsername) {
        this.uploaderUsername = uploaderUsername;
    }
    
    public int getLikeCount() {
        return likeCount;
    }
    
    public void setLikeCount(int likeCount) {
        this.likeCount = likeCount;
    }
}
