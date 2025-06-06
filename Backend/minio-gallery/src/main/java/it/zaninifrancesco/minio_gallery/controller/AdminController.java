package it.zaninifrancesco.minio_gallery.controller;

import it.zaninifrancesco.minio_gallery.dto.ImageResponse;
import it.zaninifrancesco.minio_gallery.dto.MessageResponse;
import it.zaninifrancesco.minio_gallery.dto.UserResponse;
import it.zaninifrancesco.minio_gallery.service.AdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Controller REST per funzionalità amministrative
 * Accessibile solo agli utenti con ruolo ADMIN
 */
@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Amministrazione", description = "API per la gestione amministrativa del sistema (solo ADMIN)")
@SecurityRequirement(name = "Bearer Authentication")
public class AdminController {
    
    private static final Logger logger = LoggerFactory.getLogger(AdminController.class);
    
    @Autowired
    private AdminService adminService;
    
    /**
     * Ottieni tutti gli utenti con paginazione
     * GET /api/admin/users?page=0&size=20
     */
    @GetMapping("/users")
    @Operation(summary = "Lista tutti gli utenti", 
               description = "Recupera tutti gli utenti registrati nel sistema con paginazione (solo ADMIN)")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista utenti recuperata con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = Page.class))),
        @ApiResponse(responseCode = "403", description = "Accesso negato - solo ADMIN",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Access denied\"}"))),
        @ApiResponse(responseCode = "500", description = "Errore interno del server",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Failed to fetch users\"}")))
    })
    public ResponseEntity<?> getAllUsers(
            @Parameter(description = "Numero della pagina (inizia da 0)", example = "0")
            @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Numero di elementi per pagina", example = "20")
            @RequestParam(defaultValue = "20") int size) {
        try {
            logger.info("Admin requesting all users - page: {}, size: {}", page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<UserResponse> users = adminService.getAllUsers(pageable);
            
            logger.info("Retrieved {} users out of {} total", users.getNumberOfElements(), users.getTotalElements());
            
            return ResponseEntity.ok(users);
            
        } catch (Exception e) {
            logger.error("Error fetching users", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch users: " + e.getMessage()));
        }
    }
    
    /**
     * Ottieni tutte le immagini con paginazione (per admin)
     * GET /api/admin/images?page=0&size=20
     */
    @GetMapping("/images")
    public ResponseEntity<?> getAllImages(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            logger.info("Admin requesting all images - page: {}, size: {}", page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = adminService.getAllImages(pageable);
            
            logger.info("Retrieved {} images out of {} total", images.getNumberOfElements(), images.getTotalElements());
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error fetching images for admin", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch images: " + e.getMessage()));
        }
    }
    
    /**
     * Elimina un utente (admin only)
     * DELETE /api/admin/users/{userId}
     */
    @DeleteMapping("/users/{userId}")
    public ResponseEntity<?> deleteUser(@PathVariable Long userId) {
        try {
            logger.info("Admin requesting deletion of user ID: {}", userId);
            
            adminService.deleteUser(userId);
            
            logger.info("User deleted successfully: {}", userId);
            
            return ResponseEntity.ok(new MessageResponse("User deleted successfully"));
            
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                logger.warn("User not found for deletion: {}", userId);
                return ResponseEntity.notFound().build();
            } else {
                logger.error("Error deleting user: {}", userId, e);
                return ResponseEntity.badRequest()
                        .body(Map.of("error", e.getMessage()));
            }
        } catch (Exception e) {
            logger.error("Error deleting user: {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to delete user: " + e.getMessage()));
        }
    }
    
    /**
     * Elimina un'immagine (admin può eliminare qualsiasi immagine)
     * DELETE /api/admin/images/{imageId}
     */
    @DeleteMapping("/images/{imageId}")
    public ResponseEntity<?> deleteImage(@PathVariable UUID imageId) {
        try {
            logger.info("Admin requesting deletion of image ID: {}", imageId);
            
            adminService.deleteImage(imageId);
            
            logger.info("Image deleted successfully by admin: {}", imageId);
            
            return ResponseEntity.ok(new MessageResponse("Image deleted successfully"));
            
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                logger.warn("Image not found for deletion: {}", imageId);
                return ResponseEntity.notFound().build();
            } else {
                logger.error("Error deleting image: {}", imageId, e);
                return ResponseEntity.badRequest()
                        .body(Map.of("error", e.getMessage()));
            }
        } catch (Exception e) {
            logger.error("Error deleting image: {}", imageId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to delete image: " + e.getMessage()));
        }
    }
    
    /**
     * Cambia il ruolo di un utente
     * PUT /api/admin/users/{userId}/role
     */
    @PutMapping("/users/{userId}/role")
    public ResponseEntity<?> changeUserRole(
            @PathVariable Long userId,
            @RequestBody Map<String, String> request) {
        try {
            String newRole = request.get("role");
            if (newRole == null || newRole.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Role is required"));
            }
            
            logger.info("Admin requesting role change for user ID: {} to role: {}", userId, newRole);
            
            UserResponse updatedUser = adminService.changeUserRole(userId, newRole);
            
            logger.info("User role changed successfully: {} -> {}", userId, newRole);
            
            return ResponseEntity.ok(updatedUser);
            
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                logger.warn("User not found for role change: {}", userId);
                return ResponseEntity.notFound().build();
            } else {
                logger.error("Error changing user role: {}", userId, e);
                return ResponseEntity.badRequest()
                        .body(Map.of("error", e.getMessage()));
            }
        } catch (Exception e) {
            logger.error("Error changing user role: {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to change user role: " + e.getMessage()));
        }
    }
    
    /**
     * Attiva/Disattiva un utente
     * PUT /api/admin/users/{userId}/status
     */
    @PutMapping("/users/{userId}/status")
    public ResponseEntity<?> toggleUserStatus(
            @PathVariable Long userId,
            @RequestBody Map<String, Boolean> request) {
        try {
            Boolean enabled = request.get("enabled");
            if (enabled == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Enabled status is required"));
            }
            
            logger.info("Admin requesting status change for user ID: {} to enabled: {}", userId, enabled);
            
            UserResponse updatedUser = adminService.toggleUserStatus(userId, enabled);
            
            logger.info("User status changed successfully: {} -> enabled: {}", userId, enabled);
            
            return ResponseEntity.ok(updatedUser);
            
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                logger.warn("User not found for status change: {}", userId);
                return ResponseEntity.notFound().build();
            } else {
                logger.error("Error changing user status: {}", userId, e);
                return ResponseEntity.badRequest()
                        .body(Map.of("error", e.getMessage()));
            }
        } catch (Exception e) {
            logger.error("Error changing user status: {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to change user status: " + e.getMessage()));
        }
    }
    
    /**
     * Ottieni statistiche del sistema
     * GET /api/admin/stats
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getSystemStats() {
        try {
            logger.info("Admin requesting system statistics");
            
            Map<String, Object> stats = adminService.getSystemStats();
            
            return ResponseEntity.ok(stats);
            
        } catch (Exception e) {
            logger.error("Error fetching system stats", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch system statistics: " + e.getMessage()));
        }
    }
}
