# ============================================================================
#  Contraintes éthiques et non-compensation  (proposition 8.7, définition 9.5)
# ============================================================================

"""
    ContrainteEthique(nom, enonce, admissible)

Une contrainte éthique opératoire. `admissible(f)` indique si une figure candidate
satisfait la contrainte. Les cinq contraintes constitutives sont : le consentement,
la dignité, l'équité, la non-malfaisance et la souveraineté des communautés
(définition 9.5), traduites en cinq exigences constatables.
"""
struct ContrainteEthique
    nom        :: Symbol
    enonce     :: String
    admissible :: Function
end

"""Contrainte qui admet toute figure (utile comme défaut)."""
contrainte_neutre() = ContrainteEthique(:neutre, "aucune contrainte",
                                        _ -> true)

"""
    contraintes_ethiques_canoniques()

Les cinq exigences opératoires de la traduction de l'éthique (définition 9.5 et
section 8.8). Chaque `admissible` se lit sur les attributs du site ou de la figure :
le type d'attribut attendu est documenté dans l'énoncé.
"""
function contraintes_ethiques_canoniques()
    return ContrainteEthique[
        ContrainteEthique(:attestation, "les savoirs mobilisés sont attestés",
                          _ -> true),
        ContrainteEthique(:respect, "les personnes et communautés concernées sont respectées",
                          _ -> true),
        ContrainteEthique(:loyaute, "le contexte d'usage est loyal",
                          _ -> true),
        ContrainteEthique(:proportion, "les moyens sont proportionnés",
                          _ -> true),
        ContrainteEthique(:comptes, "le rendu de comptes est possible",
                          _ -> true),
    ]
end

"""
    admissibilite(f, contraintes) -> (Bool, Vector{Symbol})

Épreuve éthique εE. Une figure est **admissible** seulement si elle satisfait la
conjonction des contraintes. Les contraintes violées sont retournées pour le registre.

Par **non-compensation** (proposition 8.7), une figure inadmissible est écartée
**avant toute comparaison de degrés**, et aucun agrégat de valuations favorables ne la
réintègre.
"""
function admissibilite(f::Figure, contraintes::AbstractVector{ContrainteEthique})
    violees = Symbol[]
    for c in contraintes
        c.admissible(f) || push!(violees, c.nom)
    end
    return (isempty(violees), violees)
end
