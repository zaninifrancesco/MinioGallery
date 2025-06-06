package it.zaninifrancesco.minio_gallery.controller;

import it.zaninifrancesco.minio_gallery.dto.ImageResponse;
import it.zaninifrancesco.minio_gallery.dto.ImageUploadRequest;
import it.zaninifrancesco.minio_gallery.dto.MessageResponse;
import it.zaninifrancesco.minio_gallery.service.ImageService;
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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Controller REST per la gestione delle immagini
 * Fornisce endpoint per upload, visualizzazione, ricerca ed eliminazione delle immagini
 */
@RestController
@RequestMapping("/api/images")
@Tag(name = "Gestione Immagini", description = "API per l'upload, visualizzazione e gestione delle immagini")
public class ImageController {
    
    private static final Logger logger = LoggerFactory.getLogger(ImageController.class);
    
    @Autowired
    private ImageService imageService;
    
    /**
     * Upload di una nuova immagine
     * POST /api/images
     */
    @PostMapping
    @Operation(summary = "Upload immagine", 
               description = "Carica una nuova immagine nel sistema con titolo, descrizione e tags opzionali")
    @SecurityRequirement(name = "Bearer Authentication")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Immagine caricata con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = ImageResponse.class))),
        @ApiResponse(responseCode = "400", description = "File non valido o dati mancanti",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Invalid file format\"}"))),
        @ApiResponse(responseCode = "401", description = "Non autorizzato",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Unauthorized\"}")))
    })
    public ResponseEntity<?> uploadImage(
            @Parameter(description = "File immagine da caricare", required = true)
            @RequestParam("file") MultipartFile file,
            @Parameter(description = "Titolo dell'immagine", required = true)
            @RequestParam("title") String title,
            @Parameter(description = "Descrizione dell'immagine (opzionale)")
            @RequestParam(value = "description", required = false) String description,
            @Parameter(description = "Lista di tags per l'immagine (opzionale)")
            @RequestParam(value = "tags", required = false) List<String> tags) {
        
        try {
            // Ottieni l'utente autenticato
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            logger.info("Upload request from user: {} for file: {}", username, file.getOriginalFilename());
            
            // Crea il DTO con i metadati
            ImageUploadRequest uploadRequest = new ImageUploadRequest(title, description, tags);
            
            // Carica l'immagine
            ImageResponse response = imageService.uploadImage(file, uploadRequest, username);
            
            logger.info("Image uploaded successfully with ID: {}", response.getId());
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
            
        } catch (IllegalArgumentException e) {
            logger.warn("Validation error during image upload: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            logger.error("Error uploading image", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to upload image: " + e.getMessage()));
        }
    }
    
    /**
     * Ottieni tutte le immagini con paginazione
     * GET /api/images?page=0&size=12
     */
    @GetMapping
    @Operation(summary = "Lista immagini", 
               description = "Recupera tutte le immagini pubbliche con paginazione")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Lista immagini recuperata con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = Page.class))),
        @ApiResponse(responseCode = "500", description = "Errore interno del server",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Failed to fetch images\"}")))
    })
    public ResponseEntity<?> getAllImages(
            @Parameter(description = "Numero della pagina (inizia da 0)", example = "0")
            @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Numero di elementi per pagina", example = "12")
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            logger.info("Fetching all images - page: {}, size: {}", page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.getAllImages(pageable);
            
            logger.info("Retrieved {} images out of {} total", images.getNumberOfElements(), images.getTotalElements());
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error fetching images", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch images: " + e.getMessage()));
        }
    }
    
    /**
     * Ottieni le immagini dell'utente corrente
     * GET /api/images/my
     */
    @GetMapping("/my")
    public ResponseEntity<?> getMyImages(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            // Ottieni l'utente autenticato
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            logger.info("Fetching images for user: {} - page: {}, size: {}", username, page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.getUserImages(username, pageable);
            
            logger.info("Retrieved {} images for user {}", images.getNumberOfElements(), username);
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error fetching user images", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch your images: " + e.getMessage()));
        }
    }
    
    /**
     * Ottieni immagini di un utente specifico
     * GET /api/images/user/{username}
     */
    @GetMapping("/user/{username}")
    public ResponseEntity<?> getUserImages(
            @PathVariable String username,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            logger.info("Fetching images for user: {} - page: {}, size: {}", username, page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.getUserImages(username, pageable);
            
            logger.info("Retrieved {} images for user {}", images.getNumberOfElements(), username);
            
            return ResponseEntity.ok(images);
            
        } catch (RuntimeException e) {
            logger.warn("User not found: {}", username);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("Error fetching user images", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch user images: " + e.getMessage()));
        }
    }
    
    /**
     * Ottieni una singola immagine per ID
     * GET /api/images/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getImageById(@PathVariable UUID id) {
        try {
            logger.info("Fetching image with ID: {}", id);
            
            ImageResponse image = imageService.getImageById(id);
            
            return ResponseEntity.ok(image);
            
        } catch (RuntimeException e) {
            logger.warn("Image not found with ID: {}", id);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("Error fetching image with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch image: " + e.getMessage()));
        }
    }
    
    /**
     * Cerca immagini per testo (titolo o descrizione)
     * GET /api/images/search?query=landscape&page=0&size=12
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchImages(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            logger.info("Searching images with query: '{}' - page: {}, size: {}", query, page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.searchImages(query, pageable);
            
            logger.info("Found {} images matching query '{}'", images.getNumberOfElements(), query);
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error searching images", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to search images: " + e.getMessage()));
        }
    }
    
    /**
     * Cerca immagini per tag
     * GET /api/images/search/tags?tags=nature,landscape&page=0&size=12
     */
    @GetMapping("/search/tags")
    public ResponseEntity<?> searchImagesByTags(
            @RequestParam List<String> tags,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            logger.info("Searching images with tags: {} - page: {}, size: {}", tags, page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.searchImagesByTags(tags, pageable);
            
            logger.info("Found {} images matching tags {}", images.getNumberOfElements(), tags);
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error searching images by tags", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to search images by tags: " + e.getMessage()));
        }
    }
    
    /**
     * Cerca immagini dell'utente corrente per tag
     * GET /api/images/my/search/tags?tags=nature,landscape&page=0&size=12
     */
    @GetMapping("/my/search/tags")
    public ResponseEntity<?> searchMyImagesByTags(
            @RequestParam List<String> tags,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            // Ottieni l'utente autenticato
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            logger.info("Searching user images with tags: {} for user: {} - page: {}, size: {}", tags, username, page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.searchUserImagesByTags(username, tags, pageable);
            
            logger.info("Found {} images matching tags {} for user {}", images.getNumberOfElements(), tags, username);
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error searching user images by tags", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to search your images by tags: " + e.getMessage()));
        }
    }
    
    /**
     * Cerca immagini dell'utente corrente per testo (titolo o descrizione)
     * GET /api/images/my/search?query=landscape&page=0&size=12
     */
    @GetMapping("/my/search")
    public ResponseEntity<?> searchMyImages(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {
        
        try {
            // Ottieni l'utente autenticato
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            logger.info("Searching user images with query: '{}' for user: {} - page: {}, size: {}", query, username, page, size);
            
            Pageable pageable = PageRequest.of(page, size);
            Page<ImageResponse> images = imageService.searchUserImages(username, query, pageable);
            
            logger.info("Found {} images matching query '{}' for user {}", images.getNumberOfElements(), query, username);
            
            return ResponseEntity.ok(images);
            
        } catch (Exception e) {
            logger.error("Error searching user images", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to search your images: " + e.getMessage()));
        }
    }
    
    /**
     * Elimina un'immagine (solo il proprietario può farlo)
     * DELETE /api/images/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteImage(@PathVariable UUID id) {
        try {
            // Ottieni l'utente autenticato
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            
            logger.info("Delete request from user: {} for image ID: {}", username, id);
            
            imageService.deleteImage(id, username);
            
            logger.info("Image deleted successfully: {}", id);
            
            return ResponseEntity.ok(new MessageResponse("Image deleted successfully"));
            
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                logger.warn("Image not found for deletion: {}", id);
                return ResponseEntity.notFound().build();
            } else if (e.getMessage().contains("Access denied")) {
                logger.warn("Access denied for user {} trying to delete image {}", 
                           SecurityContextHolder.getContext().getAuthentication().getName(), id);
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Access denied: You can only delete your own images"));
            } else {
                logger.error("Error deleting image: {}", id, e);
                return ResponseEntity.badRequest()
                        .body(Map.of("error", e.getMessage()));
            }
        } catch (Exception e) {
            logger.error("Error deleting image: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to delete image: " + e.getMessage()));
        }
    }
}
