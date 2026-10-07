# ============================================================================
#  Aide multicritère à la décision kamitique  (chapitre 26)
# ----------------------------------------------------------------------------
#  « pesée des regards, non-compensation native ». L'harmonie d'une alternative est
#  plafonnée par son plus mauvais critère non négociable : µ(a) = min(min des
#  non-négociables, agrégat des négociables). Aucun agrégat ne rachète un plancher.
# ============================================================================

"""
    ResultatClassement

Le résultat d'un classement par pesée harmonique : l'ordre des alternatives, leurs
degrés d'harmonie et le registre.
"""
struct ResultatClassement
    ordre    :: Vector{Int}
    degres   :: Vector{Float64}
    registre :: Vector{String}
end

Base.length(r::ResultatClassement) = length(r.ordre)

"""
    classement_par_pesee_harmonique(criteres; non_negociables, poids) -> ResultatClassement

**Classement par pesée harmonique** (méthode 26.1). `criteres` est une matrice
`alternatives × critères` de degrés dans `M`. Pour chaque alternative, l'harmonie est

    µ(a) = min( min des critères non négociables , moyenne pondérée des négociables ).

La **non-compensation est native** : le plancher des critères non négociables **plafonne**
l'agrégat des négociables — une somme pondérée ne peut pas racheter un critère rédhibitoire.
"""
function classement_par_pesee_harmonique(criteres::AbstractMatrix{<:Real};
                                         non_negociables::AbstractVector{Bool} = Bool[],
                                         poids::AbstractVector{<:Real} = Float64[])
    m, n = size(criteres)
    m == 0 && throw(ArgumentError("aucune alternative"))
    n == 0 && throw(ArgumentError("aucun critère"))
    nn = isempty(non_negociables) ? falses(n) : collect(non_negociables)
    length(nn) == n ||
        throw(ArgumentError("un marqueur de non-négociabilité par critère"))
    p = isempty(poids) ? ones(n) : float.(collect(poids))
    length(p) == n || throw(ArgumentError("un poids par critère"))
    degres = zeros(m)
    for a in 1:m
        plancher = Inf
        for j in 1:n
            nn[j] && (plancher = min(plancher, clamp(float(criteres[a, j]), 0.0, 1.0)))
        end
        num = 0.0
        den = 0.0
        for j in 1:n
            nn[j] && continue
            w = max(p[j], 0.0)
            num += w * clamp(float(criteres[a, j]), 0.0, 1.0)
            den += w
        end
        agrege = den > 0 ? num / den : 1.0
        degres[a] = min(plancher, agrege)
    end
    ordre = sortperm(degres; rev = true)
    registre = String["classement par pesée harmonique de $m alternative(s) sur $n critère(s)",
                      "non-compensation native : µ = min(plancher non négociable, agrégat des négociables)",
                      "degrés : " * join(round.(degres; digits = 3), ", ")]
    return ResultatClassement(ordre, degres, registre)
end

"""
    negociation_par_reponderation(criteres, regards; non_negociables) -> ResultatClassement

**Négociation par repondération des regards** (méthode 26.2). Les « regards » — les
poids accordés aux critères négociables — sont repondérés, et le classement est recalculé.
Changer un regard ne touche jamais les critères non négociables : leur plancher demeure.
"""
function negociation_par_reponderation(criteres::AbstractMatrix{<:Real},
                                       regards::AbstractVector{<:Real};
                                       non_negociables::AbstractVector{Bool} = Bool[])
    r = classement_par_pesee_harmonique(criteres; non_negociables = non_negociables,
                                        poids = regards)
    push!(r.registre, "négociation : repondération des regards " *
                      join(round.(float.(regards); digits = 3), ", "))
    return r
end
