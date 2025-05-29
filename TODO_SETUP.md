# Todo List - MinioGallery Setup

Data: 29 maggio 2025

## Backend (Spring Boot)

### Configurazione Iniziale
- [x] Setup Progetto Spring Boot (generato)
- [x] Configurazione Database PostgreSQL in `application.properties`
  - [x] Definizione URL, username, password
  - [x] Configurazione `ddl-auto`, dialect, `show-sql`
  - [x] Aggiunta commenti esplicativi alle proprietà
- [x] Aggiunta dipendenza driver PostgreSQL (`postgresql`) in `pom.xml`
- [x] Configurazione MinIO in `application.properties`
  - [x] Definizione endpoint, access key, secret key, bucket name
- [x] Aggiunta dipendenza MinIO SDK in `pom.xml`
- [ ] Configurazione JWT in `application.properties`
  - [ ] Definizione segreto, expiration, header, prefix
- [ ] Aggiunta dipendenze JWT (jjwt-api, jjwt-impl, jjwt-jackson) in `pom.xml`
- [ ] Verifica connessione al database PostgreSQL (avvio applicazione e controllo log/actuator)

### Feature 1: Upload Immagine
- [ ] Creazione Entità JPA `ImageMetadata.java` (UUID, titolo, descrizione, tags, path MinIO, bucket, data caricamento)
- [ ] Creazione Repository JPA `ImageMetadataRepository.java` (estendere JpaRepository/PagingAndSortingRepository)
- [ ] Creazione Servizio `MinioService.java`
  - [ ] Logica per upload file su MinIO
  - [ ] Logica per generazione presigned URL
  - [ ] Gestione configurazione client MinIO (da `application.properties`)
- [ ] Creazione Servizio `ImageService.java`
  - [ ] Metodo per upload immagine (validazione, generazione UUID, salvataggio file su MinIO, salvataggio metadati su DB)
  - [ ] Gestione transazionale (rollback in caso di fallimento upload MinIO)
- [ ] Creazione DTOs (Data Transfer Objects)
  - [ ] `ImageUploadRequest.java` (per metadati: titolo, descrizione, tags)
  - [ ] `ImageMetadataResponse.java` (per restituire i metadati dopo l'upload e nella galleria)
- [ ] Creazione Controller REST `ImageController.java`
  - [ ] Endpoint `POST /api/images` (multipart: file + metadati JSON)
  - [ ] Validazione input (tipo file, dimensione - anche se primariamente frontend, una validazione backend è buona pratica)
  - [ ] Integrazione con `ImageService`
  - [ ] Gestione risposte HTTP (201 Created, 400 Bad Request, 401 Unauthorized)
- [ ] Configurazione Sicurezza Spring Security & JWT
  - [ ] Creazione `JwtTokenProvider.java` (o simile) per generazione e validazione token
  - [ ] Creazione `UserDetailsService` custom (se necessario per caricare utenti da DB, o in-memory per test)
  - [ ] Creazione Filtro JWT per validare token nelle richieste
  - [ ] Configurazione `SecurityFilterChain` per proteggere l'endpoint `/api/images` (richiedere autenticazione JWT)
  - [ ] Endpoint per autenticazione (login) per ottenere il JWT (es. `/api/auth/login`) - *Potrebbe essere fuori scope iniziale se il token viene gestito esternamente*

### Feature 2: Galleria Immagini
- [ ] Servizio `ImageService.java`
  - [ ] Metodo per recuperare immagini paginate e ordinate per data (dal DB)
  - [ ] Integrazione con `MinioService` per generare presigned URL per ogni immagine
- [ ] Controller REST `ImageController.java`
  - [ ] Endpoint `GET /api/images` (con parametri `page` e `size`)
  - [ ] Integrazione con `ImageService`
  - [ ] Gestione risposte HTTP (200 OK, 401 Unauthorized)
- [ ] Configurazione Paginazione in `ImageMetadataRepository.java`

### Altro Backend
- [ ] Gestione Errori Globale (`@ControllerAdvice` con `@ExceptionHandler`)
- [ ] Logging (configurazione e utilizzo)
- [ ] Test Unitari e di Integrazione
- [ ] (Opzionale) Configurazione Swagger/OpenAPI per documentazione API

## Frontend (Flutter)

### Configurazione Iniziale
- [ ] Setup Progetto Flutter (generato)
- [ ] Configurazione `pubspec.yaml`
  - [ ] Aggiunta dipendenze necessarie (es. `http` per chiamate API, `image_picker` per selezionare file, `flutter_secure_storage` per JWT, gestore di stato come Provider/Bloc)
- [ ] Struttura cartelle del progetto (es. per feature, models, services, widgets, screens)
- [ ] Setup Navigazione (Routes)

### Feature 1: Upload Immagine
- [ ] Schermata/Widget per upload immagine
  - [ ] UI per selezionare file (JPEG/PNG)
  - [ ] UI per inserire metadati (titolo, descrizione, tags)
  - [ ] Validazione frontend (tipo file, dimensione < 5MB)
- [ ] Servizio API per upload
  - [ ] Metodo per inviare richiesta multipart a `POST /api/images`
  - [ ] Gestione token JWT nell'header della richiesta
  - [ ] Gestione risposte (successo, errore)
- [ ] Gestione stato per l'upload (loading, success, error)

### Feature 2: Galleria Immagini
- [ ] Schermata/Widget per visualizzare galleria
  - [ ] UI per mostrare griglia responsive di immagini (titolo, anteprima, descrizione breve)
  - [ ] Logica per caricare immagini paginate da `GET /api/images`
  - [ ] Gestione caricamento immagini da presigned URL
- [ ] Servizio API per recupero galleria
  - [ ] Metodo per chiamare `GET /api/images` con paginazione
  - [ ] Gestione token JWT nell'header
- [ ] Gestione stato per la galleria (loading, data, error, no images)
- [ ] (Opzionale) Schermata di dettaglio immagine (su click)

### Autenticazione Frontend
- [ ] Schermata di Login
  - [ ] UI per inserire credenziali
  - [ ] Servizio API per chiamare endpoint di login backend
  - [ ] Salvataggio sicuro del token JWT (es. `flutter_secure_storage`)
- [ ] Gestione stato autenticazione (utente loggato/non loggato)
- [ ] Interceptor HTTP per aggiungere automaticamente JWT alle richieste API protette
- [ ] Logica di re-login o refresh token (se implementato)

### Altro Frontend
- [ ] UI Design e Theming generale
- [ ] Gestione Errori e messaggi all'utente
- [ ] Test Widget e Unitari

## User Flows

### Utente Non Registrato (Visitatore)

- **Può:**
  - Visualizzare la pagina principale dell'applicazione (se esiste una parte pubblica).
  - Visualizzare informazioni generali sull'applicazione.
- **Non Può:**
  - Accedere a nessuna funzionalità che richieda autenticazione.
  - Caricare immagini.
  - Visualizzare la galleria di immagini (se protetta).
  - Visualizzare i dettagli delle immagini.
  - Accedere a sezioni di amministrazione.

### Utente Registrato (Autenticato)

1.  **Autenticazione:**
    -   Accede alla pagina di login.
    -   Inserisce credenziali (es. email/username e password).
    -   In caso di successo, riceve un token JWT e viene reindirizzato alla dashboard/galleria.
    -   In caso di fallimento, riceve un messaggio di errore.

2.  **Upload Immagine (Feature 1):**
    -   Accede alla sezione di upload.
    -   Seleziona un file immagine (JPEG/PNG, <5MB) dal proprio dispositivo.
    -   Inserisce metadati: titolo (obbligatorio), descrizione (obbligatoria), tag (opzionali).
    -   Avvia l'upload.
    -   Visualizza un indicatore di progresso.
    -   In caso di successo, riceve una conferma e l'immagine appare nella sua galleria.
    -   In caso di errore (validazione fallita, problemi di rete, errore server), riceve un messaggio di errore specifico.

3.  **Visualizzazione Galleria Immagini (Feature 2):**
    -   Accede alla sezione galleria.
    -   Visualizza le proprie immagini caricate, paginate e ordinate per data di caricamento (le più recenti prima).
    -   Per ogni immagine, visualizza: titolo, anteprima immagine (caricata da MinIO tramite presigned URL), descrizione breve.
    -   Può navigare tra le pagine della galleria.
    -   Se non ci sono immagini, visualizza un messaggio amichevole.

4.  **Visualizzazione Dettaglio Immagine (Opzionale, ma implicito nel Data Flow Steps):**
    -   Clicca su un'immagine nella galleria.
    -   Viene reindirizzato a una schermata di dettaglio che mostra l'immagine completa e tutti i suoi metadati (titolo, descrizione, tags, data caricamento).

5.  **Gestione Proprie Immagini (Non specificato in `spec.md`, ma comune):**
    -   **Può:**
        -   Modificare i metadati delle proprie immagini (titolo, descrizione, tags).
        -   Eliminare le proprie immagini (questo comporterebbe l'eliminazione del file da MinIO e dei metadati da PostgreSQL).
    -   **Non Può:**
        -   Visualizzare, modificare o eliminare immagini di altri utenti (se l'applicazione fosse multi-utente in quel senso).

6.  **Logout:**
    -   Effettua il logout, invalidando la sessione/token JWT lato client.

### Admin (Ruolo con Privilegi Elevati - Non definito in `spec.md`, ma ipotizzabile per gestione)

*Se un ruolo Admin fosse necessario, le sue capacità potrebbero includere (oltre a tutte quelle dell'utente registrato per le proprie risorse):*

1.  **Gestione Utenti:**
    -   Visualizzare elenco di tutti gli utenti registrati.
    -   Attivare/Disattivare account utente.
    -   Modificare ruoli utente (es. promuovere un utente ad admin).
    -   (Potenzialmente) Eliminare utenti.

2.  **Gestione Contenuti Globali:**
    -   Visualizzare tutte le immagini caricate da tutti gli utenti.
    -   Modificare i metadati di qualsiasi immagine.
    -   Eliminare qualsiasi immagine dal sistema.
    -   Visualizzare statistiche di utilizzo (es. numero di immagini, spazio occupato).

3.  **Configurazione Applicazione (Potenziale):**
    -   Modificare impostazioni globali dell'applicazione (se presenti e gestibili via UI).

- **Non Può (Generalmente):**
  - Visualizzare le password degli utenti in chiaro.

**Nota:** Le funzionalità dell'Admin non sono definite nel file `spec.md` fornito. Questa sezione è un'ipotesi basata su requisiti comuni per ruoli amministrativi. Se non è previsto un ruolo Admin, questa sezione può essere ignorata o rimossa. L'attuale `spec.md` si concentra sulle funzionalità per un utente singolo autenticato che gestisce le proprie immagini.
