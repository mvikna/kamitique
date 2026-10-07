# ============================================================================
#  Les critères de conformité au socle  (définition 13.3)
# ----------------------------------------------------------------------------
#  Une structure — pratique, institution, système de signes ou de règles — est
#  conforme au socle lorsque : ses unités sont des figures situées ; ses décisions
#  se pèsent ; sa conduite est encadrée ; sa décision engageante demeure humaine
#  et rendue. Une structure qui manque un critère n'est pas rejetée : elle est
#  mobilisable partiellement, aux seuls constituants où elle est conforme.
# ============================================================================

"""
    CritereConformite

Un des quatre critères de conformité au socle (définition 13.3).
"""
struct CritereConformite
    numero     :: Int
    nom        :: Symbol
    definition :: String
end

"""Les quatre critères de conformité au socle (définition 13.3)."""
const CRITERES_CONFORMITE = CritereConformite[
    CritereConformite(1, :figures_situees,
        "ses unités sont des figures situées — chacune porte un lieu et des relations, et ne signifie pas par une valeur nue"),
    CritereConformite(2, :decisions_pesees,
        "ses décisions se pèsent — degrés dans un ordre, comparaisons positionnelles, résolutions consignées, plutôt que des drapeaux binaires"),
    CritereConformite(3, :conduite_encadree,
        "sa conduite est encadrée — des règles explicites disent quand agir, comment agir et ce qui interrompt l'action, et leur satisfaction se constate"),
    CritereConformite(4, :decision_humaine_rendue,
        "sa décision engageante demeure humaine et rendue — l'acte qui engage est porté par un responsable devant ses concernés, et le savoir retourne à la communauté qui le porte"),
]

"""
    ConformiteSocle

L'évaluation des quatre critères de conformité pour une structure donnée.
"""
struct ConformiteSocle
    criteres :: Vector{Tuple{Symbol,Bool}}
end

function ConformiteSocle(verdicts::AbstractVector{<:Bool})
    length(verdicts) == 4 ||
        throw(ArgumentError("les quatre critères de conformité doivent être évalués"))
    return ConformiteSocle(
        [(CRITERES_CONFORMITE[i].nom, verdicts[i]) for i in 1:4])
end

"""Une structure est conforme si elle satisfait la conjonction des quatre critères."""
est_conforme(c::ConformiteSocle) = all(last, c.criteres)

"""
    mobilisable(c::ConformiteSocle) -> Vector{Symbol}

**Mobilisabilité partielle** (définition 13.3) : une structure qui manque un critère
n'est pas rejetée — elle est mobilisable aux seuls constituants conformes. Retourne
les constituants (critères) où la structure est conforme.
"""
mobilisable(c::ConformiteSocle) = Symbol[n for (n, ok) in c.criteres if ok]

function Base.show(io::IO, c::ConformiteSocle)
    print(io, "ConformiteSocle(", est_conforme(c) ? "conforme" :
              "partielle : " * join(string.(mobilisable(c)), ", "), ")")
end
