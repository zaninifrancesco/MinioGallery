

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

