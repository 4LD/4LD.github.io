// =============================================================================
// PlutokuJS.js — Port JavaScript de PlutokuNext.jl
// Inspiré de : PlutokuNext.jl (Pluto.jl / Julia) par Alexis
// v1.8.9 bêta mardi 07/07/2026 🎈
// =============================================================================
//
// PLAN DES ÉTAPES (≤ 4h chacune) :
//
//  Étape 1 (ce fichier) ── Structures de base + résoutSudoku (propagation simple)
//    → kelcar, carr, jsvd, jsm/mjs, adini, jcvd
//    → vérifSudokuBon, simPossible
//    → résoutSudoku  (propagation naked singles + backtracking)
//    → résoutSudokuMax appelé quand limite nbTmax atteinte (stub → étape 2)
//
//  Étape 2 ── résoutSudokuMax complet
//    → chiPossible (avec mImp : contraintes propagées)
//    → Dicompte, Dicoréz, Dicombo (en objets JS)
//    → sac, uniclk, pasAssezDePropal
//    → résoutSudokuMax (hidden singles, pointing pairs, naked sets + backtracking)
//
//  Étape 3 ── Génération aléatoire + mémoire
//    → sudokuAléatoireFini, sudokuAléatoire
//    → SudokuMémo, vieuxSudoku (chargement dans l'UI)
//    → tousudoku (parse texte → grille)
//
//  Étape 4 ── UI : createsudini / makesudiniReactive
//    → Grille de saisie interactive (inputs)
//    → Navigation clavier + bidouilliste (raccourcis AZERTY)
//    → misEnValeurSiDoublonChiffre (animation endouble-shake)
//
//  Étape 5 ── UI : createsudfini / msga
//    → Affichage de la solution
//    → Pointer events (feedback tactile)
//    → Va-et-vient (swap solution ↔ grille initiale)
//
//  Étape 6 ── UI : createsudpropal
//    → Aide visuelle : chiffres possibles par case
//    → Mode "par chiffre", "par case", "par total (minima ✔)"
//    → Caroligne ⚔ (cases liées)
//
//  Étape 7 ── index.html + intégration
//    → Page HTML autonome (CSS inline + JS)
//    → Boutons, radio, état global
//    → PWA manifest optionnel
//
// =============================================================================
//
// FORMAT DES DONNÉES (convention interne) :
//   mat[r][c]  — matrice row-major 9×9, r=ligne (0..8), c=colonne (0..8)
//   JSudoku (format Julia) = tableau de 9 colonnes : jsu[c][r]
//     → jsm(jsu)  converti en mat[r][c]
//     → mjs(mat)  converti en jsu[c][r]
//   Relation : mat[r][c]  ≡  julia_mat[r+1, c+1]  ≡  jsu[c][r]
//
// =============================================================================

'use strict';

// ── CONSTANTES ────────────────────────────────────────────────────────────────

const nbTmax    = 81;   // nb de tours max dans résoutSudoku avant résoutSudokuMax
const àcorriger = '😜 Merci de corriger le Sudoku';
const impossible = '🧐 Sudoku faux et impossible';

// ── UTILITAIRES DE BASE ───────────────────────────────────────────────────────

/** kelcar(r,c) → numéro du carré 0..8, r et c de 0 à 8  ↔  Julia kelcarré(i,j) */
const kelcar = (r, c) => Math.floor(r/3)*3 + Math.floor(c/3);

/** carr(r) → les 3 indices [d, d+1, d+2] du carré sur cet axe  ↔  Julia carr(i) */
const carr = (r) => { const d = Math.floor(r/3)*3; return [d, d+1, d+2]; };

/** Crée une matrice 9×9 remplie de zéros (row-major)  ↔  Julia jsvd() mais en mat */
const matVide = () => Array.from({length:9}, () => new Array(9).fill(0));

// ── CONVERSIONS Julia JSudoku ↔ mat row-major ─────────────────────────────────

/** jsvd() → sudoku vide au format JSudoku Julia (9 colonnes de 9 zéros)  ↔  Julia jsvd() */
const jsvd = () => Array.from({length:9}, () => new Array(9).fill(0));

/**
 * jsm(jsu) — JSudoku Julia (col-major jsu[c][r]) → mat row-major mat[r][c]
 * Équivalent Julia : listeJSàmatrice(JSudoku)  (hcat)
 */
const jsm = (jsu) =>
  Array.from({length:9}, (_,r) =>
    Array.from({length:9}, (_,c) => jsu[c][r]));

/**
 * mjs(mat) — mat row-major mat[r][c] → JSudoku Julia (col-major jsu[c][r])
 * Équivalent Julia : matriceàlisteJS(mat)
 */
const mjs = (mat) =>
  Array.from({length:9}, (_,c) =>
    Array.from({length:9}, (_,r) => mat[r][c]));

/** adini() → sudoku par défaut (initiales, format JSudoku Julia)  ↔  Julia adini() */
const adini = () => [
  new Array(9).fill(0), new Array(9).fill(0),
  [0,1,2,3,4,5,0,0,0], [0,2,0,0,3,0,6,0,0],
  [0,3,4,5,6,0,0,7,0], [0,6,0,0,7,0,8,0,0],
  [0,7,0,0,8,9,0,0,0],
  new Array(9).fill(0), new Array(9).fill(0)
];

/** jcvd() → sudoku vide sauf une case aléatoire (format JSudoku Julia)  ↔  Julia jcvd() */
const jcvd = () => {
  const jsu = jsvd();
  jsu[Math.floor(Math.random()*9)][Math.floor(Math.random()*9)] =
    1 + Math.floor(Math.random()*9);
  return jsu;
};

// ── COPIE ─────────────────────────────────────────────────────────────────────

/** copyMat(mat) → copie profonde d'une matrice 9×9 */
const copyMat = (mat) => mat.map(row => [...row]);

/** copyZéros(s) → copie d'un Set de clés "r,c" */
const copyZéros = (s) => new Set(s);

// ── UTILITAIRE SET ────────────────────────────────────────────────────────────

/**
 * setTake(s) → extrait et retourne un élément du Set (comme Julia pop!)
 * Attention : modifie s en place
 */
const setTake = (s) => {
  const v = s.values().next().value;
  s.delete(v);
  return v;
};

// ── VÉRIFICATION ──────────────────────────────────────────────────────────────

/**
 * vérifSudokuBon(mat) → true si pas de doublon sur lignes/cols/carrés
 * ↔ Julia vérifSudokuBon(mat::Matrix{Int})
 * mat : row-major mat[r][c]
 */
function vérifSudokuBon(mat) {
  const lignes   = Array.from({length:9}, () => new Set());
  const colonnes = Array.from({length:9}, () => new Set());
  const carrés   = Array.from({length:9}, () => new Set());
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const n = mat[r][c];
      if (n !== 0) {
        const k = kelcar(r, c);
        if (lignes[r].has(n) || colonnes[c].has(n) || carrés[k].has(n)) return false;
        lignes[r].add(n); colonnes[c].add(n); carrés[k].add(n);
      }
    }
  }
  return true;
}

// ── POSSIBLES SIMPLES ─────────────────────────────────────────────────────────

/**
 * simPossible(mat, r, c) → Set<number> des chiffres 1..9 possibles à (r,c)
 * ↔ Julia simPossible(mat::Matrix{Int}, c::Case)
 */
function simPossible(mat, r, c) {
  const exclu = new Set();
  const [cr0, cr1, cr2] = carr(r);
  const [cc0, cc1, cc2] = carr(c);
  // Ligne r
  for (let x = 0; x < 9; x++) exclu.add(mat[r][x]);
  // Colonne c
  for (let x = 0; x < 9; x++) exclu.add(mat[x][c]);
  // Carré
  for (const kr of [cr0, cr1, cr2])
    for (const kc of [cc0, cc1, cc2])
      exclu.add(mat[kr][kc]);
  exclu.delete(0);
  const res = new Set();
  for (let n = 1; n <= 9; n++) if (!exclu.has(n)) res.add(n);
  return res;
}

// ── SOLVEUR PRINCIPAL (propagation simple + backtracking) ─────────────────────
//
// Port fidèle de résoutSudoku() dans PlutokuNext.jl.
// Utilise uniquement simPossible (naked singles).
// Si nbTmax tours est atteint, délègue à résoutSudokuMax (étape 2, stub pour l'instant).
//
// Structures de backtracking :
//   listedechoix      ↔  Julia listedechoix::Choix[]
//   listedancienneMat ↔  Julia listedancienneMat::Matrix{Int}[]
//   listedesZéros     ↔  Julia listedesZéros::Set{Case}[]
//
// Représentation des cases vides : Set<string> de clés "r,c"
// Représentation d'un choix : {r, c, n, max, rcl: Set<number>}
//   ↔ Julia struct Choix { c::Case; n::Int; max::Int; rcl::Set{Int} }
//

/**
 * résoutSudoku(jsu, nbToursMax?) → [jsu_résolu, statsMsg]  |  [àcorriger, msg]  |  [impossible, msg]
 * Entrée  : jsu au format JSudoku Julia (col-major)
 * Sortie  : idem ou constantes àcorriger / impossible
 * ↔ Julia résoutSudoku(JSudoku::Vector{Vector{Int}}, nbToursMax::Int = nbTmax)
 */
function résoutSudoku(jsu, nbToursMax = nbTmax) {
  const mat = jsm(jsu);  // copie row-major (on va la muter)
  if (!vérifSudokuBon(mat)) return [àcorriger, àcorriger];

  // Initialisation des cases vides (Set de clés "r,c")
  let lesZéros = new Set();
  for (let r = 0; r < 9; r++)
    for (let c = 0; c < 9; c++)
      if (mat[r][c] === 0) lesZéros.add(`${r},${c}`);

  // Structures de backtracking
  const listedechoix      = [];  // {r, c, n, max, rcl: Set<number>}
  const listedancienneMat = [];  // copies de mat
  const listedesZéros     = [];  // copies de lesZéros

  let nbChoixfait         = 0;
  let nbToursTotal        = 0;
  let allerAuChoixSuivant = false;
  let choixPrécédent      = null;
  let choixAfaire         = null;
  let çaNavancePas        = true;
  let lesZérosàSuppr      = new Set();

  while (lesZéros.size > 0 && nbToursTotal < nbToursMax) {

    // ── Phase de propagation ──────────────────────────────────────────────────
    if (!allerAuChoixSuivant) {
      nbToursTotal++;
      çaNavancePas = true;
      let minChoix = 10;
      choixAfaire  = null;
      lesZérosàSuppr = new Set();

      for (const key of lesZéros) {
        const [r, c] = key.split(',').map(Number);
        const liste = simPossible(mat, r, c);

        if (liste.size === 0) {
          // Impasse → mauvais choix précédent
          allerAuChoixSuivant = true;
          lesZérosàSuppr = new Set();
          break;
        } else if (liste.size === 1) {
          // Unique possibilité : on remplit tout de suite (naked single)
          mat[r][c] = setTake(liste);
          lesZérosàSuppr.add(key);
          çaNavancePas = false;
        } else if (çaNavancePas && liste.size < minChoix) {
          // On garde la case avec le moins de choix pour le backtracking
          minChoix    = liste.size;
          choixAfaire = {r, c, n:1, max:minChoix, rcl: liste};
        }
      }
    }

    // ── Phase de backtracking ─────────────────────────────────────────────────
    if (allerAuChoixSuivant) {
      if (listedechoix.length === 0) return [impossible, impossible]; // pas de bol hein

      const prev = choixPrécédent; // ↔ Julia choixPrécédent

      if (prev.n < prev.max) {
        // Aller au choix suivant (même niveau)  ↔  Julia : Choix(c, n+1, max, rcl)
        prev.n++;
        listedechoix[nbChoixfait - 1] = prev;
        const backup = listedancienneMat[nbChoixfait - 1];
        for (let r = 0; r < 9; r++) mat[r] = [...backup[r]];
        allerAuChoixSuivant = false;
        mat[prev.r][prev.c] = setTake(prev.rcl); // pop!(rcl)
        lesZéros = copyZéros(listedesZéros[nbChoixfait - 1]);

      } else if (listedechoix.length < 2) {
        return [impossible, impossible]; // pas 2 bol

      } else {
        // Revenir d'un cran  ↔  Julia : map(pop!, (listedechoix, ...))
        listedechoix.pop();
        listedancienneMat.pop();
        listedesZéros.pop();
        nbChoixfait--;
        choixPrécédent = listedechoix[nbChoixfait - 1];
      }

    } else if (çaNavancePas && choixAfaire) {
      // ── Nouveau choix à faire et à garder en mémoire ──────────────────────
      //  ↔ Julia : push!(listedechoix, choixAfaire); delete!(lesZéros, caf); ...
      listedechoix.push(choixAfaire);
      listedancienneMat.push(copyMat(mat));
      lesZéros.delete(`${choixAfaire.r},${choixAfaire.c}`); // on retire AVANT de copier
      listedesZéros.push(copyZéros(lesZéros));
      nbChoixfait++;
      mat[choixAfaire.r][choixAfaire.c] = setTake(choixAfaire.rcl); // pop!(rcl)
      choixPrécédent = choixAfaire;

    } else if (!çaNavancePas) {
      // ── Tout va bien : on retire les cases remplies ────────────────────────
      for (const key of lesZérosàSuppr) lesZéros.delete(key);
      lesZérosàSuppr = new Set();
    }
    // Note : si çaNavancePas && !choixAfaire → toutes les cases vides ont 0 possibilité
    // → sera capturé à la prochaine itération (allerAuChoixSuivant)
  }

  // ── Vérification fin de boucle ────────────────────────────────────────────
  if (nbToursTotal >= nbToursMax) {
    // Limite atteinte → retour au 1er niveau de choix puis résoutSudokuMax
    // ↔ Julia résoutSudoku (fin : construction de dicoréz et appel résoutSudokuMax)
    if (listedancienneMat.length > 0) {
      const backup = listedancienneMat[0];
      for (let r = 0; r < 9; r++) mat[r] = [...backup[r]];
      const caf = listedechoix[0];
      mat[caf.r][caf.c] = 0;
      lesZéros = copyZéros(listedesZéros[0]);
      lesZéros.add(`${caf.r},${caf.c}`);
    }
    const soréz = newDicoréz();
    for (const key of lesZéros) {
      const [r, c] = key.split(',').map(Number);
      pushfun(soréz, r, c, kelcar(r, c));
    }
    return résoutSudokuMax(mat, lesZéros, soréz, nbToursTotal);
  }

  // ── Succès ────────────────────────────────────────────────────────────────
  const pluriel = nbToursTotal > 1 ? 'tours' : 'tour';
  return [
    mjs(mat),
    `Statistiques : ce programme fait ${nbChoixfait} choix et ${nbToursTotal} ${pluriel} pour résoudre ce sudoku`
  ];
}

// =============================================================================
// ÉTAPE 2 : résoutSudokuMax — propagation avancée
//   chiPossible (avec mImp)  +  Dicoréz / Dicompte / Dicombo
//   sac  +  uniclk  +  pasAssezDePropal  +  résoutSudokuMax
// =============================================================================

// ── chiPossible ───────────────────────────────────────────────────────────────

/**
 * chiPossible(mat, r, c, cr, cc, mImp) → Set<number>
 * Comme simPossible mais exclut aussi les chiffres impossibles déduits (mImp).
 * ↔ Julia chiPossible(mat, c::Case, limp::Set{Int})
 * mImp : Map<"r,c", Set<number>>  (contraintes propagées)
 */
function chiPossible(mat, r, c, cr, cc, mImp) {
  const limp = mImp.get(`${r},${c}`) ?? new Set();
  const exclu = new Set(limp);
  for (let x = 0; x < 9; x++) exclu.add(mat[r][x]);
  for (let x = 0; x < 9; x++) exclu.add(mat[x][c]);
  for (const kr of cr) for (const kc of cc) exclu.add(mat[kr][kc]);
  exclu.delete(0);
  const res = new Set();
  for (let n = 1; n <= 9; n++) if (!exclu.has(n)) res.add(n);
  return res;
}

// ── Dicoréz : cases vides indexées par ligne / colonne / carré ─────────────────
// ↔ Julia struct Dicoréz { lig, col, car }

function newDicoréz() {
  return { lig: new Map(), col: new Map(), car: new Map() };
}
/** pushfun(d, r, c, k) — enregistre une case vide dans Dicoréz */
function pushfun(d, r, c, k) {
  if (!d.lig.has(r)) d.lig.set(r, new Set());
  d.lig.get(r).add(c);
  if (!d.col.has(c)) d.col.set(c, new Set());
  d.col.get(c).add(r);
  if (!d.car.has(k)) d.car.set(k, new Set());
  d.car.get(k).add(`${r},${c}`);
}
/** deletefun(d, r, c, k) — retire une case de Dicoréz */
function deletefun(d, r, c, k) {
  d.lig.get(r)?.delete(c);
  d.col.get(c)?.delete(r);
  d.car.get(k)?.delete(`${r},${c}`);
}
function deepCopyDicoréz(d) {
  return {
    lig: new Map([...d.lig].map(([k,v]) => [k, new Set(v)])),
    col: new Map([...d.col].map(([k,v]) => [k, new Set(v)])),
    car: new Map([...d.car].map(([k,v]) => [k, new Set(v)]))
  };
}
const deepCopyMImp = (m) => new Map([...m].map(([k,v]) => [k, new Set(v)]));

// ── ajoute / nettoie (pour résoutSudokuMax) ───────────────────────────────────
// ↔ Julia ajoute() et nettoie() dans PlutokuNext.jl

function ajoute(mat, r, c, k, n, lesZérosàSuppr, dz) {
  mat[r][c] = n;
  lesZérosàSuppr.add(`${r},${c}`);
  deletefun(dz, r, c, k);
}
function nettoie(r, c, k, n, nbs) {
  nbs.lig.get(r)?.delete(n);
  nbs.col.get(c)?.delete(n);
  nbs.car.get(k)?.delete(n);
}

// ── Dicompte : comptage des chiffres possibles par ligne / col / carré ─────────
// ↔ Julia struct Dicompte { lig, col, car, ful, fuc, fuk }
// Sisenettoie ↔ { statut, r, c, k, cr, cc }
//   statut 1=unique, 2=pointing via lig, 3=via col, 4=via car→lig, 5=via car→col

function newDicompte() {
  return {
    lig: new Map(), col: new Map(), car: new Map(),
    ful: new Map(), fuc: new Map(), fuk: new Map()
  };
}
function getfunDicompte(nbs, r, c, k) {
  if (!nbs.lig.has(r)) nbs.lig.set(r, new Map());
  if (!nbs.col.has(c)) nbs.col.set(c, new Map());
  if (!nbs.car.has(k)) nbs.car.set(k, new Map());
  if (!nbs.ful.has(r)) nbs.ful.set(r, new Set());
  if (!nbs.fuc.has(c)) nbs.fuc.set(c, new Set());
  if (!nbs.fuk.has(k)) nbs.fuk.set(k, new Set());
}

// ── Dicombo : naked sets (ensembles nus) ──────────────────────────────────────
// ↔ Julia struct Dicombo { lig, col, car }
// Clés : sets sérialisés en JSON trié (car JS Set ≠ Map key par valeur)

const setKey = (s) => JSON.stringify([...s].sort((a, b) => a - b));
function newDicombo() {
  return { lig: new Map(), col: new Map(), car: new Map() };
}

// ── sac ───────────────────────────────────────────────────────────────────────

/**
 * sac(nbs, r, c, k, cr, cc, listepossibles)
 * Compte chaque chiffre possible : détecte hidden singles et pointing pairs.
 * ↔ Julia sac!(nbs::Dicompte, c::Case, listepossibles::Set{Int})
 */
function sac(nbs, r, c, k, cr, cc, listepossibles) {
  getfunDicompte(nbs, r, c, k);
  const lig_dict = nbs.lig.get(r),  col_dict = nbs.col.get(c),  car_dict = nbs.car.get(k);
  const ful_i    = nbs.ful.get(r),  fuc_j    = nbs.fuc.get(c),  fuk_k    = nbs.fuk.get(k);

  for (const n of listepossibles) {
    // ── Ligne ──
    if (!ful_i.has(n)) {
      const nbsin = lig_dict.get(n);
      if      (nbsin === undefined)     lig_dict.set(n, {statut:1, r, c, k, cr, cc});
      else if (nbsin.k === k)           nbsin.statut = 2;  // pointing pair potentiel
      else { ful_i.add(n); lig_dict.delete(n); }           // vu dans ≥2 carrés → grillé
    }
    // ── Colonne ──
    if (!fuc_j.has(n)) {
      const nbsjn = col_dict.get(n);
      if      (nbsjn === undefined)     col_dict.set(n, {statut:1, r, c, k, cr, cc});
      else if (nbsjn.k === k)           nbsjn.statut = 3;
      else { fuc_j.add(n); col_dict.delete(n); }
    }
    // ── Carré ──
    if (!fuk_k.has(n)) {
      const nbskn = car_dict.get(n);
      if      (nbskn === undefined)                          car_dict.set(n, {statut:1, r, c, k, cr, cc});
      else if (nbskn.r === r && nbskn.statut !== 5)          nbskn.statut = 4;  // même ligne
      else if (nbskn.c === c && nbskn.statut !== 4)          nbskn.statut = 5;  // même col
      else { fuk_k.add(n); car_dict.delete(n); }
    }
  }
}

// ── uniclk ────────────────────────────────────────────────────────────────────

/**
 * uniclk(nbs, çaNavancePas, mat, lesZérosàSuppr, soréz, mImp)
 *   → retourne çaNavancePas mis à jour (false = au moins un chiffre placé),
 *     ou false pour contradiction (n plus possible dans mImp).
 * ↔ Julia uniclk!(nbs, çaNavancePas, mat, lesZérosàSuppr, soréz, dimp)
 */
function uniclk(nbs, çaNavancePas, mat, lesZérosàSuppr, soréz, mImp) {

  // ── Lignes : hidden singles + pointing pairs via ligne ────────────────────
  for (const [i, nbsi] of nbs.lig) {
    for (const [n, nbsin] of nbsi) {
      if (nbsin.statut === 2) {
        // Pointing pair : n n'apparaît dans la ligne i que dans le carré k
        // → retirer n des cases du carré k qui NE sont PAS dans la ligne i
        const squareCells = soréz.car.get(nbsin.k) ?? new Set();
        for (const cellKey of squareCells) {
          const lr = parseInt(cellKey)  // fast: first char before ','
          || Number(cellKey.split(',')[0]);
          if (Number(cellKey.split(',')[0]) !== i) {
            if (!mImp.has(cellKey)) mImp.set(cellKey, new Set());
            mImp.get(cellKey).add(n);
          }
        }
      } else {  // statut == 1 : hidden single dans la ligne i
        const {c: hc, k: hk, cr: hcr, cc: hcc} = nbsin;
        if (!chiPossible(mat, i, hc, hcr, hcc, mImp).has(n)) return false;
        ajoute(mat, i, hc, hk, n, lesZérosàSuppr, soréz);
        nbs.col.get(hc)?.delete(n);
        nbs.car.get(hk)?.delete(n);
        çaNavancePas = false;
      }
    }
  }

  // ── Colonnes : hidden singles + pointing pairs via colonne ────────────────
  for (const [j, nbsj] of nbs.col) {
    for (const [n, nbsjn] of nbsj) {
      if (nbsjn.statut === 3) {
        // Pointing pair : n n'apparaît dans la col j que dans le carré k
        const squareCells = soréz.car.get(nbsjn.k) ?? new Set();
        for (const cellKey of squareCells) {
          if (Number(cellKey.split(',')[1]) !== j) {
            if (!mImp.has(cellKey)) mImp.set(cellKey, new Set());
            mImp.get(cellKey).add(n);
          }
        }
      } else {  // statut == 1 : hidden single dans la col j
        const {r: hr, k: hk, cr: hcr, cc: hcc} = nbsjn;
        if (!chiPossible(mat, hr, j, hcr, hcc, mImp).has(n)) return false;
        ajoute(mat, hr, j, hk, n, lesZérosàSuppr, soréz);
        nbs.car.get(hk)?.delete(n);
        çaNavancePas = false;
      }
    }
  }

  // ── Carrés : hidden singles + pointing pairs via carré ────────────────────
  for (const [k, nbsk] of nbs.car) {
    for (const [n, nbskn] of nbsk) {
      if (nbskn.statut === 4) {
        // Pointing pair : n dans le carré k est tout dans la ligne nbskn.r
        // → retirer n des cases de la ligne hors du carré
        const rowCols = soréz.lig.get(nbskn.r) ?? new Set();
        for (const lc of rowCols) {
          if (!nbskn.cc.includes(lc)) {
            const cellKey = `${nbskn.r},${lc}`;
            if (!mImp.has(cellKey)) mImp.set(cellKey, new Set());
            mImp.get(cellKey).add(n);
          }
        }
      } else if (nbskn.statut === 5) {
        // Pointing pair : n dans le carré k est tout dans la col nbskn.c
        const colRows = soréz.col.get(nbskn.c) ?? new Set();
        for (const lr of colRows) {
          if (!nbskn.cr.includes(lr)) {
            const cellKey = `${lr},${nbskn.c}`;
            if (!mImp.has(cellKey)) mImp.set(cellKey, new Set());
            mImp.get(cellKey).add(n);
          }
        }
      } else {  // statut == 1 : hidden single dans le carré k
        const {r: hr, c: hc, cr: hcr, cc: hcc} = nbskn;
        if (!chiPossible(mat, hr, hc, hcr, hcc, mImp).has(n)) return false;
        ajoute(mat, hr, hc, k, n, lesZérosàSuppr, soréz);
        çaNavancePas = false;
      }
    }
  }

  return çaNavancePas;
}

// ── pasAssezDePropal ──────────────────────────────────────────────────────────

/**
 * pasAssezDePropal(permu, r, c, k, cr, cc, soréz, listepossibles, mImp)
 *   → true  si contradiction (plus assez de propositions)
 *   → false si tout va bien
 * Détecte les naked sets (paires/triplets nus) et propage via mImp.
 * ↔ Julia pasAssezDePropal!(permu::Dicombo, c::Case, Nimp, soréz, listepossibles)
 */
function pasAssezDePropal(permu, r, c, k, cr, cc, soréz, listepossibles, mImp) {
  const lkAll = setKey(listepossibles);

  // ── Ligne ──
  if (!permu.lig.has(r)) permu.lig.set(r, new Map());
  const lig_r = permu.lig.get(r);
  for (const [lKey, v] of [...lig_r]) {
    const kk    = new Set([...JSON.parse(lKey), ...listepossibles]);
    const kkKey = setKey(kk);
    if (kk.size > v.size) {
      const vv = new Set([...v, c, ...(lig_r.get(kkKey) ?? new Set())]);
      if (kk.size === vv.size) {
        const rowCols = soréz.lig.get(r) ?? new Set();
        for (const lc of rowCols) {
          if (!vv.has(lc)) {
            const ck = `${r},${lc}`;
            if (!mImp.has(ck)) mImp.set(ck, new Set());
            for (const n of kk) mImp.get(ck).add(n);
          }
        }
      }
      lig_r.set(kkKey, vv);
    } else return true;
  }
  if (!lig_r.has(lkAll)) lig_r.set(lkAll, new Set([c]));

  // ── Colonne ──
  if (!permu.col.has(c)) permu.col.set(c, new Map());
  const col_c = permu.col.get(c);
  for (const [lKey, v] of [...col_c]) {
    const kk    = new Set([...JSON.parse(lKey), ...listepossibles]);
    const kkKey = setKey(kk);
    if (kk.size > v.size) {
      const vv = new Set([...v, r, ...(col_c.get(kkKey) ?? new Set())]);
      if (kk.size === vv.size) {
        const colRows = soréz.col.get(c) ?? new Set();
        for (const lr of colRows) {
          if (!vv.has(lr)) {
            const ck = `${lr},${c}`;
            if (!mImp.has(ck)) mImp.set(ck, new Set());
            for (const n of kk) mImp.get(ck).add(n);
          }
        }
      }
      col_c.set(kkKey, vv);
    } else return true;
  }
  if (!col_c.has(lkAll)) col_c.set(lkAll, new Set([r]));

  // ── Carré ──  (positions = "r,c" strings)
  if (!permu.car.has(k)) permu.car.set(k, new Map());
  const car_k = permu.car.get(k);
  const rcKey = `${r},${c}`;
  for (const [lKey, v] of [...car_k]) {
    const kk    = new Set([...JSON.parse(lKey), ...listepossibles]);
    const kkKey = setKey(kk);
    if (kk.size > v.size) {
      const vv = new Set([...v, rcKey, ...(car_k.get(kkKey) ?? new Set())]);
      if (kk.size === vv.size) {
        const carCells = soréz.car.get(k) ?? new Set();
        for (const lp of carCells) {
          if (!vv.has(lp)) {
            if (!mImp.has(lp)) mImp.set(lp, new Set());
            for (const n of kk) mImp.get(lp).add(n);
          }
        }
      }
      car_k.set(kkKey, vv);
    } else return true;
  }
  if (!car_k.has(lkAll)) car_k.set(lkAll, new Set([rcKey]));

  return false;
}

// ── résoutSudokuMax ───────────────────────────────────────────────────────────

/**
 * résoutSudokuMax(mat, lesZéros, soréz, tours?)
 * Solveur avancé : naked singles + hidden singles + pointing pairs + naked sets
 * + backtracking avec sauvegarde de mImp et soréz.
 * ↔ Julia résoutSudokuMax(mS, lesZéros, dicoréz, tours)
 *
 * mat      : matrice row-major (mutée en place)
 * lesZéros : Set<"r,c"> des cases vides
 * soréz    : Dicoréz (muté en place)
 * tours    : nb de tours déjà effectués dans résoutSudoku
 */
function résoutSudokuMax(mat, lesZéros, soréz, tours = 0) {
  let nbToursTotal        = tours;
  const listedechoix      = [];
  const listedancienneMat = [];
  const listedesZéros     = [];
  const listedancienImp   = [];  // ↔ Julia listedancienImp
  const listedicoréz      = [];  // ↔ Julia listedicoréz

  let nbChoixfait         = 0;
  let allerAuChoixSuivant = false;
  let choixPrécédent      = null;
  let choixAfaire         = null;
  let çaNavancePas        = true;
  let lesZérosàSuppr      = new Set();
  let mImp                = new Map();
  let dicompte            = null;   // créé dans le bloc if (!allerAuChoixSuivant)

  while (lesZéros.size > 0) {

    // ── Phase de propagation avancée ─────────────────────────────────────────
    if (!allerAuChoixSuivant) {
      nbToursTotal++;
      çaNavancePas  = true;
      let minChoix  = 10;
      choixAfaire   = null;
      lesZérosàSuppr = new Set();
      dicompte       = newDicompte();
      const dicombo  = newDicombo();

      for (const key of lesZéros) {
        const [r, c] = key.split(',').map(Number);
        const cr = carr(r), cc = carr(c), k = kelcar(r, c);
        const listechiffre = chiPossible(mat, r, c, cr, cc, mImp);
        sac(dicompte, r, c, k, cr, cc, listechiffre);

        if (listechiffre.size === 0 ||
            pasAssezDePropal(dicombo, r, c, k, cr, cc, soréz, listechiffre, mImp)) {
          allerAuChoixSuivant = true;
          lesZérosàSuppr = new Set();
          break;
        } else if (listechiffre.size === 1) {
          // Naked single
          const pos = [...listechiffre][0];
          ajoute(mat, r, c, k, pos, lesZérosàSuppr, soréz);
          nettoie(r, c, k, pos, dicompte);
          çaNavancePas = false;
        } else if (çaNavancePas && listechiffre.size < minChoix) {
          minChoix    = listechiffre.size;
          choixAfaire = {r, c, k, cr, cc, n:1, max:minChoix, rcl: new Set(listechiffre)};
        }
      }
    }

    // ── uniclk : hidden singles + pointing pairs ──────────────────────────────
    const goBt = allerAuChoixSuivant ||
      uniclk(dicompte, çaNavancePas, mat, lesZérosàSuppr, soréz, mImp);

    if (goBt) {
      if (allerAuChoixSuivant) {
        // ── Backtracking ────────────────────────────────────────────────────
        if (listedechoix.length === 0) return [impossible, impossible];
        const prev = choixPrécédent;
        if (prev.n < prev.max) {
          // Aller au choix suivant  ↔  Julia : Choix(c, n+1, max, rcl)
          prev.n++;
          listedechoix[nbChoixfait - 1] = prev;
          const backup = listedancienneMat[nbChoixfait - 1];
          for (let r = 0; r < 9; r++) mat[r] = [...backup[r]];
          mImp  = deepCopyMImp(listedancienImp[nbChoixfait - 1]);
          soréz = deepCopyDicoréz(listedicoréz[nbChoixfait - 1]);
          allerAuChoixSuivant = false;
          mat[prev.r][prev.c] = setTake(prev.rcl);
          lesZéros = copyZéros(listedesZéros[nbChoixfait - 1]);
        } else if (listedechoix.length < 2) {
          return [impossible, impossible];
        } else {
          // Revenir d'un cran  ↔  Julia : map(pop!, ...)
          listedechoix.pop(); listedancienneMat.pop(); listedancienImp.pop();
          listedesZéros.pop(); listedicoréz.pop();
          nbChoixfait--;
          choixPrécédent = listedechoix[nbChoixfait - 1];
        }
      } else {
        // ── Nouveau choix ────────────────────────────────────────────────────
        listedechoix.push(choixAfaire);
        listedancienneMat.push(copyMat(mat));
        listedancienImp.push(deepCopyMImp(mImp));
        lesZéros.delete(`${choixAfaire.r},${choixAfaire.c}`);
        listedesZéros.push(copyZéros(lesZéros));
        nbChoixfait++;
        deletefun(soréz, choixAfaire.r, choixAfaire.c, choixAfaire.k);
        listedicoréz.push(deepCopyDicoréz(soréz));
        mat[choixAfaire.r][choixAfaire.c] = setTake(choixAfaire.rcl);
        choixPrécédent = choixAfaire;
      }
    } else {
      // ── Retrait des cases remplies ────────────────────────────────────────
      for (const key of lesZérosàSuppr) lesZéros.delete(key);
      lesZérosàSuppr = new Set();
    }
  }

  const pluriel = nbToursTotal > 1 ? 'tours' : 'tour';
  return [
    mjs(mat),
    `Statistiques : ce programme fait ${nbChoixfait} choix et ${nbToursTotal} ${pluriel} pour résoudre ce sudoku`
  ];
}

// =============================================================================
// ÉTAPE 3 : Génération aléatoire + SudokuMémo + tousudoku
// =============================================================================

// ── SudokuMémo (état global) ──────────────────────────────────────────────────
// Index : [0]=vide, [1]=instantané/mémo, [2]=enCours, [3]=défaut, [4+]=historique
// Format JSudoku Julia (col-major jsu[c][r])
// ↔ Julia histo=SudokuMémo = [jsvd(), adini(), adini(), adini()]

let SudokuMémo = [jsvd(), adini(), adini(), adini()];

// ── Utilitaires JSudoku ───────────────────────────────────────────────────────

/** deepCopyJsu(jsu) → copie profonde d'un JSudoku col-major */
const deepCopyJsu = (jsu) => jsu.map(col => [...col]);

/** isJsuEqual(a, b) → true si deux JSudoku sont identiques valeur par valeur */
function isJsuEqual(a, b) {
  for (let c = 0; c < 9; c++)
    for (let r = 0; r < 9; r++)
      if (a[c][r] !== b[c][r]) return false;
  return true;
}

// ── Fisher-Yates shuffle ──────────────────────────────────────────────────────
// Julia shuffle! = identity (désactivé), ici on a besoin d'un vrai shuffle

function shuffleArray(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// ── sudokuAléatoireFini ───────────────────────────────────────────────────────

/**
 * sudokuAléatoireFini() → mat (row-major 9×9), sudoku complet sans case vide
 * ↔ Julia sudokuAléatoireFini() = listeJSàmatrice(first(résoutSudoku(jcvd())))
 */
function sudokuAléatoireFini() {
  const [jsu] = résoutSudoku(jcvd());
  if (typeof jsu === 'string') return matVide(); // fallback (ne devrait pas arriver)
  return jsm(jsu); // JSudoku → mat row-major
}
const saf = sudokuAléatoireFini;  // alias  ↔  Julia saf = maf = sudokuAléatoireFini

// ── sudokuAléatoire ───────────────────────────────────────────────────────────

/**
 * sudokuAléatoire(x?, matzéro?) → jsu (JSudoku col-major)
 * Vide aléatoirement x cases d'un sudoku complet.
 * ↔ Julia sudokuAléatoire(x=19:62 ; fun=rand, matzéro=sudokuAléatoireFini())
 *
 * x       : Int | [min, max] (défaut [19,62])
 * matzéro : mat row-major source (généré si null)
 */
function sudokuAléatoire(x = [19, 62], matzéro = null) {
  if (matzéro === null) matzéro = sudokuAléatoireFini();
  let nb;
  if (Array.isArray(x))           nb = x[0] + Math.floor(Math.random() * (x[1] - x[0] + 1));
  else if (typeof x === 'number') nb = x;
  else                            nb = 19 + Math.floor(Math.random() * 44);
  nb = (nb >= 0 && nb < 82) ? nb : 81;

  const mat = copyMat(matzéro);
  const allCells = [];
  for (let r = 0; r < 9; r++) for (let c = 0; c < 9; c++) allCells.push([r, c]);
  shuffleArray(allCells);
  for (let i = 0; i < nb; i++) mat[allCells[i][0]][allCells[i][1]] = 0;
  return mjs(mat); // mat → JSudoku
}

// ── vieuxSudoku ───────────────────────────────────────────────────────────────

/**
 * vieuxSudoku(nouveau?, opts?) → jsu chargé  (met à jour SudokuMémo)
 * ↔ Julia vieuxSudoku!(nouveau=sudokuAléatoire() ; défaut, mémoire, matzéro, ...)
 *
 * nouveau : JSudoku  |  Int  |  [min,max]  |  null (aléatoire)
 * opts    : { défaut: bool, matzéro: mat|null }
 */
function vieuxSudoku(nouveau = null, { défaut = false, matzéro = null } = {}) {
  const mz = matzéro ?? sudokuAléatoireFini();
  let jsu;

  if (défaut) {
    // Retour au 4e slot (1er historique sauvé)  ↔  Julia mémo[4]
    jsu = deepCopyJsu(SudokuMémo[3]);
  } else if (nouveau === null) {
    jsu = sudokuAléatoire([19, 62], mz);
  } else if (typeof nouveau === 'number') {
    jsu = sudokuAléatoire(nouveau, mz);
  } else if (Array.isArray(nouveau) && typeof nouveau[0] === 'number') {
    // Intervalle [min, max]
    jsu = sudokuAléatoire(nouveau, mz);
  } else if (isJsuEqual(nouveau, SudokuMémo[0])) {
    // Si nouveau == vide → aléatoire  ↔  Julia : nouveau==mémoire[1]
    jsu = sudokuAléatoire([19, 62], mz);
  } else {
    // Copie directe d'un JSudoku fourni
    jsu = deepCopyJsu(nouveau);
  }

  SudokuMémo[1] = jsu; // instantané / mémo  ↔  Julia mémoire[2]
  SudokuMémo[2] = jsu; // en cours           ↔  Julia mémoire[3]
  // Historique  ↔  Julia mémoire[end] != mémoire[2] && push!(mémoire, mémoire[2])
  if (!isJsuEqual(SudokuMémo[SudokuMémo.length - 1], jsu)) SudokuMémo.push(jsu);
  return jsu;
}
const vs  = vieuxSudoku;                                   // alias  ↔  Julia vs = vieux = vS!
const vsd = (opts = {}) => vieuxSudoku(null, { ...opts, défaut: true }); // ↔ Julia vsd

/** sudokuinitial() — restaure SudokuMémo[2] dans le slot mémo  ↔  Julia sudokuinitial!() */
function sudokuinitial() {
  SudokuMémo[1] = deepCopyJsu(SudokuMémo[2]);
  return SudokuMémo[2];
}

// ── tousudoku ─────────────────────────────────────────────────────────────────

/**
 * tousudoku(texte) → mat (row-major 9×9)
 * Parse un texte quelconque en grille sudoku (chiffres 1-9, autres → 0).
 * Formats acceptés : chaîne 81 chars, multi-lignes, Excel 72 tabs.
 * ↔ Julia tousudoku(texte::TexteàPeuPrès)
 */
function tousudoku(texte) {
  if (typeof texte !== 'string') texte = String(texte);
  const tabCount = (texte.match(/\t/g) || []).length;
  if (tabCount === 72) return pastab(texte); // Format Excel  ↔  Julia

  let text = texte.replace(/\n/g, '');
  if (text.length > 81) text = text.replace(/[ \t\u00a0]/g, '').trim();

  const is19 = (ch) => {
    const code = ch.charCodeAt(0);
    return (code >= 49 && code <= 57) ? code - 48 : 0; // '1'..'9' → 1..9
  };
  const mat = matVide();
  const chars = [...text];
  for (let i = 0; i < Math.min(81, chars.length); i++)
    mat[Math.floor(i / 9)][i % 9] = is19(chars[i]);
  return mat;
}
const ts = tousudoku;  // alias  ↔  Julia ts = tousudoku

/**
 * pastab(texte) → mat pour format Excel (72 tabulations)
 * ↔ Julia pastab(t) avec corrections des cases vides
 */
function pastab(texte) {
  let t = texte
    .replace(/\n\t/g, '\n0\t').replace(/\t\n/g, '\t0\n').replace(/\t\t/g, '\t0\t');
  t = t.replace(/^\t/, '0\t').replace(/\t$/, '\t0').replace(/\n/g, '');
  const vals = t.split('\t').map(v => { const n = parseInt(v, 10); return (!isNaN(n) && n >= 1 && n <= 9) ? n : 0; });
  const mat = matVide();
  for (let i = 0; i < Math.min(81, vals.length); i++) mat[Math.floor(i / 9)][i % 9] = vals[i];
  return mat;
}

/** jsuFromTexte(texte) → JSudoku (col-major) prêt pour vieuxSudoku() */
const jsuFromTexte = (texte) => mjs(tousudoku(texte));  // ↔ Julia vieux(toustes(t))

// =============================================================================
// ÉTAPE 4 : UI createsudini / makesudiniReactive — Grille de saisie interactive
// ↔ Julia sudini() + window.createsudini + window.makesudiniReactive
//
// Convention données : data[i][j] = valeur en visual-row i, visual-col j
//   i (outer) = visual row = Julia colonne  →  data correspond à JSudoku
//   j (inner) = visual col = Julia ligne
//   data passé directement à résoutSudoku() sans conversion
// =============================================================================

/**
 * createsudini(values) → { _sudoku: HTMLTableElement, data: Array[][] }
 * Crée la grille sudoku éditable en DOM.
 * values : JSudoku col-major (format SudokuMémo)
 * ↔ JS window.createsudini dans sudini() de PlutokuNext.jl
 */
function createsudini(values) {
  const data  = [];
  const tbody = document.createElement('tbody');

  for (let i = 0; i < 9; i++) {
    data.push([]);
    const tr = document.createElement('tr');
    if (i % 3 === 0) tr.className = 'troisr';

    for (let j = 0; j < 9; j++) {
      const value = values[i]?.[j] || 0;
      data[i][j]  = value;

      const input = document.createElement('input');
      input.type      = 'text';
      input.dataset.row = i;
      input.dataset.col = j;
      input.maxLength = 1;
      if (value) input.value = value;

      const td      = document.createElement('td');
      const isDroite = j % 3 === 0;
      const isGris   = (Math.floor(i/3) + Math.floor(j/3)) % 2 !== 0;
      if      (isDroite && isGris) td.className = 'damier troisd';
      else if (isDroite)           td.className = 'troisd';
      else if (isGris)             td.className = 'damier';

      td.appendChild(input);
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }

  const table = document.createElement('table');
  table.id        = 'sudokincipit';
  table.className = 'sudokool';
  table.setAttribute('sudata', JSON.stringify(data));
  table.appendChild(tbody);
  return { _sudoku: table, data };
}

/**
 * makesudiniReactive({ _sudoku, data }) → HTMLTableElement réactif
 * Ajoute : navigation clavier, raccourcis AZERTY, détection doublons animée,
 *          sync avec radio buttons 'ModifierInit' et SudokuMémo.
 * ↔ JS window.makesudiniReactive dans sudini() de PlutokuNext.jl
 *
 * Après appel, la table émet un événement 'input' à chaque modification.
 * Lire table.value (ou table.getAttribute('sudata')) pour accéder aux données.
 */
function makesudiniReactive({ _sudoku: html, data }) {
  // Captures pour comparaison  ↔  Julia const premier, const deuxième
  const premier  = JSON.stringify(SudokuMémo[0]); // vide
  const deuxième = JSON.stringify(SudokuMémo[1]); // mémo instantané

  // ── Sync table.value = data (pour listeners externes) ─────────────────────
  html.addEventListener('input', (e) => {
    e.stopPropagation(); e.preventDefault();
    html.value = data;
    return false;
  });

  // ── Marquage des doublons (animation CSS endouble-shake) ───────────────────
  // ↔ Julia JS misEnValeurSiDoublonChiffre dans sudini()
  const misEnValeurSiDoublonChiffre = (data) => {
    html.querySelectorAll('input').forEach(inp => inp.classList.remove('endouble'));
    for (let z = 0; z < 9; z++) {
      // Lignes (visual row = Julia col)
      for (let i = 0; i < 9; i++) {
        if (data[i][z] !== 0 && data[i].filter(x => x === data[i][z]).length > 1)
          html.firstChild.childNodes[i].childNodes[z].firstChild.classList.add('endouble');
      }
      // Colonnes (visual col = Julia row)
      for (let j = 0; j < 9; j++) {
        const colo = data.map(row => row[j]);
        if (data[z][j] !== 0 && colo.filter(x => x === data[z][j]).length > 1)
          html.firstChild.childNodes[z].childNodes[j].firstChild.classList.add('endouble');
      }
      // Carrés
      const seen = {}, sr = Math.floor(z/3)*3, sc = (z%3)*3;
      for (let i = sr; i < sr+3; i++) {
        for (let j = sc; j < sc+3; j++) {
          const num = data[i][j];
          if (num !== 0) {
            if (seen[num]) {
              for (let m = sr; m < sr+3; m++)
                for (let n = sc; n < sc+3; n++)
                  if (data[m][n] === num)
                    html.firstChild.childNodes[m].childNodes[n].firstChild.classList.add('endouble');
            } else seen[num] = true;
          }
        }
      }
    }
  };

  // ── Sync radio buttons + dispatch 'input' ─────────────────────────────────
  // ↔ Julia JS puCHECKetMATdispatchEvent dans sudini()
  const puCHECKetMATdispatchEvent = () => {
    const ele = document.getElementsByName('ModifierInit');
    ele.forEach(el => { el.checked = false; });
    const jdata = JSON.stringify(data);
    html.setAttribute('sudata', jdata);
    html.dispatchEvent(new Event('input'));
    if      (jdata === premier)  { if (ele[0]) ele[0].checked = true; }
    else if (jdata === deuxième) { if (ele[1]) ele[1].checked = true; }
    misEnValeurSiDoublonChiffre(data);
  };

  // ── Listeners sur chaque cellule ───────────────────────────────────────────
  html.querySelectorAll('input').forEach(input => {
    // Helpers navigation  ↔  Julia JS daligne, dacol, etp2, etp3
    const daligne = ({target}) => target.dataset.row; // string (OK pour childNodes)
    const dacol   = ({target}) => target.dataset.col;
    const etp2 = ({target}) => target.parentElement.parentElement;        // <tr>
    const etp3 = ({target}) => target.parentElement.parentElement.parentElement; // <tbody>

    const moveDown  = (e) => {
      etp2(e).nextElementSibling === null
        ? etp3(e).firstChild.childNodes[dacol(e)].firstChild.focus()
        : etp2(e).nextElementSibling.childNodes[dacol(e)].firstChild.focus();
    };
    const moveUp    = (e) => {
      etp2(e).previousElementSibling === null
        ? etp3(e).lastChild.childNodes[dacol(e)].firstChild.focus()
        : etp2(e).previousElementSibling.childNodes[dacol(e)].firstChild.focus();
    };
    const moveLeft  = (e) => {
      if (e.target.parentElement.previousElementSibling === null) {
        etp2(e).previousElementSibling === null
          ? etp3(e).lastChild.lastChild.firstChild.focus()
          : etp2(e).previousElementSibling.lastChild.firstChild.focus();
      } else e.target.parentElement.previousElementSibling.firstChild.focus();
    };
    const moveRight = (e) => {
      if (e.target.parentElement.nextElementSibling === null) {
        etp2(e).nextElementSibling === null
          ? etp3(e).firstChild.firstChild.firstChild.focus()
          : etp2(e).nextElementSibling.firstChild.firstChild.focus();
      } else e.target.parentElement.nextElementSibling.firstChild.focus();
    };

    // Touches clavier  ↔  Julia JS input.addEventListener('keydown', ...)
    input.addEventListener('keydown', (e) => {
      e.target.select();
      switch (e.key) {
        case 'ArrowDown':  moveDown(e);  break;
        case 'ArrowUp':    moveUp(e);    break;
        case 'ArrowLeft':  moveLeft(e);  break;
        case 'ArrowRight': moveRight(e); break;
        case 'Shift': case 'CapsLock': case 'NumLock': break;
        case 'Backspace':
        case 'Delete': {
          if (data[daligne(e)][dacol(e)] !== 0) {
            data[daligne(e)][dacol(e)] = 0;
            e.target.value = '';
            puCHECKetMATdispatchEvent();
          }
          e.key === 'Delete' ? moveRight(e) : moveLeft(e);
          const da = document.activeElement;
          if (e.key === 'Delete') { da.selectionStart = da.selectionEnd = da.value.length; }
          else                    { da.selectionStart = da.selectionEnd = 0; }
          break;
        }
        default: return;
      }
    });

    // Mise à jour valeur  ↔  Julia JS màjValeur
    const màjValeur = (e) => {
      const i   = e.target.dataset.row;  // string-key (coercion OK pour arrays)
      const j   = e.target.dataset.col;
      const val = e.target.value;
      const oldata = data[i][j];
      // Raccourcis AZERTY + bidouilliste  ↔  Julia bidouilliste
      const bidouilliste = {
        a:1,z:2,e:3,r:4,t:5,y:6,u:7,i:8,o:9,
        A:1,Z:2,E:3,R:4,T:5,Y:6,U:7,I:8,O:9,
        '&':1,'é':2,'"':3,"'":4,'(':5,'-':6,'è':7,'_':8,'ç':9,
        '§':6,'!':8,q:1,Q:1,w:2,W:2
      };
      if      (val in bidouilliste)                 e.target.value = data[i][j] = bidouilliste[val];
      else if (val <= 9 && val >= 1)                data[i][j] = parseInt(val);
      else if (val == 0 || val === 'à' || val === 'p' || val === 'P') {
        data[i][j] = 0; e.target.value = '';
      } else e.target.value = data[i][j] === 0 ? '' : data[i][j];

      if (oldata === data[i][j]) { e.stopPropagation(); e.preventDefault(); }
      else puCHECKetMATdispatchEvent();
    };

    // Mise à jour + déplacement  ↔  Julia JS màjEtBouge
    const màjEtBouge = (e) => {
      const val = e.target.value;
      màjValeur(e);
      const mouvements = {
        b:moveDown,B:moveDown, h:moveUp,H:moveUp,
        j:moveRight,J:moveRight, g:moveLeft,G:moveLeft,
        v:moveLeft,V:moveLeft, d:moveRight,D:moveRight,
        n:moveRight,N:moveRight
      };
      if (val in mouvements) mouvements[val](e); else moveRight(e);
      document.activeElement?.select();
    };

    input.addEventListener('input', màjEtBouge);  // saisie clavier
    input.addEventListener('ctop',  màjValeur);   // mise à jour depuis grille solution
  });

  puCHECKetMATdispatchEvent();
  return html;
}

/**
 * initSudini(container, values?) → HTMLTableElement
 * Crée, rend réactive, et attache la grille à un container.
 * container : HTMLElement | ID string
 * values    : JSudoku (SudokuMémo[1] par défaut)
 */
function initSudini(container, values = null) {
  if (typeof container === 'string') container = document.getElementById(container);
  const grid = makesudiniReactive(createsudini(values ?? SudokuMémo[1]));
  container.appendChild(grid);
  return grid;
}

// =============================================================================
// ÉTAPE 5 : UI createsudfini / msga — Affichage de la solution
// ↔ Julia sudfini() + createsudfini + window.msga
// =============================================================================

let _msga_toutVoir = true;  // dernière valeur toutVoir — pour déjàvu()  ↔ closure Julia

/**
 * createsudfini(values, values_ini, toutVoir) → HTMLTableElement
 * Crée la grille de solution en DOM.
 * ↔ JS createsudfini dans sudfini() de PlutokuNext.jl
 */
function createsudfini(values, values_ini, toutVoir = true) {
  // kc(i,j) : visual i = Julia col = mat col, visual j = Julia row = mat row
  // → kelcar(mat_r=j, mat_c=i) = Math.floor(j/3)*3 + Math.floor(i/3)
  const kc = (i, j) => Math.floor(j/3)*3 + Math.floor(i/3);
  const tbody = document.createElement('tbody');
  for (let i = 0; i < 9; i++) {
    const tr = document.createElement('tr');
    if (i % 3 === 0) tr.className = 'troisr';
    for (let j = 0; j < 9; j++) {
      const value     = values[i]?.[j]     || 0;
      const isInitial = (values_ini[i]?.[j] || 0) > 0;
      const isDroite  = j % 3 === 0 ? ' troisd' : '';
      const td = document.createElement('td');
      td.textContent = value || ' ';
      td.dataset.row = i; td.dataset.col = j; td.dataset.car = kc(i, j);
      td.className   = (isInitial ? 'ini' : (toutVoir ? 'vide' : 'vide cachée')) + isDroite;
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }
  const table = document.createElement('table');
  table.id = 'sudokufini'; table.className = 'sudokool';
  if (!toutVoir) table.style.userSelect = 'none';
  table.appendChild(tbody);
  return table;
}

/**
 * msga(_sudoku, toutVoir) → _sudoku réactif
 * MakeSudokuGreatAgain : pointer events + interaction sur la grille solution.
 * ↔ JS window.msga dans sudfini() / déjàvu de PlutokuNext.jl
 */
function msga(_sudoku, toutVoir = _msga_toutVoir) {
  _msga_toutVoir = toutVoir;
  // Pointer events tactiles  ↔  Julia JS handlePointerDown/Up/Entré
  let isPointerDown = false;
  const _onPU = () => { isPointerDown = false; };
  document.removeEventListener('pointerup', _onPU);
  document.addEventListener('pointerup', _onPU);
  const hPD = ({target}) => { isPointerDown = true; target.style.transform='scale(1.3,1)'; target.style.transition='transform 0.1s'; };
  const hPE = ({target}) => { if (isPointerDown) { target.dispatchEvent(new Event('pointerdown')); target.style.transform='scale(1.3,1)'; target.style.transition='transform 0.1s'; } };
  const hPU = ({target}) => { target.style.transform = 'scale(1)'; };
  _sudoku.querySelectorAll('td').forEach(cell => {
    cell.addEventListener('pointerdown', hPD);
    cell.addEventListener('pointerenter', hPE);
    cell.addEventListener('pointerup',    hPU);
    cell.addEventListener('pointerleave', hPU);
  });

  // upme : transfert d'un chiffre vers la grille initiale  ↔  Julia JS upme
  const upme = (target) => {
    if (!document.getElementById('choixàmettreenhaut')?.checked) return;
    const { row, col } = target.dataset;
    const cible = document.querySelector(`#sudokincipit > tbody > tr:nth-child(${+row+1}) > td:nth-child(${+col+1}) > input`);
    const vale  = target.textContent.trim();
    if (!cible || !vale || isNaN(vale)) return;
    cible.value = cible.value == vale ? 0 : vale;
    if (cible.value == 0) {
      target.classList.remove('ini');
      target.addEventListener('pointerdown', videactiv);
      target.removeEventListener('pointerdown', upmee);
      if (!toutVoir) target.removeEventListener('pointerdown', bleucache);
    } else {
      target.classList.add('ini');
      target.removeEventListener('pointerdown', videactiv);
      target.addEventListener('pointerdown', upmee);
      if (!toutVoir) target.addEventListener('pointerdown', bleucache);
    }
    target.classList.remove('cachée'); target.classList.add('gris');
    cible.dispatchEvent(new Event('ctop'));
  };
  const upmee = ({target}) => upme(target);

  // bleucache : cacher les vides quand on clique sur ini (sans choixàmettreenhaut)
  const bleucache = ({target}) => {
    if (!document.getElementById('choixàmettreenhaut')?.checked)
      target.parentElement.parentElement.querySelectorAll('td:not(.ini)').forEach(c => c.classList.add('cachée'));
  };

  // videactiv : cliquer sur une case résolue  ↔  Julia JS videactiv
  const videactiv = ({target}) => {
    upme(target);
    if (toutVoir) return;
    if (document.getElementById('caroligne')?.checked) {
      const { row, col, car } = target.dataset;
      _sudoku.querySelectorAll(`td.vide[data-row='${row}'],td.vide[data-col='${col}'],td.vide[data-car='${car}']`)
             .forEach(t => t.classList.remove('cachée'));
    } else target.classList.toggle('cachée');
  };

  const tdbleus = _sudoku.querySelectorAll('td.ini');
  tdbleus.forEach(td => {
    td.addEventListener('pointerdown', upmee);
    if (!toutVoir) td.addEventListener('pointerdown', bleucache);
  });
  _sudoku.querySelectorAll('td.vide').forEach(td => td.addEventListener('pointerdown', videactiv));
  return _sudoku;
}

/**
 * sudfini(JSudokuFini?, JSudokuini?, toutVoir?) → HTMLElement
 * ↔ Julia sudfini(JSudokuFini, JSudokuini ; toutVoir)
 */
function sudfini(JSudokuFini = null, JSudokuini = null, toutVoir = true) {
  const fini = JSudokuFini ?? jsvd(), ini = JSudokuini ?? jsvd();
  if (typeof fini === 'string' || (Array.isArray(fini) && typeof fini[0] === 'string')) {
    const h5 = document.createElement('h5');
    h5.textContent = '⚡ Attention, sudoku initial à revoir ! ' + (Array.isArray(fini) ? fini[0] : fini);
    h5.style.cssText = 'text-align:center;margin-bottom:6px;user-select:none;cursor:pointer;';
    h5.addEventListener('click', () => typeof déjàvu === 'function' && déjàvu());
    return h5;
  }
  return msga(createsudfini(fini, ini, toutVoir), toutVoir);
}
const htmls = sudfini;  // alias  ↔  Julia htmls = sudfini

// ── Va-et-vient : swap solution ↔ grille initiale ──────────────────────────────
// ↔ Julia vaetvient (déjàvu / làhaut)

let _vaetVientVielle = false;

/** déjàvu() — revient au sudoku initial depuis la vue solution  ↔  Julia déjàvu() */
function déjàvu() {
  const père = document.getElementById('sudokincipit')?.parentElement;
  const fils = document.getElementById('copiefinie'), ancien = document.getElementById('sudokufini');
  if (!père || !fils) return;
  if (_vaetVientVielle && ancien && _vaetVientVielle.isEqualNode(ancien)) {
    ancien.innerHTML = fils.innerHTML; ancien.querySelector('tfoot')?.remove(); msga(ancien);
  }
  document.getElementById('sudokincipit').hidden = false;
  père.removeChild(fils);
  const vv = document.getElementById('va_et_vient');
  if (vv) vv.textContent = 'Sudoku initial ⤴ (modifiable) et sa solution : ';
}

/** làhaut() — monte la solution en remplacement de la grille initiale  ↔  Julia làhaut() */
function làhaut() {
  const père = document.getElementById('sudokincipit')?.parentElement; if (!père) return;
  const fils = document.getElementById('copiefinie'), copie = document.getElementById('sudokufini');
  if (fils) père.removeChild(fils);
  document.getElementById('sudokincipit').hidden = true;
  const tabl = document.createElement('table');
  _vaetVientVielle = copie ? copie.cloneNode(true) : tabl;
  tabl.id = 'copiefinie'; tabl.className = 'sudokool';
  tabl.innerHTML = (copie ? copie.innerHTML :
    `<thead id='taide'><tr><td style='text-align:center;width:340px;padding:26px 0;border:0;'>Rien à montrer, c'est coché <code>🤫 Cachée</code></td></tr></thead>`) +
    `<tfoot id='tesfoot'><tr id='lignenonvisible'><th colspan='9'>↪ Cliquer ici pour revenir au sudoku modifiable</th></tr></tfoot>`;
  père.appendChild(tabl);
  tabl.querySelector('#taide')?.addEventListener('click', déjàvu);
  tabl.querySelector('#tesfoot')?.addEventListener('click', déjàvu);
  if (copie) msga(tabl);
  const vv = document.getElementById('va_et_vient');
  if (vv) vv.textContent = 'Solution ↑ (au lieu du sudoku modifiable initial)';
}

/** initVaetVient() — connecte le span va_et_vient  ↔  Julia vaetvient */
function initVaetVient() { document.getElementById('va_et_vient')?.addEventListener('click', làhaut); }

// =============================================================================
// ÉTAPE 6 : UI sudpropal — Aide visuelle (chiffres/total possibles par case)
// ↔ Julia sudpropal() + chiffrePropal + nbPropal
// =============================================================================

const pt1 = '·', pt2 = '◌', pt3 = '●';  // ↔ Julia const pt1, pt2, pt3

/**
 * chiffrePropal(mat, r, c, mImp, vide) → Array[3][3]<string>
 * Mini-grille 3×3 des chiffres possibles.  ↔  Julia chiffrePropal(mat, c, mImp, vide)
 */
function chiffrePropal(mat, r, c, mImp, vide) {
  const cp = mat[r][c] === 0 ? chiPossible(mat, r, c, carr(r), carr(c), mImp) : new Set([mat[r][c]]);
  if (cp.size === 0) return [['◜','‽','◝'],['¡','/','!'],['◟','_','◞']];
  const vi = vide ? ' ' : pt1;
  return [[1,2,3],[4,5,6],[7,8,9]].map(row => row.map(n => cp.has(n) ? String(n) : vi));
}

/**
 * nbPropal(mat, r, c, mImp) → { grid: Array[3][3], count: number }
 * Mini-grille 3×3 indicateur du nombre de possibles.  ↔  Julia nbPropal(mat, c, mImp)
 */
function nbPropal(mat, r, c, mImp) {
  const lcp = mat[r][c] === 0 ? chiPossible(mat, r, c, carr(r), carr(c), mImp).size : 1;
  if (lcp === 0) return { grid:[['↘','↓','↙'],['→','0','←'],['↗','↑','↖']], count:0 };
  const grid = [[1,2,3],[4,5,6],[7,8,9]].map(row =>
    row.map(x => x===lcp ? String(x) : (x<lcp ? (lcp<4?pt1:lcp<7?pt2:pt3) : ' ')));
  return { grid, count: lcp };
}

/**
 * sudpropal(JSudokuini?, JSudokuFini?, opts?) → HTMLTableElement
 * Affiche les chiffres possibles par case (avec propagation partielle).
 * ↔ Julia sudpropal(JSudokuini, JSudokuFini ; toutVoir, parCase, somme)
 */
function sudpropal(JSudokuini = null, JSudokuFini = null, { toutVoir=true, parCase=true, somme=true }={}) {
  const jsuini = JSudokuini ?? jsvd();
  const mat    = jsm(jsuini);
  let lesZéros = new Set();
  const soréz  = newDicoréz();
  for (let r = 0; r < 9; r++) for (let c = 0; c < 9; c++) if (mat[r][c] === 0) {
    const k = kelcar(r, c); lesZéros.add(`${r},${c}`); pushfun(soréz, r, c, k);
  }
  const lesZérosIni = new Set(lesZéros), mImp = new Map();
  let lesZérosàSuppr = new Set();

  // ── Propagation sans backtracking  ↔  Julia partie calcul de sudpropal() ──
  while (lesZéros.size > 0) {
    const dc = newDicompte(), dm = newDicombo(); let ok = true;
    for (const key of lesZéros) {
      const [r, c] = key.split(',').map(Number);
      const cr = carr(r), cc = carr(c), k = kelcar(r, c);
      const lc = chiPossible(mat, r, c, cr, cc, mImp);
      sac(dc, r, c, k, cr, cc, lc);
      if (lc.size === 0 || pasAssezDePropal(dm, r, c, k, cr, cc, soréz, lc, mImp)) {
        ok = false; lesZérosàSuppr = new Set(); break;
      } else if (lc.size === 1) {
        ajoute(mat, r, c, k, [...lc][0], lesZérosàSuppr, soréz);
        nettoie(r, c, k, [...lc][0], dc);
      }
    }
    if (!ok) break;
    uniclk(dc, true, mat, lesZérosàSuppr, soréz, mImp);
    if (lesZérosàSuppr.size === 0) break;
    for (const key of lesZérosàSuppr) lesZéros.delete(key);
    lesZérosàSuppr = new Set();
  }

  // ── Calcul des mini-grilles  ↔  Julia mPropal + grisemine ─────────────────
  const mPropal = new Map(); let mine = 10; const grisemine = [];
  for (const key of lesZérosIni) {
    const [r, c] = key.split(',').map(Number);
    if (somme) {
      const res = nbPropal(mat, r, c, mImp); mPropal.set(key, res);
      if (res.count > 0 && res.count < mine) { mine = res.count; grisemine.length = 0; grisemine.push(key); }
      else if (res.count === mine) grisemine.push(key);
    } else mPropal.set(key, { grid: chiffrePropal(mat, r, c, mImp, !parCase), count: 0 });
  }
  if (somme && mine > 0 && mine < 9)
    grisemine.forEach(k => { const p = mPropal.get(k); if (p) p.grid[2][2] = '✔'; });

  // ── Construction du tableau  ↔  Julia createsudpropal ────────────────────
  // kc(i,j) : même correction que createsudfini
  const kc = (i, j) => Math.floor(j/3)*3 + Math.floor(i/3);
  const tbody = document.createElement('tbody');
  for (let i = 0; i < 9; i++) {
    const tr = document.createElement('tr'); if (i % 3 === 0) tr.className = 'troisr';
    for (let j = 0; j < 9; j++) {
      const isInitial = (jsuini[i]?.[j] || 0) > 0, isDroite = j%3===0?' troisd':'';
      const td = document.createElement('td');
      td.dataset.row = i; td.dataset.col = j; td.dataset.car = kc(i, j);
      if (isInitial) {
        td.textContent = jsuini[i][j]; td.className = 'ini' + isDroite;
      } else {
        td.className = 'props' + isDroite;
        const propal = mPropal.get(`${j},${i}`);  // mat key = (r=j, c=i) ↔ visual (i,j)
        if (propal) {
          const mt = document.createElement('table'); mt.className = 'sudokoolmini'; mt.style.userSelect = 'none';
          const mtb = document.createElement('tbody');
          for (let pi = 0; pi < 3; pi++) {
            const mtr = document.createElement('tr'); mtr.style.borderStyle = 'none';
            for (let pj = 0; pj < 3; pj++) {
              const mtd = document.createElement('td');
              mtd.textContent = propal.grid[pi][pj];
              mtd.dataset.row = pi; mtd.dataset.col = pj; mtd.dataset.car = kc(pi, pj);
              mtd.className = (toutVoir && (somme || parCase)) ? 'mini' : 'mini vide cachée';
              mtr.appendChild(mtd);
            }
            mtb.appendChild(mtr);
          }
          mt.appendChild(mtb); td.appendChild(mt);
        }
      }
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }
  const table = document.createElement('table');
  table.id = 'sudokufini'; table.className = 'sudokool'; table.style.userSelect = 'none';
  table.appendChild(tbody);

  // ── Interactions  ↔  Julia JS msgaPropal ──────────────────────────────────

  // justeremonte : transfère le chiffre d'une mini-case vers sudokincipit  ↔  Julia justeremonte
  // Retourne true si le transfert a eu lieu (stoppe la révélation)
  const justeremonte = (target) => {
    if (!document.getElementById('choixàmettreenhaut')?.checked) return false;
    const pTd = target.closest('td.props');
    const { row, col } = pTd ? pTd.dataset : {};
    if (row === undefined) return false;
    const vale = target.textContent;
    if (!vale.trim() || isNaN(vale)) return false;
    const cible = document.querySelector(`#sudokincipit > tbody > tr:nth-child(${+row+1}) > td:nth-child(${+col+1}) > input`);
    if (!cible) return false;
    cible.value = cible.value == vale ? 0 : vale;
    target.classList.toggle('ini');
    target.classList.add('gris');
    cible.dispatchEvent(new Event('ctop'));
    return true;
  };

  table.querySelectorAll('td.mini').forEach(mtd => {
    mtd.addEventListener('click', (e) => {
      const { row: ilig, col: jcol } = e.target.dataset;
      const pTd = e.target.closest('td.props');
      const { row, col, car } = pTd ? pTd.dataset : {};
      if (somme) {
        // somme : révéler le même chiffre (carolign ou tousleségalit)
        if (document.getElementById('caroligne')?.checked && row !== undefined) {
          const minj = `td.vide[data-row='${ilig}'][data-col='${jcol}']`;
          table.querySelectorAll(`td.props[data-row='${row}'] ${minj},td.props[data-col='${col}'] ${minj},td.props[data-car='${car}'] ${minj}`)
               .forEach(t => t.classList.remove('cachée'));
        } else {
          table.querySelectorAll(`td.vide[data-row='${ilig}'][data-col='${jcol}']`).forEach(t => t.classList.remove('cachée'));
        }
      } else {
        // !somme : justeremonte d'abord ↔  Julia justeremonte(tdmini)
        if (justeremonte(e.target)) return;
        // Révélation selon parCase / caroligne / toutVoir  ↔  Julia justeunecase / carolignios / tousleségalitios
        if (parCase) {
          // par case : révéler la mini-grille de la case (casecarolign ou toggle all)
          if (document.getElementById('caroligne')?.checked && row !== undefined) {
            table.querySelectorAll(`td.props[data-row='${row}'] td, td.props[data-col='${col}'] td, td.props[data-car='${car}'] td`)
                 .forEach(t => t.classList.remove('cachée'));
          } else {
            pTd?.querySelectorAll('td.vide').forEach(t => t.classList.toggle('cachée'));
          }
        } else {
          // par chiffre : révéler le même chiffre (carolign, tousleségalit, ou toggle)
          if (document.getElementById('caroligne')?.checked && row !== undefined) {
            const minj = `td.vide[data-row='${ilig}'][data-col='${jcol}']`;
            table.querySelectorAll(`td.props[data-row='${row}'] ${minj},td.props[data-col='${col}'] ${minj},td.props[data-car='${car}'] ${minj}`)
                 .forEach(t => t.classList.remove('cachée'));
          } else if (toutVoir) {
            table.querySelectorAll(`td.vide[data-row='${ilig}'][data-col='${jcol}']`).forEach(t => t.classList.remove('cachée'));
          } else {
            e.target.classList.toggle('cachée');
          }
        }
      }
    });
  });

  // td.ini : transfert (choixàmettreenhaut) + touteffacer si mode caché  ↔  Julia touteffacer
  const hiddenMode = !(toutVoir && (somme || parCase));
  table.querySelectorAll('td.ini').forEach(td => {
    td.addEventListener('pointerdown', ({target}) => {
      if (document.getElementById('choixàmettreenhaut')?.checked) {
        const { row, col } = target.dataset;
        const cible = document.querySelector(`#sudokincipit > tbody > tr:nth-child(${+row+1}) > td:nth-child(${+col+1}) > input`);
        const vale  = target.textContent.trim();
        if (!cible || !vale || isNaN(vale)) return;
        cible.value = cible.value == vale ? 0 : vale;
        target.classList.add('gris'); cible.dispatchEvent(new Event('ctop'));
      } else if (hiddenMode) {
        // touteffacer : cacher toutes les mini-cases vides  ↔  Julia touteffacer
        target.closest('tbody')?.querySelectorAll('td.vide')
              .forEach(t => t.classList.add('cachée'));
      }
    });
  });

  _msga_toutVoir = toutVoir;
  return table;
}
const htmlsp = sudpropal;  // alias  ↔  Julia htmlsp = sudpropal

// ── EXPORTS ────────────────────────────────────────────────────────────────────
// Pour usage en module ES6 :
//   export { kelcar, carr, jsvd, jsm, mjs, adini, jcvd, matVide,
//            vérifSudokuBon, simPossible, chiPossible,
//            newDicoréz, pushfun, deletefun, résoutSudoku, résoutSudokuMax,
//            SudokuMémo, sudokuAléatoireFini, sudokuAléatoire,
//            vieuxSudoku, vs, vsd, sudokuinitial,
//            tousudoku, ts, jsuFromTexte, deepCopyJsu, isJsuEqual,
//            createsudini, makesudiniReactive, initSudini,
//            createsudfini, msga, sudfini, déjàvu, làhaut, initVaetVient,
//            chiffrePropal, nbPropal, sudpropal };
// Pour usage en <script> classique, tout est global (window.*).

// Test rapide (décommenter en console navigateur ou Node.js) :
// const [sol, stats] = résoutSudoku(adini()); console.log(stats);
// console.log('Aléatoire :', sudokuAléatoire(30).map(col => col.join('')).join(' '));
