## Feature Specifications

### Feature 1: Upload immagine

**Goal**  
Permettere agli utenti di caricare immagini, salvando i file su MinIO e i metadati su PostgreSQL.

**API relationships**  
* POST `/api/images`  
* MinIO SDK (upload file)  
* JPA Repository (salvataggio metadati)



### Detailed requirements

**Requirement A**  
Validazione lato frontend: solo file JPEG/PNG, dimensione < 5MB.

**Requirement B**  
Upload multipart: immagine + metadati (titolo, descrizione, tag opzionali)

**Requirement C**  
Generazione UUID per file e nome su MinIO

**Requirement D**  
Persistenza dei metadati con riferimento al file MinIO (path + bucket)

**Requirement E**  
Token JWT richiesto nel request header per autenticazione

---

### Implementation guide

#### Pseudocode (Upload backend)
POST /api/images

If (user not authenticated) → return 401

Parse multipart:
  file ← immagine
  metadata ← JSON (titolo, descrizione, tag)

Validate:
  file.type == JPEG || PNG
  file.size < 5MB

uuid ← generateUUID()
filename ← uuid + extension

Upload file to MinIO(bucket, filename)
Save metadata in DB (uuid, titolo, descrizione, tag, path)
Return 201 + JSON(metadata)

#### Data flow steps
1. Utente seleziona immagine + metadati via form Flutter
2. Flutter invia richiesta multipart a Spring Boot
3. Spring valida, salva su MinIO, registra su PostgreSQL
4. Backend risponde con ID immagine + conferma

#### Key edge cases
* Upload fallisce (MinIO down) → rollback transazione
* File non conforme → 400 Bad Request
* Token assente o non valido → 401 Unauthorized
* Duplicati UUID (teoricamente impossibili, ma va gestito)

---

### Feature 2: Galleria immagini

**Goal**  
Visualizzare tutte le immagini caricate, con metadati, in una galleria responsive.

**API relationships**  
* GET `/api/images?page=X&size=Y`  
* MinIO (serve URL per le immagini firmate temporanee, es. presigned URLs)

---

### Detailed requirements

**Requirement A**  
Recupero immagini paginato e ordinato per data di caricamento (DESC)

**Requirement B**  
Visualizzazione titolo, anteprima immagine, descrizione breve

**Requirement C**  
Presigned URL temporaneo (es. 5 minuti) per caricare immagine da MinIO

**Requirement D**  
Frontend responsive: griglia mobile e desktop

---

### Implementation guide

#### Pseudocode (Gallery backend)
GET /api/images?page=0&size=12

If (user not authenticated) → return 401

images ← DB.queryByPage(page, size, sortByDateDesc)

For each image:
  presignedUrl ← MinIO.generatePresignedUrl(filename, expiry=5min)

Return List<{
  id,
  titolo,
  descrizione,
  tag,
  uploadedAt,
  imageUrl
}>

#### Data flow steps
1. Flutter chiama API per recuperare elenco immagini
2. Spring carica dati + genera URL temporanei per ogni immagine
3. Flutter mostra immagini in griglia
4. Clic su immagine apre dettaglio (navigazione a schermo dedicato)

#### Key edge cases
* Token scaduto → richiede re-login
* Nessuna immagine → UI mostra messaggio amichevole
* URL MinIO scaduto → immagine non visibile, richiesta nuovo fetch

---

## Componenti Backend Spring Boot

Questa sezione descrive i principali componenti dell'applicazione backend Spring Boot.

### 1. Entità (Model - `it.zaninifrancesco.minio_gallery.model`)
Rappresentano i dati persistenti dell'applicazione.
*   **`User.java`**: Entità JPA per gli utenti. Contiene informazioni come `id`, `username`, `password` (hashed), e una relazione `ManyToMany` con `Role`.
*   **`Role.java`**: Entità JPA per i ruoli. Contiene `id` e `name` (che fa riferimento a `ERole`).
*   **`ERole.java`**: Enum che definisce i tipi di ruolo disponibili (es. `ROLE_USER`, `ROLE_ADMIN`).
*   **`ImageMetadata.java`**: (Da creare) Entità JPA per i metadati delle immagini. Includerà `id` (UUID), `title`, `description`, `tags` (potrebbe essere una lista di stringhe o una relazione separata), `fileName` (nome del file su MinIO, es. UUID + estensione), `bucketName`, `originalFileName`, `contentType`, `size`, `uploadTimestamp`, e una relazione `ManyToOne` con `User`.

### 2. Repository (Data Access Layer - `it.zaninifrancesco.minio_gallery.repository`)
Interfacce Spring Data JPA per interagire con il database.
*   **`UserRepository.java`**: (Da creare) Estende `JpaRepository<User, Long>`. Include metodi per trovare utenti per username, verificare l'esistenza per username, ecc.
*   **`RoleRepository.java`**: (Da creare) Estende `JpaRepository<Role, Integer>`. Include un metodo per trovare ruoli per nome (es. `findByName(ERole name)`).
*   **`ImageMetadataRepository.java`**: (Da creare) Estende `JpaRepository<ImageMetadata, String>` (o `UUID` se l'ID è di tipo UUID). Include metodi per la paginazione e l'ordinamento (es. per data di caricamento).

### 3. Servizi (Business Logic Layer - `it.zaninifrancesco.minio_gallery.service`)
Contengono la logica di business dell'applicazione.
*   **`UserDetailsServiceImpl.java`**: (Da creare) Implementa `UserDetailsService` di Spring Security per caricare i dettagli dell'utente per l'autenticazione.
*   **`MinioService.java`**: (Da creare) Gestisce le interazioni con MinIO: upload, download, generazione di presigned URL, eliminazione file.
*   **`ImageService.java`**: (Da creare) Gestisce la logica di business per le immagini, coordinando `ImageMetadataRepository` e `MinioService`. Include la logica per l'upload (salvataggio metadati e file), il recupero paginato delle immagini con presigned URL.
*   **`AuthService.java`**: (Da creare, o logica integrata in `AuthController`) Gestisce la logica di autenticazione e registrazione utenti.

### 4. Controller (API Layer - `it.zaninifrancesco.minio_gallery.controller`)
Espongono gli endpoint REST API.
*   **`TestController.java`**: (Esistente) Controller di test per verificare la connettività base.
*   **`AuthController.java`**: (Da creare) Gestisce gli endpoint di autenticazione (es. `/api/auth/login`, `/api/auth/register`).
*   **`ImageController.java`**: (Da creare) Gestisce gli endpoint relativi alle immagini (es. `POST /api/images` per l'upload, `GET /api/images` per la galleria).

### 5. Configurazione (`it.zaninifrancesco.minio_gallery.config`)
Classi di configurazione per Spring Boot e altre dipendenze.
*   **`SecurityConfig.java`**: (Esistente) Configura Spring Security: CORS, regole di autorizzazione per gli endpoint, configurazione del `PasswordEncoder`, integrazione del filtro JWT.
*   **`MinioConfig.java`**: (Da creare, opzionale) Potrebbe contenere la configurazione del client MinIO se non gestita direttamente in `MinioService` o tramite `application.properties`.
*   **`ApplicationProperties`**: (File `application.properties`) Contiene le configurazioni per database, MinIO (endpoint, credenziali, bucket), JWT (segreto, scadenza).

### 6. Sicurezza (`it.zaninifrancesco.minio_gallery.security` o sottocartelle)
Componenti specifici per la gestione della sicurezza e JWT.
*   **`JwtTokenProvider.java`** (o `JwtUtils.java`): (Da creare) Utility class per generare, parsare e validare i token JWT.
*   **`AuthTokenFilter.java`** (o `JwtRequestFilter.java`): (Da creare) Filtro Spring Security che intercetta le richieste, estrae il JWT, lo valida e imposta l'autenticazione nel contesto di sicurezza di Spring.
*   **`PasswordEncoder`**: (Bean definito in `SecurityConfig.java`) Utilizzato per codificare le password degli utenti prima di salvarle nel database.

### 7. DTO (Data Transfer Objects - `it.zaninifrancesco.minio_gallery.payload` o `it.zaninifrancesco.minio_gallery.dto`)
Oggetti semplici per trasferire dati tra i layer, specialmente per le richieste e risposte API.
*   **`LoginRequest.java`**: (Da creare) DTO per i dati di login (username, password).
*   **`SignupRequest.java`**: (Da creare) DTO per i dati di registrazione (username, password, email opzionale, ruoli opzionali).
*   **`JwtResponse.java`** (o `LoginResponse.java`): (Da creare) DTO per la risposta dopo un login успешный (token JWT, tipo di token, id utente, username, ruoli).
*   **`ImageUploadRequest.java`**: (Da creare, o gestito con `@RequestPart` per `MultipartFile` e un DTO per i metadati) DTO per i metadati dell'immagine durante l'upload (titolo, descrizione, tag).
*   **`ImageResponse.java`**: (Da creare) DTO per restituire i dettagli di un'immagine, inclusi i metadati e l'`imageUrl` (presigned URL).
*   **`MessageResponse.java`**: (Da creare, opzionale) DTO generico per risposte API semplici (es. messaggi di successo o errore).

### 8. Gestione Eccezioni (`it.zaninifrancesco.minio_gallery.exception`)
*   **`GlobalExceptionHandler.java`** (o `@ControllerAdvice` specifici): (Da creare) Per gestire eccezioni globali e restituire risposte HTTP appropriate.
*   Custom exceptions (es. `ResourceNotFoundException.java`, `BadRequestException.java`, `MinioOperationException.java`).

---

## Schema Database (PostgreSQL)

Di seguito è descritto lo schema del database PostgreSQL utilizzato dall'applicazione.

### Tabella: `roles`
Memorizza i ruoli disponibili nell'applicazione.

| Colonna | Tipo        | Constraint      | Descrizione                  |
|---------|-------------|-----------------|------------------------------|
| `id`    | `INTEGER`   | `PRIMARY KEY`   | ID univoco del ruolo (auto-generato) |
| `name`  | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` | Nome del ruolo (es. `ROLE_USER`) |

*Esempio dati:*
* (1, 'ROLE_USER')
* (2, 'ROLE_ADMIN')

### Tabella: `users`
Memorizza le informazioni degli utenti registrati.

| Colonna    | Tipo          | Constraint                        | Descrizione                           |
|------------|---------------|-----------------------------------|---------------------------------------|
| `id`       | `BIGINT`      | `PRIMARY KEY`                     | ID univoco dell'utente (auto-generato) |
| `username` | `VARCHAR(255)`| `NOT NULL`, `UNIQUE`              | Username univoco per il login         |
| `password` | `VARCHAR(255)`| `NOT NULL`                        | Password dell'utente (hashed)         |
| `email`    | `VARCHAR(255)`| `UNIQUE`                          | Email dell'utente (opzionale, univoca) |
| `created_at` | `TIMESTAMP`   | `DEFAULT CURRENT_TIMESTAMP`     | Data e ora di creazione utente        |
| `updated_at` | `TIMESTAMP`   | `DEFAULT CURRENT_TIMESTAMP`     | Data e ora ultimo aggiornamento utente |

### Tabella: `user_roles`
Tabella di join per la relazione Many-to-Many tra `users` e `roles`.

| Colonna   | Tipo      | Constraint                                       | Descrizione                     |
|-----------|-----------|--------------------------------------------------|---------------------------------|
| `user_id` | `BIGINT`  | `PRIMARY KEY`, `FOREIGN KEY` references `users(id)` | ID dell'utente                  |
| `role_id` | `INTEGER` | `PRIMARY KEY`, `FOREIGN KEY` references `roles(id)` | ID del ruolo                    |

*Chiave Primaria Composita:* (`user_id`, `role_id`)

### Tabella: `image_metadata`
Memorizza i metadati delle immagini caricate.

| Colonna             | Tipo          | Constraint                             | Descrizione                                      |
|---------------------|---------------|----------------------------------------|--------------------------------------------------|
| `id`                | `UUID`        | `PRIMARY KEY`                          | ID univoco dell'immagine (generato dall'applicazione) |
| `title`             | `VARCHAR(255)`| `NOT NULL`                             | Titolo dell'immagine                             |
| `description`       | `TEXT`        |                                        | Descrizione dell'immagine                        |
| `file_name`         | `VARCHAR(255)`| `NOT NULL`, `UNIQUE`                   | Nome del file su MinIO (es. `uuid.jpg`)          |
| `bucket_name`       | `VARCHAR(255)`| `NOT NULL`                             | Nome del bucket MinIO                            |
| `original_file_name`| `VARCHAR(255)`|                                        | Nome originale del file caricato dall'utente     |
| `content_type`      | `VARCHAR(100)`|                                        | Tipo MIME del file (es. `image/jpeg`)            |
| `size`              | `BIGINT`      |                                        | Dimensione del file in byte                      |
| `uploaded_at`       | `TIMESTAMP`   | `DEFAULT CURRENT_TIMESTAMP`            | Data e ora di caricamento                        |
| `user_id`           | `BIGINT`      | `FOREIGN KEY` references `users(id)`   | ID dell'utente che ha caricato l'immagine        |

*Indici:*
* Potrebbe essere utile un indice su `uploaded_at` per ordinare la galleria.
* Indice su `user_id` per recuperare rapidamente le immagini di un utente.

### Tabella: `tags`
Memorizza tutti i tag univoci disponibili nel sistema.

| Colonna    | Tipo          | Constraint                        | Descrizione                           |
|------------|---------------|-----------------------------------|---------------------------------------|
| `id`       | `BIGINT`      | `PRIMARY KEY`                     | ID univoco del tag (auto-generato)   |
| `name`     | `VARCHAR(100)`| `NOT NULL`, `UNIQUE`              | Nome del tag (es. "natura", "viaggio") |
| `created_at` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP`       | Data di creazione del tag             |

*Esempio dati:*
* (1, 'natura')
* (2, 'viaggio')  
* (3, 'famiglia')

### Tabella: `image_tags`
Tabella di join per la relazione Many-to-Many tra `image_metadata` e `tags`.

| Colonna    | Tipo    | Constraint                                              | Descrizione               |
|------------|---------|---------------------------------------------------------|---------------------------|
| `image_id` | `UUID`  | `PRIMARY KEY`, `FOREIGN KEY` references `image_metadata(id)` | ID dell'immagine          |
| `tag_id`   | `BIGINT`| `PRIMARY KEY`, `FOREIGN KEY` references `tags(id)`      | ID del tag                |

*Chiave Primaria Composita:* (`image_id`, `tag_id`)

*Vincoli aggiuntivi:*
* `ON DELETE CASCADE` per `image_id`: se un'immagine viene eliminata, rimuove automaticamente le associazioni con i tag
* `ON DELETE CASCADE` per `tag_id`: se un tag viene eliminato, rimuove automaticamente le associazioni con le immagini

*Indici:*
* Indice su `image_id` per trovare rapidamente tutti i tag di un'immagine
* Indice su `tag_id` per trovare rapidamente tutte le immagini con un tag specifico

---

## Query SQL Comuni

### Trovare tutte le immagini con i loro tag
```sql
SELECT 
    im.id, im.title, im.description, im.file_name, im.uploaded_at,
    ARRAY_AGG(t.name) as tags
FROM image_metadata im
LEFT JOIN image_tags it ON im.id = it.image_id
LEFT JOIN tags t ON it.tag_id = t.id
GROUP BY im.id, im.title, im.description, im.file_name, im.uploaded_at
ORDER BY im.uploaded_at DESC;
```

### Trovare immagini per tag specifico
```sql
SELECT DISTINCT im.*
FROM image_metadata im
JOIN image_tags it ON im.id = it.image_id
JOIN tags t ON it.tag_id = t.id
WHERE t.name = 'natura'
ORDER BY im.uploaded_at DESC;
```

### Trovare immagini con più tag (AND logic)
```sql
SELECT im.*
FROM image_metadata im
WHERE im.id IN (
    SELECT it.image_id
    FROM image_tags it
    JOIN tags t ON it.tag_id = t.id
    WHERE t.name IN ('natura', 'viaggio')
    GROUP BY it.image_id
    HAVING COUNT(DISTINCT t.name) = 2
);
```

### Contare immagini per tag (statistiche)
```sql
SELECT t.name, COUNT(it.image_id) as image_count
FROM tags t
LEFT JOIN image_tags it ON t.id = it.tag_id
GROUP BY t.id, t.name
ORDER BY image_count DESC;
```

---

## Vantaggi del Schema con Tabelle Separate per i Tag

1. **Prestazioni**: Le query di ricerca per tag sono molto più veloci usando indici su relazioni normalizzate
2. **Integrità dei Dati**: I tag vengono memorizzati una sola volta, evitando duplicazioni e inconsistenze
3. **Statistiche**: È facile calcolare quante immagini hanno un determinato tag
4. **Autocompletamento**: È possibile implementare facilmente un sistema di autocompletamento dei tag
5. **Gestione Tag**: È possibile rinominare o eliminare tag globalmente
6. **Scalabilità**: Lo schema supporta meglio un gran numero di tag e immagini
7. **Query Complesse**: Permette ricerche avanzate come "immagini con tag A ma non tag B"

---

