package it.zaninifrancesco.minio_gallery.service;

import it.zaninifrancesco.minio_gallery.entity.User;
import it.zaninifrancesco.minio_gallery.repository.ImageLikeRepository;
import it.zaninifrancesco.minio_gallery.repository.ImageMetadataRepository;
import it.zaninifrancesco.minio_gallery.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * Service per statistiche pubbliche
 * Fornisce statistiche generali del sistema visibili a tutti
 */
@Service
public class StatisticsService {
    
    private static final Logger logger = LoggerFactory.getLogger(StatisticsService.class);
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ImageMetadataRepository imageMetadataRepository;
    
    @Autowired
    private ImageLikeRepository imageLikeRepository;
    
    /**
     * Ottiene statistiche pubbliche del sistema
     * Queste statistiche sono visibili a tutti senza autenticazione
     */
    public Map<String, Object> getPublicStats() {
        logger.info("Generating public statistics");
        
        Map<String, Object> stats = new HashMap<>();
        
        // Conteggio totale foto
        long totalPhotos = imageMetadataRepository.count();
        
        // Conteggio totale likes
        long totalLikes = imageLikeRepository.count();
        
        // Conteggio totale partecipanti (utenti attivi)
        long totalParticipants = userRepository.countByEnabledTrue();
        
        stats.put("totalPhotos", totalPhotos);
        stats.put("totalLikes", totalLikes);
        stats.put("totalParticipants", totalParticipants);
        
        logger.info("Public stats generated: {} photos, {} likes, {} participants", 
                   totalPhotos, totalLikes, totalParticipants);
        
        return stats;
    }
}
