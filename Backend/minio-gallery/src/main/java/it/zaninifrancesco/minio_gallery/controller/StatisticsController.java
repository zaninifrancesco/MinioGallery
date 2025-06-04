package it.zaninifrancesco.minio_gallery.controller;

import it.zaninifrancesco.minio_gallery.service.StatisticsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller REST per statistiche pubbliche
 * Accessibile a tutti senza autenticazione per la dashboard home
 */
@RestController
@RequestMapping("/api/statistics")
public class StatisticsController {
    
    private static final Logger logger = LoggerFactory.getLogger(StatisticsController.class);
    
    @Autowired
    private StatisticsService statisticsService;
    
    /**
     * Ottieni statistiche pubbliche per la dashboard home
     * GET /api/statistics/public
     */
    @GetMapping("/public")
    public ResponseEntity<?> getPublicStatistics() {
        try {
            logger.info("Fetching public statistics for home dashboard");
            
            Map<String, Object> stats = statisticsService.getPublicStats();
            
            logger.info("Public statistics generated: {} photos, {} likes, {} participants", 
                       stats.get("totalPhotos"), 
                       stats.get("totalLikes"), 
                       stats.get("totalParticipants"));
            
            return ResponseEntity.ok(stats);
            
        } catch (Exception e) {
            logger.error("Error fetching public statistics", e);
            return ResponseEntity.status(500).body(Map.of("error", "Internal server error"));
        }
    }
}
