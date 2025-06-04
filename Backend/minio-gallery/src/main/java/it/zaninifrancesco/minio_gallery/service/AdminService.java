package it.zaninifrancesco.minio_gallery.service;

import it.zaninifrancesco.minio_gallery.dto.ImageResponse;
import it.zaninifrancesco.minio_gallery.dto.UserResponse;
import it.zaninifrancesco.minio_gallery.entity.ImageMetadata;
import it.zaninifrancesco.minio_gallery.entity.User;
import it.zaninifrancesco.minio_gallery.repository.ImageMetadataRepository;
import it.zaninifrancesco.minio_gallery.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Service per funzionalità amministrative
 * Gestisce operazioni che solo gli admin possono eseguire
 */
@Service
@Transactional
public class AdminService {
    
    private static final Logger logger = LoggerFactory.getLogger(AdminService.class);
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ImageMetadataRepository imageMetadataRepository;
    
    @Autowired
    private ImageService imageService;
    
    @Autowired
    private MinioService minioService;
    
    /**
     * Ottiene tutti gli utenti con paginazione
     */
    public Page<UserResponse> getAllUsers(Pageable pageable) {
        logger.info("Fetching all users with pagination");
        Page<User> users = userRepository.findAll(pageable);
        return users.map(user -> {
            int imageCount = (int) imageMetadataRepository.countByUserId(user.getId());
            return new UserResponse(user, imageCount);
        });
    }
    
    /**
     * Ottiene tutte le immagini con paginazione (per admin)
     */
    public Page<ImageResponse> getAllImages(Pageable pageable) {
        logger.info("Fetching all images for admin with pagination");
        return imageService.getAllImages(pageable);
    }
    
    /**
     * Elimina un utente (admin only)
     */
    public void deleteUser(Long userId) {
        logger.info("Admin deleting user with ID: {}", userId);
        
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        
        // Trova tutte le immagini dell'utente
        Page<ImageMetadata> userImages = imageMetadataRepository.findByUserOrderByUploadedAtDesc(user, Pageable.unpaged());
        
        // Elimina tutte le immagini dell'utente da MinIO e dal database
        for (ImageMetadata image : userImages.getContent()) {
            try {
                // Elimina da MinIO
                boolean deleted = minioService.deleteFile(image.getFileName());
                if (!deleted) {
                    logger.warn("Failed to delete file from MinIO: {}", image.getFileName());
                }
                
                // Elimina dal database
                imageMetadataRepository.delete(image);
                logger.info("Deleted image {} from user {}", image.getId(), userId);
                
            } catch (Exception e) {
                logger.error("Error deleting image {} during user deletion", image.getId(), e);
                // Continua con le altre immagini anche se una fallisce
            }
        }
        
        // Elimina l'utente
        userRepository.delete(user);
        logger.info("User {} and all associated images deleted successfully", userId);
    }
    
    /**
     * Elimina un'immagine (admin può eliminare qualsiasi immagine)
     */
    public void deleteImage(UUID imageId) {
        logger.info("Admin deleting image with ID: {}", imageId);
        
        ImageMetadata imageMetadata = imageMetadataRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found: " + imageId));
        
        try {
            // Elimina da MinIO
            boolean deleted = minioService.deleteFile(imageMetadata.getFileName());
            if (!deleted) {
                logger.warn("Failed to delete file from MinIO: {}", imageMetadata.getFileName());
            }
            
            // Elimina dal database
            imageMetadataRepository.delete(imageMetadata);
            
            logger.info("Image deleted successfully by admin: {}", imageId);
            
        } catch (Exception e) {
            logger.error("Error deleting image: {}", imageId, e);
            throw new RuntimeException("Failed to delete image: " + e.getMessage(), e);
        }
    }
    
    /**
     * Cambia il ruolo di un utente
     */
    public UserResponse changeUserRole(Long userId, String newRole) {
        logger.info("Admin changing role for user {} to {}", userId, newRole);
        
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        
        try {
            User.Role role = User.Role.valueOf(newRole.toUpperCase());
            user.setRole(role);
            user = userRepository.save(user);
            
            int imageCount = (int) imageMetadataRepository.countByUserId(user.getId());
            logger.info("User role changed successfully: {} -> {}", userId, newRole);
            return new UserResponse(user, imageCount);
            
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid role: " + newRole + ". Valid roles are: USER, ADMIN");
        }
    }
    
    /**
     * Attiva/Disattiva un utente
     */
    public UserResponse toggleUserStatus(Long userId, boolean enabled) {
        logger.info("Admin changing status for user {} to enabled: {}", userId, enabled);
        
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        
        user.setEnabled(enabled);
        user = userRepository.save(user);
        
        int imageCount = (int) imageMetadataRepository.countByUserId(user.getId());
        logger.info("User status changed successfully: {} -> enabled: {}", userId, enabled);
        return new UserResponse(user, imageCount);
    }
    
    /**
     * Ottiene statistiche del sistema
     */
    public Map<String, Object> getSystemStats() {
        logger.info("Generating system statistics");
        
        Map<String, Object> stats = new HashMap<>();
        
        // Conteggio utenti
        long totalUsers = userRepository.count();
        long adminUsers = userRepository.countByRole(User.Role.ADMIN);
        long regularUsers = userRepository.countByRole(User.Role.USER);
        long enabledUsers = userRepository.countByEnabledTrue();
        long disabledUsers = userRepository.countByEnabledFalse();
        
        // Conteggio immagini
        long totalImages = imageMetadataRepository.count();
        
        // Conteggio like totali
        long totalLikes = imageMetadataRepository.getTotalLikes();
        
        // Dimensione totale delle immagini
        long totalSize = imageMetadataRepository.getTotalImageSize();
        
        // Statistiche utenti
        Map<String, Object> userStats = new HashMap<>();
        userStats.put("total", totalUsers);
        userStats.put("admins", adminUsers);
        userStats.put("regularUsers", regularUsers);
        userStats.put("enabled", enabledUsers);
        userStats.put("disabled", disabledUsers);
        
        // Statistiche immagini
        Map<String, Object> imageStats = new HashMap<>();
        imageStats.put("total", totalImages);
        imageStats.put("totalSizeBytes", totalSize);
        imageStats.put("totalSizeMB", Math.round(totalSize / (1024.0 * 1024.0) * 100.0) / 100.0);
        
        // Statistiche like
        Map<String, Object> likeStats = new HashMap<>();
        likeStats.put("total", totalLikes);
        
        stats.put("users", userStats);
        stats.put("images", imageStats);
        stats.put("likes", likeStats);
        
        logger.info("System stats generated: {} users, {} images, {} likes, {}MB total", 
                   totalUsers, totalImages, totalLikes, imageStats.get("totalSizeMB"));
        
        return stats;
    }
}
