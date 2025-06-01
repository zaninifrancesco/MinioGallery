package it.zaninifrancesco.minio_gallery.repository;

import it.zaninifrancesco.minio_gallery.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface TagRepository extends JpaRepository<Tag, Long> {
    
    /**
     * Trova un tag per nome (case-insensitive)
     */
    Optional<Tag> findByNameIgnoreCase(String name);
    
    /**
     * Verifica se esiste un tag con il nome specificato (case-insensitive)
     */
    boolean existsByNameIgnoreCase(String name);
    
    /**
     * Trova tutti i tag i cui nomi sono nella lista specificata (case-insensitive)
     */
    @Query("SELECT t FROM Tag t WHERE LOWER(t.name) IN :names")
    List<Tag> findByNamesIgnoreCase(@Param("names") Set<String> names);
    
    /**
     * Trova i tag più popolari (con più immagini associate)
     */
    @Query("SELECT t FROM Tag t LEFT JOIN t.images i GROUP BY t ORDER BY COUNT(i) DESC")
    List<Tag> findMostPopularTags();
    
    /**
     * Trova i tag più popolari limitati ad un numero specifico
     */
    @Query("SELECT t FROM Tag t LEFT JOIN t.images i GROUP BY t ORDER BY COUNT(i) DESC")
    List<Tag> findTopPopularTags(@Param("limit") int limit);
    
    /**
     * Conta il numero di immagini associate ad un tag
     */
    @Query("SELECT COUNT(i) FROM Tag t LEFT JOIN t.images i WHERE t.id = :tagId")
    Long countImagesByTagId(@Param("tagId") Long tagId);
    
    /**
     * Trova tag che contengono la stringa specificata nel nome (per autocompletamento)
     */
    @Query("SELECT t FROM Tag t WHERE LOWER(t.name) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY t.name")
    List<Tag> findByNameContainingIgnoreCase(@Param("query") String query);
}
