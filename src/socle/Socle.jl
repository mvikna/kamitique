# ============================================================================
#  Module Socle — le socle formel de la Kamitique
# ----------------------------------------------------------------------------
#  Le porteur géométrique, l'état cosmologique, la valuation et l'harmonie,
#  l'axiomatique ΣK, les opérateurs δ/ι/κ, la trajectoire encadrée et les
#  théorèmes fondamentaux. C'est la formalisation de la Cosmologie Quantique
#  Géométrique dont la Kamitique dérive.
# ============================================================================
module Socle

export
    # Ordre de pesée
    OrdrePesee, M, DEUX_VALEURS, bornes, est_dense, appartient, valider_degre, couper,
    # Porteur géométrique
    Site, Figure, Porteur, ⊙, ≺, composer, raffine, paire_canonique, figure_vide,
    composer_cumule, ajouter_site!, site, voisins, identifiants, figure_totale,
    verifier_appartenance,
    # Fermeture canonique du support (axiome A-K7)
    cloture, est_close, cloture_support, reunion, canoniser,
    # Stratification du porteur (axiome A-K6)
    echelles, profondeur,
    # Invariance de signature (axiome A-K4⁺)
    Signature, signature, composantes_connexes, meme_composante,
    # États
    Etat, etat, support, poids, normaliser, est_resolu, figure_resolue,
    redistribuer, redistribuer_delta, support_effectif,
    EspaceKamitique, Cosmos, porteur, harmonie,
    # Valuation et harmonie
    Proposition, proposition_binaire, valuation, valuations_nommees,
    Harmonie, HarmonieRaffinement, compatibilite_raffinement, degre_maat, respecte_raffinement,
    # Opérateurs
    Question, Spectre, δ, ι, κ, structuration, plan_annulaire,
    ScorePesee, scores_pesee, resolve, pesee_resoudre,
    # Dynamique
    Pas, Trajectoire, ajouter_pas!, etat_initial, etat_final,
    est_encadree, conserve_maat, est_admissible, harmonie_le_long,
    # Progression de Maât (axiome A-K5⁺)
    ecart_maat, verifie_progression_maat, estime_progression, borne_pas_progression,
    # Invariance de signature (axiome A-K4⁺)
    verifie_invariance_signature,
    # Axiomatique
    Axiome, AXIOMES, axiome, enonce, RapportAxiomes,
    verifie_ak1, verifie_ak2, verifie_ak3, verifie_ak4, verifie_ak4plus, verifie_ak5,
    verifie_ak6, verifie_ak7,
    verifier_axiomes,
    # Théorèmes
    Degenerescence, degenerer, configuration_reproduite, verifie_subsumption_binaire,
    verifie_gouverne_non_phase, verifie_convergence_maat, attracteur_maat,
    verifie_irreversibilite_pesee, cout_descriptif, completude_couverture, subsumption

include("ordre.jl")
include("site.jl")
include("etat.jl")
include("valuation.jl")
include("operateurs.jl")
include("dynamique.jl")
include("axiomes.jl")
include("theoremes.jl")

end # module Socle
