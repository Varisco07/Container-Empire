/// ─────────────────────────────────────────────────────────────────────────────
/// CONTENUTI LEGALI — fonte di verità UNICA per Privacy Policy e Termini.
/// Usati sia in-app (LegalScreen) sia, in forma HTML, nelle pagine web
/// (web/privacy.html, web/terms.html) richieste dalle schede store.
///
/// ⚠️ DA VERIFICARE PRIMA DELLA PUBBLICAZIONE:
///   • [kContactEmail] deve essere una casella REALE e attiva (serve possedere
///     il dominio containerempire.app, oppure sostituiscila con la tua email).
///   • [kEffectiveDate] = data di prima pubblicazione.
///   • Se pubblichi come persona fisica, valuta se indicare nome/cognome reali.
/// ─────────────────────────────────────────────────────────────────────────────
library;

const String kDeveloperName = 'Container Empire';
const String kContactEmail = 'support@containerempire.app';
const String kEffectiveDate = '16 giugno 2026';
const String kAppVersion = '1.0.0';

const String kPrivacyPolicy = '''
PRIVACY POLICY — Container Empire
In vigore dal $kEffectiveDate

Questa informativa spiega quali dati tratta l'app Container Empire ("l'App", "noi") e come li usiamo, ai sensi del Regolamento UE 2016/679 (GDPR).

1. TITOLARE DEL TRATTAMENTO
$kDeveloperName. Per qualsiasi richiesta sulla privacy puoi scrivere a: $kContactEmail.

2. DATI CHE TRATTIAMO
• Dati account: username e, se la fornisci, email (per accesso e recupero account).
• Dati di gioco: monete, gemme, livello, statistiche, inventario, progressi dell'impero, classifica.
• Identificativi tecnici: ID utente generato dal sistema di autenticazione (Firebase UID).
• Acquisti: lo stato dei tuoi acquisti in-app. NON trattiamo i dati di pagamento (carta ecc.): sono gestiti esclusivamente da Apple App Store / Google Play.

Se giochi in MODALITÀ OSPITE, i dati restano salvati solo localmente sul tuo dispositivo e non vengono inviati ai nostri server.

3. FINALITÀ E BASE GIURIDICA
• Fornire e salvare il gioco, sincronizzare i progressi, gestire classifiche e acquisti — base giuridica: esecuzione del servizio richiesto.
• Sicurezza e prevenzione abusi — legittimo interesse.
• Eventuali comunicazioni di supporto — esecuzione del servizio o consenso.

4. SERVIZI DI TERZE PARTI
Per funzionare l'App usa fornitori che possono trattare dati per nostro conto:
• Google Firebase (Authentication, Cloud Firestore) — account e salvataggio cloud.
• Google Sign-In — accesso con account Google (opzionale).
• Apple App Store / Google Play — gestione degli acquisti in-app.
Ti invitiamo a consultare le rispettive privacy policy.

5. CONSERVAZIONE
Conserviamo i dati account e di gioco finché l'account esiste. Puoi chiederne la cancellazione in qualsiasi momento (vedi punto 7).

6. I TUOI DIRITTI (GDPR)
Hai diritto di accesso, rettifica, cancellazione, limitazione, opposizione e portabilità dei tuoi dati. Puoi esercitarli scrivendo a $kContactEmail. Hai inoltre diritto di proporre reclamo all'autorità di controllo (in Italia: Garante per la protezione dei dati personali).

7. CANCELLAZIONE DELL'ACCOUNT E DEI DATI
Puoi eliminare l'account e i dati associati direttamente dall'App: Profilo → Impostazioni → "Elimina account". In alternativa scrivi a $kContactEmail e provvederemo. La cancellazione rimuove i dati cloud (profilo, progressi, inventario, classifica) e i dati locali sul dispositivo.

8. MINORI
L'App non è destinata a bambini di età inferiore a quella prevista dalla legge locale (di norma 13/16 anni). Non raccogliamo consapevolmente dati di minori senza consenso di chi esercita la responsabilità genitoriale.

9. MODIFICHE
Potremmo aggiornare questa informativa. La data "in vigore dal" indica l'ultima versione; le modifiche rilevanti saranno comunicate nell'App.

Contatti: $kContactEmail
''';

const String kTermsOfService = '''
TERMINI DI SERVIZIO — Container Empire
In vigore dal $kEffectiveDate

1. ACCETTAZIONE
Usando Container Empire accetti questi Termini e la Privacy Policy. Se non li accetti, non utilizzare l'App.

2. LICENZA D'USO
Ti concediamo una licenza personale, non esclusiva e non trasferibile per usare l'App a scopo di intrattenimento.

3. ACCOUNT
Sei responsabile della sicurezza delle tue credenziali e delle attività svolte con il tuo account. Devi fornire informazioni veritiere.

4. VALUTA VIRTUALE E ACQUISTI IN-APP
Monete e gemme sono valuta puramente virtuale: non hanno alcun valore monetario reale, non sono convertibili in denaro e non sono trasferibili fuori dall'App. Gli acquisti in-app sono gestiti da Apple App Store / Google Play secondo le loro condizioni; eventuali rimborsi seguono le policy dello store e la normativa applicabile.

5. ABBONAMENTO VIP
Il VIP è un abbonamento a rinnovo automatico gestito dallo store. Puoi gestirlo o disdirlo in qualsiasi momento dalle impostazioni del tuo account store; la disdetta ha effetto al termine del periodo già pagato.

6. CONDOTTA
È vietato barare, manomettere l'App, sfruttare bug, o usare l'App in modo illecito o lesivo di terzi.

7. PROPRIETÀ INTELLETTUALE
Grafica, testi, marchi e contenuti dell'App sono protetti e restano di proprietà dei rispettivi titolari.

8. GARANZIE E RESPONSABILITÀ
L'App è fornita "così com'è". Nei limiti consentiti dalla legge, non garantiamo assenza di errori o disponibilità continua e non siamo responsabili per la perdita di progressi di gioco.

9. LEGGE APPLICABILE
Salvo norme inderogabili a tutela del consumatore, si applica la legge italiana.

10. CONTATTI
$kContactEmail
''';
