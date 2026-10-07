# ============================================================================
#  Module Chaine — la chaîne épistémologique gouvernée
# ----------------------------------------------------------------------------
#  Les sept dimensions (quatre étapes de production + trois gouvernes), les
#  opérateurs δ/ι/κ de la chaîne, la chaîne gouvernée et son registre de
#  justification. Les opérateurs δ, ι, κ sont LES MÊMES que ceux du socle :
#  ils sont importés puis étendus (identité structurelle, chapitre 12).
# ============================================================================
module Chaine

using ..Socle
import ..Socle: δ, ι, κ

export
    # Les sept dimensions
    Metadonnee, Donnee, est_attestee, consentement_recueilli,
    Information, reduction_incertitude,
    Connaissance, infere,
    Renseignement, evaluer,
    Justification, justification_valide,
    Ressources, Frugalite,
    EpreuveGouvernanceEthique,
    # Les opérateurs de la chaîne (extensions de δ/ι/κ)
    CorpusDonnees, donnees_attestees, rho,
    # La chaîne gouvernée
    Dimension, DIMENSIONS, etapes, gouvernes,
    JournalChaine, consigner!, journal_du_resultat,
    ChaineGouvernee, ResultatChaine, derouler,
    # Axiomes et théorèmes de la chaîne
    verifie_insécabilite, verifie_non_reduction, verifie_preeminence_ethique,
    verifie_frugalite_conditionnee, verifie_explicabilite_due,
    verifie_irreversibilite_abstraction, verifie_gouvernabilite

include("dimensions.jl")
include("operateurs.jl")
include("gouvernee.jl")

end # module Chaine
