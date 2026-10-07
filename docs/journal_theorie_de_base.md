# Journal des modifications de la théorie de base de la Kamitique

> Document de suivi. Il retrace, **au fur et à mesure**, toute modification apportée à la
> *théorie de base* de la Kamitique — son axiomatique `ΣK`, ses théorèmes fondamentaux et
> les primitives du cosmos de calcul — en explicitant pour chaque entrée : la source dans
> la Cosmologie Quantique Géométrique (CQG), le défaut constaté, le réajustement proposé,
> le gain attendu, les risques et les vérifications exigées.

- Source physique : `docs/Cosmologie_Quantique_Geometrique.pdf` (édition septembre 2026)
- Source computationnelle : `docs/Kamitique.pdf`
- Implémentation de référence : `src/` (loi, socle, pesée, chaîne, méthodologie, dispositif, catégories)
- Suite de non-régression : `test/runtests.jl` (779 tests) et `benchmark/benchmarks.jl`

---

## 0. Objet et portée

La **théorie de base** désigne ce qui, dans la Kamitique, ne se déduit de rien d'autre :

| Composante | Contenu | Source |
|---|---|---|
| La Loi fondamentale (CQG) — la **racine** | quatre axiomes `A1` Noun, `A2` Kheper, `A3` Spirale d'or, `A4` Maât ; espace des phases `(ℋ_Noun, M₄, {ℳ_k}²²)` ; Loi Universelle (ch. 2) ; énergie du Noun — Heka (ch. 3) ; principe de manifestation (ch. 4) | CQG, ch. 1–4 ; `src/loi/` |
| Le cosmos de calcul | `K = (G, ⊙, ≺, µ)` | Kamitique, figure 3.1 |
| Les primitives | site, figure, porteur `G`, état `Ψ = Σ α_g·g`, valuation `ν`, harmonie `µ` | Kamitique, ch. 5 ; `src/socle/` |
| Les opérateurs | `δ` (structurer), `ι` (composer), `κ` (peser) | Kamitique, déf. 7.1–7.4 ; `src/socle/operateurs.jl` |
| L'axiomatique `ΣK` | `A-K1` … `A-K7` | Kamitique, ch. 6 ; `src/socle/axiomes.jl` |
| Les théorèmes | `T-K1` … `T-K6` | Kamitique, ch. 8 ; `src/socle/theoremes.jl` |
| Les principes méthodologiques | balance (8.1), trièdre `εE/εF/εX`, non-compensation (26.1) | Kamitique, ch. 8 et 26 ; `src/methodologie/epreuves.jl` |

Le rapport entre les deux livres est **d'unité, non d'analogie** (principe 3.1) : *« la
Kamitique est sa version computationnelle : le même socle, les mêmes axiomes, la même
dynamique gouvernée. »* Toute modification de la théorie de base doit donc se justifier
**depuis la CQG**, et non depuis une commodité d'implémentation. Depuis `M-07`, cette
exigence est **structurelle** : les axiomes `A1`–`A4` de la CQG sont consignés dans
`src/loi/`, et le système `ΣK` en **dérive** explicitement (`A-K1`…`A-K7` ⇐ `A1`–`A4`, § 2.1).

---

## 1. Règle de recevabilité d'une modification

Une modification n'est inscrite au journal qu'après avoir satisfait les cinq garde-fous
ci-dessous. Un défaut sur l'un d'eux vaut rejet.

| Code | Garde-fou | Exigence |
|---|---|---|
| `G1` | **Fidélité à la CQG** | La modification doit être la lecture computationnelle d'un axiome ou d'un théorème de la CQG — non un ajout étranger. |
| `G2` | **Compatibilité `T-K1`** | La modification doit être **trivialement satisfaite** par le cosmos binaire dégénéré (états résolus, valuation aux bornes, harmonie constante). Sinon la subsumption binaire tombe, et avec elle la sécurité de l'alternative. |
| `G3` | **Non-régression** | La suite de tests passe (779 tests aujourd'hui) ; le benchmark ne doit montrer aucune régression d'ordre. |
| `G4` | **Équivalence mesurée** | Lorsqu'une modification est présentée comme un simple renforcement *à sémantique constante*, l'équivalence doit être mesurée sur un grand nombre de tirages (cf. le précédent `_partagent_un_site`, 20 000 tirages). |
| `G5` | **Fidélité de la traçabilité** | Aucun chiffre **consigné** (registres `εX`, degrés rapportés `ν`/`µ`) ne peut changer sans que le changement soit déclaré. Un résultat consigné qui change est une modification de théorie, pas d'implémentation. |

Statuts possibles d'une entrée : `proposé` → `retenu` → `appliqué` → `vérifié`, ou `rejeté`.

---

## 2. La source : les quatre axiomes de la CQG

| Axiome CQG | Énoncé (résumé) | Ce qu'il apporte formellement |
|---|---|---|
| **A1 — Noun** | L'espace-temps émerge d'un espace de Hilbert global `ℋ_tot` **saturé de toutes les configurations potentielles** ; la création est « une actualisation sélective au sein d'un réservoir d'anticipation total ». | **Complétude / plénitude** : rien de possible n'est absent. Aucune singularité. |
| **A2 — Kheper** | Application `K̂(s) : ℋ → M₄`, `dim DOF_top = 9` (classes de Stiefel–Whitney, Chern, Pontryagin). | **Invariants** : *« chaque degré de liberté topologique invariant sous `K̂(s)` constitue une contrainte permanente sur la dynamique. »* |
| **A3 — Spirale d'or** | Auto-similarité conforme régie par `φ` ; **coupure topologique naturelle `R₀ ≠ 0`**. | **Échelle finie** : *« la coupure topologique naturelle `R₀ ≠ 0` remplace le continuum indéfiniment divisible par une hiérarchie fractale ordonnée. »* |
| **A4 — Maât** | `δS_eff = 0 ⟹ ∃! g*μν, A*μ : S[g*, A*] = minimum global, m_gap > 0`. | **Attracteur unique et global** + **écart strict** (`m_gap > 0`) : exclut les vacua dégénérés et les multivers de paysages. |

### 2.1 Dérivation `ΣK ⇐ A1 … A4`

Le système `ΣK` **dérive** des quatre axiomes (consignation : `src/loi/axiomes.jl`,
`DERIVATION_SIGMA_K` ; contrôle : `verifier_derivation()`).

| Engagement `ΣK` | Axiome source | Motif de la dérivation |
|---|---|---|
| `A-K1` totalité géométrique | `A1` | plénitude du Noun : toute valeur est la valeur d'une figure située |
| `A-K2` superposition | `A1` | `ℋ_tot` est un espace de Hilbert : l'état est une superposition pondérée |
| `A-K3` valuation continue | `A4` | la Maât est le principe de pesée graduée (la bivalence est une coupure décisionnelle) |
| `A-K4` processualité gouvernée | `A2` | Kheper est le devenir continu (+ les neuf invariants topologiques, `A-K4⁺`) |
| `A-K5` conservation et progression | `A4` | attracteur unique et global, `m_gap > 0` (`M-02`) |
| `A-K6` coupure de résolution | `A3` | la spirale d'or fournit la coupure conforme `R₀` (`M-01`) |
| `A-K7` fermeture canonique | `A1` | la plénitude se lit comme clôture du support (`M-03`) |

Les **quatre** axiomes sont sollicités — `A1` : `A-K1`, `A-K2`, `A-K7` ; `A2` : `A-K4` ;
`A3` : `A-K6` ; `A4` : `A-K3`, `A-K5` — et aucun `A-K` n'est sans source. C'est la
garantie `G1` portée au registre de l'axiomatique (§ 4, `M-07`).

---

## 3. Écarts constatés entre la CQG et `ΣK`

L'examen mené sur `src/socle/` met au jour quatre écarts structurels. Chacun est un
**affaiblissement** de la théorie de base par rapport à son propre fondement.

| # | CQG | `ΣK` actuel | Nature de l'affaiblissement |
|---|---|---|---|
| `E1` | A3 : coupure `R₀ ≠ 0`, échelle finie | `≺` (`src/socle/site.jl`) n'a **aucun plancher** : un raffinement peut se poursuivre sans borne | Le cosmos est *verticalement infini* ; `T-K3` doit **supposer** la finitude de la trajectoire au lieu de la démontrer |
| `E2` | A4 : attracteur **unique et global**, `m_gap > 0` | `A-K5` ne donne qu'une **croissance** ; `T-K3` n'atteint qu'un **maximum local** | Aucun certificat d'optimalité globale ; aucune borne sur le nombre de pas de convergence |
| `E3` | A1 : plénitude formelle du Noun | `A-K1` n'impose qu'un **contrôle d'appartenance** (`verifier_appartenance`) ; le support d'un état est une liste finie quelconque | **Pas de fermeture** : deux supports différents peuvent désigner le même cosmos ; l'égalité d'états n'est pas canonique |
| `E4` | A2 : les 9 invariants sont des **contraintes permanentes** | `A-K4` n'exige que l'« encadrement » ; aucune notion d'**invariant de la dynamique** | Aucun élagage par invariant possible dans les catégories de recherche |

Ces quatre écarts expliquent une part de ce que le benchmark « constate actuellement » :
la borne quadratique du noyau `µ`, l'absence de garantie de terminaison, et la dépense de
recherche non informée par la structure.

> **Note (issue de `M-01`)** : `E1` s'est révélé **infirmé** à l'examen. Le porteur est fini
> (aucune dynamique ne crée de site) et un raffinement strict croît strictement en largeur :
> `≺` est **déjà bien fondé**, borné par `|G|`. L'écart `E1` relevait d'une lecture trop
> rapide de `T-K3` ; il est conservé ici à titre de trace, avec sa réfutation en `M-01`.

> **Note (issue de `M-02`)** : `E2` est **réparé**, non infirmé. `A-K5⁺` (progression +
> `m_gap`) fournit bien le certificat manquant — attracteur unique, borne de pas explicite.
> Mais la mesure montre que la **borne ne mord pas** : la pesée `κ` résout en **un seul**
> pas (`µ` d'un état résolu vaut exactement `1`), donc la borne `O(log(1/ε))` est satisfaite
> avec un pas. Le gain est **déclaratif et de refus**, non calculatoire.

> **Note (issue de `M-03`)** : `E3` est **réparé**. `A-K7` dote la théorie d'une **forme
> normale** (clôture) et d'un **demi-treillis supérieur**, et fait tomber le défaut de
> canonicité. Mais la mesure montre que la clôture **ne change aucun chiffre consigné**
> (`ν`, `µ`, `argmax` identiques) : le gain est **structurel**, non calculatoire. En
> revanche, elle **déclare non admissibles** les supports du benchmark, qui n'attestent
> aucun lien — la théorie gagne en exigence ce qu'elle ne gagne pas en vitesse.

> **Note (issue de `M-04`)** : `E4` est **réparé**. `A-K4⁺` attache à chaque figure une
> **signature** (classe de raffinement + profil topologique `β₀/β₁`) invariante le long
> des pas admissibles, et en tire un **élagage exact** : hors de la composante `β₀` de
> `depart`, aucune voie n'existe. C'est le **seul** des quatre réajustements qui produit
> un gain **calculatoire** — mais il est **localisé** : il ne mord que là où la recherche
> *traverse le porteur* (ch. 21 et ch. 29). Mesuré : **6,7× à 14,6×** de nœuds en moins
> sur tous les couples d'un porteur à plusieurs composantes, **0 écart** sur 19 602
> couples (aucune solution coupée). Sur la relaxation (ch. 21), qui parcourt le *support*
> et non le porteur, `β₀` est **sans prise** : la réduction atteignable y est exactement
> celle de `A-K7`, non additionnelle.

---

## 4. Journal des modifications

### M-01 — `A-K6` : Coupure de résolution (plancher `R₀`)

- **Statut** : `vérifié` — partie axiomatique **appliquée** ; volet calculatoire **`rejeté`** (mesuré défavorable).
- **Source CQG** : A3 — *« remplace le continuum indéfiniment divisible par une hiérarchie fractale ordonnée »*.
- **Défaut allégué (`E1`)** : `≺` est un ordre partiel sur les figures, sans borne inférieure de granularité ; `T-K3` énonce sa convergence pour une trajectoire *« admissible finie »* — la finitude serait une hypothèse.
- **Résultat de l'examen : `E1` infirmé.** `ajouter_site!` n'est appelé qu'à la construction (`degenerer`) ou par l'appelant ; **aucune dynamique** (`δ`, `ι`, `κ`) ne crée de site. Le porteur est donc **fini**, et un raffinement strict croît strictement en largeur (`a ≺ b`, `a ≠ b` ⟹ `|a| < |b|`) : toute chaîne de raffinements stricts est bornée par `|G|`. `≺` est **déjà bien fondé** et `T-K3` n'a pas à supposer la finitude. La verticale infinie n'existe pas.
- **Réajustement appliqué — *A-K6 (Coupure de résolution)*** : la coupure `R₀` devient un objet explicite et vérifiable du porteur.
  - `Site` porte une `echelle ∈ ℕ*` (`src/socle/site.jl`), défaut `1` ;
  - `profondeur(G)` donne la coupure `R` (nombre fini d'échelles) ; `echelles(G)` les énumère ;
  - `verifie_ak6(G)` exige que chaque site ait une échelle dans `[1, R]` et que **tout voisinage attesté relie des échelles contiguës** (la hiérarchie fractale *ordonnée* de la CQG ne saute pas d'échelle) ;
  - l'axiome est inscrit dans `AXIOMES[:AK6]` et intégré au rapport `verifier_axiomes`.
- **Gain réel** : **déclaratif**. Le porteur dispose d'une stratification finie, cohérente et **vérifiable**, que les catégories peuvent exploiter (cf. `M-04`). Aucun gain de calcul n'est revendiqué.
- **Volet calculatoire : mesuré, puis rejeté.** La lecture « `≺` en `O(R)` » (profil d'échelle + rejet stratifié) a été implémentée et mesurée contre le noyau canonique :

  | largeur `l` | canonique (o/couple, ns) | stratifié A-K6 (o/couple, ns) |
  |---|---|---|
  | 4 | **0**, 30 | 704, 529 |
  | 16 | **0**, 221 | 704, 1 798 |
  | 64 | **0**, 3 197 | 704, 8 857 |

  Le rejet stratifié **ajoute 704 o/couple** (construction des profils) et n'est **jamais plus rapide** sur cette charge : il est retiré (frugalité `εF`). Le noyau reste à **0 o/couple** ; `≺` demeure en `O(l²)` — cet `O(l²)` est *intrinsèque* (test d'appartenance sans index), non accidentel.
- **G2** : le cosmos dégénéré de `T-K1` a `échelle 1` partout ⇒ `R = 1`, A-K6 satisfait trivialement (test ajouté).
- **G3** : **174** tests passent (165 + 9). **G4** : l'équivalence `≺`/stratifié n'est pas retenue (voie supprimée). **G5** : aucun chiffre consigné ne change (`echelle` défaut `1` ⇒ degrés, `ν` et `µ` inchangés).

### M-02 — `A-K5⁺` : Conservation **et progression** (écart `m_gap`)

- **Statut** : `vérifié` — axiome **appliqué** et **mesuré** ; gain **déclaratif et de refus**, gain calculatoire **nul** (le noyau converge déjà en un pas).
- **Source CQG** : A4 — *« `δS_eff = 0 ⟹ ∃! g*μν, A*μ : S[g*, A*] = minimum global, m_gap > 0` »* ; *« l'unicité de l'attracteur est décisive : elle exclut les vacua dégénérés dont la multiplicité rendrait l'ordre cosmique contingente »*.
- **Défaut (`E2`)** : `A-K5` n'énonçait qu'une **croissance** (`µ(Ψ_{i+1}) ≥ µ(Ψ_i)`). `T-K3` ne concluait qu'à un **maximum local** parmi les états accessibles : ni **unicité** de l'attracteur, ni **de combien** `µ` doit croître — donc aucune borne de convergence, et un *plateau* résolu par un `argmax` arbitraire.
- **Réajustement appliqué — *A-K5⁺ (Conservation et progression)*** : `A-K5` conserve son énoncé de conservation et reçoit en plus l'**inégalité de Łojasiewicz**
  `µ(Ψ_{k+1}) − µ(Ψ_k) ≥ c · (µ* − µ(Ψ_k))^p`, `c > 0`, `p ≥ 1`,
  pour toute **pesée** (`operateur = :κ`) où un accroissement est encore possible (`µ(Ψ_k) < µ*`).
  - `ecart_maat(h, Ψs)` matérialise `m_gap` : écart entre le degré maximal accessible et le meilleur degré **distinct**. Un écart **nul** signale un *plateau* (vacua dégénérés) : l'attracteur n'est pas unique, la décision serait arbitraire.
  - `estime_progression(t, h)` mesure `(c, p)` — régression log-log de `log(gain)` sur `log(reste)`, et `c` = **minimum** des rapports `gain/reste^p`, donc borne inférieure *certifiée*.
  - `borne_pas_progression` explicite la borne de pas : `O((1/c)·log(1/ε))` pour `p = 1`, polynomiale en `ε^{1−p}` pour `p > 1`.
- **Spécification déclarée (à ne pas confondre avec la CQG)** : la locution *« pas où un accroissement est possible »* est **spécifiée** comme portant sur la **pesée**, non sur `δ`/`ι`. Cette spécification est exigée par `G1` : `κ` est le seul opérateur qui *tranche et résout* (déf. 7.3, 10.4 ; `A-K2` — la résolution ne s'obtient que par une pesée explicite) ; `δ` (structurer) et `ι` (composer) réorganisent la présence **sans décider** et ne peuvent, par définition, être soumis à une exigence de progression.
- **Mesure** — familles `l ∈ {4, 8, 16, 32, 64, 128}` (porteur en chaîne, état uniforme sur `l` figures atomiques, puis la pesée qui tranche) :

  | largeur `l` | `µ(Ψ₀)` | `µ*` | `m_gap` | `c` | `p` | pas observés | borne | certifié |
  |---|---|---|---|---|---|---|---|---|
  | 4 | 0,850 000 | 1 | 0,150 000 | 1 | 1 | 1 | 1 | oui |
  | 16 | 0,812 500 | 1 | 0,187 500 | 1 | 1 | 1 | 1 | oui |
  | 64 | 0,803 125 | 1 | 0,196 875 | 1 | 1 | 1 | 1 | oui |
  | 128 | 0,801 563 | 1 | 0,198 438 | 1 | 1 | 1 | 1 | oui |

  Le certificat est **exactement `c = 1`, `p = 1`**, et l'attracteur est atteint en **un seul** pas. **Raison** : `κ` résout sur une figure unique (`resolve`), et `compatibilite_raffinement(f, f) = 1` puisque `≺` est réflexif ; tout état résolu a donc `µ = 1 = µ*`. La convergence est **immédiate par construction du noyau**.
- **Contrôle de la borne** sur des suites satisfaisant l'énoncé (`Δ = c·r^p`, `r₀ = 0,5`, `ε = 1e-9`) :

  | `c` | `p = 1` (observés / borne) | `p = 1,5` | `p = 2` |
  |---|---|---|---|
  | 0,05 | 391 / 391 | 1 264 840 / 1 264 855 | ≥ 1e8 / 2,0e10 |
  | 0,25 | 70 / 70 | 252 956 / 252 971 | ≥ 1e8 / 4,0e9 |
  | 0,90 | 9 / 9 | 70 255 / 70 270 | ≥ 1e8 / 1,1e9 |
  | 1,00 | 1 / 1 | 63 227 / 63 243 | ≥ 1e8 / 1,0e9 |

  Pour `p = 1`, la borne est **exacte** (observé = borne) : elle est *serrée*. Pour `p > 1` elle devient **polynomiale** et, dès `p = 2`, dépasse `1e8` pas : seule la classe `p = 1` est praticable — et le noyau la réalise avec `c = 1`, la meilleure constante possible.
- **Gain réel** : **déclaratif et de refus**, non calculatoire.
  1. `m_gap` **rend explicite** ce qui était implicite : le cosmos dégénéré de `T-K1` (`µ` constante) a `m_gap = 0` — la théorie **déclare** qu'aucune décision par Maât n'y est disponible, au lieu de rendre un `argmax` arbitraire. C'est précisément le point de la CQG (« exclut les vacua dégénérés »).
  2. `T-K3` devient un énoncé **certifié** : attracteur atteint et `m_gap > 0` (unicité) sont **vérifiables**, non supposés.
  3. `borne_pas_progression` transforme « ça converge » en « converge en ≤ N pas », `N` explicite.
  4. **Aucun gain de temps** n'est revendiqué : le noyau convergeait déjà en un pas.
- **Coût (`εF`)** : **nul au-dessus de `A-K5`**. `verifie_progression_maat` teste `Δµ ≥ −tolerance` sur **chaque** pas *avant* de n'exiger la progression que sur la pesée ; `verifie_ak5` se réduit donc à `verifie_progression_maat` (l'appel redondant à `conserve_maat` a été retiré). Mesure à `l = 64` :

  | appel | allocation | temps |
  |---|---|---|
  | `h(Ψ₀)` seul (**pré-existant**) | 299 568 o | 413 µs |
  | `conserve_maat(t, h)` (**pré-existant**) | 299 792 o | 360 µs |
  | `verifie_progression_maat(t, h)` (nouveau) | **299 840 o** | **341 µs** |
  | `estime_progression(t, h)` | 300 000 o | 405 µs |
  | `ecart_maat(h, Ψs)` | 300 000 o | 336 µs |

  La dépense est **entièrement** portée par l'évaluation de `µ`, elle-même dominée par le **dispatch dynamique** de `h.compatibilite :: Function` sur chacun des couples de figures (noyau `O(n²)` déjà consigné au §3). `A-K5⁺` **n'ajoute aucune passe** sur les états.
- **G2** : dans le cosmos dégénéré, `µ` est **constante** : aucun accroissement n'est possible, l'énoncé de progression est **vide** (test ajouté). `T-K1` est sauvegardé.
- **G3** : **194** tests passent (174 + 20) ; benchmark **inchangé** (11/11 cas limites ; exposants `n²`, `n log n`, `n`, `sⁿ` inchangés — `A-K5⁺` n'entre dans aucun chemin mesuré). **G4** : l'équivalence de coût `verifie_progression_maat ≡ conserve_maat` est **mesurée** (tableau ci-dessus). **G5** : aucun chiffre consigné ne change (ni `µ`, ni `ν`, ni registres `εX`) : l'axiome ajoute une **condition**, il ne modifie aucune **valeur**.

### M-03 — `A-K7` : Fermeture canonique du support

- **Statut** : `vérifié` — axiome **appliqué** et **mesuré** ; gain **structurel** (canonicité, demi-treillis), gain calculatoire **nul** (aucun chiffre consigné ne change).
- **Source CQG** : A1 — le Noun est *« un réservoir d'anticipation total »* ; *« rien de ce qui est possible n'en est absent »*. La plénitude se lit, côté computationnel, comme une **clôture** : une figure située ne peut porter que les liens que le porteur atteste.
- **Défaut (`E3`)** : `A-K1` n'impose qu'un **contrôle d'appartenance** (`verifier_appartenance`) ; le support d'un état est une liste finie **quelconque**. Deux états de supports différents peuvent dénoter le même cosmos ; l'égalité (donc le hachage, la déduplication, la mémoïsation) n'est pas canonique.
- **Réajustement appliqué — *A-K7 (Fermeture)*** : le support d'un état admissible est **clos** — chaque figure porte **exactement** les liens de voisinage que `G` atteste entre ses propres sites.
  - `cloture(G, f)` : la `figure_totale(G)` **restreinte** aux sites de `f` — même suite de sites (l'arrangement de la déf. 5.2 est préservé), liens internes **attestés uniquement**. Idempotente, monotone, **canonique** sur une suite de sites donnée.
  - `est_close(G, f) = (cloture(G, f) == f)` ; `verifie_ak7(G, Ψ)` exige A-K1 **et** chaque figure close.
  - `cloture_support(G, Ψ)` : la `figure_totale(G)` restreinte à l'union des sites du support.
  - `reunion(G, a, b) = cloture(G, a ⊙ b)` : brique du **demi-treillis supérieur** des figures closes (`figure_vide` en bas, `figure_totale(G)` en haut).
  - `canoniser(G, Ψ)` : **forme normale** d'un état — chaque figure remplacée par sa clôture, deux figures de même clôture **fusionnées** (poids additionnés).
  - l'axiome est inscrit dans `AXIOMES[:AK7]` et intégré au rapport `verifier_axiomes`.
- **Spécification déclarée** : les liens internes **non attestés** sont **exclus** par la clôture — c'est la lecture littérale de « *sa clôture est la `figure_totale` restreinte* ». C'est une **restriction** de sémantique, assumée et conforme à A-K1 (une figure située ne mobilise rien hors du porteur).
- **Mesure (A) — clôture des supports du benchmark** (anneau, figures de 3 sites consécutifs) :

  | `N` | figures | closes | non closes | `verifie_ak7` |
  |---|---|---|---|---|
  | 64 | 64 | 0 | 64 | `false` |
  | 128 | 128 | 0 | 128 | `false` |
  | 256 | 256 | 0 | 256 | `false` |

  Les instances du benchmark **ne sont pas closes** : le `Figure([...])` canonique n'y porte **aucun** lien, alors que `G` en atteste deux par figure (`(s_i, s_{i+1})`, `(s_{i+1}, s_{i+2})`). `A-K7` les **déclare non admissibles** ; `canoniser` les rend admissibles.
- **Mesure (B) — effet sur les chiffres consignés (`G5`)** : la canonisation **ne modifie aucun degré consigné**.

  | `N` | `ν` avant | `ν` après | `µ` avant | `µ` après | `argmax` pesée |
  |---|---|---|---|---|---|
  | 64 | 0,730 769 23 | **idem** | 0,792 010 36 | **idem** | 1 → 1 |
  | 128 | 0,740 310 08 | **idem** | 0,795 921 03 | **idem** | 1 → 1 |
  | 256 | 0,745 136 19 | **idem** | 0,797 938 82 | **idem** | 1 → 1 |

  **Raison** : `ν` n'emploie pas les liens ; et dans la branche « recouvrement » de [`compatibilite_raffinement`](file:///c:/Users/VP-RITRE/Desktop/Kamitique/src/socle/valuation.jl#L109-L117) — celle qui s'applique entre figures de largeurs voisines — seuls les **sites** entrent, jamais les liens. Ajouter les liens attestés **ne change donc ni `ν`, ni `µ`, ni l'`argmax`** des pesées. **Aucun chiffre consigné ne change.**
  La canonisation **agit** en revanche là où deux figures ne différaient que par leurs liens : sur le porteur d'exemple, `|support| 2 → 1`, poids `[1,0]` (fusion effective).
- **Mesure (C) — coût (`εF`)** à `N = 256` (fonctions typées, après échauffement) :

  | appel | temps | allocation |
  |---|---|---|
  | `cloture` (par figure, 256 figures) | 61,5 µs | 212,0 Ko |
  | `verifie_ak7` | 2,9 µs | 848 o |
  | `canoniser` | 278,5 µs | 273,5 Ko |
  | `cloture_support` | 31,4 µs | 56,0 Ko |

  `verifie_ak7` **sort au premier refus** (une seule clôture construite) : 848 o seulement sur un support non clos. L'axiome **n'entre dans aucun chemin mesuré du benchmark** : il est *fourni*, non *imposé*.
- **Gain réel** : **structurel**, non calculatoire.
  1. *Canonicité* : deux figures de même arrangement coïncident après clôture — `canoniser` **fusionne** leurs poids. L'égalité devient décidable par forme normale ; la déduplication et la mémoïsation deviennent sûres.
  2. *Demi-treillis supérieur* : les figures closes sont bornées (`figure_vide`, `figure_totale`) et closes par `reunion`. **Piste offerte, non encore exploitée** : une arithmétique d'intervalles sur le treillis (encadrer `ν` par le bas et le haut) — elle exigerait d'établir la monotonie de la valuation le long de `≺`, ce qui n'est **pas** fait ici.
  3. **Aucun gain de temps** n'est revendiqué : aucun chiffre consigné ne change.
- **Réserve de fidélité** : `figure_totale(G)` énumère ses sites par `keys(G.sites)` — l'ordre d'un `Dict`, **non l'ordre d'insertion**. Le « haut » du treillis n'est donc canonique qu'**à l'arrangement près**. La clôture, elle, **préserve** l'arrangement de son entrée : elle ne réordonne jamais. C'est la seule entorse résiduelle à la canonicité, et elle est déclarée.
- **G2** : dans le cosmos dégénéré de `T-K1`, les figures sont des singletons **sans lien** : elles sont closes trivialement (`cloture_support ≡ figure_totale` à l'arrangement près). **Satisfait** (test ajouté).
- **G3** : **224** tests passent (194 + 30) ; benchmark **inchangé** (exit 0 ; 11/11 cas limites ; exposants `n²`, `n log n`, `n`, `sⁿ` inchangés — `A-K7` n'entre dans aucun chemin mesuré). **G4** : l'effet de la canonisation est **mesuré** (tableau B) et se réduit à la fusion des figures de même clôture. **G5** : aucun chiffre consigné ne change (`ν`, `µ`, `argmax` identiques) — vérifié sur trois largeurs.

### M-04 — `A-K4⁺` : Invariance de signature

- **Statut** : `vérifié` — axiome **appliqué** et **mesuré** ; **gain calculatoire réel** (élagage exact), **localisé aux traversées du porteur** ; aucun chiffre consigné ne change (`G5`).
- **Source CQG** : A2 — *« chaque degré de liberté topologique invariant sous `K̂(s)` constitue une contrainte permanente »* ; *« l'univers se déploie librement dans ses configurations métriques, mais jamais en violation de ses invariants caractéristiques »*.
- **Défaut (`E4`)** : `A-K4` n'exigeait que l'**encadrement** (« hors encadrement, il y a accident »). Aucune quantité n'était déclarée **invariante** le long d'une trajectoire ; le calcul ne pouvait donc rejeter une branche *a priori*, faute d'un critère conservé par les pas admissibles.
- **Réajustement appliqué — *A-K4⁺ (Invariance de signature)*** : à chaque figure est attachée une **signature** — sa **classe de raffinement** (la figure close engendrée par ses sites : l'ensemble de ses sous-figures minimales situées) et son **profil topologique** `(β₀, β₁)` — et **tout pas admissible préserve la signature** des figures qu'il transporte.
  - `Signature(classe, composantes, cycles)` : `signature(G, f)` = `cloture(G, f)` + `β₀` (composantes de `(sites, liens)`) + `β₁ = |liens| − |sites| + β₀` (nombre cyclomatique). Décidable (pure combinatoire) et stable (entièrement déterminée par les sous-figures minimales situées).
  - `signature(G, Ψ)` : les signatures du support, dans l'ordre des figures. Deux figures de même signature dénotent le même cosmos à raffinement près — c'est le **certificat d'identité**.
  - `verifie_invariance_signature(G, t)` : pour **chaque** pas, **chaque** figure de `apres` **raffine** une figure de `avant` (`∃ f ∈ avant, f ≺ g`). Un pas admissible **ne peut perdre une sous-figure minimale**.
  - l'axiome est intégré au rapport : `verifie_ak4plus(G, t, h) = est_encadree(t, h) ∧ invariance` ; `verifier_axiomes(G, Ψ; trajectoire, h)[:AK4]` l'emploie dès qu'un porteur est fourni.
  - `composantes_connexes(G)` / `meme_composante(G, a, b)` matérialisent l'invariant `β₀` au service de l'élagage.
- **Élagage exact (ch. 29)** : `recherche_par_pesee_de_promesse` reçoit `invariant::Bool = false`. Un pas admissible ne suit que des **voisinages attestés** (`courant → v`) : il ne peut donc **jamais changer de composante**. Si `but` n'est pas dans la composante de `depart`, aucune voie n'existe — l'espace est élagué **sans développer un seul nœud**, et le registre le consigne (« 0 nœud développé, aucune solution coupée »).
- **Spécification déclarée — composantes *faibles*** : `composantes_connexes` parcourt les voisinages **dans les deux sens** (le voisinage attesté est une relation **symétrique**, déf. 5.1 ; cf. `paire_canonique`), si bien que la partition ne dépend pas de l'ordre d'itération du `Dict`. Comme la composante *faible* **contient** la composante *dirigée* de l'atteignabilité, la garde est une **sur-approximation** : elle ne coupe **jamais** une solution, même sur un porteur dont les `voisins` ne seraient pas mutuellement déclarés. *(Correction assumée : un premier parcours purement sortant dépendait de l'ordre du `Dict` et pouvait, sur porteur asymétrique, séparer deux sites reliés — donc couper une solution. Le défaut est corrigé et couvert par un test.)*
- **Mesure (A) — élagage (ch. 29)** : nœuds développés, **somme sur tous les couples ordonnés** `(départ, but)`, `départ ≠ but`, budget `max_noeuds = n + 8`.

  | porteur `k×m` | `n` | couples | dont inter-composantes | nœuds **sans** | nœuds **avec** | facteur |
  |---|---|---|---|---|---|---|
  | 4×16 | 64 | 4 032 | 3 072 | 57 792 | 8 640 | **6,7×** |
  | 8×32 | 256 | 65 280 | 57 344 | 1 969 920 | 134 912 | **14,6×** |
  | 4×64 | 256 | 65 280 | 49 152 | 3 677 952 | 532 224 | **6,9×** |

  Sur les couples **inter-composantes**, les nœuds passent de `49 152 / 1 835 008 / 3 145 728` à **`0`** : l'économie est **totale** — la recherche aurait brûlé tout son budget pour échouer. Sur les couples **intra-composantes**, `β₀` ne mord pas (même composante) : aucun nœud n'est économisé.
- **Mesure (B) — aucune solution coupée (`G4`)** : égalité **exacte** de `trouve`, du `chemin` et de la `promesse`, sur **tous** les couples ordonnés de cinq porteurs, dont deux **asymétriques** :

  | porteur | couples | identiques | écarts |
  |---|---|---|---|
  | anneau unique (1×48) | 2 256 | 2 256 | **0** |
  | 2 composantes (2×24) | 2 256 | 2 256 | **0** |
  | aléatoire `n=60`, symétrique | 3 540 | 3 540 | **0** |
  | aléatoire `n=60`, **asymétrique** | 3 540 | 3 540 | **0** |
  | aléatoire `n=90`, **asymétrique** | 8 010 | 8 010 | **0** |

  **19 602 couples, 0 écart.** La preuve est doublée d'un argument : l'élagage ne décide que sur une **sur-approximation** de l'atteignabilité (composante faible ⊇ composante dirigée) ; il ne peut donc qu'écarter des couples **sans aucune voie**.
- **Mesure (C) — portée sur la relaxation (ch. 21)** : `recherche_par_relaxation(Ψ, p)` parcourt le **support d'un état**, non le porteur — il n'y a ni `depart`, ni `but`, ni traversée. `β₀` y est donc **sans prise**.

  | cas | candidats |
  |---|---|
  | support 256 figures × 5 seuils (espace ≤) | 1 280 |
  | seuil emporté au 1ᵉʳ candidat | 1 |
  | pire cas (cible = dernière figure) | 256 |

  La seule réduction atteignable sur ce support — déduplication par **classe de raffinement** — donne `2 → 1`, résultat **identique** à `canoniser` (`A-K7`, cf. `M-03`). Elle est donc **non additionnelle** : `A-K4⁺` ne revendique **rien** sur la relaxation.
- **Mesure (D) — coût (`εF`)** : n = 256 sinon indiqué (fonctions typées, après échauffement).

  | appel | temps | allocation |
  |---|---|---|
  | `composantes_connexes` n=64 | 7,8 µs | 21,1 Ko |
  | `composantes_connexes` n=256 | 37,1 µs | 82,4 Ko |
  | `composantes_connexes` n=1024 | 231,4 µs | 326,7 Ko |
  | `signature` (figure à 2 sites) | 0,4 µs | 1,6 Ko |
  | `verifie_invariance_signature` (64 figures, 2 pas) | 9,6 µs | **0 o** |
  | recherche intra, `invariant = false` | 22,5 µs | 75,7 Ko |
  | recherche intra, `invariant = true` | 58,8 µs | 158,5 Ko |

  La garde coûte **un seul parcours de `G`** par appel (`composantes_connexes` + index inverse). Conséquence déclarée : sur une requête **intra-composante résolue en 1–2 nœuds**, la garde **double** le coût (22,5 → 58,8 µs) ; elle s'amortit dès que la requête est difficile ou **sans voie**, où elle ramène le coût à zéro. `verifie_invariance_signature` n'alloue **rien** (parcours pur).
- **Gain réel** : **calculatoire**, et c'est le seul des quatre réajustements dans ce cas.
  1. *Élagage exact* : hors composante `β₀`, **aucun nœud** ; le budget de recherche n'est plus dépensé à prouver une absence.
  2. *Certificat d'identité* : deux figures de même signature sont le même cosmos à raffinement près — la mémoïsation devient **sûre** (recoupe `A-K7`).
  3. *Contrainte permanente* (lecture littérale d'A2) : la signature est ce que la théorie **déclare** ne pas pouvoir être violé ; `verifie_ak4plus` en fait un **refus**, non un commentaire.
- **Réserve d'honnêteté (portée exacte)** : le gain n'est **pas** général. Il est **nul** là où la recherche ne traverse pas `G` (relaxation, ch. 21) et **nul** sur les couples intra-composantes. Il est **entier** sur les couples inter-composantes. La garde ajoute un parcours `O(|G|)` ; ce surcoût est mesuré et déclaré ci-dessus.
- **G2** : dans le cosmos dégénéré de `T-K1`, les états sont **résolus** (support à une figure atomique) : passage de `apres` = passage de `avant`, et la figure atomique se raffine elle-même (`≺` réflexif) ⇒ l'invariance est **automatique** (test ajouté). `T-K1` est sauvegardé.
- **G3** : **247** tests passent (224 + 23) ; benchmark **inchangé** (exit 0 ; 11/11 cas limites ; exposants `n²`, `n log n`, `n`, `sⁿ` inchangés — la garde est **désactivée par défaut**, `invariant = false`, et n'entre donc dans aucun chemin mesuré). **G4** : équivalence mesurée sur **19 602 couples** (tableau B), 0 écart. **G5** : aucun chiffre consigné ne change — l'invariance ajoute une **condition** sur les pas, elle ne modifie ni `ν`, ni `µ`, ni `argmax`, ni registre `εX`.


### M-05 — `IndexPesee` : recherche par pesée de promesse **amortie**

- **Statut** : `vérifié` — **entrée d'ingénierie, hors théorie de base** : aucun axiome, aucun théorème, aucune primitive n'est en jeu ; la fonction directe est **inchangée** et l'API est **additive**.
- **Origine (mesurée, non théorique)** : la question « la théorie de base et la CQG peuvent-elles mettre un terme aux itérations qui entravent la frugalité ? » a été instruite par une sonde de faisabilité. Verdict : `A-K6` **n'arrête pas** l'exploration (au mieux `1,2×` par réordonnancement, et seulement au prix d'une promesse dégradée ; `1,02–1,04×` sans dégradation), et il ne fournit **aucun certificat de non-atteignabilité** (`120/120` cas dirigés s'arrêtent sur épuisement, jamais sur budget). Le coût `εF` **n'est pas** dans les axiomes mais dans les **allocations par arête** : `recherche_par_pesee_de_promesse` construisait **deux `Figure`** et un **`vcat` de chemin** par arête développée, et recalculait `µ` à chaque appel.
- **Réajustement appliqué — *lecture en index*** : `IndexPesee(G, h)` fixe une fois par `(G, h)` ce qui ne dépend ni de `depart` ni de `but` — identifiants, index inverse, **compatibilités `µ` de toutes les arêtes attestées** (`Vector{Vector{Tuple{Int,Float64}}}`) et **partition `β₀`** (`composantes_connexes`). `recherche_par_pesee_de_promesse(idx::IndexPesee, depart, but; …)` la consomme : `µ` n'est plus recalculée, le chemin est reconstruit par **pointeurs parents `Int`** (plus de `vcat`), la visite est un `BitVector`, la frontière des tuples de types primitifs. **Aucun chiffre ne change** : c'est le même algorithme, dans le même ordre.
- **Mesure (A) — équivalence *stricte* (`G4`)** : comparaison **chemin, promesse ET registre** (jusqu'aux messages « promesse nulle », « but atteint », « but non atteint »), sur **5 porteurs** dont un **asymétrique** (`reciproque = false`) et un à **4 composantes**, en forme directe **et** avec `invariant = true` ; puis, sur la grille `16×64`, avec **budgets tronqués** (`3`, `7`, `13` nœuds) et **heuristique non uniforme** (branche « but non atteint ») :

  | bloc | couples | comparaisons | écarts (chemin / promesse / registre) |
  |---|---|---|---|
  | (A) 5 porteurs × 600 couples × (direct, amorti, `invariant`) | 3 000 | 12 000 | **0 / 0 / 0** |
  | (A2) 400 couples × (3 budgets + heuristique) | 1 600 | 4 800 | **0 / 0 / 0** |

  **4 600 couples, 0 écart.** L'équivalence est exacte au bit près (mêmes flottants, même ordre de développement, mêmes registres).
- **Mesure (B) — coût (`εF`)** : grille `16×64` (`n = 1024`), mêmes 120 requêtes, fonctions typées et échauffées.

  | appel | temps | allocation |
  |---|---|---|
  | construction `IndexPesee(G, h)` (**une fois**) | 2,340 ms | 5,74 Mo |
  | directe — 1 requête | 543,4 µs | 1,54 Mo |
  | **amortie** — 1 requête | **21,9 µs** | **15,8 Ko** |
  | directe — 120 requêtes | 74,231 ms | 140,45 Mo |
  | **amortie** — 120 requêtes | **2,765 ms** | **1,68 Mo** |

  Gain : **26,9× en temps, 83,5× en allocation** sur 120 requêtes. Le coût de construction est **payé une fois** ; seuil de rentabilité mesuré (temps cumulé de `k` requêtes, min sur 5 répétitions) :

  | requêtes `k` | 1 | 2 | 4 | **8** | 16 | 32 | 64 | 128 | 256 |
  |---|---|---|---|---|---|---|---|---|---|
  | directe | 0,544 ms | 1,208 | 2,136 | 3,967 | 9,811 | 18,651 | 35,816 | 72,993 | 140,658 |
  | construction + amortie | 2,364 ms | 2,389 | 2,446 | **2,517** | 2,697 | 3,013 | 3,714 | 5,025 | 7,262 |
  | ratio | 0,23× | 0,51× | 0,87× | **1,58×** | 3,64× | 6,19× | 9,64× | 14,53× | 19,37× |

  **Rentable dès ≈ 6 requêtes** (`n = 1024`) ; le seuil est `O(|E|)` donc franchi d'autant plus tôt que le porteur est grand — et d'autant plus vite qu'on interroge.
- **Mesure (C) — l'élagage `A-K4⁺` devient gratuit** : 4 composantes `4×16`, 400 couples.

  | appel | temps | allocation |
  |---|---|---|
  | directe, `invariant = false` | 3,887 ms | 12,01 Mo |
  | directe, `invariant = true` | 5,636 ms | 10,45 Mo |
  | amortie, `invariant = false` | 233,9 µs | 604,5 Ko |
  | **amortie, `invariant = true`** | **131,8 µs** | **315,8 Ko** |

  La garde `β₀` était un **parcours `O(|G|)` par requête** (`M-04`, mesure D : elle *doublait* le coût des requêtes faciles). Précalculée dans l'index, elle **ne coûte plus rien** : `invariant = true` **divise encore par 1,8×** le temps de la forme amortie, puisqu'elle élide d'emblée les 3/4 des couples (inter-composantes).
- **Réserve d'honnêteté (portée exacte)** : le gain est **entièrement** dans la **réutilisation**. Sur **un appel isolé**, l'index est un **coût net** (2,34 ms contre 0,54 ms). Sur une **requête triviale** (`depart = but`), la forme amortie est **plus lente** (0,73 µs → 3,96 µs par appel, `n = 1024`) : elle alloue un `BitVector` et un `Vector{Int}` de taille `|G|` par requête, là où la forme directe n'alloue qu'un singleton. **Coût fixe par requête `O(|G|)`**, déclaré, et non `O(1)`. Enfin, l'index suppose `h.compatibilite` **pure** (précalculée) : c'est le cas de `compatibilite_raffinement` et de toute compatibilité de la définition 5.6, mais l'hypothèse est explicite.
- **G1** : **sans objet** — l'entrée est déclarée **hors théorie de base** : elle n'ajoute ni axiome, ni théorème, ni primitive, et ne modifie aucune loi du cosmos `K = (G, ⊙, ≺, µ)`. Elle est la lecture frugale d'une boucle **déjà consignée** (méthode 29.1).
- **G2** : **sans objet** pour la même raison ; on vérifie toutefois que le cas dégénéré est **inchangé** (`depart = but` : même chemin `[depart]`, même promesse `1`, même registre).
- **G3** : **350** tests passent (247 + 103) ; benchmark **inchangé** (exit 0 ; 11/11 cas limites ; exposants `n²`, `n log n`, `n`, `sⁿ` inchangés — le banc mesure la forme **directe**, que `M-05` ne touche pas).
- **G4** : équivalence **mesurée** — **4 600 couples, 0 écart** sur chemin / promesse / registre (blocs A et A2).
- **G5** : **aucun chiffre consigné ne change**. `recherche_par_pesee_de_promesse(G, depart, but, h; …)` est **inchangée** ligne pour ligne ; `IndexPesee` est un objet **neuf**, optionnel, dont les résultats sont *mesurés identiques*. Les chiffres de `M-04` (nœuds développés, coût de la garde) restent valides pour la forme directe.


### M-06 — Champ d'attraction de Maât : la recherche devient un **calcul de point fixe**

- **Statut** : `vérifié` — **entrée d'ingénierie, hors théorie de base** : la fonction directe et l'index (`M-05`) sont **inchangés** ; l'API est **additive** (`ChampMaat`, `champ_vers`, `promesse_optimale`, `descente_par_champ`, et son **dual** `ChampDepuis`, `champ_depuis`, `promesse_depuis`, `chemin_depuis`, `hors_bassin`).
- **Source CQG / théorie de base** : l'axiome **A4 (Maât)** — `m_gap > 0` garantit un attracteur **unique** et **strictement séparé**. De là une conséquence computationnelle directe, que la théorie autorise sans ajout : puisque l'optimum est un **point fixe**, il se **calcule** au lieu d'être **exploré**. Trois lectures s'y conjuguent :
  1. **A4** : l'attracteur unique rend le champ (meilleure-promesse-par-site) **bien défini** et **déterministe** ;
  2. **`T-K5`** (coût descriptif) : l'objectif d'un chemin est son **coût de description** ; à compatibilité constante, il ne dépend que du **nombre de pas** ;
  3. **`A-K4⁺`** (invariant de signature) : les sites hors du bassin reçoivent `valeur = 0` — l'élagage `β₀` **exact** est obtenu **de surcroît**, sans le parcours `O(|G|)` par requête de la garde de `M-04`.
- **Réajustement appliqué — *le champ remplace l'exploration*** : `champ_vers(idx, but)` exécute **une seule passe** arrière depuis `but` dans le semi-anneau `(max, ×)` — un Dijkstra de fiabilité maximale, `O(E log V)`. On en tire ensuite, **pour toutes les sources à la fois**, `valeur[x]` (meilleure promesse), `succ[x]`, et le chemin par **descente** `O(L)` par requête (`descente_par_champ`). `promesse_optimale` est une lecture `O(1)`. Le **dual** `champ_depuis(idx, source)` couvre le motif symétrique « **une source → toutes les cibles** » par une **passe avant** (`ChampDepuis`, `promesse_depuis`, `chemin_depuis`), tout aussi `O(E log V)` ; `hors_bassin` lève l'ambiguïté « **promesse nulle** / **hors du bassin** » dans les deux sens.
- **Mesure (A) — équivalence (`G4`)** : le champ doit **retrouver** l'optimum de l'exploration. Comparaison **chemin / promesse / « jamais plus long »** sur **6 porteurs** (fixture, composantes, grille `16×64`, stratifié, aléatoire, **aléatoire non réciproque**) dont **4 cibles** tirées au hasard par porteur :

  | bloc | couples | écarts (trouvé / promesse / pas en plus) |
  |---|---|---|
  | (A) 6 porteurs × 4 cibles × toutes sources | 10 984 | **0 / 0 / 0** |
  | (A2) balayage exhaustif des couples (chaîne 4 ; anneau 8×4) | 1 004 | **0 / 0 / 0** |

  **11 988 couples, 0 écart.** Ici le chemin du champ n'est **jamais plus long** — il est **de même longueur** partout (0 « chemin plus court »), car à `κ` constante l'exploration par meilleure promesse coïncide déjà avec le plus court chemin.
- **Mesure (B) — coût (`εF`)** : grille `16×64` (`n = 1024`), « **toutes les sources → une cible fixe** » (1023 requêtes), fonctions typées et échauffées.

  | appel | temps | allocation |
  |---|---|---|
  | recherche — 1023 requêtes (index `M-05` réutilisé) | 20,541 ms | 13,58 Mo |
  | **`champ_vers` — UNE passe (toutes sources)** | **152,6 µs** | **298,3 Ko** |
  | `descente` — 1023 chemins reconstruits et recomposés | 1,169 ms | 2,00 Mo |

  Gain : **134,6× en temps, 47× en allocation** pour la passe seule ; **15,5× en temps** passe **et** descente incluses. En **opérations** : **364 179 nœuds développés** (exploration) contre **3 936 relaxations = `E` exactement** (champ), soit **92,5×** ; la frontière de l'exploration balaye implicitement **`V² = 1 048 576`** contre `E = 3 936`, soit **266,4×**. Le **dual** « une source → n cibles » (`r1`) est mesuré sur la même grille : **1023 cibles** coûtent **25,724 ms / 15,32 Mo** par l'exploration (ou **196,714 ms / 297,35 Mo** par 1023 passes `champ_vers`), contre **40,9 µs / 29,0 Ko** pour **une** passe `champ_depuis` et **1,053 ms / 2,01 Mo** pour 1023 remontées `chemin_depuis` — soit **4809,6×** sur la passe.
- **Mesure (C) — pourquoi `κ` constante** : sur figures **atomiques**, deux sites **distincts** ne sont **jamais emboîtés**, donc `µ = 0,8` partout (« cohabitation neutre ») — mesuré `min = max = 0,8000`, **1 valeur distincte** sur composantes `8×32`, grille `16×64`, stratifié `12×64` et aléatoire `n=400`. La promesse d'un chemin est donc **`0,8^L`** : elle ne dépend que du **nombre de pas** — et le champ coïncide alors avec le **plus court chemin**.
- **Mesure (D) — contrôle à `κ` variable : le champ reste exact ; l'exploration, non** : avec une compatibilité **non canonique** (`κ ∈ [0,5 ; 1,0]`), le champ continue de maximiser le **produit** (et non la longueur) : `31` valeurs distinctes de `W*` — ce n'est plus `0,8^L`. **Fait nouveau, qui falsifie la réserve n°2 de la version précédente** : dans ce régime, **l'exploration par meilleure promesse est sous-optimale**. Elle **marque `visite` à l'insertion** dans le tas (`heuristique.jl`) : un nœud atteint d'abord par une voie médiocre y est **figé** et n'est plus jamais réévalué par une voie meilleure. Contre-exemple « diamant » (`µ(:s,:a) = 0,90`, `µ(:s,:b) = 0,99`, `µ(:a,:v) = 0,90`, `µ(:b,:v) = 0,01`, `µ(:v,:t) = 0,90`) : l'exploration rend `0,008910` par `[:s, :b, :v, :t]`, le champ rend `0,729000` par `[:s, :a, :v, :t]` — **81,8×**. Sur grille `12×48` à `κ` variable, **2821 des 3450 couples** ont une exploration **sous-optimale** (pire cas mesuré **6,0×**). L'algorithme d'exploration n'était donc **pas optimal** ; le champ, **si**.
- **Réserve d'honnêteté (portée exacte, corrigée)** : le champ est **par extrémité** — une passe `O(E log V)` **par cible**, amortie sur **toutes** les sources ; pour des couples `(départ, but)` **arbitraires**, `IndexPesee` (`M-05`) reste préférable (« une cible » amortit la passe, « toutes les cibles » coûterait `O(V · E log V)`). Le **dual** `champ_depuis` (résolution `r1`) amortit symétriquement le motif « **une source → toutes les cibles** ». **Correction de la réserve n°2 (règle `G5`)** : la version précédente affirmait que « le gain est **entièrement** dans le **coût**, **jamais** dans la **qualité** » — cette réserve était **fausse**. Elle concluait du cas `κ` **constante** (où l'exploration coïncide avec l'optimum) au cas général ; or, dès que `κ` **varie**, l'exploration **manque** l'optimum, parce qu'elle **fige** un nœud à l'insertion (mesure D : jusqu'à **81,8×**). Le gain de `M-06` est donc **aussi**, et en premier lieu, un **gain de qualité** en régime `κ` variable, en plus du gain de coût. La monotonie exige `κ ∈ (0, 1]` : une compatibilité `> 1` est **écartée** et **saturée à `1`** (`r3`), une arête de `µ = 0` **retire** la source du bassin (`r4` — `hors_bassin` distingue « **promesse nulle** » d'« **aucune chaîne dirigée** »). Enfin, la promesse rendue par `descente` est **recomposée gauche→droite** (`r5`) : elle coïncide avec celle de la recherche **au bit près** quand les chemins coïncident (vérifié `===`).
- **Résolution des réserves (`r1`–`r5`)** : les cinq réserves honnêtes de la version précédente sont **soldées**, chacune avec son test :
  - **`r1` (dualité)** : `champ_depuis(idx, source)` ajoute le motif « une source → toutes les cibles » (passe **avant**, `pred`, `promesse_depuis`, `chemin_depuis`) ; la **dualité** `champ_depuis(s)[t] = champ_vers(t)[s]` est vérifiée sur **1 047 552 couples, 0 écart**. Champ neuf `ChampDepuis` ; `KeyError` sur site inconnu.
  - **`r2` (qualité)** : la réserve fausse « gain de coût seulement » est **reformulée** — c'est un **gain de qualité** en régime `κ` variable (mesure D, `81,8×`) ; un test de **non-régression** reproduit le contre-exemple « diamant ».
  - **`r3` (`κ ≤ 1`)** : une compatibilité `> 1` est **écartée** (`clamp` identique dans les deux voies) ; test de **saturation** (`κ = 5` → `1,000`, champ **et** exploration).
  - **`r4` (`µ = 0`)** : `hors_bassin` tranche par **atteignabilité dirigée** (`_atteint`, BFS `O(E)`) entre « **promesse nulle** » (chaîne à `µ = 0`) et « **hors du bassin** » (aucune chaîne) ; test sur porteur à arête `µ = 0` et site isolé.
  - **`r5` (flottants)** : `descente_par_champ` / `chemin_depuis` **recomposent** la promesse gauche→droite (µ × h), au lieu de lire la valeur accumulée droite→gauche ; test **bit-exact** (`r.promesse === r0.promesse` quand les chemins coïncident). Contrepartie déclarée en `G5` : descente un peu plus lente.
- **G1** : **sans objet** — l'entrée est déclarée **hors théorie de base** : elle n'ajoute ni axiome, ni théorème, ni primitive, et ne modifie aucune loi du cosmos `K = (G, ⊙, ≺, µ)`. Elle est la **lecture computationnelle** d'`A4` (attracteur unique ⇒ point fixe calculable).
- **G2** : **sans objet** pour la même raison ; on vérifie toutefois que le cas dégénéré est **inchangé** (`départ = but` : chemin `[but]`, promesse `1`, registre conforme).
- **G3** : **562** tests passent (435 + 127) ; benchmark **vert** (exit 0 ; **15/15** cas limites — quatre cas `M-06` ajoutés ; les exposants des séries existantes sont **inchangés**). Le banc **couvre désormais `M-06`** et son **dual**. La section « coût de la passe » expose la **signature algorithmique** au lieu du seul temps mural : `champ_vers` comme `champ_depuis` relâchent **exactement `E = 2n` arêtes** (mesuré `2 000 / 8 000 / 32 000` pour `n = 1 000 / 4 000 / 16 000`) — le temps mural, lui, se dégrade au-delà de la mémoire cache et affiche un exposant trompeur (`≈ n²`), que la colonne « relax. » rectifie. Séries : `champ_vers` / `champ_depuis` (une passe), `descente_par_champ` / `chemin_depuis` (n chemins reconstruits, `≈ n²` — c'est la **taille de sortie** `n × L`). Gain εF « n sources → 1 cible » (**29,7×** à `n = 125`, **125,5×** à `n = 1000`) et gain **dual** « 1 source → n cibles » (**72,4×** à `n = 125`, **198,0×** à `n = 1000`) sur l'anneau : dans les deux motifs le gain **croît** avec `n`.
- **G4** : équivalence **mesurée** — **11 988 couples, 0 écart** sur chemin / promesse / « jamais plus long » (blocs A et A2) ; **dualité** `champ_depuis(s)[t] = champ_vers(t)[s]` vérifiée sur **1 047 552 couples, 0 écart** (`r1`) ; gain de coût mesuré **134,6×** en temps et **47×** en allocation (bloc B), et **4809,6×** pour le dual « une source → n cibles » en une passe (`r1`) ; **gain de qualité** mesuré jusqu'à **81,8×** en régime `κ` variable (bloc D).
- **G5** : `recherche_par_pesee_de_promesse` (directe **et** sur `IndexPesee`) est **inchangée** ; `ChampMaat` et `ChampDepuis` sont des objets **neufs**, optionnels. **Changements consignés** : (i) le gain passe seule du bloc (B) passe de `145,6×` à **`134,6×`** (allocation `48× → 47×`), la descente de `799,4 µs` à **`1,169 ms`**, et passe+descente de `20,3×` à **`15,5×`** — parce que `descente_par_champ` / `chemin_depuis` / `promesse_depuis` **recomposent** désormais la promesse pas à pas (µ × h) pour la rendre **bit-exacte** (`r5`) ; (ii) la **réserve n°2** est **corrigée** (« gain de coût, jamais de qualité » → **gain de coût *et* de qualité**). Les chiffres de `M-04` et `M-05` restent valides.


### M-07 — `Loi` : le bloc fondationnel de la CQG devient la **source** (refonte de l'axiomatique)

- **Statut** : `vérifié` — module **appliqué** et **mesuré** ; refonte **structurelle** de l'ordre axiomatique (la CQG devient la racine, `ΣK` en **dérive**) ; gain **déclaratif** ; aucun chiffre consigné ne change (`G5`).
- **Source CQG** : ch. 1 (A1 Noun § 1.2, A2 Kheper § 1.3, A3 Spirale d'or § 1.4, A4 Maât § 1.5 ; espace des phases § 1.6), ch. 2 (Loi Universelle, éq. 6), ch. 3 (Heka, éq. 7–10), ch. 4 (principe de manifestation, éq. 13–16).
- **Défaut** : l'implémentation ne consignait **ni la Loi Universelle ni les quatre axiomes de la CQG**. Seul `ΣK` — leur lecture computationnelle — existait (`src/socle/axiomes.jl`). La théorie de base se présentait donc **amputée de sa racine** : `A-K1` … `A-K7` y figuraient comme premiers, alors qu'ils **dérivent**.
- **Réajustement appliqué — *module `Kamitique.Loi`*** (premier module, `src/loi/`) : il consigne le bloc fondationnel et **inverse l'ordre axiomatique** — `Loi` est la **source**, `ΣK` en **dérive**.
  - `axiomes.jl` : les **quatre** axiomes de la CQG (`AxiomeCQG`, `AXIOMES_CQG`), chacun avec son énoncé (verbatim § 1.2–1.5), sa figure traditionnelle, sa formule et son apport ; la **dérivation déclarée** `DERIVATION_SIGMA_K` (`A-K1`…`A-K7` ⇐ `A1`–`A4`, § 2.1) et son contrôle `verifier_derivation()`.
  - `espace_phases.jl` : le triplet `(ℋ_Noun, M₄, {ℳ_k}²²)` (§ 1.6) — les **neuf constituants** universels de toute entité (éq. 17), l'**Ennéade** (`dim DOF_top = 9`) et l'**algèbre de Lie** des **vingt-deux Métous** `[ℳ_j, ℳ_k] = i f_jkl ℳ_l` (éq. 18), avec ses contrats d'antisymétrie et d'identité de Jacobi.
  - `spirale.jl` : A3 — le nombre d'or `φ`, le pas `b = ln φ / (π/2)` (un quart de tour multiplie le rayon par `φ`), la coupure conforme `R₀ ≠ 0`, l'échelle `rₙ = R₀ φⁿ` (§ 3.2) et le facteur conforme `e^{2bθ}` (éq. 16).
  - `lagrangien.jl` : la **Loi Universelle** (éq. 6) — trois secteurs conjoints : élasticité de l'éther `(R − 2Λ)/(2κ)`, antagonisme Horus–Seth `−¼ F²` (tenseur non-abélien `F_μν = ∂_μA_ν − ∂_νA_μ + g[A_μ, A_ν]`, éq. 4–5), commande morphique `ℒ_morph`.
  - `heka.jl` : l'**énergie du Noun** (éq. 7–10) — générateur `Ĥ_Noun Ψ = iℏ ∂Ψ/∂s`, énergie `E[Ψ] = ⟨Ψ|Ĥ_Noun|Ψ⟩`, décomposition `E = E_éther + E_jauge + E_morph`, conservation `dE/ds = 0 ⟹ ∇_μ J^μ = 0` (théorème de Noether).
  - `manifestation.jl` : le **principe de manifestation** (éq. 13) — la triade `K̂(s) = Â_At ∘ P̂_Pt ∘ Ĝ_Kh` (Atoum actualisation, Ptah commande, Khnoum modelage).
  - Câblage : `include("loi/Loi.jl")` en **tête** de `src/Kamitique.jl`, `using .Loi`, `Loi` en tête de `_SOUS_MODULES` ; stdlib `LinearAlgebra` ajoutée à `Project.toml`.
- **Gain réel** : **déclaratif et structurel**, non calculatoire.
  1. La théorie de base a désormais **sa racine consignée** : les axiomes de la CQG et leur lecture computationnelle (`ΣK`) forment un même édifice, la seconde **dérivant** des premiers — l'exigence `G1` devient **structurelle**.
  2. `verifier_derivation()` garantit qu'aucun `A-K` n'est sans source et que les **quatre** axiomes sont sollicités.
  3. La Loi Universelle, Heka et la manifestation — jusque-là **absents** — sont **consignés** avec leurs équations exactes.
  4. **Aucun gain de calcul** n'est revendiqué : le module n'entre dans aucun chemin du noyau `µ`.
- **Corrections de justesse déclarées (`G5`)** — révélées par le testset exhaustif (le test de fumée, à tenseur nul, les masquait) :
  1. **Identité de Jacobi des Métous** (`espace_phases.jl`) : la formule contractée portait `f_lnj` / `f_lnk` au lieu de `f_ljn` / `f_lkn` — elle **rejetait toute algèbre de Lie non triviale**. Corrigée en `Σ_l ( f_jkl·f_lmn + f_kml·f_ljn + f_mjl·f_lkn ) = 0`, vérifiée sur un `so(3)` plongé dans les 22 Métous.
  2. **Constructeur `Heka`** (`heka.jl`) : un constructeur externe doublait le constructeur par défaut ; pour des arguments exactement `Vector{ComplexF64}` / `Matrix{ComplexF64}`, le second (plus spécifique) l'emportait et **sautait la garde `n×n`**. Converti en constructeur **interne** validant.
- **Écart de la CQG consigné (`G5`)** : la formule (2) telle qu'imprimée — `φ/(φ−1) = φ` — est **numériquement fausse** (`φ/(φ−1) = φ² = 2,618…`). L'identité définissante authentique est `φ² = φ + 1` (⟺ `φ − 1 = 1/φ`) ; `verifie_nombre_or` teste **cette** identité, et `spirale.jl` la consigne comme telle en signalant la forme imprimée fautive. **Aucun autre chiffre consigné ne change.**
- **G1** : c'est la **mise en conformité** de la théorie de base à la CQG — la fidélité devient **structurelle** (la source est consignée, non seulement invoquée).
- **G2** : le module n'ajoute **aucune loi** au cosmos `K = (G, ⊙, ≺, µ)` ; les quatre axiomes et `ΣK` sont inchangés, seule leur **source** est consignée. `T-K1` est sauvegardé (aucun test de subsumption binaire modifié).
- **G3** : **779** tests passent (684 + **95** pour `Loi`) ; suite verte.
- **G4** : sans objet (aucune équivalence à mesurer) ; les grandeurs de la spirale sont **vérifiées exactement** (`φ² = φ + 1`, `r(θ+π/2) = φ·r(θ)`, `e^{2b(θ+π/2)} = φ²·e^{2bθ}`) et l'algèbre des Métous est **vérifiée** (antisymétrie + Jacobi non triviaux).
- **G5** : aucun chiffre **consigné** (`ν`, `µ`, registres `εX`) ne change. Sont **déclarés** : les deux corrections de justesse ci-dessus et l'écart de la formule (2) de la CQG.


### R-01 — Enrichissement de `δ/ι/κ` aux 22 opérateurs de structuration `{ℳ_k}`

- **Statut** : `rejeté`
- **Source CQG** : `{ℳ_k}_{k=1..22}`, « l'algèbre des vingt-deux opérateurs de structuration, établie à l'anatomie universelle, chapitre 5 ».
- **Raison du rejet** : la Kamitique **définit** son cosmos comme `K = (G, ⊙, ≺, µ)` avec la **triple opératoire `δ/ι/κ`** (figure 3.1 ; déf. 7.1–7.4). Les 22 opérateurs de la CQG sont l'algèbre de structuration *physique* ; les trois opérateurs kamitiques en sont la projection computationnelle (rendre lisible / composer / trancher). Substituer 22 opérateurs aux trois **contredirait** la définition du cosmos de calcul — ce serait une *autre* théorie, non un réajustement de celle-ci. Le `G1` (fidélité) est ici pris au sens strict : *« le même socle, les mêmes axiomes »*.

---

## 5. Synthèse et ordre de priorité

| Entrée | Écart | Nature du gain | Touche le noyau `µ` ? | Coût | Statut |
|---|---|---|---|---|---|
| `M-01` `A-K6` coupure | `E1` (infirmé) | stratification finie vérifiable (déclaratif) | non (voie calculatoire rejetée) | révision de `Site` | `vérifié` (axiome) / `rejeté` (calcul) |
| `M-02` `A-K5⁺` écart | `E2` (réparé) | global certifié + borne de convergence (déclaratif et de refus) | non | rédaction de l'inégalité ; coût nul au-dessus de `A-K5` | `vérifié` |
| `M-03` `A-K7` fermeture | `E3` (réparé) | canonicité + demi-treillis (structurel) | non | clôture fournie, non imposée ; aucun chiffre consigné ne change | `vérifié` |
| `M-04` `A-K4⁺` invariant | `E4` (réparé) | élagage exact de recherche (calculatoire, **localisé**) | non | garde `O(\|G\|)` fournie et **désactivée par défaut** ; aucun chiffre consigné ne change | `vérifié` |
| `M-05` `IndexPesee` (**hors théorie**) | aucun (`E1`–`E4` soldés) | amortissement de la boucle de recherche (calculatoire, `εF`) | non | index **fourni**, optionnel ; coût de construction payé **une fois**, rentable dès ≈ 6 requêtes ; fonction directe **inchangée** | `vérifié` |
| `M-06` champ d'attraction (**hors théorie**) | aucun (`E1`–`E4` soldés) | point fixe : **une passe** `(max, ×)` remplace l'exploration — gain de **coût** *et* de **qualité** (calculatoire, `εF`) | non | `champ_vers` + son dual `champ_depuis` **fournis**, optionnels ; une passe **par cible** (resp. **par source**), amortie sur toutes les autres ; coût `134,6×` / `47×`, qualité jusqu'à `81,8×` ; fonction directe **inchangée** | `vérifié` |
| `M-07` `Loi` refonte axiomatique (**appliqué**) | la **racine** consignée (`ΣK` ⇐ `A1`–`A4`) | fidélité **structurelle** + Loi Universelle / Heka / manifestation consignés (déclaratif) | non | module neuf, **premier** ; aucun chiffre consigné ne change ; 2 corrections de justesse + 1 écart CQG déclarés | `vérifié` |

**Priorité** : `M-07` vient **en amont** de tout le reste : il ne répare aucun des écarts
`E1`–`E4`, mais **consigne la racine** dont ils procèdent — les axiomes `A1`–`A4` de la CQG
et leur lecture computationnelle `ΣK`, désormais **liés par une dérivation vérifiable**. Il
fonde l'édifice au lieu de l'optimiser ; c'est pourquoi il ouvre le module `Loi` en tête de
`src/`. Ceci posé, `M-01` a été traité en premier — il a montré que le seul levier touchant le noyau
quadratique `µ` (`≺` en `O(R)`) **ne paye pas** : le noyau est déjà à zéro allocation, et
la stratification ajoute une allocation. Toutes les optimisations restantes n'agissent que
sur des constantes **hors** noyau. `M-02` ensuite, car il convertit `T-K3` d'un énoncé
qualitatif en un énoncé quantitatif **certifié** (attracteur unique, `m_gap` explicite,
borne de pas) — à coût nul au-dessus de `A-K5`. `M-03` enfin, qui achève la cohérence
`A-K1` (support clos) en fournissant la **forme normale** et le **demi-treillis**, à
nouveau sans changer aucun chiffre consigné. `M-04` enfin : c'est le seul réajustement
qui achète du **temps de calcul**, et il ne l'achète que là où la recherche **traverse le
porteur** — le gain y est **entier** (6,7× à 14,6×), ailleurs il est **nul**, et le
suroût de la garde est mesuré, borné et déclaré. `M-05` vient **après** les quatre, et
hors de la théorie : les quatre écarts étant soldés, aucune lecture axiomatique nouvelle
n'était disponible ; la mesure a montré que l'entrave à la frugalité n'était pas dans les
axiomes mais dans les **allocations par arête** de la boucle. `M-05` ne change donc rien à
la théorie — il **amortit** la boucle existante (26,9× en temps, 83,5× en allocation) et
rend au passage l'élagage `A-K4⁺` **gratuit** (la garde `O(|G|)` par requête disparaît,
précalculée dans l'index). `M-06` va plus loin, toujours **hors théorie** : `M-05`
**amortissait** la boucle, `M-06` la **supprime** — là où `A4` donne un attracteur unique,
l'optimum est un **point fixe**, et une **seule passe** `(max, ×)` en arrière (`O(E log V)`)
en donne la valeur pour **toutes les sources** (`134,6×` en temps, `47×` en allocation sur
1 023 requêtes ; `92,5×` en nœuds). Le gain est **à la fois** dans le coût **et** dans la
qualité : en régime `κ` variable, l'exploration **manquait** l'optimum (jusqu'à `81,8×`),
le champ ne le manque **jamais**.

**Réserve d'honnêteté** : `M-07` n'est pas une optimisation mais une **mise en conformité** —
il ne revendique **aucun gain calculatoire**, borne sa portée à la consignation de la racine
(`A1`–`A4`, `ΣK` ⇐ `A1`–`A4`, Loi Universelle, Heka, manifestation), et **déclare** ses deux
corrections de justesse ainsi que l'écart de la formule (2) de la CQG (`φ/(φ−1) = φ`, en
réalité `φ² = φ + 1`). `M-01` n'a été retenu que pour sa partie **axiomatique**, et son
volet calculatoire est consigné comme **rejeté sur mesures**. `M-02` et `M-03` sont
`vérifié`, mais leurs gains sont respectivement **déclaratif / de refus** et **structurel** :
aucun des deux n'accélère le noyau. `M-04` est `vérifié` et apporte le seul gain
**calculatoire** des quatre — mais il est **localisé** (traversées du porteur : ch. 29 ;
la relaxation du ch. 21 n'en bénéficie pas) et **désactivé par défaut**, pour ne pas faire
payer un parcours `O(|G|)` aux trajectoires où il ne sert à rien. Une modification
de la théorie de base n'est pas une optimisation : elle engage les théorèmes, et le
principe 3.1 interdit de la faire « depuis l'implémentation ». `M-05` respecte cette
frontière : il est **déclaré hors théorie** et consigné comme tel — c'est une optimisation,
mesurée, *additive*, qui laisse la théorie de base **exactement** dans son état. `M-06`
respecte la même frontière, avec une portée **bornée** déclarée : une passe **par cible**,
qui n'accélère que les requêtes **partageant** cette cible — et qui, en régime `κ` variable,
**corrige** en outre la qualité (l'exploration y était sous-optimale).

---

## 6. Protocole de mise à jour de ce journal

1. Toute modification — même mineure — entre au journal avec un identifiant `M-nn`
   (modification) ou `R-nn` (proposition rejetée), et un **statut**.
2. Une entrée ne passe à `appliqué` qu'après `G3` (tests + benchmark) ; à `vérifié`
   qu'après `G4` (équivalence ou gain mesuré et chiffré).
3. Un changement de **chiffre consigné** (degré, harmonie, registre `εX`) est consigné
   explicitement dans la ligne « Risque / coût » (`G5`).
4. Le tableau de synthèse (§ 5) est tenu à jour à chaque nouvelle entrée.

---

*Ouvert le 2026-09-26. `M-01`, `M-02`, `M-03`, `M-04`, `M-05`, `M-06` et `M-07` sont réglés
(`vérifié` ; volet calculatoire `rejeté` pour `M-01`, gain calculatoire `localisé` pour
`M-04`, `M-05` et `M-06` consignés **hors théorie de base**, `M-07` **refonte structurelle**
de l'axiomatique). Les quatre écarts constatés (`E1` infirmé, `E2`, `E3`, `E4` réparés) sont
soldés ; `M-07` consigne par-dessus la **racine** dont ils procèdent (`A1`–`A4`, `ΣK` ⇐
`A1`–`A4`) ; la théorie de base est à son état courant — **779 tests** et benchmark verts.
Deux corrections de justesse (identité de Jacobi des Métous, constructeur `Heka`) et un écart
de la CQG (formule (2) : `φ/(φ−1) = φ`, en réalité `φ² = φ + 1`) sont **déclarés** au titre de
`G5`. La réserve d'honnêteté n°2 de `M-06` — *le gain
est entièrement dans le coût, jamais dans la qualité* — a été **reconnue fausse** et
**corrigée** sous la règle `G5` : en régime `κ` variable, `M-06` **corrige aussi la
qualité** (jusqu'à `81,8×`), et les cinq réserves `r1`–`r5` sont **soldées**.*
