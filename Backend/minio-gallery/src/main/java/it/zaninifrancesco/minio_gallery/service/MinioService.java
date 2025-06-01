package it.zaninifrancesco.minio_gallery.service;

import io.minio.*;
import io.minio.http.Method;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.util.concurrent.TimeUnit;

@Service
public class MinioService {
    
    private static final Logger logger = LoggerFactory.getLogger(MinioService.class);
    
    @Value("${minio.endpoint}")
    private String endpoint;
    
    @Value("${minio.access.key}")
    private String accessKey;
    
    @Value("${minio.secret.key}")
    private String secretKey;
    
    @Value("${minio.bucket.name}")
    private String bucketName;
    
    private MinioClient minioClient;
    
    @PostConstruct
    public void init() {
        try {
            // Inizializza il client MinIO
            minioClient = MinioClient.builder()
                    .endpoint(endpoint)
                    .credentials(accessKey, secretKey)
                    .build();
            
            // Verifica se il bucket esiste, altrimenti lo crea
            createBucketIfNotExists();
            
            logger.info("MinIO client initialized successfully with endpoint: {}", endpoint);
        } catch (Exception e) {
            logger.error("Failed to initialize MinIO client", e);
            throw new RuntimeException("Failed to initialize MinIO client", e);
        }
    }
    
    /**
     * Crea il bucket se non esiste
     */
    private void createBucketIfNotExists() {
        try {
            boolean bucketExists = minioClient.bucketExists(
                    BucketExistsArgs.builder()
                            .bucket(bucketName)
                            .build()
            );
            
            if (!bucketExists) {
                minioClient.makeBucket(
                        MakeBucketArgs.builder()
                                .bucket(bucketName)
                                .build()
                );
                logger.info("Created MinIO bucket: {}", bucketName);
            } else {
                logger.info("MinIO bucket already exists: {}", bucketName);
            }
        } catch (Exception e) {
            logger.error("Error checking/creating bucket: {}", bucketName, e);
            throw new RuntimeException("Error checking/creating bucket: " + bucketName, e);
        }
    }
    
    /**
     * Carica un file su MinIO
     *
     * @param file il file da caricare
     * @param fileName il nome del file su MinIO (deve essere univoco)
     * @return true se il caricamento è riuscito
     */
    public boolean uploadFile(MultipartFile file, String fileName) {
        try {
            InputStream inputStream = file.getInputStream();
            
            minioClient.putObject(
                    PutObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileName)
                            .stream(inputStream, file.getSize(), -1)
                            .contentType(file.getContentType())
                            .build()
            );
            
            logger.info("File uploaded successfully: {}", fileName);
            return true;
            
        } catch (Exception e) {
            logger.error("Error uploading file: {}", fileName, e);
            return false;
        }
    }
    
    /**
     * Carica un file su MinIO con metadati personalizzati
     *
     * @param inputStream stream del file
     * @param fileName nome del file
     * @param contentType tipo di contenuto
     * @param size dimensione del file
     * @return true se il caricamento è riuscito
     */
    public boolean uploadFile(InputStream inputStream, String fileName, String contentType, long size) {
        try {
            minioClient.putObject(
                    PutObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileName)
                            .stream(inputStream, size, -1)
                            .contentType(contentType)
                            .build()
            );
            
            logger.info("File uploaded successfully: {}", fileName);
            return true;
            
        } catch (Exception e) {
            logger.error("Error uploading file: {}", fileName, e);
            return false;
        }
    }
    
    /**
     * Genera un URL temporaneo (presigned) per accedere al file
     *
     * @param fileName nome del file
     * @param expiryMinutes durata in minuti della validità dell'URL
     * @return URL presigned per accedere al file
     */
    public String generatePresignedUrl(String fileName, int expiryMinutes) {
        try {
            return minioClient.getPresignedObjectUrl(
                    GetPresignedObjectUrlArgs.builder()
                            .method(Method.GET)
                            .bucket(bucketName)
                            .object(fileName)
                            .expiry(expiryMinutes, TimeUnit.MINUTES)
                            .build()
            );
        } catch (Exception e) {
            logger.error("Error generating presigned URL for file: {}", fileName, e);
            return null;
        }
    }
    
    /**
     * Genera un URL temporaneo con scadenza di default (5 minuti)
     *
     * @param fileName nome del file
     * @return URL presigned per accedere al file
     */
    public String generatePresignedUrl(String fileName) {
        return generatePresignedUrl(fileName, 5); // Default: 5 minuti
    }
    
    /**
     * Elimina un file da MinIO
     *
     * @param fileName nome del file da eliminare
     * @return true se l'eliminazione è riuscita
     */
    public boolean deleteFile(String fileName) {
        try {
            minioClient.removeObject(
                    RemoveObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileName)
                            .build()
            );
            
            logger.info("File deleted successfully: {}", fileName);
            return true;
            
        } catch (Exception e) {
            logger.error("Error deleting file: {}", fileName, e);
            return false;
        }
    }
    
    /**
     * Verifica se un file esiste su MinIO
     *
     * @param fileName nome del file
     * @return true se il file esiste
     */
    public boolean fileExists(String fileName) {
        try {
            minioClient.statObject(
                    StatObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileName)
                            .build()
            );
            return true;
        } catch (Exception e) {
            logger.debug("File does not exist: {}", fileName);
            return false;
        }
    }
    
    /**
     * Ottiene le informazioni di un file (metadati)
     *
     * @param fileName nome del file
     * @return oggetto StatObjectResponse con le informazioni del file
     */
    public ObjectStat getFileInfo(String fileName) {
        try {
            StatObjectResponse response = minioClient.statObject(
                    StatObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileName)
                            .build()
            );
            
            return new ObjectStat(
                    response.object(),
                    response.size(),
                    response.contentType(),
                    response.lastModified().toString(),
                    response.etag()
            );
        } catch (Exception e) {
            logger.error("Error getting file info: {}", fileName, e);
            return null;
        }
    }
    
    /**
     * Ottiene il nome del bucket configurato
     *
     * @return nome del bucket
     */
    public String getBucketName() {
        return bucketName;
    }
    
    /**
     * Classe per incapsulare le informazioni di un file
     */
    public static class ObjectStat {
        private final String objectName;
        private final long size;
        private final String contentType;
        private final String lastModified;
        private final String etag;
        
        public ObjectStat(String objectName, long size, String contentType, String lastModified, String etag) {
            this.objectName = objectName;
            this.size = size;
            this.contentType = contentType;
            this.lastModified = lastModified;
            this.etag = etag;
        }
        
        // Getters
        public String getObjectName() { return objectName; }
        public long getSize() { return size; }
        public String getContentType() { return contentType; }
        public String getLastModified() { return lastModified; }
        public String getEtag() { return etag; }
    }
}
