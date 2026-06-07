# CONTAINER EMPIRE — GUIDA SETUP RAPIDO

## Prerequisiti
- Flutter SDK >= 3.3.0 (`flutter --version`)
- Dart >= 3.3.0
- Android Studio / VS Code con Flutter extension
- Account Firebase (gratuito)
- Java 17+ per Android

---

## 1. Clona / Apri il Progetto

Apri la cartella "CONTAINER EMPIRE" in VS Code:
```
File → Open Folder → seleziona questa cartella
```

---

## 2. Installa dipendenze

```bash
flutter pub get
```

---

## 3. Configura Firebase

### 3a. Installa Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 3b. Installa FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 3c. Configura il tuo progetto Firebase
```bash
# Crea progetto su https://console.firebase.google.com
# Poi lancia:
flutterfire configure --project=IL-TUO-PROJECT-ID
```

Questo sovrascriverà automaticamente `lib/core/config/firebase_options.dart`.

### 3d. Abilita servizi Firebase Console
- Authentication → Anonymous + Google
- Firestore → crea database in modalità produzione
- Crashlytics → attiva
- Remote Config → attiva
- Analytics → attiva (automatico)

---

## 4. AdMob (Ads)

1. Crea app su https://admob.google.com
2. Sostituisci in `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```
3. Per iOS, aggiungi in `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

---

## 5. Aggiungi Font Rajdhani

Scarica da Google Fonts: https://fonts.google.com/specimen/Rajdhani

Crea cartella `assets/fonts/` e copia:
- Rajdhani-Regular.ttf
- Rajdhani-SemiBold.ttf
- Rajdhani-Bold.ttf

Aggiungi in `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: Rajdhani
      fonts:
        - asset: assets/fonts/Rajdhani-Regular.ttf
        - asset: assets/fonts/Rajdhani-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Rajdhani-Bold.ttf
          weight: 700
```

---

## 6. Aggiungi placeholder assets

Per far compilare il progetto, crea immagini placeholder:

```bash
# Su Windows PowerShell:
# Crea file PNG vuoti nelle cartelle assets/
# Oppure usa flutter pub run flutter_launcher_icons
```

---

## 7. Esegui su emulatore / dispositivo

```bash
# Lista dispositivi disponibili
flutter devices

# Esegui in debug
flutter run

# Build release Android
flutter build appbundle --release

# Build release iOS
flutter build ipa --release
```

---

## 8. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

---

## Struttura File Generata

```
lib/
├── main.dart                          # Entry point
├── core/
│   ├── config/
│   │   └── firebase_options.dart      # ⚠️ Genera con flutterfire configure
│   ├── theme/
│   │   ├── app_theme.dart             # Dark theme industriale
│   │   └── app_colors.dart            # Palette neon
│   ├── models/
│   │   ├── rarity.dart                # Enum Rarity + Mutation
│   │   ├── item_model.dart            # Modello oggetto (Hive)
│   │   ├── item_model.g.dart          # Hive adapter (generato)
│   │   ├── player_model.dart          # Modello giocatore (Hive)
│   │   ├── player_model.g.dart        # Hive adapter (generato)
│   │   └── container_model.dart       # Container + loot tables
│   └── services/
│       ├── rng_service.dart           # Sistema RNG avanzato
│       ├── player_service.dart        # Gestione profilo + XP
│       ├── inventory_service.dart     # Inventario + vendita
│       └── service_locator.dart       # GetIt DI setup
├── features/
│   ├── home/                          # Home + selezione container
│   ├── container_opening/             # Roulette + Flame animation
│   │   └── game/container_game.dart   # Flame Engine game
│   ├── inventory/                     # Inventario grid + filtri
│   ├── shop/                          # Gemme + IAP + VIP
│   ├── upgrades/                      # 6 potenziamenti
│   ├── missions/                      # Daily/Weekly/Permanent
│   ├── collection/                    # Pokédex-style
│   ├── leaderboard/                   # Firebase leaderboard
│   └── profile/                       # Stats + Settings
├── widgets/common/                    # Shell, CurrencyBar, NeonText
├── routes/app_router.dart             # GoRouter
└── firebase/                          # Cloud Functions (TODO)
```

---

## Prossimi Passi Consigliati

1. `flutterfire configure` per Firebase reale
2. Aggiungi font Rajdhani
3. Sostituisci icon `Icons.category_rounded` con PNG reali degli oggetti
4. Collega AdMob con ID reali
5. Configura In-App Purchase su Play Console / App Store Connect
6. Implementa Google Sign-In per autenticazione
7. Aggiungi Lottie animations per container opening
