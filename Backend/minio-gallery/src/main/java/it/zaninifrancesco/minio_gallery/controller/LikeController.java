package it.zaninifrancesco.minio_gallery.controller;

import it.zaninifrancesco.minio_gallery.dto.LeaderboardEntry;
import it.zaninifrancesco.minio_gallery.dto.LikeResponse;
import it.zaninifrancesco.minio_gallery.entity.ImageMetadata;
import it.zaninifrancesco.minio_gallery.service.LikeService;
import it.zaninifrancesco.minio_gallery.service.MinioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/likes")
@CrossOrigin(origins = "*", maxAge = 3600)
public class LikeController {
    
    @Autowired
    private LikeService likeService;
    
    @Autowired
    private MinioService minioService;
      /**
     * Toggle like for an image
     */
    @PostMapping("/toggle/{imageId}")
    public ResponseEntity<LikeResponse> toggleLike(@PathVariable UUID imageId) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()) {
                return ResponseEntity.status(401).build();
            }
            
            UserDetails userDetails = (UserDetails) auth.getPrincipal();
            String username = userDetails.getUsername();
            
            LikeResponse response = likeService.toggleLike(imageId, username);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
      /**
     * Get like status for an image
     */
    @GetMapping("/status/{imageId}")
    public ResponseEntity<LikeResponse> getLikeStatus(@PathVariable UUID imageId) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            
            int likeCount = likeService.getLikeCount(imageId);
            boolean isLiked = false;
            
            if (auth != null && auth.isAuthenticated()) {
                UserDetails userDetails = (UserDetails) auth.getPrincipal();
                String username = userDetails.getUsername();
                isLiked = likeService.isLikedByUser(imageId, username);
            }
            
            return ResponseEntity.ok(new LikeResponse(isLiked, likeCount));
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
      /**
     * Get monthly leaderboard
     */
    @GetMapping("/leaderboard")
    public ResponseEntity<List<LeaderboardEntry>> getMonthlyLeaderboard(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        try {
            LocalDate now = LocalDate.now();
            int targetYear = year != null ? year : now.getYear();
            int targetMonth = month != null ? month : now.getMonthValue();
            
            List<LeaderboardEntry> leaderboard = likeService.getMonthlyLeaderboard(targetYear, targetMonth);
            
            return ResponseEntity.ok(leaderboard);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();        }
    }
    
    /**
     * Get photo of the month
     */
    @GetMapping("/photo-of-month")
    public ResponseEntity<LeaderboardEntry> getPhotoOfMonth(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        try {
            LocalDate now = LocalDate.now();
            int targetYear = year != null ? year : now.getYear();
            int targetMonth = month != null ? month : now.getMonthValue();
            
            Optional<ImageMetadata> photoOfMonth = likeService.getPhotoOfMonth(targetYear, targetMonth);
              if (photoOfMonth.isPresent()) {
                ImageMetadata image = photoOfMonth.get();
                String imageUrl = minioService.generatePresignedUrl(image.getFileName(), 30);
                int likeCount = likeService.getLikeCount(image.getId());
                
                LeaderboardEntry entry = new LeaderboardEntry(
                    image.getId(),
                    image.getTitle(),
                    imageUrl,
                    image.getUser().getUsername(),
                    likeCount
                );
                
                return ResponseEntity.ok(entry);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
