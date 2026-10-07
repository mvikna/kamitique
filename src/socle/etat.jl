# ============================================================================
#  L'état cosmologique et l'espace kamitique  (définitions 5.3, 5.4)
# ----------------------------------------------------------------------------
#  Ψ = Σ αg g, les poids αg sont positifs ou nuls et leur somme vaut 1 : la
#  présence est une totalité, pondérer c'est répartir une présence finie.
# ============================================================================

"""
    Etat(figures, poids)

L'**état cosmologique** (définition 5.3) : une superposition pondérée de figures

    Ψ = Σ_g αg · g,

où les poids de présence `αg` sont des réels positifs ou nuls de somme `1`.

Un état **n'est jamais nativement résolu** (axiome A-K2) : la résolution est le cas
particulier où un seul poids vaut `1`, et elle ne s'obtient que par une opération
explicite de pesée ([`κ`](@ref)).
"""
struct Etat
    figures :: Vector{Figure}
    poids   :: Vector{Float64}

    function Etat(figures::AbstractVector{Figure}, poids::AbstractVector{<:Real};
                  tolerance::Real = 1e-9)
        length(figures) == length(poids) ||
            throw(ArgumentError("un état superpose autant de figures que de poids"))
        isempty(figures) &&
            throw(ArgumentError("un état porte au moins une figure"))
        ps = float.(collect(poids))
        any(p -> p < -tolerance, ps) &&
            throw(ArgumentError("les poids de présence sont positifs ou nuls"))
        ps = clamp.(ps, 0.0, Inf)
        s = sum(ps)
        s <= 0 && throw(ArgumentError("la présence totale doit être strictement positive"))
        # normalisation : la présence est une totalité
        abs(s - 1.0) > tolerance && (ps = ps ./ s)
        new(collect(figures), ps)
    end
end

"""Construit un état à partir de couples `figure => poids`."""
function etat(couples::Pair{Figure,<:Real}...)
    figures = Figure[f for (f, _) in couples]
    poids = Float64[p for (_, p) in couples]
    return Etat(figures, poids)
end

"""Support de l'état : les figures présentes."""
support(Ψ::Etat) = Ψ.figures

"""Poids de présence `αg` de la m-ième figure du support."""
poids(Ψ::Etat, i::Integer) = Ψ.poids[i]

"""Poids associé à une figure, `0.0` si elle est absente du support."""
function poids(Ψ::Etat, f::Figure)
    i = findfirst(==(f), Ψ.figures)
    return i === nothing ? 0.0 : Ψ.poids[i]
end

Base.length(Ψ::Etat) = length(Ψ.figures)

"""Nombre de figures de poids strictement positif (support effectif)."""
support_effectif(Ψ::Etat; seuil::Real = 1e-12) = count(>(seuil), Ψ.poids)

"""
    normaliser(Ψ)

Retourne un nouvel état de même support dont les poids somment à `1`.
"""
normaliser(Ψ::Etat) = Etat(Ψ.figures, Ψ.poids)

"""
    est_resolu(Ψ; tolerance = 1e-9)

Indique si l'état est **résolu** (définition 5.3) : un seul poids vaut `1`.
"""
est_resolu(Ψ::Etat; tolerance::Real = 1e-9) = any(p -> abs(p - 1.0) <= tolerance, Ψ.poids)

"""Indice de la figure résolue, ou `nothing` si l'état n'est pas résolu."""
function figure_resolue(Ψ::Etat; tolerance::Real = 1e-9)
    i = findfirst(p -> abs(p - 1.0) <= tolerance, Ψ.poids)
    return i === nothing ? nothing : Ψ.figures[i]
end

"""
    redistribuer(Ψ, ajustements; tolerance)

Applique la **loi de redistribution** (axiome A-K2) : toute information entrante
repondère la présence au lieu de l'ajouter. `ajustements` est un vecteur de
multiplicateurs (ou de deltas) appliqués aux poids, après quoi l'état est renormalisé.

Un ajustement qui ferait sortir un poids de `[0, +∞[` est tronqué à `0`.
"""
function redistribuer(Ψ::Etat, ajustements::AbstractVector{<:Real})
    length(ajustements) == length(Ψ.poids) ||
        throw(ArgumentError("un ajustement par figure du support"))
    return Etat(Ψ.figures, Ψ.poids .* float.(ajustements))
end

"""Redistribution par deltas additifs, bornée à zéro puis renormalisée."""
function redistribuer_delta(Ψ::Etat, deltas::AbstractVector{<:Real})
    length(deltas) == length(Ψ.poids) ||
        throw(ArgumentError("un delta par figure du support"))
    return Etat(Ψ.figures, max.(Ψ.poids .+ float.(deltas), 0.0))
end

# ----------------------------------------------------------------------------
#  Fermeture canonique du support  (axiome A-K7)
# ----------------------------------------------------------------------------

"""
    cloture_support(G::Porteur, Ψ::Etat) -> Figure

La **clôture du support** (axiome A-K7) : la [`figure_totale`](@ref)`(G)` restreinte à
l'union des sites de tout le support de `Ψ`. C'est la figure close minimale portant tous
les sites présents dans l'état.
"""
function cloture_support(G::Porteur, Ψ::Etat)
    sites = Symbol[]
    vus = Set{Symbol}()
    for f in Ψ.figures, s in f.sites
        s in vus && continue
        push!(vus, s); push!(sites, s)
    end
    return _cloture(G, sites)
end

"""
    canoniser(G::Porteur, Ψ::Etat) -> Etat

La **forme normale** d'un état (axiome A-K7) : chaque figure du support est remplacée
par sa [`cloture`](@ref), et deux figures de même clôture **fusionnent** — leurs poids
s'additionnent. Deux états dénotant le même cosmos ont alors une représentation
identique, et la déduplication / la mémoïsation deviennent sûres.
"""
function canoniser(G::Porteur, Ψ::Etat)
    figures = Figure[]
    poids = Float64[]
    index = Dict{Figure,Int}()
    for (f, a) in zip(Ψ.figures, Ψ.poids)
        cl = cloture(G, f)
        i = get(index, cl, 0)
        if i == 0
            push!(figures, cl); push!(poids, a); index[cl] = length(figures)
        else
            poids[i] += a
        end
    end
    return Etat(figures, poids)
end

"""Signatures du support d'un état, dans l'ordre des figures (axiome A-K4⁺)."""
signature(G::Porteur, Ψ::Etat) = Signature[signature(G, f) for f in Ψ.figures]

# ----------------------------------------------------------------------------
#  Espace kamitique et cosmos
# ----------------------------------------------------------------------------

"""
    EspaceKamitique(porteur, harmonie)

L'**espace kamitique** `K = (G, ⊙, ≺, µ)` (définition 5.4) : le porteur géométrique,
sa composition `⊙`, son raffinement `≺` et sa mesure d'harmonie `µ`.
"""
struct EspaceKamitique
    porteur  :: Porteur
    harmonie :: Any          # application E(G) → [0, 1] (voir Harmonie)
end

EspaceKamitique(G::Porteur) = EspaceKamitique(G, HarmonieRaffinement())

"""
    Cosmos(espace, init, gouverne = nothing)

Un **cosmos de calcul** (définition 5.4) : un espace kamitique considéré avec sa
dynamique, c'est-à-dire l'ensemble des trajectoires que sa gouverne admet.
"""
struct Cosmos
    espace   :: EspaceKamitique
    init     :: Etat
    gouverne :: Any
end

Cosmos(espace::EspaceKamitique, init::Etat) = Cosmos(espace, init, nothing)

porteur(K::EspaceKamitique) = K.porteur

"""Évalue l'harmonie `µ(Ψ)` d'un état dans un espace kamitique."""
harmonie(K::EspaceKamitique, Ψ::Etat) = K.harmonie(Ψ)
