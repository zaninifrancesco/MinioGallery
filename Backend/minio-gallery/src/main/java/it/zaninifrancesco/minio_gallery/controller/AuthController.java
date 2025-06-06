package it.zaninifrancesco.minio_gallery.controller;

import it.zaninifrancesco.minio_gallery.dto.*;
import it.zaninifrancesco.minio_gallery.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Autenticazione", description = "API per la gestione dell'autenticazione utenti")
public class AuthController {
    
    @Autowired
    private AuthService authService;
    
    @PostMapping("/register")
    @Operation(summary = "Registrazione utente", 
               description = "Registra un nuovo utente nel sistema")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Registrazione completata con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = AuthResponse.class))),
        @ApiResponse(responseCode = "400", description = "Dati di registrazione non validi",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Username already exists\"}")))
    })
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            AuthResponse response = authService.register(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @PostMapping("/login")
    @Operation(summary = "Login utente", 
               description = "Autentica l'utente e restituisce un JWT token")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Login effettuato con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = AuthResponse.class))),
        @ApiResponse(responseCode = "400", description = "Credenziali non valide",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Invalid username or password\"}")))
    })
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            // Validazione manuale dato che abbiamo rimosso @NotBlank da username
            if ((request.getUsername() == null || request.getUsername().trim().isEmpty()) && 
                (request.getEmail() == null || request.getEmail().trim().isEmpty())) {
                return ResponseEntity.badRequest()
                    .body(Map.of("error", "Username or email is required"));
            }
            
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Invalid username or password"));
        }
    }
    
    @PostMapping("/refresh")
    @Operation(summary = "Refresh token", 
               description = "Rinnova il JWT token utilizzando il refresh token")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Token rinnovato con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = AuthResponse.class))),
        @ApiResponse(responseCode = "400", description = "Refresh token non valido",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Invalid refresh token\"}")))
    })
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> request) {
        try {
            String refreshToken = request.get("refreshToken");
            AuthResponse response = authService.refreshToken(refreshToken);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/profile")
    @Operation(summary = "Profilo utente", 
               description = "Restituisce i dati del profilo dell'utente autenticato")
    @SecurityRequirement(name = "Bearer Authentication")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Profilo recuperato con successo",
                    content = @Content(mediaType = "application/json", 
                                     schema = @Schema(implementation = UserResponse.class))),
        @ApiResponse(responseCode = "401", description = "Non autorizzato",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"error\": \"Unauthorized\"}")))
    })
    public ResponseEntity<?> getUserProfile() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String username = authentication.getName();
            UserResponse response = authService.getUserProfile(username);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @PostMapping("/logout")
    @Operation(summary = "Logout utente", 
               description = "Effettua il logout dell'utente (in implementazione stateless JWT)")
    @SecurityRequirement(name = "Bearer Authentication")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Logout effettuato con successo",
                    content = @Content(mediaType = "application/json",
                                     examples = @ExampleObject(value = "{\"message\": \"Logged out successfully\"}")))
    })
    public ResponseEntity<?> logout() {
        // In a JWT stateless implementation, logout is handled client-side
        // by removing the token from storage
        return ResponseEntity.ok(Map.of("message", "Logged out successfully"));
    }
    
    @GetMapping("/users")
    public ResponseEntity<?> getAllUsers() {
        try {
            List<UserResponse> users = authService.getAllUsers();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
