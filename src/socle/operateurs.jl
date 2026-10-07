# ============================================================================
#  Opérateurs et dynamique gouvernée  (définitions 7.1 à 7.4)
# ----------------------------------------------------------------------------
#  Trois opérateurs constituent l'outillage élémentaire du devenir kamitique :
#    δ  structuration — rend l'état lisible, sans le transformer ;
#    ι  composition   — engendre un état nouveau (siège du génératif) ;
#    κ  pesée        — tranche et résout l'état (irréversible).
#  Ces opérateurs sont les mêmes que ceux de la chaîne épistémologique : le
#  module Chaine en ajoute les méthodes, réalisant l'identité structurelle.
# ============================================================================

"""
    Question(nom, propositions)

Une question `q` portée par un faisceau de propositions `p1, …, pm`. La question
précède la mesure (clause (i) de la balance, principe 8.1).
"""
struct Question
    nom          :: Symbol
    propositions :: Vector{Proposition}
end

Question(nom::Symbol, ps::Proposition...) = Question(nom, Proposition[ps...])

"""
    Spectre

Le spectre géométrique d'un état (définition 7.1) : la liste ordonnée des figures
qui portent l'essentiel de la présence, avec leurs poids et leurs relations de
raffinement. `δ` ne transforme pas l'état : il le rend lisible.
"""
struct Spectre
    figures :: Vector{Figure}
    poids   :: Vector{Float64}
    liens   :: Vector{Tuple{Int,Int}}   # couple (i, j) signifiant figures[i] ≺ figures[j]
    seuil   :: Float64
end

Base.length(s::Spectre) = length(s.figures)

"""Fonction générique de structuration. Voir les méthodes dans `Socle` et `Chaine`."""
function δ end

"""Fonction générique de composition (génératif). Voir `Socle` et `Chaine`."""
function ι end

"""Fonction générique de pesée (décision irréversible). Voir `Socle` et `Chaine`."""
function κ end

# ----------------------------------------------------------------------------
#  δ — structuration
# ----------------------------------------------------------------------------

"""
    δ(Ψ::Etat, G::Porteur = Porteur(); seuil = 1e-9) -> Spectre

L'**opérateur de structuration** (définition 7.1, 10.2) : extrait de `Ψ` le spectre
géométrique — les figures significatives, leurs poids et les liens `≺` qui les
ordonnent. Aucune information significative n'est écartée sans être signalée.
"""
function δ(Ψ::Etat, G::Porteur = Porteur(); seuil::Real = 1e-9)
    idx = sortperm(Ψ.poids; rev = true)
    figs = Figure[]
    ps = Float64[]
    for i in idx
        Ψ.poids[i] > seuil || continue
        if isempty(G.sites) || verifier_appartenance(G, Ψ.figures[i])
            push!(figs, Ψ.figures[i])
            push!(ps, Ψ.poids[i])
        end
    end
    liens = Tuple{Int,Int}[]
    for i in eachindex(figs), j in eachindex(figs)
        i == j && continue
        (figs[i] ≺ figs[j]) && !(figs[j] ≺ figs[i]) && push!(liens, (i, j))
    end
    return Spectre(figs, ps, liens, float(seuil))
end

structuration(args...; kwargs...) = δ(args...; kwargs...)

# ----------------------------------------------------------------------------
#  ι — composition
# ----------------------------------------------------------------------------

"""
    ι(Ψ::Etat, plan; G = nothing) -> Etat

L'**opérateur de composition** (définitions 7.2, 10.3) : produit un nouvel état en
composant des figures tirées de `Ψ` et en redistribuant les poids, sous la seule
contrainte de normalisation.

`plan` est un vecteur de couples `(i, j)` d'indices du support : chaque couple
désigne deux figures à composer par `⊙`. La figure composée reçoit la présence
cumulée de ses composantes, puis l'état est renormalisé — **rien n'entre sans que la
totalité se réorganise** (axiome A-K2).
"""
function ι(Ψ::Etat, plan::AbstractVector{<:Tuple{Int,Int}}; G::Union{Porteur,Nothing} = nothing)
    figures = copy(Ψ.figures)
    ps = copy(Ψ.poids)
    consomme = Set{Int}()
    nouvelles = Figure[]
    nouveaux_poids = Float64[]
    for (i, j) in plan
        (1 <= i <= length(Ψ.figures) && 1 <= j <= length(Ψ.figures)) ||
            throw(BoundsError(Ψ.figures, (i, j)))
        composee = G === nothing ? (Ψ.figures[i] ⊙ Ψ.figures[j]) : ⊙(G, Ψ.figures[i], Ψ.figures[j])
        push!(nouvelles, composee)
        push!(nouveaux_poids, Ψ.poids[i] + Ψ.poids[j])
        push!(consomme, i)
        push!(consomme, j)
    end
    reste = [k for k in eachindex(Ψ.figures) if !(k in consomme)]
    for k in reste
        push!(nouvelles, Ψ.figures[k])
        push!(nouveaux_poids, Ψ.poids[k])
    end
    isempty(nouvelles) && return Ψ
    return Etat(nouvelles, nouveaux_poids)
end

"""Compose deux figures présentes et redistribue — acte élémentaire de `ι`."""
function ι(Ψ::Etat, i::Integer, j::Integer; G::Union{Porteur,Nothing} = nothing)
    return ι(Ψ, [(Int(i), Int(j))]; G = G)
end

"""Apparie les figures présentes deux à deux : éventail de composition complet."""
function plan_annulaire(n::Integer)
    plan = Tuple{Int,Int}[]
    i = 1
    while i + 1 <= n
        push!(plan, (i, i + 1))
        i += 2
    end
    return plan
end

# ----------------------------------------------------------------------------
#  κ — pesée
# ----------------------------------------------------------------------------

"""
    ScorePesee

Résultat détaillé d'une pesée : les degrés mesurés sur chaque figure candidate, la
cohérence harmonique de chacune, et le score agrégé qui tranche. C'est la matière du
registre de pesée.
"""
struct ScorePesee
    indices    :: Vector{Int}
    valuations :: Vector{Float64}   # moyenne des ν(Ψ, p) sur les propositions de la question
    coherence  :: Vector{Float64}   # compatibilité moyenne avec la présence totale
    scores     :: Vector{Float64}   # score agrégé, ∈ [0, 1]
end

"""
    _valuation_figure(f, ps) -> Float64

Valuation d'une **figure unique** portée avec le poids `1` (cas particulier de
[`valuation`](@ref) lorsque le support est la figure seule). Évite de construire un
état intermédiaire à chaque figure candidate de la pesée.
"""
function _valuation_figure(f::Figure, ps::AbstractVector{Proposition})
    isempty(ps) && return 1.0
    s = 0.0
    for p in ps
        s += clamp(float(p.verdict(f)), 0.0, 1.0)
    end
    return valider_degre(s / length(ps); nom = "valuation")
end

"""
    scores_pesee(Ψ, q, h; λ = 0.5)

Calcule, pour chaque figure du support, la moyenne de ses valuations sur les
propositions de la question `q`, sa cohérence harmonique avec la présence totale, et
le score agrégé

    score = (1 - λ) · ν_moyen + λ · cohérence.

La comparaison est **une position dans l'ordre, non un verdict binaire** (clause (iii)
de la balance).
"""
function scores_pesee(Ψ::Etat, q::Question, h::Harmonie; λ::Real = 0.5)
    (0.0 <= λ <= 1.0) || throw(ArgumentError("λ doit appartenir à [0, 1]"))
    n = length(Ψ.figures)
    νm = zeros(n)
    for i in 1:n
        νm[i] = _valuation_figure(Ψ.figures[i], q.propositions)
    end
    # Cohérence : κ étant symétrique, chaque couple {i, j} n'est évalué qu'une fois
    # (triangle supérieur + diagonale) et sa contribution est répartie sur les deux
    # figures — le coût du noyau est divisé par deux, sans matrice intermédiaire.
    figs = Ψ.figures
    poids = Ψ.poids
    c = zeros(n)
    for j in 1:n
        aj = poids[j]
        c[j] += aj * clamp(float(h.compatibilite(figs[j], figs[j])), 0.0, 1.0)
        for i in 1:(j - 1)
            ai = poids[i]
            (ai == 0.0 && aj == 0.0) && continue
            v = clamp(float(h.compatibilite(figs[i], figs[j])), 0.0, 1.0)
            c[i] += aj * v
            c[j] += ai * v
        end
    end
    coh = Float64[valider_degre(clamp(c[i], 0.0, 1.0); nom = "cohérence") for i in 1:n]
    scores = clamp.((1 - λ) .* νm .+ λ .* coh, 0.0, 1.0)
    return ScorePesee(collect(1:n), νm, coh, scores)
end

"""
    κ(Ψ::Etat, q::Question, h::Harmonie; λ = 0.5) -> (Etat, ScorePesee)

L'**opérateur de pesée** (définitions 7.3, 10.4) : mesure les valuations pertinentes,
compare les figures candidates au regard de l'harmonie, et **résout** l'état par
sélection — la présence est concentrée sur la figure retenue.

La pesée est **irréversible** (théorème 8.4) : on ne défait pas une pesée.
"""
function κ(Ψ::Etat, q::Question, h::Harmonie; λ::Real = 0.5)
    scores = scores_pesee(Ψ, q, h; λ = λ)
    gagnant = scores.indices[argmax(scores.scores)]
    return (resolve(Ψ, gagnant), scores)
end

"""Concentre la présence entière sur la m-ième figure du support (résolution)."""
function resolve(Ψ::Etat, i::Integer)
    1 <= i <= length(Ψ.figures) || throw(BoundsError(Ψ.figures, i))
    return Etat([Ψ.figures[i]], [1.0])
end

pesee_resoudre(args...; kwargs...) = κ(args...; kwargs...)
