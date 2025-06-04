package it.zaninifrancesco.minio_gallery.repository;

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
public interface ImageMetadataRepository extends JpaRepository<ImageMetadata, UUID> {
    
    /**
     * Trova tutte le immagini ordinate per data di upload (più recenti per prime)
     */
    Page<ImageMetadata> findAllByOrderByUploadedAtDesc(Pageable pageable);
    
    /**
     * Trova le immagini di un utente specifico ordinate per data di upload
     */
    Page<ImageMetadata> findByUserOrderByUploadedAtDesc(User user, Pageable pageable);
    
    /**
     * Trova le immagini di un utente specifico per ID
     */
    Page<ImageMetadata> findByUserIdOrderByUploadedAtDesc(Long userId, Pageable pageable);
    
    /**
     * Trova un'immagine per nome file
     */
    Optional<ImageMetadata> findByFileName(String fileName);
    
    /**
     * Verifica se esiste un'immagine con il nome file specificato
     */
    boolean existsByFileName(String fileName);
    
    /**
     * Trova tutte le immagini che hanno un tag specifico
     */
    @Query("SELECT DISTINCT im FROM ImageMetadata im JOIN im.tags t WHERE t.name = :tagName ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByTagName(@Param("tagName") String tagName, Pageable pageable);
    
    /**
     * Trova tutte le immagini che hanno tutti i tag specificati (AND logic)
     */
    @Query("SELECT im FROM ImageMetadata im JOIN im.tags t WHERE t.name IN :tagNames " +
           "GROUP BY im HAVING COUNT(DISTINCT t.name) = :tagCount ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByAllTags(@Param("tagNames") List<String> tagNames, 
                                      @Param("tagCount") long tagCount, 
                                      Pageable pageable);
    
    /**
     * Trova tutte le immagini che hanno almeno uno dei tag specificati (OR logic)
     */
    @Query("SELECT DISTINCT im FROM ImageMetadata im JOIN im.tags t WHERE t.name IN :tagNames ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByAnyTags(@Param("tagNames") List<String> tagNames, Pageable pageable);
    
    /**
     * Cerca immagini per titolo (case-insensitive, partial match)
     */
    @Query("SELECT im FROM ImageMetadata im WHERE LOWER(im.title) LIKE LOWER(CONCAT('%', :title, '%')) ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByTitleContainingIgnoreCase(@Param("title") String title, Pageable pageable);
    
    /**
     * Cerca immagini per titolo o descrizione (case-insensitive, partial match)
     */
    @Query("SELECT im FROM ImageMetadata im WHERE LOWER(im.title) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(im.description) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByTitleOrDescriptionContainingIgnoreCase(@Param("query") String query, Pageable pageable);
    
    /**
     * Conta il numero totale di immagini di un utente
     */
    long countByUserId(Long userId);
    
    /**
     * Conta il numero totale di immagini nel sistema
     */
    @Query("SELECT COUNT(im) FROM ImageMetadata im")
    long countTotalImages();
    
    /**
     * Trova le immagini più recenti (limite specificato)
     */
    List<ImageMetadata> findTop10ByOrderByUploadedAtDesc();
    
    /**
     * Trova immagini per tipo di contenuto
     */
    Page<ImageMetadata> findByContentTypeOrderByUploadedAtDesc(String contentType, Pageable pageable);
    
    /**
     * Trova immagini dell'utente che hanno almeno uno dei tag specificati (OR logic)
     */
    @Query("SELECT DISTINCT im FROM ImageMetadata im JOIN im.tags t WHERE im.user = :user AND t.name IN :tagNames ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByUserAndAnyTags(@Param("user") User user, @Param("tagNames") List<String> tagNames, Pageable pageable);
    
    /**
     * Cerca immagini dell'utente per titolo o descrizione (case-insensitive, partial match)
     */
    @Query("SELECT im FROM ImageMetadata im WHERE im.user = :user AND (LOWER(im.title) LIKE LOWER(CONCAT('%', :query, '%')) " +
           "OR LOWER(im.description) LIKE LOWER(CONCAT('%', :query, '%'))) ORDER BY im.uploadedAt DESC")
    Page<ImageMetadata> findByUserAndTitleOrDescriptionContainingIgnoreCase(@Param("user") User user, @Param("query") String query, Pageable pageable);
    
    /**
     * Calcola la dimensione totale di tutte le immagini nel sistema
     */
    @Query("SELECT COALESCE(SUM(im.size), 0) FROM ImageMetadata im")
    long getTotalImageSize();
}
