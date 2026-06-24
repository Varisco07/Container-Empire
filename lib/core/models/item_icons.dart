/// ─────────────────────────────────────────────────────────────────────────────
/// ICONE OGGETTI — fonte di verità UNICA per le emoji degli item.
/// Tutti i widget (reveal, multi-reveal, inventario, collezione, roulette,
/// share) usano [itemEmoji] così aggiungendo un container nuovo basta mettere
/// le sue icone QUI e appaiono ovunque. Fallback: 📦.
/// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> kItemEmojis = {
  // Base / Free / Basic
  'Bullone Arrugginito': '🔩', 'Bottiglia Vuota': '🍶', 'Chiave Inglese': '🔧',
  'Orologio Rotto': '⌚', 'Moneta Antica': '🪙', 'Cacciavite': '🪛',
  'Martello': '🔨', 'Smartphone Vecchio': '📱', 'Orologio Vintage': '⌚',
  'Chitarra Acustica': '🎸', 'Vaso Ming': '🏺',
  // Industrial
  'Trapano Industriale': '🔧', 'Saldatrice': '⚡', 'Generatore': '🔋',
  'CNC Machine Part': '⚙️', 'Prototipo Robot': '🤖', 'Core Nucleare Piccolo': '☢️',
  // Military
  'Elmetto Tattico': '🪖', 'Giubbotto Antiproiettile': '🦺', 'Drone Militare': '🚁',
  'Visore Notturno': '🔭', 'Esoscheletro Prototipo': '🦾', 'Stealth Tech Module': '🛡️',
  // Luxury
  'Orologio Rolex': '⌚', 'Borsa Hermès': '👜', 'Anello con Diamante': '💍',
  'Quadro Picasso': '🖼️', 'Corona Reale': '👑', 'Ferrari Miniatura d\'Oro': '🏎️',
  // Space
  'Meteorite Frammento': '☄️', 'Luna Rock Certificato': '🌙',
  'Satellite Disattivato': '🛰️', 'Cristallo Alieno': '💎',
  'Stardust Vial': '✨', 'Nucleo di Stella di Neutroni': '⭐',
  // Quantum
  'Bit Quantistico': '🔮', 'Entangled Particle Pair': '🌀',
  'Quantum Processor': '💻', 'Materia Oscura Campione': '🕳️',
  'Singolarità Compressa': '🌌', 'Frammento Big Bang': '💥', 'Ω Omega Particle': '⚛️',
  'Fenice Cosmica': '🔥', 'Cristallo dell\'Universo': '💠', 'Singolarità Primordiale': '🌌',
  // Cosmic (10M)
  'Polvere Cosmica': '✨', 'Cristallo di Plasma': '🔮', 'Reliquia Stellare': '🌟',
  'Frammento di Cometa': '☄️', 'Cuore di Supernova': '💥', 'Essenza del Vuoto': '🕳️',
  'Lacrima della Galassia': '💧', 'Fenice Eterna': '🔥',
  // Galactic (100M)
  'Gas Nebulare': '🌫️', 'Lega Galattica': '🔩', 'Nucleo di Pulsar': '🌀',
  'Anello di Saturno': '🪐', 'Frammento di Quasar': '💫', 'Corona Galattica': '👑',
  'Sigillo delle Stelle': '⭐', 'Trono Galattico': '👑',
  // Multiverse (1B)
  'Eco Dimensionale': '🔊', 'Scheggia di Realtà': '🔷', 'Chiave Interdimensionale': '🗝️',
  'Specchio dei Paralleli': '🪞', 'Nodo del Multiverso': '🕸️', 'Codice della Creazione': '📜',
  'Occhio dell\'Infinito': '👁️', 'Cuore del Multiverso': '💠',
  // Singularity (10B)
  'Frammento di Orizzonte': '🌑', 'Materia Degenerata': '⚫', 'Filamento Gravitazionale': '〰️',
  'Nucleo di Buco Nero': '⚫', 'Radiazione di Hawking': '☢️', 'Punto di Singolarità': '🕳️',
  'Origine del Tempo': '⏳', 'Big Bang Compresso': '💥',
};

/// Emoji per il nome di un oggetto (📦 se sconosciuto).
String itemEmoji(String name) => kItemEmojis[name] ?? '📦';
