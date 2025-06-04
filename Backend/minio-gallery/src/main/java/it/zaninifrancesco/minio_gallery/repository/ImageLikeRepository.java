package it.zaninifrancesco.minio_gallery.repository;

import it.zaninifrancesco.minio_gallery.entity.ImageLike;
import it.zaninifrancesco.minio_gallery.entity.ImageMetadata;
import it.zaninifrancesco.minio_gallery.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ImageLikeRepository extends JpaRepository<ImageLike, UUID> {
    
    /**
     * Find a like by image and user
     */
    Optional<ImageLike> findByImageAndUser(ImageMetadata image, User user);
    
    /**
     * Check if an image is liked by a user
     */
    boolean existsByImageAndUser(ImageMetadata image, User user);
    
    /**
     * Count likes for a specific image
     */
    int countByImage(ImageMetadata image);
    
    /**
     * Count likes for a specific image by ID
     */
    @Query("SELECT COUNT(l) FROM ImageLike l WHERE l.image.id = :imageId")
    int countByImageId(@Param("imageId") UUID imageId);
    
    /**
     * Find all likes by user
     */
    Page<ImageLike> findByUser(User user, Pageable pageable);
    
    /**
     * Find all likes for a specific image
     */
    Page<ImageLike> findByImage(ImageMetadata image, Pageable pageable);    /**
     * Get monthly leaderboard - images with most likes in a specific month/year
     */
    @Query("SELECT l.image.id, l.image.title, l.image.user.username, COUNT(l) as likeCount " +
           "FROM ImageLike l " +
           "WHERE YEAR(l.likedAt) = :year AND MONTH(l.likedAt) = :month " +
           "GROUP BY l.image.id, l.image.title, l.image.user.username " +
           "ORDER BY COUNT(l) DESC")
    List<Object[]> getMonthlyLeaderboard(@Param("year") int year, @Param("month") int month);
      /**
     * Get photo of the month - image with most likes in a specific month/year
     */
    @Query("SELECT l.image.id " +
           "FROM ImageLike l " +
           "WHERE YEAR(l.likedAt) = :year AND MONTH(l.likedAt) = :month " +
           "GROUP BY l.image.id " +
           "ORDER BY COUNT(l) DESC")
    List<UUID> getPhotoOfMonth(@Param("year") int year, @Param("month") int month, Pageable pageable);
    
    /**
     * Delete like by image and user
     */
    void deleteByImageAndUser(ImageMetadata image, User user);
}
