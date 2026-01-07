# SpartX

SpartX è un'applicazione Flutter open-source progettata per aiutare musicisti, studenti e insegnanti a gestire i loro spartiti musicali digitali. L'app fornisce un set completo di strumenti per organizzare, visualizzare e interagire con gli spartiti in formato PDF, rendendola un compagno essenziale per la pratica musicale, lo studio e l'esecuzione.

## Caratteristiche principali

- **Gestione degli spartiti**: importa, rinomina ed elimina facilmente gli spartiti PDF dal tuo dispositivo. Una funzione di ricerca integrata ti consente di trovare rapidamente qualsiasi brano nella tua libreria.
- **Visualizzatore PDF con annotazioni**: visualizza i tuoi spartiti con un visualizzatore PDF ad alte prestazioni. Attiva la modalità di annotazione per aggiungere note, segni o evidenziazioni utilizzando gli strumenti penna ed evidenziatore.
- **Gestione playlist**: crea playlist personalizzate per le tue sessioni di pratica, esibizioni o lezioni. Aggiungi e rimuovi facilmente spartiti dalle playlist per mantenere organizzata la tua musica.
- **Calendario eventi**: tieni traccia di lezioni, prove, concerti ed esami con la funzione calendario integrata. Aggiungi, modifica ed elimina eventi per gestire in modo efficace il tuo programma musicale.
- **Metronomo integrato**: esercitati a tempo con il metronomo integrato. Regola il BPM (battiti al minuto) in base alle tue esigenze e scegli tra diversi suoni di tick.
- **Personalizzazione**: personalizza l'aspetto dell'app scegliendo tra una varietà di colori per il tema. Passa dalla modalità chiara a quella scura per adattarla al tuo ambiente.

## Struttura del progetto e panoramica del codice

Il progetto segue una struttura standard di Flutter, con la logica principale dell'applicazione che risiede nella directory `lib`. Ecco una panoramica dei file chiave:

- **`main.dart`**: il punto di ingresso dell'applicazione. Inizializza l'app e gestisce la navigazione principale e la gestione del tema.
- **`sheet_music_page.dart`**: gestisce la visualizzazione, l'importazione, la ridenominazione, l'eliminazione e la ricerca degli spartiti.
- **`pdf_viewer_page.dart`**: responsabile della visualizzazione dei file PDF e della gestione delle funzionalità di annotazione.
- **`playlists_page.dart`**: gestisce la creazione, la ridenominazione e l'eliminazione delle playlist.
- **`playlist_details_page.dart`**: visualizza il contenuto di una singola playlist, consentendo agli utenti di aggiungere o rimuovere spartiti.
- **`calendar_page.dart`**: implementa la funzionalità di calendario per la gestione degli eventi.
- **`metronome_page.dart`**: contiene l'interfaccia utente per il metronomo.
- **`metronome_service.dart`**: gestisce la logica per la funzionalità del metronomo.

## Come iniziare

1. **Aggiungere uno spartito**:
   - Nella scheda "Spartiti", tocca il pulsante `+`.
   - Seleziona un file PDF dal tuo dispositivo da importare nell'app.
2. **Creare una playlist**:
   - Vai alla scheda "Playlist" e tocca il pulsante `+`.
   - Assegna un nome alla tua playlist e inizia ad aggiungere spartiti.
3. **Annotare un documento**:
   - Apri uno spartito toccandolo.
   - Tocca l'icona di modifica per attivare la modalità di annotazione.
   - Usa gli strumenti penna ed evidenziatore per segnare il tuo spartito.
4. **Programmare un evento**:
   - Nella scheda "Calendario", tocca il pulsante `+`.
   - Compila i dettagli del tuo evento, come titolo, data, ora e luogo.

## Tecnologie e librerie utilizzate

Questo progetto è costruito utilizzando le seguenti tecnologie e librerie open source:

- **Flutter**: il framework dell'interfaccia utente di Google per la creazione di applicazioni compilate in modo nativo per dispositivi mobili, Web e desktop da un'unica base di codice.
- **Dart**: il linguaggio di programmazione utilizzato da Flutter.

### Librerie open source

- **`cupertino_icons`**: fornisce le icone in stile iOS.
- **`file_picker`**: consente di selezionare i file dal dispositivo.
- **`flutter_pdfview`**: un visualizzatore di PDF per Flutter.
- **`path_provider`**: per trovare percorsi di uso comune nel file system.
- **`uuid`**: per generare UUID (identificatori univoci universali).
- **`table_calendar`**: un calendario highly personalizzabile per le app Flutter.
- **`audioplayers`**: una libreria Flutter per riprodurre più file audio contemporaneamente.
- **`shared_preferences`**: per l'archiviazione permanente di dati semplici.
- **`provider`**: per la gestione dello stato.
- **`share_plus`**: per la condivisione di contenuti con altre app.

## Sviluppi futuri

SpartX è in continuo sviluppo. Le funzionalità future pianificate includono:

- **Registrazione audio**: registra le tue sessioni di pratica e riascoltale.
- **Strumenti di annotazione avanzati**: aggiungi testo, forme e altri simboli ai tuoi spartiti.
- **Sincronizzazione cloud**: sincronizza la tua libreria di spartiti su più dispositivi.

Sentiti libero di contribuire al progetto o suggerire nuove funzionalità!
