# Backend Architecture - MinioGallery

## Panoramica del Sistema di Autenticazione

Il backend di MinioGallery utilizza **Spring Boot** con **Spring Security** e **JWT** per implementare un sistema di autenticazione sicuro e stateless. L'architettura segue il pattern MVC (Model-View-Controller) con separazione delle responsabilità.

---

## 📁 Struttura del Progetto

```
src/main/java/it/zaninifrancesco/minio_gallery/
├── config/          # Configurazioni di sicurezza
├── controller/      # Controller REST per gli endpoint
├── dto/            # Data Transfer Objects
├── entity/         # Entità JPA per il database
├── repository/     # Repository per l'accesso ai dati
├── service/        # Logica di business
├── util/           # Utility classes (JWT)
└── MinioGalleryApplication.java
```

---

## 🏗️ Architettura delle Classi

### **1. Entità (Entity Layer)**

#### `User.java`
**Ruolo:** Rappresenta l'entità utente nel database.

**Responsabilità:**
- Definisce la struttura della tabella `users` nel database PostgreSQL
- Implementa `UserDetails` di Spring Security per l'integrazione con il sistema di autenticazione
- Gestisce i campi: id, username, email, password (hashata), ruolo, date di creazione/modifica
- Fornisce validazioni automatiche tramite annotazioni (`@NotBlank`, `@Email`, `@Size`)

**Caratteristiche chiave:**
- Password mai salvate in chiaro (hashate con BCrypt)
- Supporto per ruoli (USER, ADMIN)
- Integrazione diretta con Spring Security
- Gestione automatica delle date con `@PrePersist` e `@PreUpdate`

---

### **2. Repository Layer**

#### `UserRepository.java`
**Ruolo:** Interfaccia per l'accesso ai dati degli utenti.

**Responsabilità:**
- Estende `JpaRepository` per operazioni CRUD automatiche
- Fornisce metodi personalizzati per trovare utenti per username/email
- Verifica esistenza di username/email per prevenire duplicati

**Metodi principali:**
```java
Optional<User> findByUsername(String username);
Optional<User> findByEmail(String email);
boolean existsByUsername(String username);
boolean existsByEmail(String email);
```

---

### **3. DTO (Data Transfer Objects)**

#### `RegisterRequest.java`
**Ruolo:** DTO per la richiesta di registrazione.
- Contiene: username, email, password
- Validazioni: campi obbligatori, formato email, lunghezza password

#### `LoginRequest.java`
**Ruolo:** DTO per la richiesta di login.
- Contiene: username, password
- Validazioni: campi obbligatori

#### `AuthResponse.java`
**Ruolo:** DTO per la risposta di autenticazione.
- Contiene: JWT token, refresh token, username, email, ruolo
- Inviato dopo login/registrazione di successo

#### `UserResponse.java`
**Ruolo:** DTO per le informazioni del profilo utente.
- Contiene: id, username, email, ruolo, createdAt
- **NON** contiene la password (sicurezza)

---

### **4. Service Layer**

#### `AuthService.java`
**Ruolo:** Logica di business per l'autenticazione.

**Responsabilità:**
- **Registrazione:** Valida dati, hash password, salva utente, genera JWT
- **Login:** Autentica credenziali, genera JWT token
- **Refresh Token:** Rinnova token scaduti
- **Profilo:** Recupera informazioni utente autenticato

**Flusso di registrazione:**
1. Verifica che username/email non esistano già
2. Hash della password con BCrypt
3. Salva utente nel database
4. Genera JWT token
5. Restituisce AuthResponse con token

**Flusso di login:**
1. Autentica username/password tramite AuthenticationManager
2. Se valide, genera JWT token
3. Restituisce AuthResponse con token

#### `CustomUserDetailsService.java`
**Ruolo:** Implementazione personalizzata di `UserDetailsService`.

**Responsabilità:**
- Carica i dettagli dell'utente dal database per Spring Security
- Converte l'entità `User` in un oggetto `UserDetails`
- Utilizzato da Spring Security durante l'autenticazione

#### `JwtService.java` (se esiste) o `JwtUtil.java`
**Ruolo:** Gestione dei token JWT.

**Responsabilità:**
- Generazione di token JWT con username e scadenza
- Validazione dei token (firma, scadenza)
- Estrazione delle informazioni dal token (username, scadenza)
- Firma dei token con chiave segreta

---

### **5. Controller Layer**

#### `AuthController.java`
**Ruolo:** Controller REST per gli endpoint di autenticazione.

**Endpoints:**
- `POST /api/auth/register` - Registrazione nuovo utente
- `POST /api/auth/login` - Login utente esistente
- `POST /api/auth/refresh` - Rinnovo token
- `GET /api/auth/profile` - Profilo utente (protetto)
- `POST /api/auth/logout` - Logout (client-side con JWT)

**Caratteristiche:**
- Validazione automatica dei DTO con `@Valid`
- Gestione degli errori con try-catch
- Risposta unificata con `ResponseEntity`

#### `TestController.java`
**Ruolo:** Controller per test di connettività.
- Endpoint `/api/test` pubblico per verificare che il backend funzioni

---

### **6. Configuration Layer**

#### `SecurityConfig.java`
**Ruolo:** Configurazione centrale di Spring Security.

**Responsabilità:**
- **CSRF:** Disabilitato (usiamo JWT)
- **Autorizzazioni:** `/api/auth/**` pubblico, tutto il resto protetto
- **Sessioni:** STATELESS (no sessioni server-side)
- **CORS:** Configurato per frontend
- **Filtri:** Aggiunge `JwtAuthenticationFilter` prima del filtro standard
- **Provider:** Configura `DaoAuthenticationProvider` con `CustomUserDetailsService`
- **Password Encoder:** Configura BCrypt per hash delle password

**Configurazione chiave:**
```java
.requestMatchers("/api/test", "/api/auth/**").permitAll() // Pubblici
.anyRequest().authenticated() // Tutto il resto richiede autenticazione
```

#### `JwtAuthenticationFilter.java`
**Ruolo:** Filtro personalizzato per validare JWT token.

**Responsabilità:**
- Intercetta ogni richiesta HTTP
- Estrae il token dall'header `Authorization: Bearer <token>`
- Valida il token con `JwtUtil`
- Se valido, imposta l'autenticazione nel `SecurityContext`
- Permette alla richiesta di proseguire

**Flusso:**
1. Estrae token dall'header
2. Valida token e estrae username
3. Carica `UserDetails` dal database
4. Crea `Authentication` e lo imposta nel context
5. Spring Security autorizza la richiesta

---

### **7. Utility Layer**

#### `JwtUtil.java`
**Ruolo:** Utility per la gestione dei token JWT.

**Metodi principali:**
- `generateToken(String username)` - Genera nuovo token
- `validateToken(String token)` - Valida token
- `extractUsername(String token)` - Estrae username dal token
- `extractExpiration(String token)` - Estrae scadenza dal token

**Configurazione JWT:**
- Algoritmo: HS256
- Scadenza: 24 ore (configurabile)
- Chiave segreta: da `application.properties`

---

### **8. Application Entry Point**

#### `MinioGalleryApplication.java`
**Ruolo:** Classe principale dell'applicazione Spring Boot.
- Punto di ingresso con `main()` method
- Annotazione `@SpringBootApplication` per auto-configurazione

---

## 🔄 Flusso Completo di Autenticazione

### **Registrazione:**
1. `AuthController.register()` riceve `RegisterRequest`
2. `AuthService.register()` valida e salva utente
3. Password hashata con BCrypt
4. `JwtUtil.generateToken()` crea JWT
5. Restituisce `AuthResponse` con token

### **Login:**
1. `AuthController.login()` riceve `LoginRequest`
2. `AuthService.login()` autentica tramite `AuthenticationManager`
3. `CustomUserDetailsService` carica utente dal DB
4. Se credenziali corrette, `JwtUtil.generateToken()` crea JWT
5. Restituisce `AuthResponse` con token

### **Richiesta Protetta:**
1. Client invia richiesta con `Authorization: Bearer <token>`
2. `JwtAuthenticationFilter` intercetta richiesta
3. `JwtUtil.validateToken()` valida token
4. Se valido, `SecurityContext` viene popolato
5. `SecurityConfig` autorizza l'accesso
6. Controller elabora richiesta

---

## 🔒 Sicurezza

- **Password:** Mai salvate in chiaro, sempre hashate con BCrypt
- **JWT:** Stateless, firmati con chiave segreta
- **CORS:** Configurato per frontend
- **Validazioni:** Automatiche sui DTO
- **Autorizzazioni:** Endpoint pubblici vs protetti
- **Sessioni:** Disabilitate (stateless)

---

## 📝 Configurazione

### `application.properties`
```properties
# Database PostgreSQL
spring.datasource.url=jdbc:postgresql://localhost:5432/minio_gallery_db
spring.datasource.username=zaninifrancesco
spring.datasource.password=Divano147!

# JWT
jwt.secret=mySecretKey123456789012345678901234567890
jwt.expiration=86400000  # 24 ore in millisecondi
```

---

## 🧪 Testing

### Endpoints disponibili:
- **Pubblici:** `/api/test`, `/api/auth/**`
- **Protetti:** Tutti gli altri (richiedono JWT token)

### Test flow:
1. Registra utente → ottieni token
2. Login → ottieni token
3. Usa token per endpoint protetti (`/api/auth/profile`)

---

Questa architettura garantisce un sistema di autenticazione **sicuro**, **scalabile** e **manutenibile** seguendo le best practice di Spring Security e JWT.
