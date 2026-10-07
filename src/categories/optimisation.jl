# ============================================================================
#  Optimisation et recherche opérationnelle kamitiques  (chapitre 25)
# ----------------------------------------------------------------------------
#  « harmonisation, élagage par pesée des voies ». L'optimum de Maât s'atteint par
#  descente par harmonisation ; l'élagage borne les voies par le produit des degrés
#  tranchés et des maxima restants — peser les voies avant de les payer.
# ============================================================================

"""
    ResultatDescenteOptimale

Le résultat d'une descente par harmonisation : la figure optimale atteinte, sa valeur
et le nombre d'itérations.
"""
struct ResultatDescenteOptimale
    figure     :: Figure
    valeur     :: Float64
    iterations :: Int
    registre   :: Vector{String}
end

"""
    descente_par_harmonisation(Ψ, q, h; λ = 0.5, η = 0.5, max_iter = 64, tolerance = 1e-4)
        -> ResultatDescenteOptimale

**Descente par harmonisation** (méthode 25.1). On pèse d'abord les voies (les figures
du support) par `scores_pesee`, puis on **repondère** la présence vers la meilleure
figure (`η` est le pas). La descente converge vers l'**optimum de Maât** : la présence
se concentre sur une figure, sans avoir payé les voies écartées.
"""
function descente_par_harmonisation(Ψ::Etat, q::Question, h::Harmonie;
                                    λ::Real = 0.5, η::Real = 0.5,
                                    max_iter::Integer = 64, tolerance::Real = 1e-4)
    courant = Ψ
    iterations = 0
    precedent = -1.0
    registre = String["descente par harmonisation (optimum de Maât)"]
    while iterations < max_iter
        sc = scores_pesee(courant, q, h; λ = λ)
        i = argmax(sc.scores)
        valeur = sc.scores[i]
        if abs(valeur - precedent) < tolerance
            push!(registre, "optimum atteint : figure $i, valeur $(round(valeur; digits = 4)) " *
                            "en $iterations itération(s)")
            return ResultatDescenteOptimale(courant.figures[i], valeur, iterations, registre)
        end
        precedent = valeur
        n = length(courant.figures)
        facteurs = ones(n)
        facteurs[i] = 1.0 + η
        courant = redistribuer(courant, facteurs)
        iterations += 1
    end
    sc = scores_pesee(courant, q, h; λ = λ)
    i = argmax(sc.scores)
    push!(registre, "limite d'itérations atteinte : figure $i")
    return ResultatDescenteOptimale(courant.figures[i], sc.scores[i], iterations, registre)
end

"""
    borne_harmonique(tranches, maxima_restants) -> Float64

**Borne harmonique** d'une voie partiellement explorée : le produit des degrés déjà
tranchés et des maxima restants. C'est la borne de Maât d'une branche — jamais un
simple compteur.
"""
function borne_harmonique(tranches::AbstractVector{<:Real},
                          maxima_restants::AbstractVector{<:Real})
    b = 1.0
    for d in tranches
        b *= clamp(float(d), 0.0, 1.0)
    end
    for d in maxima_restants
        b *= clamp(float(d), 0.0, 1.0)
    end
    return valider_degre(b; nom = "borne harmonique")
end

"""
    ResultatElagage

Le résultat d'un élagage par pesée des voies : les voies retenues, les voies écartées
et le registre.
"""
struct ResultatElagage
    retenues :: Vector{Int}
    ecartees :: Vector{Int}
    registre :: Vector{String}
end

"""
    elagage_par_pesee(bornes; seuil = 0.5) -> ResultatElagage

**Élagage par pesée des voies** (méthode 25.2). Chaque voie porte une borne harmonique ;
toute voie dont la borne tombe sous `seuil` est écartée **sans être payée**, en le
consignant. C'est l'élagage qui rend la recherche combinatoire praticable.
"""
function elagage_par_pesee(bornes::AbstractVector{<:Real}; seuil::Real = 0.5)
    isempty(bornes) && throw(ArgumentError("aucune voie à élaguer"))
    retenues = Int[]
    ecartees = Int[]
    registre = String["élagage par pesée des voies (seuil $seuil)"]
    sizehint!(retenues, length(bornes))
    sizehint!(ecartees, length(bornes))
    sizehint!(registre, length(bornes) + 2)   # une entrée par voie écartée, + en-tête/pied
    for k in eachindex(bornes)
        b = clamp(float(bornes[k]), 0.0, 1.0)
        if b >= seuil
            push!(retenues, k)
        else
            push!(ecartees, k)
            push!(registre, "voie $k élaguée (borne $(round(b; digits = 4)))")
        end
    end
    push!(registre, "retenues : $(length(retenues)), élaguées : $(length(ecartees))")
    return ResultatElagage(retenues, ecartees, registre)
end
