# ============================================================================
#  L'axiomatique ΣK  (axiomes A-K1 à A-K7)
# ----------------------------------------------------------------------------
#  A-K1 support      : totalité géométrique
#  A-K2 constitution : superposition
#  A-K3 vérité       : valuation continue
#  A-K4 loi du devenir : processualité gouvernée et invariance de signature (A-K4⁺)
#  A-K5 finalité     : conservation et progression de Maât (écart m_gap)
#  A-K6 résolution   : coupure de résolution (stratification finie du porteur)
#  A-K7 fermeture    : fermeture canonique du support (clôture sous ⊙ et ≺)
# ============================================================================

"""
    Axiome(code, nom, fonction, enonce)

Un engagement de théorie du système `ΣK`. `fonction` indique la fonction de
vérification associée.
"""
struct Axiome
    code     :: Symbol
    nom      :: String
    fonction :: String
    enonce   :: String
end

"""Le catalogue des sept axiomes de la Kamitique."""
const AXIOMES = Dict{Symbol,Axiome}(
    :AK1 => Axiome(
        :AK1, "Totalité géométrique", "verifie_ak1",
        "Tout objet d'un calcul kamitique est un site ou une figure composée de sites ; " *
        "tout état est une superposition de sites. Il n'existe pas de valeur nue."),
    :AK2 => Axiome(
        :AK2, "Superposition", "verifie_ak2",
        "Tout état est une superposition pondérée ; aucun état n'est nativement résolu, " *
        "et la résolution ne s'obtient que par une pesée explicite."),
    :AK3 => Axiome(
        :AK3, "Valuation continue", "verifie_ak3",
        "Toute proposition portée par un état se pèse dans l'ordre M ; aucune n'est " *
        "nativement vraie ou fausse — le deux-valeurs est une coupure décisionnelle."),
    :AK4 => Axiome(
        :AK4, "Processualité gouvernée et invariance de signature (A-K4⁺)", "verifie_ak4",
        "Toute évolution admissible est encadrée par la chaîne épistémologique et ses " *
        "trois gouvernes ; hors encadrement, il y a accident et non évolution. De plus, " *
        "tout pas admissible préserve la signature (classe de raffinement et profil " *
        "topologique) des figures qu'il transporte : chaque figure produite raffine une " *
        "figure présente avant le pas, aucune sous-figure minimale située ne se perd — " *
        "l'univers se déploie librement dans ses configurations métriques, mais jamais " *
        "en violation de ses invariants caractéristiques."),
    :AK5 => Axiome(
        :AK5, "Conservation et progression de Maât (A-K5⁺)", "verifie_ak5",
        "Toute évolution admissible ne décroît pas l'harmonie : μ(Ψ_{i+1}) ≥ μ(Ψ_i). " *
        "De plus, toute pesée qui n'a pas encore atteint l'attracteur le rapproche " *
        "d'au moins c·(μ* − μ)^p (inégalité de Łojasiewicz) : le minimum de Maât est " *
        "global, atteint sur une classe unique, et l'écart m_gap = μ* − μ₂ > 0 exclut " *
        "les vacua dégénérés. L'énoncé de progression est vide lorsque la pesée ne peut " *
        "pas accroître l'harmonie."),
    :AK6 => Axiome(
        :AK6, "Coupure de résolution", "verifie_ak6",
        "Le porteur est stratifié en un nombre fini R d'échelles, et tout voisinage " *
        "attesté relie des échelles contiguës. La coupure de résolution R₀ remplace le " *
        "continuum indéfiniment divisible par une hiérarchie fractale ordonnée et finie : " *
        "toute chaîne de raffinements stricts est finie."),
    :AK7 => Axiome(
        :AK7, "Fermeture canonique du support", "verifie_ak7",
        "Tout état admissible a un support clos : chaque figure de son support porte " *
        "tous les liens de voisinage que le porteur atteste entre ses sites, et aucun " *
        "autre. Sa clôture est la figure_totale restreinte à ses sites. Deux figures de " *
        "même arrangement ont donc la même forme normale, et les figures closes forment " *
        "un demi-treillis supérieur borné par la figure vide et la figure totale."),
)

axiome(code::Symbol) = AXIOMES[code]
enonce(code::Symbol) = AXIOMES[code].enonce

# ----------------------------------------------------------------------------
#  Vérifications
# ----------------------------------------------------------------------------

"""
    verifie_ak1(G::Porteur, Ψ::Etat) -> Bool

A-K1 : toute figure de l'état est portée par des sites attestés dans le porteur.
"""
function verifie_ak1(G::Porteur, Ψ::Etat)
    for f in Ψ.figures
        verifier_appartenance(G, f) || return false
    end
    return true
end

"""
    verifie_ak2(Ψ::Etat; tolerance = 1e-9) -> Bool

A-K2 : les poids sont positifs ou nuls et la présence est une totalité (somme `1`).
"""
function verifie_ak2(Ψ::Etat; tolerance::Real = 1e-9)
    any(p -> p < -tolerance, Ψ.poids) && return false
    return abs(sum(Ψ.poids) - 1.0) <= tolerance
end

"""
    verifie_ak3(Ψ::Etat, ps::AbstractVector{Proposition}) -> Bool

A-K3 : toutes les valuations appartiennent à l'ordre `M`.
"""
function verifie_ak3(Ψ::Etat, ps::AbstractVector{Proposition})
    for p in ps
        appartient(M, valuation(Ψ, p)) || return false
    end
    return true
end

verifie_ak3(ν::AbstractVector{<:Real}) = all(x -> appartient(M, x), ν)

"""
    verifie_ak4(t::Trajectoire, h::Harmonie[, G::Porteur]) -> Bool

A-K4 : l'évolution est encadrée par la chaîne (chaque pas est un passage réglé).
Lorsqu'un porteur `G` est fourni, l'énoncé renforcé **A-K4⁺** exige en outre que chaque
pas préserve la signature des figures qu'il transporte
([`verifie_invariance_signature`](@ref)).
"""
verifie_ak4(t::Trajectoire, h::Harmonie) = est_encadree(t, h)
verifie_ak4(t::Trajectoire, h::Harmonie, G::Porteur) =
    est_encadree(t, h) && verifie_invariance_signature(G, t)

"""
    verifie_ak4plus(G::Porteur, t::Trajectoire, h::Harmonie) -> Bool

Alias explicite de l'énoncé renforcé **A-K4⁺** (invariance de signature).
"""
verifie_ak4plus(G::Porteur, t::Trajectoire, h::Harmonie) = verifie_ak4(t, h, G)

"""
    verifie_ak5(t, h; c = 1.0, p = 1.0, tolerance = 1e-9) -> Bool

A-K5 (conservation) et son renforcement quantitatif A-K5⁺ (progression) : l'évolution
ne décroît pas l'harmonie, et toute pesée qui n'a pas encore atteint l'attracteur
progresse au moins selon l'inégalité de Łojasiewicz `Δµ ≥ c·(µ* − µ)^p`.

La conservation est incluse : [`verifie_progression_maat`](@ref) teste `Δµ ≥ −tolerance`
sur **chaque** pas avant de n'exiger la progression que sur la pesée. Aucune évaluation
supplémentaire de `µ` n'est donc faite par rapport à `A-K5` seul.
"""
verifie_ak5(t::Trajectoire, h::Harmonie; c::Real = 1.0, p::Real = 1.0,
            tolerance::Real = 1e-9) =
    verifie_progression_maat(t, h; c = c, p = p, tolerance = tolerance)

"""
    verifie_ak7(G::Porteur, Ψ::Etat) -> Bool

A-K7 : le support de l'état est **clos** — chaque figure est attestée dans `G` (A-K1)
et porte exactement les liens que `G` atteste entre ses propres sites :
`cloture(G, f) == f`. Un état dont une figure porte un lien non attesté, ou omet un
lien attesté, n'est pas admissible.
"""
function verifie_ak7(G::Porteur, Ψ::Etat)
    verifie_ak1(G, Ψ) || return false
    for f in Ψ.figures
        est_close(G, f) || return false
    end
    return true
end

"""
    RapportAxiomes

Rapport de conformité d'un état ou d'une trajectoire aux sept axiomes.
"""
struct RapportAxiomes
    conformite :: Dict{Symbol,Bool}
end

Base.all(r::RapportAxiomes) = all(values(r.conformite))
Base.getindex(r::RapportAxiomes, code::Symbol) = r.conformite[code]

"""
    verifier_axiomes(G, Ψ; trajectoire = nothing, h = nothing, propositions = Proposition[])

Contrôle les sept axiomes applicables. A-K6 et A-K7 portent sur le porteur et l'état ;
A-K4 (encadrement **et** invariance de signature, A-K4⁺) et A-K5 ne sont vérifiés que si
une trajectoire et une harmonie sont fournies ; sinon ils sont réputés non applicables
(renvoyés `true`).
"""
function verifier_axiomes(G::Porteur, Ψ::Etat;
                          trajectoire::Union{Trajectoire,Nothing} = nothing,
                          h::Union{Harmonie,Nothing} = nothing,
                          propositions::AbstractVector{Proposition} = Proposition[])
    r = Dict{Symbol,Bool}()
    r[:AK1] = verifie_ak1(G, Ψ)
    r[:AK2] = verifie_ak2(Ψ)
    r[:AK3] = verifie_ak3(Ψ, propositions)
    r[:AK4] = trajectoire === nothing || h === nothing ? true : verifie_ak4(trajectoire, h, G)
    r[:AK5] = trajectoire === nothing || h === nothing ? true : verifie_ak5(trajectoire, h)
    r[:AK6] = verifie_ak6(G)
    r[:AK7] = verifie_ak7(G, Ψ)
    return RapportAxiomes(r)
end
