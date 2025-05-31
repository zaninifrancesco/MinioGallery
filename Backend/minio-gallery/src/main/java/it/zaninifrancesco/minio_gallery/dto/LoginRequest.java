package it.zaninifrancesco.minio_gallery.dto;

import jakarta.validation.constraints.NotBlank;

public class LoginRequest {
    
    private String username;
    
    @NotBlank(message = "Password is required")
    private String password;

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
