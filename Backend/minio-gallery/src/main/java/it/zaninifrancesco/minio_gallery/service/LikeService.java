package it.zaninifrancesco.minio_gallery.service;

import it.zaninifrancesco.minio_gallery.dto.LeaderboardEntry;
import it.zaninifrancesco.minio_gallery.dto.LikeResponse;
import it.zaninifrancesco.minio_gallery.entity.ImageLike;
import it.zaninifrancesco.minio_gallery.entity.ImageMetadata;
import it.zaninifrancesco.minio_gallery.entity.User;
import it.zaninifrancesco.minio_gallery.repository.ImageLikeRepository;
import it.zaninifrancesco.minio_gallery.repository.ImageMetadataRepository;
import it.zaninifrancesco.minio_gallery.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
public class LikeService {    @Autowired
    private ImageLikeRepository imageLikeRepository;
    
    @Autowired
    private ImageMetadataRepository imageMetadataRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private MinioService minioService;
      /**
     * Toggle like for an image by a user
     * @param imageId The image ID
     * @param username The username
     * @return LikeResponse with current like status and count
     */
    public LikeResponse toggleLike(UUID imageId, String username) {
        ImageMetadata image = imageMetadataRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found"));
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Optional<ImageLike> existingLike = imageLikeRepository.findByImageAndUser(image, user);
        
        if (existingLike.isPresent()) {
            // Unlike
            imageLikeRepository.delete(existingLike.get());
            return new LikeResponse(false, getLikeCount(imageId));
        } else {            // Like
            ImageLike like = new ImageLike();
            like.setImage(image);
            like.setUser(user);
            like.setLikedAt(LocalDateTime.now());
            imageLikeRepository.save(like);
            return new LikeResponse(true, getLikeCount(imageId));
        }
    }
    
    /**
     * Get like count for an image
     * @param imageId The image ID
     * @return The number of likes
     */
    public int getLikeCount(UUID imageId) {
        return imageLikeRepository.countByImageId(imageId);
    }
    
    /**
     * Check if an image is liked by a user
     * @param imageId The image ID
     * @param userId The user ID
     * @return true if liked, false otherwise
     */    public boolean isLikedByUser(UUID imageId, String username) {
        ImageMetadata image = imageMetadataRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found"));
        
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return imageLikeRepository.existsByImageAndUser(image, user);
    }    /**
     * Get monthly leaderboard
     * @param year The year
     * @param month The month (1-12)
     * @return List of LeaderboardEntry with image details and like counts
     */
    @Transactional(readOnly = true)
    public List<LeaderboardEntry> getMonthlyLeaderboard(int year, int month) {
        List<Object[]> rawResults = imageLikeRepository.getMonthlyLeaderboard(year, month);
        return rawResults.stream()
                .map(row -> {
                    UUID imageId = (UUID) row[0];
                    String title = (String) row[1];
                    String authorUsername = (String) row[2];
                    int likeCount = ((Number) row[3]).intValue();
                    
                    // Get the image metadata to retrieve the filename
                    ImageMetadata imageMetadata = imageMetadataRepository.findById(imageId)
                            .orElseThrow(() -> new RuntimeException("Image not found"));
                    
                    // Generate the image URL
                    String imageUrl = minioService.generatePresignedUrl(imageMetadata.getFileName(), 30);
                    
                    return new LeaderboardEntry(imageId, title, imageUrl, authorUsername, likeCount);
                })
                .toList();
    }
    
    /**
     * Get photo of the month (image with most likes in a specific month)
     * @param year The year
     * @param month The month (1-12)
     * @return The image with most likes that month
     */    @Transactional(readOnly = true)
    public Optional<ImageMetadata> getPhotoOfMonth(int year, int month) {
        Pageable pageable = PageRequest.of(0, 1);
        List<UUID> result = imageLikeRepository.getPhotoOfMonth(year, month, pageable);
        if (!result.isEmpty()) {
            UUID imageId = result.get(0);
            return imageMetadataRepository.findById(imageId);
        }
        return Optional.empty();
    }
    
    /**
     * Get current month's photo of the month
     * @return The image with most likes this month
     */
    @Transactional(readOnly = true)
    public Optional<ImageMetadata> getCurrentPhotoOfMonth() {
        LocalDate now = LocalDate.now();
        return getPhotoOfMonth(now.getYear(), now.getMonthValue());
    }
    
    /**
     * Get likes for a specific image
     * @param imageId The image ID
     * @param pageable Pagination parameters
     * @return Page of likes
     */
    @Transactional(readOnly = true)
    public Page<ImageLike> getLikesForImage(UUID imageId, Pageable pageable) {
        ImageMetadata image = imageMetadataRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found"));
        
        return imageLikeRepository.findByImage(image, pageable);
    }
      /**
     * Get likes by a specific user
     * @param username The username
     * @param pageable Pagination parameters
     * @return Page of likes
     */
    @Transactional(readOnly = true)
    public Page<ImageLike> getLikesByUser(String username, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return imageLikeRepository.findByUser(user, pageable);
    }
}
