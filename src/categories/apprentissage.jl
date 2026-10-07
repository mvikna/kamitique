# ============================================================================
#  Apprentissage automatique kamitique  (chapitre 30)
# ----------------------------------------------------------------------------
#  « repondération sous encadrement » : l'apprentissage ne pose pas des poids
#  arbitraires, il repondère la présence des exemples sous l'encadrement des trois
#  gouvernes — l'harmonie ne doit pas décroître.
# ============================================================================

"""
    RapportReponderation

Le résultat d'une repondération d'apprentissage : l'état initial et l'état repondéré,
leurs harmonies respectives, et le verdict d'encadrement (l'harmonie n'a pas
décru).
"""
struct RapportReponderation
    initiale             :: Etat
    finale               :: Etat
    harmonie_initiale    :: Float64
    harmonie_finale      :: Float64
    encadrement_respecte :: Bool
end

function Base.show(io::IO, r::RapportReponderation)
    print(io, "RapportReponderation(µ ", round(r.harmonie_initiale; digits = 3),
          " → ", round(r.harmonie_finale; digits = 3),
          r.encadrement_respecte ? ", encadré" : ", non encadré", ")")
end

"""
    reponderation_sous_encadrement(Ψ, performance, h; tolerance = 1e-9)
        -> RapportReponderation

**Repondération sous encadrement** (chapitre 30). Repondère la présence des exemples
proportionnellement à une performance `1 + performance[k]`, puis **contrôle
l'encadrement** : la repondération est admise seulement si l'harmonie `µ` de l'état
ne décroît pas (conservation de Maât). Le rapport dit si l'encadrement est respecté —
la performance seule ne suffit pas à trancher.
"""
function reponderation_sous_encadrement(Ψ::Etat, performance::AbstractVector{<:Real},
                                        h::Harmonie; tolerance::Real = 1e-9)
    length(performance) == length(Ψ.poids) ||
        throw(ArgumentError("une performance par exemple du support"))
    facteurs = 1.0 .+ float.(performance)
    Ψnew = redistribuer(Ψ, facteurs)
    h0 = float(h(Ψ))
    h1 = float(h(Ψnew))
    return RapportReponderation(Ψ, Ψnew, h0, h1, h1 >= h0 - tolerance)
end
