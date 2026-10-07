# ============================================================================
#  Module Loi — la Loi fondamentale de la Cosmologie Quantique Géométrique
# ----------------------------------------------------------------------------
#  `Loi` formalise le **bloc fondationnel** de la CQG (chapitres 1 à 4), dont la
#  Kamitique est la lecture computationnelle (principe 3.1 : unité, non analogie) :
#
#    • l'axiomatique fondamentale — les **quatre** engagements de la CQG
#      (A1 Noun, A2 Kheper, A3 Spirale d'or, A4 Maât). Ils sont la **racine** :
#      le système `ΣK` du Socle (`A-K1` … `A-K7`) en **dérive explicitement** ;
#    • l'**espace des phases global** `(ℋ_Noun, M₄, {ℳ_k}²²)` (chap. 1 §6, chap. 5) :
#      les neuf constituants de toute entité, les neuf degrés de liberté
#      topologiques (l'Ennéade) et l'algèbre non-commutative des vingt-deux Métous ;
#    • la **Loi Universelle** (chap. 2) : le lagrangien unifié à trois secteurs —
#      élasticité de l'éther, antagonisme Horus-Seth, commande morphique ;
#    • la doctrine de l'**énergie du Noun** (chap. 3) : le générateur `Heka`, sa
#      décomposition `E = E_éther + E_jauge + E_morph` et sa conservation ;
#    • le **principe de manifestation** (chap. 4) : la triade conjointe
#      `Atoum` (actualisation) ∘ `Ptah` (information) ∘ `Khnoum` (modelage).
#
#  Source : `docs/Cosmologie_Quantique_Geometrique.pdf` (chap. 1–4).
#  Règle `G1` : chaque énoncé consigné est la lecture d'un passage de la CQG.
# ============================================================================
module Loi

using LinearAlgebra

export
    # --- Axiomatique fondamentale de la CQG (A1 … A4) -----------------------
    AxiomeCQG, AXIOMES_CQG, axiome_cqg, enonce_cqg, apport_cqg, figure_cqg,
    # --- Dérivation ΣK ⇐ quatre axiomes -----------------------------------
    DerivationAK, DERIVATION_SIGMA_K, MOTIFS_DERIVATION, derivation_ak,
    source_cqg, axiomes_derives, verifier_derivation,
    # --- Espace des phases (ℋ_Noun, M₄, {ℳ_k}²²) --------------------------
    ORDRE_CONSTITUANTS, CONSTITUANTS, constituants, Entite, constituant,
    ordre_constituant, FAMILLES_INVARIANTS, DOF_TOPOLOGIQUES, enneade_valide,
    NB_METOUS, FAMILLES_METOUS, metous, famille_metou, AlgebreMetous,
    verifie_antisymetrie_metous, verifie_jacobi_metous,
    EspacePhases, espace_phases,
    # --- Spirale d'or (A3) -------------------------------------------------
    NOMBRE_OR, B_SPIRALE, COUPURE_R0, coupure_r0, spirale_rayon, facteur_quart_tour,
    echelle_conforme, facteur_conforme, verifie_autosimilarite, verifie_nombre_or,
    # --- Loi Universelle (chap. 2) -----------------------------------------
    SecteurEther, SecteurJauge, SecteurMorphique, LagrangienUnifie, LOI_UNIVERSELLE,
    tenseur_jauge, densite_ether, densite_jauge, densite_morphique, densite_lagrangien,
    secteurs,
    # --- Énergie du Noun — Heka (chap. 3) ----------------------------------
    Heka, SECTEURS_ENERGIE, HEKA, energie_noun, decomposition_energie,
    verifie_conservation_energie,
    # --- Principe de manifestation (chap. 4) -------------------------------
    SecteurManifestation, MANIFESTATION, manifestation_triadique, secteur_manifestation,
    composer_manifestation, verifie_manifestation

include("axiomes.jl")
include("espace_phases.jl")
include("spirale.jl")
include("lagrangien.jl")
include("heka.jl")
include("manifestation.jl")

end # module Loi
