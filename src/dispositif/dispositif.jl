# ============================================================================
#  Module Dispositif — le dispositif unifié de résolution et les ressources
# ----------------------------------------------------------------------------
#  La procédure générale qui décline, pour chaque catégorie de problèmes
#  computationnels, des méthodes gouvernées : un socle, une chaîne, quatre
#  mouvements — et les critères d'admissibilité des méthodes et de conformité
#  des ressources.
# ============================================================================
module Dispositif

using ..Socle
using ..Pesee
using ..Chaine
using ..Methodologie

export
    # Les quatre mouvements
    Mouvement, MOUVEMENTS, mouvement, TripleSubstitution, RapportMouvement,
    # Le dispositif
    Dispositif, Resolution, resoudre, reussie,
    # Critères d'admissibilité des méthodes
    CritereAdmissibilite, CRITERES_ADMISSIBILITE, AdmissibiliteMethode,
    admissible, criteres_manquants,
    # Critères de conformité des ressources
    CritereConformite, CRITERES_CONFORMITE, ConformiteSocle, est_conforme, mobilisable,
    # La carte des catégories
    Categorie, CARTE_CATEGORIES, categorie

include("mouvements.jl")
include("criteres.jl")
include("conformite.jl")
include("carte.jl")
include("resolution.jl")

end # module Dispositif
