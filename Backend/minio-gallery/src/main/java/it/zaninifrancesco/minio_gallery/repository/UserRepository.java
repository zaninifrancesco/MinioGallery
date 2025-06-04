package it.zaninifrancesco.minio_gallery.repository;

import it.zaninifrancesco.minio_gallery.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByUsername(String username);
    
    Optional<User> findByEmail(String email);
    
    boolean existsByUsername(String username);
    
    boolean existsByEmail(String email);
    
    /**
     * Conta il numero totale di utenti attivi
     */
    @Query("SELECT COUNT(u) FROM User u WHERE u.enabled = true")
    long countActiveUsers();
    
    /**
     * Conta il numero totale di utenti inattivi
     */
    @Query("SELECT COUNT(u) FROM User u WHERE u.enabled = false")
    long countInactiveUsers();
    
    /**
     * Conta il numero totale di amministratori
     */
    @Query("SELECT COUNT(u) FROM User u WHERE u.role = 'ADMIN'")
    long countAdmins();
    
    /**
     * Conta gli utenti per ruolo
     */
    long countByRole(User.Role role);
    
    /**
     * Conta gli utenti abilitati
     */
    long countByEnabledTrue();
    
    /**
     * Conta gli utenti disabilitati
     */
    long countByEnabledFalse();
}
