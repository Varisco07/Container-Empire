# 📦 Container Empire

> Un simulatore di apertura container costruito con Flutter — pensa alle casse di CS2 incrociate con il sistema di collezione di Pokémon, con progressione profonda, mutazioni rare, leaderboard globale, clan, trade e eventi live.

---

## 🎮 Features

### Core Gameplay
- **7 container** dal Free al Quantum — ognuno con loot table bilanciata e visual unico
- **8 livelli di rarità** — Comune → Cosmico, con glow animato al reveal
- **5 tipi di mutazione** — Golden, Diamond, Radioactive, Galaxy, Void — che alterano valore e aspetto
- **RNG engine avanzato** — luck boost, moltiplicatori evento, pity system (garantisce raro ogni N aperture)
- **Roulette animata** — striscia scorrevole con animazione fisica + flash al centro
- **Confetti + haptic feedback** — celebrazione scalata in base alla rarità trovata
- **Apertura multipla** — apri fino a 100 container in batch con reveal della migliore item

### Progressione
- **Sistema XP e livelli** — ogni apertura sale il livello, con ring progress in real-time
- **Upgrade tree** — Fortuna, Valore, Slot inventario, Mutazione, Auto-open, Auto-sell
- **Prestige system** — reset controllato con +15% luck permanente e badge esclusivo
- **Pity counter** — garantisce item raro+ dopo soglia configurabile
- **Daily login streak** — ricompense giornaliere crescenti

### Missioni & Social
- **Missioni giornaliere / settimanali / permanenti** — board completa con progress bar
- **Clan system** — crea o unisciti a clan, obiettivi clan condivisi, contributo punti
- **Trade marketplace** — vendi item ad altri giocatori, filtra per rarità e prezzo
- **Leaderboard globale Firestore** — 4 categorie (guadagni, livello, container, rari), podio top 3 animato
- **Crafting / Fusione** — combina 3–6 item della stessa rarità per ottenere un item della rarità superiore

### UI & UX
- **Dark theme premium** — palette neon su sfondo navy profondo
- **Bottom nav con pill animata** che scivola tra tab
- **Currency bar con anello XP circolare** e glow sulle monete
- **Pulsante APRI con gradiente** e glow pulsante sincronizzato al colore del container
- **Inventory tile** con badge rarità, shine gradient sugli item epici+, press animation
- **Bottom sheet detail** con avatar glowato, valore grande, bottoni con feedback
- **Snackbar personalizzate** — 4 tipi (success / error / coins / info) con design floating
- **Auth screen** con background animato e logo con bounce elastico
- **Podio leaderboard** — visual con barre altezza variabile e medaglie colorate

### Backend & Auth
- **Firebase Auth** — email/password + Google Sign-In
- **Cloud Firestore** — sync profilo, inventario, leaderboard, trade, clan
- **Hive** — cache locale offline
- **IAP** — gem pack, VIP Pass (ready for production)

---

## 🛠 Tech Stack

| Layer | Tecnologia |
|---|---|
| UI | Flutter 3.x — Material 3 Dark |
| State Management | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| Local Storage | Hive 2.x |
| Backend | Firebase Auth · Firestore |
| Auth | Firebase Auth + Google Sign-In |
| Animations | flutter_animate · confetti · custom AnimationController |
| IAP | in_app_purchase |
| DI | GetIt 8.x |

---

## 🗂 Project Structure

```
lib/
├── main.dart                        # Entry point — Hive init, GetIt, Firebase bootstrap
├── core/
│   ├── config/
│   │   └── firebase_options.dart    # ⚠️ Non committato — genera con flutterfire configure
│   ├── models/
│   │   ├── rarity.dart              # Rarity enum (8 livelli) + Mutation enum (5 tipi)
│   │   ├── item_model.dart          # ItemModel + Hive adapter
│   │   ├── player_model.dart        # PlayerModel (XP, coins, gems, stats, upgrade)
│   │   └── container_model.dart     # ContainerModel (loot table, prezzo, ID)
│   ├── services/
│   │   ├── rng_service.dart         # RNG — luck, pity, mutazioni, batch roll
│   │   ├── player_service.dart      # XP, level-up, currency, prestige
│   │   ├── inventory_service.dart   # Add/remove/sell/lock item, filtri, sort
│   │   ├── auth_service.dart        # Firebase Auth — email + Google Sign-In
│   │   ├── database_service.dart    # Firestore — profilo, player, inventario, leaderboard
│   │   └── service_locator.dart     # GetIt registrations
│   ├── theme/
│   │   └── app_colors.dart          # Palette neon + rarityColor() + mutationColor()
│   └── utils/
│       └── snack_helper.dart        # Snackbar personalizzate (success/error/coins/info)
├── features/
│   ├── auth/                        # Login screen — email/password + Google
│   ├── home/                        # Selezione container, hero animato, pulsante APRI
│   ├── container_opening/           # Roulette, reveal card, confetti, haptic, batch open
│   ├── inventory/                   # Griglia item, filtri, sort, sell bulk, detail sheet
│   ├── crafting/                    # Fusione item — 6 ricette, spark animation
│   ├── shop/                        # Gem store, IAP, VIP Pass, coin pack
│   ├── upgrades/                    # Upgrade tree con XP/coins
│   ├── missions/                    # Daily / weekly / permanent missions
│   ├── leaderboard/                 # Podio top 3 + lista Firestore, 4 categorie
│   ├── trade/                       # Marketplace buy/sell tra giocatori
│   ├── clan/                        # Clan create/join, obiettivi condivisi
│   └── profile/                     # Stats, prestige, avatar, logout
├── routes/
│   └── app_router.dart              # GoRouter — tutte le rotte nominate
└── widgets/common/
    ├── main_shell.dart              # Shell con bottom nav pill animata
    ├── currency_bar.dart            # Header: avatar + XP ring + coins + gems
    ├── share_drop_dialog.dart       # Dialog condivisione item
    ├── daily_streak_dialog.dart     # Dialog streak giornaliera
    └── neon_text.dart               # Widget testo con glow neon
```

---

## 🚀 Getting Started

### Prerequisiti

| Tool | Versione minima |
|---|---|
| Flutter SDK | 3.3.0 |
| Dart SDK | 3.3.0 (incluso con Flutter) |
| Git | qualsiasi |
| Firebase CLI | latest — `npm install -g firebase-tools` |
| FlutterFire CLI | latest — `dart pub global activate flutterfire_cli` |

---

### 1. Clona il repo

```bash
git clone https://github.com/<tuo-username>/container-empire.git
cd container-empire
```

### 2. Installa le dipendenze

```bash
flutter pub get
```

### 3. Genera gli adapter Hive

```bash
dart run build_runner build --delete-conflicting-outputs
```

Ripeti ogni volta che modifichi un modello `@HiveType`.

### 4. Configura Firebase ⚠️

Il file `lib/core/config/firebase_options.dart` **non è committato** — contiene le chiavi del progetto. Generalo con:

```bash
firebase login
flutterfire configure
```

Assicurati che il tuo progetto Firebase abbia abilitato:
- ✅ Authentication (email/password + Google)
- ✅ Firestore Database
- ✅ (opzionale) Analytics · Crashlytics

**Firestore Security Rules** consigliate:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /usernames/{username} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /leaderboard/{uid} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### 5. Avvia l'app

```bash
# Browser (più veloce per sviluppo)
flutter run -d chrome

# Android
flutter run -d <device-id>

# iOS (solo macOS)
flutter run -d ios
```

---

## 📦 Build per produzione

```bash
# Web
flutter build web --release

# Android (App Bundle per Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🎲 Sistema di Rarità

| # | Nome | Drop Rate base | Colore |
|---|---|---|---|
| 1 | Comune | ~60% | Grigio |
| 2 | Non Comune | ~25% | Verde |
| 3 | Raro | ~10% | Blu |
| 4 | Epico | ~4% | Viola |
| 5 | Leggendario | ~0.8% | Oro |
| 6 | Mitico | ~0.15% | Arancione |
| 7 | Divino | ~0.04% | Rosa |
| 8 | Segreto / Cosmico | < 0.01% | Teal / Bianco |

I drop rate sono valori base. Il motore RNG applica luck boost, prestige bonus, boost eventi e pity counter.

### Mutazioni

| Mutazione | Moltiplicatore valore | Probabilità |
|---|---|---|
| Golden ✨ | ×5 | ~2% |
| Diamond 💎 | ×10 | ~0.8% |
| Radioactive ☢️ | ×15 | ~0.3% |
| Galaxy 🌌 | ×25 | ~0.1% |
| Void 🕳️ | ×40 | ~0.02% |

---

## 🗺 Roadmap

| Fase | Stato | Descrizione |
|---|---|---|
| 1 — Core Gameplay | ✅ Completato | Container, RNG, inventario, roulette, reveal, progressione |
| 2 — Progressione & Social | ✅ Completato | Missioni, upgrade, crafting, clan, trade, leaderboard |
| 3 — Backend & Auth | ✅ Completato | Firebase Auth, Firestore sync, Google Sign-In, leaderboard reale |
| 4 — UI Premium | ✅ Completato | Animazioni, podio, pill nav, glow, confetti, haptic |
| 5 — Monetizzazione | 🔄 In corso | IAP gem pack, VIP Pass, Battle Pass, rewarded ads |
| 6 — Release | ⏳ Pianificato | Asset finali, tutorial, onboarding, Play Store / App Store |
| 7 — Post-Launch | ⏳ Pianificato | Eventi stagionali, tornei, aste, clan wars |

---

## 🐛 Troubleshooting

| Problema | Fix |
|---|---|
| `firebase_options.dart` mancante | Esegui `flutterfire configure` |
| Errori adapter Hive | `dart run build_runner build --delete-conflicting-outputs` |
| Login non funziona | Controlla le Firestore Security Rules (vedi sopra) |
| Google Sign-In non disponibile | Aggiungi il tuo SHA-1 nelle impostazioni Firebase |
| Build fallisce | `flutter clean && flutter pub get` poi riprova |
| Plugin non supportati su web | Alcuni plugin IAP/AdMob richiedono Android/iOS |

---

## 📄 Licenza

Tutti i diritti riservati © 2026 Varisco07
