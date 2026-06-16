# 🚀 Launch Checklist — Container Empire

Stato e passi mancanti per la pubblicazione (web + mobile). Aggiornato: giugno 2026.

## ✅ Fatto in questa sessione
- **Git**: rimossi dal tracking ~495 file (`.dart_tool/chrome-device/*` + `build/*`) — profilo Chrome con cookie/login + artefatti di build. Già coperti da `.gitignore`.
- **Regole Firestore** allineate ai path realmente usati dal codice (`users/{uid}/…`, `usernames/{username}`), con accesso solo-proprietario e anti-furto username. → **da deployare** (vedi sotto).
- **`flutter analyze`: 0 problemi** (erano 163).
- **Progetti nativi** `android/` e `ios/` generati. `applicationId` / bundle: `com.containerempire.container_empire` (niente più `com.example`).
- **Android**: nome app "Container Empire" + permesso `INTERNET` nel manifest di release.
- **Web**: `manifest.json` / `index.html` brandizzati (tema scuro) + **Firebase Hosting** configurato in `firebase.json`.
- Build verificate: `flutter analyze` ✓, `flutter test` ✓, `flutter build web` ✓.

---

## 🌐 WEB — per pubblicare
```bash
firebase login
firebase use container-empire
flutter build web --release
firebase deploy --only firestore:rules   # pubblica le regole nuove (IMPORTANTE)
firebase deploy --only hosting            # pubblica il sito (serve build/web)
```
- In **Firebase Console → Authentication → Settings → Authorized domains** aggiungi il dominio di hosting.

## 📱 MOBILE — prima del rilascio sugli store
1. **Firebase mobile (CRITICO).** In `lib/core/config/firebase_options.dart` gli `appId` Android e iOS usano per errore l'appId **web**. Esegui `flutterfire configure` (o aggiungi le app Android/iOS in console e scarica `google-services.json` → `android/app/`, `GoogleService-Info.plist` → `ios/Runner/`). Se cambi il bundle id, riallinealo in Firebase.
2. **Java/Gradle.** La build Android segnala un mismatch: imposta JDK 17 → `flutter config --jdk-dir=<percorso-JDK-17>`.
3. **Icona app.** Ora c'è l'icona Flutter di default. Aggiungi `flutter_launcher_icons` + un'immagine 1024×1024 e rigenera.
4. **Signing Android.** Crea keystore, `android/key.properties` + `signingConfigs.release`. Senza, niente upload su Play.
5. **Prodotti IAP.** Creali su Play Console / App Store Connect con gli ID esatti di `IapProducts` (`container_empire_gems_50` … `container_empire_vip_monthly`).
6. Build: `flutter build appbundle --release` (Android) · `flutter build ipa --release` (iOS, serve Mac+Xcode).

## 💰 Monetizzazione (decisioni da prendere)
- **Annunci finti.** `rewarded_ad_service.dart` mostra "ANNUNCIO (DEMO)" e regala comunque la ricompensa. Prima del lancio: integra `google_mobile_ads` (AdMob) **oppure** togli la dicitura "DEMO/ANNUNCIO" e trattalo come bonus **oppure** nascondi le feature ad-gated.
- **IAP senza validazione + VIP eterno.** `PlayerService.activateVip()` mette `isVip=true` per sempre → l'abbonamento mensile non scade mai. Aggiungere una scadenza (campo `vipUntil`) e validazione ricevuta lato server (Cloud Functions) prima di vendere il VIP.
- **Leaderboard falsificabile.** I valori non sono validati lato server.

## 🔎 Osservabilità
- Nessun crash reporting. Aggiungi `firebase_crashlytics` + `firebase_analytics` per capire crash/abbandoni in produzione.

## 🎨 Asset
- Le cartelle `assets/` (images/icons/animations/audio) sono **vuote**: il gioco gira su emoji + CustomPainter. Per lo store servono icona, screenshot e (opzionale) audio.
