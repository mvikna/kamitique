# Kamitique.jl

> **Science Computationnelle de la Cosmologie Quantique Géométrique**
> La Kamitique est la science computationnelle alternative au paradigme binaire,
> dérivée de la **Cosmologie Quantique Géométrique (CQG)**.

Ce package est la traduction en Julia des *Théories, Méthodes et Algorithmes* de la
Kamitique (`docs/La_Kamitique_Theories_Methodes_Algorithmes.pdf`) et, en amont, du
livre dont elle dérive (`docs/Cosmologie_Quantique_Geometrique.pdf`). Il ne crée
**aucune discipline nouvelle** : toutes les méthodes procèdent du même socle, de la
même chaîne et des mêmes épreuves (définition 13.1, théorème 8.5). La **Loi
fondamentale** de la CQG (chapitres 1 à 4) est consignée comme la **racine** du
module `Loi`, dont le système d'axiomes `ΣK` du socle **dérive explicitement**.

---

## 1. Prérequis et installation

- **Julia ≥ 1.10** (voir `[compat]` dans `Project.toml`).
- Aucune dépendance externe : seules les bibliothèques standard `LinearAlgebra`
  et `Random`, ainsi que `Test` (pour la suite de tests), sont utilisées.

Depuis la racine du projet :

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using Kamitique
```

Le module racine `Kamitique` inclut et **ré-exporte** l'ensemble des symboles
publics de ses huit sous-modules : un simple `using Kamitique` suffit pour accéder à
toute l'API.

---

## 2. Architecture du package

```
Kamitique/
├── Project.toml / Manifest.toml
├── README.md
├── docs/
│   ├── journal_theorie_de_base.md             # journal de la théorie de base
│   ├── Cosmologie_Quantique_Geometrique.pdf   # livre source (CQG)
│   └── La_Kamitique_Theories_Methodes_Algorithmes.pdf
├── benchmark/
│   ├── benchmarks.jl           # efficacité des méthodes (temps, allocation, ordre)
│   ├── objectifs.jl            # conformité globale du dispositif (80 contrôles)
│   └── objectifs_chNN.jl       # conformité par catégorie (ch. 14 à 30)
├── src/
│   ├── Kamitique.jl            # module racine, includes + ré-export
│   ├── loi/                    # Loi.jl + 6 fichiers — la Loi fondamentale de la CQG (ch. 1–4)
│   ├── socle/                  # Socle.jl + 8 fichiers — l'appareil formel (ΣK, δ/ι/κ)
│   ├── pesee/                  # Pesee.jl + 3 fichiers — balance de Maât, registre
│   ├── chaine/                 # Chaine.jl + 3 fichiers — chaîne épistémologique (7 dimensions)
│   ├── methodologie/           # Methodologie.jl + 4 fichiers — M = (R, P, Γ)
│   ├── dispositif/             # Dispositif.jl + 6 fichiers — les quatre mouvements, la carte
│   ├── categories/             # Categories.jl + 17 fichiers — une par catégorie de la carte
│   └── ethnomatique/           # Ethnomatique.jl + 6 fichiers — les savoirs africains formalisés
└── test/
    └── runtests.jl             # suite de tests (821 tests, module par module)
```

### Les huit modules

| Module | Rôle | Contenu principal |
|---|---|---|
| **Loi** | La **Loi fondamentale** de la CQG (ch. 1–4) — la racine | quatre axiomes `A1` Noun, `A2` Kheper, `A3` Spirale d'or, `A4` Maât ; dérivation `ΣK ⇐ A1…A4` ; espace des phases `(ℋ_Noun, M₄, {ℳ_k}²²)` ; Loi Universelle (ch. 2) ; énergie du Noun — Heka (ch. 3) ; principe de manifestation (ch. 4) |
| **Socle** | L'appareil formel (lecture computationnelle de la CQG) | sites, figures, porteur `G`, composition `⊙`, raffinement `≺`, états `Ψ = Σ αᵍ·g`, valuation `ν`, harmonie `µ`, axiomes `ΣK`, opérateurs `δ`/`ι`/`κ`, trajectoire encadrée, théorèmes `T-K1 → T-K6` |
| **Pesee** | La théorie de la décision | balance (principe 8.1), non-compensation (proposition 8.7), contraintes éthiques, registre de pesée, dernière pesée humaine (proposition 8.8) |
| **Chaine** | La chaîne épistémologique | les 7 dimensions (donnée, information, connaissance, renseignement + gouvernes éthique/frugalité/explicabilité), opérateurs de chaîne, chaîne gouvernée, registre de justification |
| **Methodologie** | La méthodologie opérationnelle `M = (R, P, Γ)` | règles opérationnelles `R`, protocoles `Pδ/Pι/Pκ`, épreuves de gouvernance `εE/εF/εX`, tableau de dérivation |
| **Dispositif** | Le dispositif unifié de résolution | les quatre mouvements, critères d'admissibilité et de conformité, carte des catégories (tableau 13.1) |
| **Categories** | Les méthodes par catégorie | les méthodes de chaque catégorie de la carte, toutes adossées au même socle |
| **Ethnomatique** | Les savoirs africains formalisés | registre extensible : numérations, jeux de semailles (awalé), géomancie (sikidy/ifa), motifs et symétries (adinkra, sona), artefacts à encoches (Ishango, Lebombo) |

---

## 3. La Loi fondamentale (CQG, ch. 1–4)

Le module **`Loi`** consigne le **bloc fondationnel** de la CQG ; il ouvre
l'édifice, car `ΣK` en **dérive** au lieu de le précéder.

- **Axiomatique fondamentale (A1–A4)** —
  `A1` **Noun** : le substrat `ℋ_tot`, présence indifférenciée, est le donné
  premier ; `A2` **Kheper** : `K̂(s) : ℋ_Noun → M₄` est l'opérateur de déploiement
  (Ennéade, 9 degrés topologiques) ; `A3` **Spirale d'or** : `r(θ) = r₀ e^{bθ}`,
  `b = ln φ/(π/2)` avec `φ = (1+√5)/2` et coupure `R₀ ≠ 0` ; `A4` **Maât** :
  `δS_eff = 0 ⟹ ∃! (g*, A*)`, avec `m_gap > 0` (l'optimum est un attracteur).
- **Dérivation `ΣK ⇐ A1…A4`** — les sept axiomes `A-K1` … `A-K7` du socle sont
  **dérivés** des quatre engagements : `AK1, AK2, AK7 ⇐ A1` ; `AK4 ⇐ A2` ;
  `AK6 ⇐ A3` ; `AK3, AK5 ⇐ A4`. `verifier_derivation()` atteste la cohérence du
  graphe de dérivation.
- **Espace des phases global** — les neuf constituants de toute entité, l'Ennéade
  (`DOF_TOPOLOGIQUES = 9`) et l'algèbre non-commutative des vingt-deux Métous
  (`[ℳ_j, ℳ_k] = i f_jkl ℳ_l`, éq. 18), dont l'antisymétrie et l'identité de
  Jacobi sont vérifiées.
- **Loi Universelle (ch. 2)** —
  `ℒ_CQG = √−g [ (R − 2Λ)/(2κ) − ¼ F² + ℒ_morph ]` avec le tenseur non-abélien
  `F_μν = ∂_μ A_ν − ∂_ν A_μ + g[A_μ, A_ν]` : trois secteurs conjoints — élasticité
  de l'éther, antagonisme Horus–Seth, commande morphique.
- **Énergie du Noun — Heka (ch. 3)** — le générateur `Ĥ_Noun Ψ = iℏ ∂Ψ/∂s`,
  l'énergie `E[Ψ] = ⟨Ψ|Ĥ_Noun|Ψ⟩`, la décomposition `E = E_éther + E_jauge + E_morph`
  et la conservation `dE/ds = 0 ⟹ ∇_μ J^μ = 0`.
- **Manifestation (ch. 4)** — la triade conjointe
  `K̂(s) = Â_At ∘ P̂_Pt ∘ Ĝ_Kh` : Atoum (actualisation) ∘ Ptah (commande
  informationnelle) ∘ Khnoum (modelage morphogénétique).

> **Fidélité (`G1`)** : la règle d'unité « non analogie » est stricte ; les
> énoncés consignés sont la lecture de la CQG, et les écarts éventuels du texte
> source sont **déclarés** au journal (`docs/journal_theorie_de_base.md`, entrée
> `M-07`, règle `G5`).

---

## 4. Le socle

Le socle formalise la lecture computationnelle de la CQG dont la Kamitique dérive.

- **Site / Figure / Porteur** — un site est un lieu possible ; une figure est une
  composition de sites ; le porteur `G` est le graphe situé qui les rassemble.
- **Composition `⊙` et raffinement `≺`** — `a ⊙ b` compose deux figures
  (associatif, `figure_vide()` neutre) ; `a ≺ b` exprime que `a` raffine `b`.
  `composer_cumule` réalise la composition en place (site et liens nouveaux).
- **État en superposition pondérée** — `Ψ = Σ αᵍ·g` avec poids `> 0` et somme `1`
  (la présence est une totalité : `Etat` normalise automatiquement).
- **Valuation `ν` et harmonie `µ`** — `valuation(Ψ, proposition)` ; l'harmonie
  `µ(Ψ)` mesure la cohérence, `h.compatibilite(g, h)` la compatibilité de deux
  figures. Un état n'est **jamais nativement résolu** : c'est la pesée qui tranche.
- **Opérateurs `δ` / `ι` / `κ`** — `δ` (structuration), `ι` (déploiement / calcul),
  `κ` (pesée qui résout). Ce sont **les mêmes** dans le Socle et dans la Chaine
  (identité structurelle, chapitre 12) : la Chaine les importe puis les étend.
- **Trajectoire encadrée** — `est_encadree` et `conserve_maat` garantissent qu'aucune
  transformation ne rompt l'harmonie.

---

## 5. Le dispositif unifié

Le **dispositif unifié de résolution** (définition 13.1) traite toute catégorie de
problèmes par les **quatre mêmes mouvements** :

1. **Problématisation** — formuler le problème dans le vocabulaire du socle
   (question, porteur, état, gouverne), question consignée et données attestées.
2. **Géométrisation** — la *triple substitution* : support → porteur de figures
   situées, valuation → ordre de pesée `M`, dynamique → trajectoire encadrée.
3. **Calcul non-binaire** — dérouler `δ`, `ι`, `κ` sous les trois gouvernes
   (éthique `E`, frugalité `F`, explicabilité `X`) et sous conservation de l'harmonie.
4. **Pesée et rendu** — trancher la question par la balance (à deux étages :
   admissibilité éthique puis pesée) et restituer le résultat avec son registre.

```julia
d = Dispositif()                              # M = (R, P, Γ) + les quatre mouvements
ch = ChaineGouvernee(;                        # la chaîne gouvernée (7 dimensions)
        question = :attestation,
        schema   = "schéma",
        langue   = "langue",
        action   = "action",
        valeur   = f -> 1.0)
sub = TripleSubstitution(G, "valuation → M", "dynamique → trajectoire encadrée")
r = resoudre(d, corpus, ch, sub, Ψ, q, h)     # → Resolution
reussie(r)                                    # les quatre mouvements sont-ils conformes ?
```

---

## 6. Carte des catégories (tableau 13.1)

Chaque catégorie de problèmes computationnels possède **un fichier** dans
`src/categories/`, avec une méthode adossée au socle.

| Ch. | Catégorie | Fichier | Méthodes principales |
|:---:|---|---|---|
| 14 | Architectures des ordinateurs | `architectures.jl` | `placement_par_pesee`, `flot_par_composition` |
| 15 | Systèmes d'exploitation | `systemes.jl` | `ordonnancement_par_pesee`, `allocation_memoire_situee` |
| 16 | Langages de programmation | `langages.jl` | `compatibilite_types`, `compilation_par_composition`, `evaluation_consignee` |
| 17 | Structures de données | `structures.jl` | `tri_par_pesee`, `parcours_regle` |
| 18 | Calcul scientifique | `scientifique.jl` | `resolution_par_descente`, `convergence_par_harmonisation` |
| 19 | Calcul haute performance | `hpc.jl` | `execution_par_harmonie`, `reponderation_sous_charge` |
| 20 | Informatique quantique | `quantique.jl` | `calcul_par_superposition`, `correction_par_harmonisation` |
| 21 | Bases de données | `bases.jl` | `recherche_par_relaxation`, `jointure_par_composition` |
| 22 | Big data | `bigdata.jl` | `partitionnement_geometrique`, `agregation_harmonique` |
| 23 | Réseaux | `reseaux.jl` | `routage_par_harmonie`, `resilience_par_pesee_locale`, `protocole_par_composition`, `transmission_longue_portee`, `resoudre_adresse` / `naviguer_toile` (toile par figures) |
| 24 | Cryptologie | `cryptologie.jl` | `hachage_par_pesee`, `chiffrement_par_redistribution` |
| 25 | Optimisation / recherche opérationnelle | `optimisation.jl` | `descente_par_harmonisation`, `elagage_par_pesee`, `borne_harmonique` |
| 26 | Aide multicritère à la décision | `multicritere.jl` | `classement_par_pesee_harmonique`, `negociation_par_reponderation` |
| 27 | Théorie des jeux | `jeux.jl` | `pesee_mutuelle`, `conception_par_attracteur` |
| 28 | Ingénierie des connaissances | `connaissances.jl` | `acquisition_par_pesee`, `raisonnement_par_composition` |
| 29 | Recherche heuristique / systèmes experts | `heuristique.jl` | `recherche_par_pesee_de_promesse`, champ d'attraction de Maât (`champ_vers`, `champ_depuis`), `inference_gouvernee` |
| 30 | Apprentissage automatique | `apprentissage.jl` | `reponderation_sous_encadrement` |

La carte est exposée par `CARTE_CATEGORIES` (module `Dispositif`) et interrogeable
par `categorie("Réseaux")` (recherche insensible à la casse).

### Patron d'implémentation

Toutes les catégories suivent le même patron, garantissant l'unité du dispositif :

- un **struct de résultat** (`ResultatXxx`) portant le produit et un
  `registre :: Vector{String}` ;
- une **fonction méthode** qui procède du socle — `scores_pesee`, `κ`,
  `valuations_nommees`, `redistribuer`, `h.compatibilite` — **sans principe étranger** ;
- des **docstrings en français** citant la méthode et le chapitre de référence.

---

## 7. L'Ethnomatique

Le module **`Ethnomatique`** formalise des savoirs africains, chacun occupant un
fichier qui **s'enregistre lui-même** au chargement : ajouter un savoir revient à
écrire un fichier appelant `enregistrer_savoir!` puis à l'`include` — rien d'autre
ne bouge. C'est la composition `⊙` appliquée aux savoirs : le registre est le
porteur, chaque savoir un site.

- **Numérations** — bases africaines, hiéroglyphes égyptiens, fractions
  égyptiennes, œil d'Horus, numération yoruba (vigésimale), guèze, cauris.
- **Jeux de semailles** — plateau d'awalé / oware, distribution et parties.
- **Géomancie** — sikidy (Madagascar), ifa (yoruba), cauris ; additions,
  inversions, réversions, figures filles et bouclier.
- **Motifs et symétries** — groupes `D4` et de frise, adinkra, sona (monolinéaires,
  circuits).
- **Artefacts à encoches** — os d'Ishango, os de Lebombo, lunaisons.

```julia
recensement_savoirs()          # l'état du registre : savoirs implémentés / prévus
savoir(:numeration)            # description d'un savoir
numerer_yoruba(42)             # une lecture computationnelle parmi d'autres
awele_jouable(plateau)         # jeu de semailles
```

---

## 8. Exemples d'usage

### a) La Loi fondamentale (module `Loi`)

```julia
using Kamitique

verifier_derivation()          # ΣK ⇐ A1…A4 : graphe de dérivation cohérent ?
verifie_nombre_or()            # φ² = φ + 1  (⟺ φ − 1 = 1/φ)
spirale_rayon(π/2)             # r(θ) de la spirale d'or (A3)
manifestation_triadique()      # (Atoum, Ptah, Khnoum) — la triade conjointe
```

### b) Le socle : un état, une question, une pesée

```julia
using Kamitique

# 1. Un porteur de figures situées
G = Porteur()
ajouter_site!(G, :g1; lieu = "signe",   voisins = [:g2, :g3])
ajouter_site!(G, :g2; lieu = "source",  voisins = [:g1])
ajouter_site!(G, :g3; lieu = "contexte", voisins = [:g1])

# 2. Un état en superposition pondérée (Σ αᵍ = 1, normalisation automatique)
a, b, c = Figure([:g1]), Figure([:g2]), Figure([:g3])
Ψ = Etat([a, b, c], [5.0, 3.0, 2.0])   # poids → [0.5, 0.3, 0.2]

# 3. Une question et une harmonie
h = HarmonieRaffinement()
q = Question(:attestation, Proposition("attesté", f -> :g1 in f.sites))

# 4. La pesée résout la question (opérateur κ)
Ψr, sc = κ(Ψ, q, h)
est_resolu(Ψr)      # true — c'est la pesée qui tranche, jamais l'état nu
figure_resolue(Ψr)  # la figure retenue
sc.scores           # les scores de pesée de chaque figure
```

### c) Une catégorie : le tri par pesée harmonique (ch. 17)

```julia
r = tri_par_pesee(Ψ, q, h)     # → ResultatTri
r.degres                       # degrés décroissants
r.registre                     # le registre consigne la question et les degrés
```

### d) La décision éthique : la balance (module `Pesee`)

```julia
contraintes = contraintes_ethiques_canoniques()
ok, violees = admissibilite(figure, contraintes)   # premier étage : admissibilité
rp = balance(Ψ, q, h; contraintes = contraintes)   # second étage : pesée
est_resolue(rp), figure_retenue(rp)
```

---

## 9. Tests

La suite vérifie, module par module, la conformité de l'implémentation aux
documents de référence :

```julia
using Pkg
Pkg.test("Kamitique")
# ou directement :
# julia --project=. test/runtests.jl
```

Elle compte **821 tests** et couvre le module `Loi` (axiomes `A1–A4`, dérivation
`ΣK ⇐ A1…A4`, espace des phases, Loi Universelle, Heka, manifestation), le Socle
(axiomes `ΣK`, théorèmes `T-K1 → T-K6`), la Pesée, la Chaine, la Méthodologie
(`M = (R, P, Γ)`), le Dispositif (quatre mouvements, carte), **chaque catégorie**
de la carte, et l'Ethnomatique. Tous les tests doivent passer.

---

## 10. Benchmark

`benchmark/benchmarks.jl` mesure, sur des instances représentatives et massives,
le temps, les allocations et l'exposant empirique de complexité des méthodes de
chaque catégorie :

```julia
# julia --project=. benchmark/benchmarks.jl
```

Il couvre aussi les cas limites (entrées dégénérées, rejets attendus) et rappelle
les classes de coût observées (`n²`, `n log n`, `n`, `sⁿ`).

### Rapports de conformité

Deux familles de rapports vérifient, **engagement par engagement**, que la carte
tient ce qu'elle consigne :

- `benchmark/objectifs.jl` — le dispositif global (`BILAN GLOBAL : 80/80`) ;
- `benchmark/objectifs_chNN.jl` — une catégorie par fichier (ch. 14 à 30), chacune
  se terminant par un `BILAN CATÉGORIE`.

```julia
# julia --project=. benchmark/objectifs.jl
# julia --project=. benchmark/objectifs_ch23.jl
```

Chaque contrôle affiche `[✓]`/`[✗]` et recoupe les chiffres consignés en
**recalculant les règles indépendamment** (fidélité `G5`, voir
`docs/journal_theorie_de_base.md`).

---

## 11. Correspondance avec les documents de référence

| Document | Couverture dans le package |
|---|---|
| `docs/Cosmologie_Quantique_Geometrique.pdf` — ch. 1–4 | module **Loi** : axiomes `A1–A4`, dérivation `ΣK`, espace des phases, Loi Universelle, Heka, manifestation |
| `docs/Cosmologie_Quantique_Geometrique.pdf` — socle | module **Socle** : sites, figures, porteur, états pondérés, valuation, harmonie, axiomes `ΣK`, opérateurs `δ/ι/κ`, trajectoire encadrée, théorèmes |
| `docs/La_Kamitique_Theories_Methodes_Algorithmes.pdf` — ch. 8 | module **Pesee** : balance, non-compensation, dernière pesée humaine |
| `docs/La_Kamitique_Theories_Methodes_Algorithmes.pdf` — ch. 9 & 11 | module **Chaine** : 7 dimensions, chaîne gouvernée ; module **Methodologie** : règles `R`, protocoles `P`, épreuves `Γ` |
| `docs/La_Kamitique_Theories_Methodes_Algorithmes.pdf` — ch. 12 & 13 | module **Dispositif** : identité `δ/ι/κ` socle↔chaîne, les quatre mouvements, carte (tableau 13.1) |
| `docs/La_Kamitique_Theories_Methodes_Algorithmes.pdf` — ch. 14 à 30 | module **Categories** : les méthodes de chaque catégorie |
| Savoirs africains | module **Ethnomatique** : numérations, semailles, géomancie, motifs, artefacts |

---

## 12. Conventions de conception

- **Aucune discipline étrangère** : chaque méthode ne mobilise que la Loi, le
  socle, la chaîne, la pesée et la méthodologie (définition 13.1).
- **Tout est consigné** : chaque méthode retourne un `registre` où sont notées les
  décisions et les figures écartées (traçabilité de l'explicabilité `εX`).
- **Aucun drapeau binaire** en sortie : les résultats sont des **degrés** (ordres de
  pesée), non des booléens — la coupure `M → {0,1}` est **différée** au dernier
  moment.
- **Non-compensation native** : un critère non négociable ne peut être racheté par
  la moyenne des autres (proposition 8.7).
- **Fidélité à la source (`G1`)** : unité, non analogie ; aucun chiffre consigné ne
  change sans être déclaré (`G5`, voir `docs/journal_theorie_de_base.md`).
- **Code et documentation en français**, en cohérence avec les documents de
  référence.

---

## 13. Journal de la théorie de base

`docs/journal_theorie_de_base.md` consigne, entrée par entrée (`M-01` … `M-07`),
l'état de la théorie de base : règles `G1–G5`, tableau des axiomes de la CQG et de
leur dérivation, entrées de consignation (défaut, réajustement, corrections,
épreuves `G3`/`G4`) et protocole de mise à jour.

---

## Licence et auteur

Auteur : **Prof. ACHIEPO Yapo** (`Project.toml`).
