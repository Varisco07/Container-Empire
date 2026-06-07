# CONTAINER EMPIRE — ROADMAP DI SVILUPPO

## FASE 1 — CORE GAMEPLAY (Settimane 1-3)
**Obiettivo:** Il gioco gira e si può aprire un container.

### Task
- [x] Struttura progetto Flutter / Clean Architecture
- [x] Sistema rarità (8 livelli)
- [x] Sistema mutazioni (5 tipi)
- [x] RNG avanzato con luck boost e moltiplicatori
- [x] Modelli dati (ItemModel, PlayerModel, ContainerModel)
- [x] Servizi core (PlayerService, InventoryService, RngService)
- [x] Hive local persistence
- [x] Home screen con selezione container
- [x] Schermata apertura container
- [x] Animazione roulette (Flutter)
- [x] Animazione container Flame Engine
- [x] Item reveal card con glow rarità
- [x] Inventario con filtri, search, sort
- [x] Vendita oggetti (singola, multipla, tutto)
- [x] Sistema lock oggetto
- [x] Barra valute (monete + gemme)
- [x] Sistema livelli + XP

---

## FASE 2 — CONTENUTO & PROGRESSION (Settimane 4-6)

### Task
- [ ] Missioni giornaliere/settimanali/permanenti (Firestore)
- [ ] Sistema potenziamenti completo (collegare a PlayerModel)
- [ ] Collezione Pokédex con % completamento per rarity
- [ ] Auto-Open funzionante con timer
- [ ] Auto-Sell funzionante
- [ ] Free Container con cooldown 24h
- [ ] Sistema eventi live (RemoteConfig)
- [ ] Lucky Weekend, Galaxy Week, ecc.
- [ ] Audio SFX: apertura, rarità reveal, monete
- [ ] Particelle Flame per ogni livello di rarità

---

## FASE 3 — ONLINE & SOCIAL (Settimane 7-9)

### Task
- [ ] Firebase Authentication (anonima + Google Sign-In)
- [ ] Sincronizzazione cloud PlayerModel
- [ ] Leaderboard globale su Firestore
- [ ] Cloud Functions: aggiornamento leaderboard, validazione acquisti
- [ ] Firebase Remote Config: bilanciamento odds, prezzi eventi
- [ ] Firebase Analytics: tracking aperture, funnel IAP
- [ ] Crashlytics integrazione

---

## FASE 4 — MONETIZZAZIONE (Settimane 10-11)

### Task
- [ ] Google AdMob: banner (schermate secondarie), rewarded (gemme)
- [ ] In-App Purchase: pacchetti gemme (6 tier)
- [ ] Starter Pack one-time
- [ ] VIP Pass mensile (abbonamento)
- [ ] Battle Pass stagionale
- [ ] Validazione server acquisti (Cloud Functions)

---

## FASE 5 — POLISH & RELEASE (Settimane 12-14)

### Task
- [ ] Asset grafici finali (container, icone oggetti)
- [ ] Font Rajdhani integrato
- [ ] Lottie animations per apertura container
- [ ] Tutorial interattivo primo avvio
- [ ] Onboarding con container gratuito iniziale
- [ ] Rating prompt (after first legendary)
- [ ] Test su dispositivi reali Android + iOS
- [ ] Performance: 60 FPS verificato
- [ ] Google Play Store listing
- [ ] Apple App Store listing
- [ ] Privacy Policy + Terms of Service
- [ ] ASO (App Store Optimization)

---

## FASE 6 — POST-LAUNCH (Mese 2+)

### Task
- [ ] Evento stagionale (Natale, Halloween, ecc.)
- [ ] Nuovo tier container (Ultra Quantum, Cosmic)
- [ ] Trade system (scambia oggetti con altri player)
- [ ] Guild/Clan system
- [ ] Weekly tournament con premi esclusivi
- [ ] Nuove mutazioni (Prismatic, Cosmic)
- [ ] Pet companion (cosmetico)
- [ ] Push notifications eventi

---

## STACK TECNOLOGICO

| Layer | Tecnologia |
|-------|-----------|
| UI | Flutter 3.x + Material 3 Dark |
| Game Engine | Flame 1.17+ |
| State Management | Riverpod 2.x |
| Local Storage | Hive 2.x |
| Backend | Firebase (Auth, Firestore, Functions, RC, Analytics) |
| Ads | Google Mobile Ads SDK |
| IAP | in_app_purchase |
| Navigation | GoRouter 14.x |
| DI | GetIt 8.x |
| Animations | flutter_animate, Lottie |

---

## STRATEGIA MONETIZZAZIONE

### Revenue Mix Target
- 40% IAP (pacchetti gemme, VIP, Battle Pass)
- 35% Rewarded Ads (gem gratis, boost 30min)
- 15% Subscription VIP
- 10% Banner Ads

### Pricing
| Prodotto | Prezzo | Valore |
|---------|--------|--------|
| Gemme Starter (50) | €0.99 | Base |
| Gemme Small (150) | €2.49 | +20% |
| Gemme Medium (350) | €4.99 | +40% |
| Gemme Large (800) | €9.99 | +60% |
| Gemme XL (2000) | €19.99 | +100% |
| Gemme XXL (5000) | €49.99 | +150% |
| Starter Pack | €4.99 | One-time |
| VIP Pass | €9.99/mese | Abbonamento |
| Battle Pass | €6.99/stagione | Stagionale |

---

## STRATEGIA PUBBLICAZIONE

### Android (Google Play)
1. Crea account Google Play Console (€25 una tantum)
2. Configura app bundle (AAB) con Gradle
3. Configura Firebase App Distribution per beta test
4. Internal testing → Closed testing (100 tester) → Open testing → Production
5. ASO: keywords "container opening", "case simulator", "loot box game"
6. Screenshot 16:9 + feature graphic 1024×500

### iOS (App Store)
1. Apple Developer Program (€99/anno)
2. Configura Xcode signing con provisioning profile
3. TestFlight beta testing
4. App Review: dichiarare chiaramente meccaniche loot box
5. Age rating: 4+ (no violenza, gambling disclosure richiesta)
6. Privacy Nutrition Labels (IDFA, Firebase)

### KPI Target (Mese 3)
- D1 Retention: >40%
- D7 Retention: >20%
- D30 Retention: >8%
- ARPU: >€1.50
- Session length: >8 min
- Sessions/day: >4
