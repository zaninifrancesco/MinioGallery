package it.zaninifrancesco.minio_gallery.service;

import it.zaninifrancesco.minio_gallery.dto.ImageResponse;
import it.zaninifrancesco.minio_gallery.dto.ImageUploadRequest;
import it.zaninifrancesco.minio_gallery.entity.ImageMetadata;
import it.zaninifrancesco.minio_gallery.entity.Tag;
import it.zaninifrancesco.minio_gallery.entity.User;
import it.zaninifrancesco.minio_gallery.repository.ImageMetadataRepository;
import it.zaninifrancesco.minio_gallery.repository.TagRepository;
import it.zaninifrancesco.minio_gallery.repository.UserRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Service per la gestione delle operazioni sulle immagini
 * Coordina le operazioni tra ImageMetadataRepository e MinioService
 */
@Service
@Transactional
public class ImageService {
    
    private static final Logger logger = LoggerFactory.getLogger(ImageService.class);
    
    // Tipi di file supportati
    private static final Set<String> SUPPORTED_CONTENT_TYPES = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"
    );
    
    // Dimensione massima file: 5MB
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024;
    
    @Autowired
    private ImageMetadataRepository imageMetadataRepository;
    
    @Autowired
    private TagRepository tagRepository;
      @Autowired
    private UserRepository userRepository;
      @Autowired
    private MinioService minioService;
    
    @Autowired
    private LikeService likeService;
    
    /**
     * Carica un'immagine con i suoi metadati
     * 
     * @param file il file immagine
     * @param uploadRequest i metadati dell'immagine
     * @param username il nome utente che carica l'immagine
     * @return ImageResponse con i dettagli dell'immagine caricata
     * @throws RuntimeException se il caricamento fallisce
     */
    public ImageResponse uploadImage(MultipartFile file, ImageUploadRequest uploadRequest, String username) {
        logger.info("Starting image upload for user: {}", username);
        
        // Validazioni
        validateFile(file);
        validateUploadRequest(uploadRequest);
        
        // Trova l'utente
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));
        
        try {
            // Genera nome file univoco
            String fileExtension = getFileExtension(file.getOriginalFilename());
            String fileName = UUID.randomUUID().toString() + fileExtension;
            
            // Carica su MinIO
            boolean uploaded = minioService.uploadFile(file, fileName);
            if (!uploaded) {
                throw new RuntimeException("Failed to upload file to MinIO");
            }
            
            logger.info("File uploaded to MinIO successfully: {}", fileName);
            
            // Crea metadati immagine
            ImageMetadata imageMetadata = new ImageMetadata(
                    uploadRequest.getTitle(), 
                    fileName, 
                    minioService.getBucketName(), 
                    user
            );
            
            imageMetadata.setDescription(uploadRequest.getDescription());
            imageMetadata.setOriginalFileName(file.getOriginalFilename());
            imageMetadata.setContentType(file.getContentType());
            imageMetadata.setSize(file.getSize());
            
            // Gestisci i tag
            if (uploadRequest.getTags() != null && !uploadRequest.getTags().isEmpty()) {
                Set<Tag> tags = processTagsForImage(uploadRequest.getTags());
                imageMetadata.setTags(tags);
            }
            
            // Salva nel database
            imageMetadata = imageMetadataRepository.save(imageMetadata);
            
            logger.info("Image metadata saved successfully with ID: {}", imageMetadata.getId());
            
            // Crea e restituisci la risposta
            return createImageResponse(imageMetadata);
            
        } catch (Exception e) {
            logger.error("Error uploading image for user: {}", username, e);
            // In caso di errore, prova a eliminare il file da MinIO se era stato caricato
            // (questo è un best effort cleanup)
            throw new RuntimeException("Failed to upload image: " + e.getMessage(), e);
        }
    }
    
    /**
     * Ottiene tutte le immagini con paginazione
     */
    public Page<ImageResponse> getAllImages(Pageable pageable) {
        Page<ImageMetadata> imagePage = imageMetadataRepository.findAllByOrderByUploadedAtDesc(pageable);
        return imagePage.map(this::createImageResponse);
    }
    
    /**
     * Ottiene le immagini di un utente specifico
     */
    public Page<ImageResponse> getUserImages(String username, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));
        
        Page<ImageMetadata> imagePage = imageMetadataRepository.findByUserOrderByUploadedAtDesc(user, pageable);
        return imagePage.map(this::createImageResponse);
    }
    
    /**
     * Ottiene un'immagine per ID
     */
    public ImageResponse getImageById(UUID imageId) {
        ImageMetadata imageMetadata = imageMetadataRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found: " + imageId));
        
        return createImageResponse(imageMetadata);
    }
    
    /**
     * Cerca immagini per tag
     */
    public Page<ImageResponse> searchImagesByTags(List<String> tagNames, Pageable pageable) {
        Page<ImageMetadata> imagePage = imageMetadataRepository.findByAnyTags(tagNames, pageable);
        return imagePage.map(this::createImageResponse);
    }
    
    /**
     * Cerca immagini per titolo o descrizione
     */
    public Page<ImageResponse> searchImages(String query, Pageable pageable) {
        Page<ImageMetadata> imagePage = imageMetadataRepository.findByTitleOrDescriptionContainingIgnoreCase(query, pageable);
        return imagePage.map(this::createImageResponse);
    }
    
    /**
     * Cerca immagini dell'utente corrente per tag
     */
    public Page<ImageResponse> searchUserImagesByTags(String username, List<String> tagNames, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));
        
        Page<ImageMetadata> imagePage = imageMetadataRepository.findByUserAndAnyTags(user, tagNames, pageable);
        return imagePage.map(this::createImageResponse);
    }
    
    /**
     * Cerca immagini dell'utente corrente per titolo o descrizione
     */
    public Page<ImageResponse> searchUserImages(String username, String query, Pageable pageable) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));
        
        Page<ImageMetadata> imagePage = imageMetadataRepository.findByUserAndTitleOrDescriptionContainingIgnoreCase(user, query, pageable);
        return imagePage.map(this::createImageResponse);
    }
    
    /**
     * Elimina un'immagine (solo il proprietario può farlo)
     */
    public void deleteImage(UUID imageId, String username) {
        ImageMetadata imageMetadata = imageMetadataRepository.findById(imageId)
                .orElseThrow(() -> new RuntimeException("Image not found: " + imageId));
        
        // Verifica che l'utente sia il proprietario
        if (!imageMetadata.getUser().getUsername().equals(username)) {
            throw new RuntimeException("Access denied: You can only delete your own images");
        }
        
        try {
            // Elimina da MinIO
            boolean deleted = minioService.deleteFile(imageMetadata.getFileName());
            if (!deleted) {
                logger.warn("Failed to delete file from MinIO: {}", imageMetadata.getFileName());
            }
            
            // Elimina dal database
            imageMetadataRepository.delete(imageMetadata);
            
            logger.info("Image deleted successfully: {}", imageId);
            
        } catch (Exception e) {
            logger.error("Error deleting image: {}", imageId, e);
            throw new RuntimeException("Failed to delete image: " + e.getMessage(), e);
        }
    }
    
    /**
     * Valida il file caricato
     */
    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is required");
        }
        
        if (!SUPPORTED_CONTENT_TYPES.contains(file.getContentType())) {
            throw new IllegalArgumentException("Unsupported file type. Supported types: " + SUPPORTED_CONTENT_TYPES);
        }
        
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("File size exceeds maximum limit of 5MB");
        }
    }
    
    /**
     * Valida la richiesta di upload
     */
    private void validateUploadRequest(ImageUploadRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("Upload request is required");
        }
        
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Title is required");
        }
    }
    
    /**
     * Estrae l'estensione dal nome file
     */
    private String getFileExtension(String fileName) {
        if (fileName == null || !fileName.contains(".")) {
            return ".jpg"; // default extension
        }
        return fileName.substring(fileName.lastIndexOf("."));
    }
    
    /**
     * Processa i tag per un'immagine, creando nuovi tag se necessario
     */
    private Set<Tag> processTagsForImage(List<String> tagNames) {
        Set<Tag> tags = new HashSet<>();
        
        if (tagNames == null || tagNames.isEmpty()) {
            return tags;
        }
        
        // Normalizza i nomi dei tag (trim e lowercase per la ricerca)
        Set<String> normalizedTagNames = tagNames.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(name -> !name.isEmpty())
                .map(String::toLowerCase)
                .collect(Collectors.toSet());
        
        // Trova tag esistenti
        List<Tag> existingTags = tagRepository.findByNamesIgnoreCase(normalizedTagNames);
        tags.addAll(existingTags);
        
        // Identifica tag da creare
        Set<String> existingTagNames = existingTags.stream()
                .map(tag -> tag.getName().toLowerCase())
                .collect(Collectors.toSet());
        
        Set<String> tagsToCreate = normalizedTagNames.stream()
                .filter(name -> !existingTagNames.contains(name))
                .collect(Collectors.toSet());
        
        // Crea nuovi tag
        for (String tagName : tagsToCreate) {
            Tag newTag = new Tag(tagName);
            tags.add(tagRepository.save(newTag));
        }
        
        return tags;
    }
      /**
     * Crea un ImageResponse da un ImageMetadata
     */
    private ImageResponse createImageResponse(ImageMetadata imageMetadata) {
        // Genera URL presigned per l'immagine (validità: 30 minuti)
        String imageUrl = minioService.generatePresignedUrl(imageMetadata.getFileName(), 30);
        
        // Estrai nomi dei tag
        List<String> tagNames = imageMetadata.getTags().stream()
                .map(Tag::getName)
                .sorted()
                .collect(Collectors.toList());
        
        // Ottieni like count
        int likeCount = imageMetadata.getLikeCount();
        
        // Determina se l'utente corrente ha messo like
        boolean isLikedByCurrentUser = false;
        try {
            // Ottieni l'utente autenticato corrente
            String currentUsername = SecurityContextHolder.getContext().getAuthentication().getName();
            if (currentUsername != null && !currentUsername.equals("anonymousUser")) {
                isLikedByCurrentUser = likeService.isLikedByUser(imageMetadata.getId(), currentUsername);
            }
        } catch (Exception e) {
            // Se non c'è un utente autenticato o si verifica un errore, 
            // isLikedByCurrentUser rimane false
        }
        
        ImageResponse response = new ImageResponse(
                imageMetadata.getId(),
                imageMetadata.getTitle(),
                imageMetadata.getDescription(),
                imageMetadata.getFileName(),
                imageMetadata.getOriginalFileName(),
                imageMetadata.getContentType(),
                imageMetadata.getSize(),
                imageUrl,
                tagNames,
                imageMetadata.getUser().getUsername(),
                imageMetadata.getUploadedAt()
        );
        
        // Imposta le informazioni sui like
        response.setLikeCount(likeCount);
        response.setLikedByCurrentUser(isLikedByCurrentUser);
        
        return response;
    }
    
    /**
     * Ottiene il nome del bucket MinIO (helper method)
     */
    public String getBucketName() {
        return minioService.getBucketName();
    }
}
