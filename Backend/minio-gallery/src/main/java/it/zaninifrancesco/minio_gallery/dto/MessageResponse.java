package it.zaninifrancesco.minio_gallery.dto;

/**
 * DTO per messaggi di risposta generici
 * Utilizzato per conferme di operazioni o messaggi di errore
 */
public class MessageResponse {
    
    private String message;
    private boolean success;
    private String timestamp;
    
    // Constructors
    public MessageResponse() {
        this.timestamp = java.time.LocalDateTime.now().toString();
    }
    
    public MessageResponse(String message) {
        this();
        this.message = message;
        this.success = true;
    }
    
    public MessageResponse(String message, boolean success) {
        this();
        this.message = message;
        this.success = success;
    }
    
    // Static factory methods for common responses
    public static MessageResponse success(String message) {
        return new MessageResponse(message, true);
    }
    
    public static MessageResponse error(String message) {
        return new MessageResponse(message, false);
    }
    
    // Getters and Setters
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public String getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }
    
    @Override
    public String toString() {
        return "MessageResponse{" +
                "message='" + message + '\'' +
                ", success=" + success +
                ", timestamp='" + timestamp + '\'' +
                '}';
    }
}
