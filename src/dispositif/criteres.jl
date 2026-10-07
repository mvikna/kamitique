# ============================================================================
#  Les critères d'admissibilité des méthodes  (définition 13.2)
# ----------------------------------------------------------------------------
#  Une méthode produite par le dispositif unifié est kamitique admissible lorsque
#  cinq critères sont satisfaits : objets dans le vocabulaire du socle, conduite
#  articulée sur la chaîne sans principe étranger, critères de validation propres
#  et constatables, continuité établie avec les méthodes classiques, transmission
#  praticable.
# ============================================================================

"""
    CritereAdmissibilite

Un des cinq critères d'admissibilité d'une méthode kamitique (définition 13.2).
"""
struct CritereAdmissibilite
    numero     :: Int
    nom        :: Symbol
    definition :: String
end

"""Les cinq critères d'admissibilité des méthodes (définition 13.2)."""
const CRITERES_ADMISSIBILITE = CritereAdmissibilite[
    CritereAdmissibilite(1, :vocabulaire_socle,
        "ses objets sont énoncés dans le vocabulaire du socle — un porteur, des états, des trajectoires, des pesées"),
    CritereAdmissibilite(2, :conduite_chaine,
        "sa conduite s'articule sur la chaîne épistémologique, sans introduire de principe étranger aux axiomes ΣK"),
    CritereAdmissibilite(3, :validation_propre,
        "ses critères de validation sont propres — admissibilité des trajectoires, conservation de l'harmonie, qualité des registres — et se constatent sans recours à l'intime conviction"),
    CritereAdmissibilite(4, :continuite_classique,
        "sa continuité avec les méthodes classiques est établie — les énoncés dégénérés recouvrent les énoncés classiques"),
    CritereAdmissibilite(5, :transmission_praticable,
        "sa transmission est praticable, l'élève pouvant parcourir la même trajectoire que la méthode"),
]

"""
    AdmissibiliteMethode

L'évaluation des cinq critères d'admissibilité pour une méthode donnée.
"""
struct AdmissibiliteMethode
    criteres :: Vector{Tuple{Symbol,Bool}}
end

"""Construit l'admissibilité à partir des cinq verdicts, dans l'ordre des critères."""
function AdmissibiliteMethode(verdicts::AbstractVector{<:Bool})
    length(verdicts) == 5 ||
        throw(ArgumentError("les cinq critères d'admissibilité doivent être évalués"))
    return AdmissibiliteMethode(
        [(CRITERES_ADMISSIBILITE[i].nom, verdicts[i]) for i in 1:5])
end

"""Une méthode est admissible si elle satisfait la conjonction des cinq critères."""
admissible(a::AdmissibiliteMethode) = all(last, a.criteres)

"""Les critères non satisfaits (pour la justification et le registre)."""
criteres_manquants(a::AdmissibiliteMethode) = Symbol[n for (n, ok) in a.criteres if !ok]

function Base.show(io::IO, a::AdmissibiliteMethode)
    print(io, "AdmissibiliteMethode(", admissible(a) ? "admissible" :
              "non admissible : " * join(string.(criteres_manquants(a)), ", "), ")")
end
