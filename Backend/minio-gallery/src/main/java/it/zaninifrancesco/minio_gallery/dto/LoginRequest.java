package it.zaninifrancesco.minio_gallery.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "Richiesta di login utente")
public class LoginRequest {
    
    @Schema(description = "Nome utente (alternativo a email)", example = "mario.rossi")
    private String username;
    
    @NotBlank(message = "Password is required")
    @Schema(description = "Password dell'utente", example = "password123", required = true)
    private String password;

    @Schema(description = "Email utente (alternativo a username)", example = "mario.rossi@example.com")
    private String email; 
    
    // Constructors
    public LoginRequest() {}
    
    public LoginRequest(String username, String password, String email) {
        this.username = username;
        this.password = password;
        this.email = email;
    }
    
    // Getters and Setters
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }

}
