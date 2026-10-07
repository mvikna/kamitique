# ============================================================================
#  Trajectoire encadrée  (définition 7.4)
# ----------------------------------------------------------------------------
#  Une trajectoire est une suite finie d'états reliés par des actes des trois
#  opérateurs. Elle est admissible si chaque pas est encadré (passage réglé de
#  la chaîne) et si chaque pas satisfait l'axiome de Maât (µ non décroissante).
# ============================================================================

"""
    Pas(operateur, avant, apres, registre = nothing)

Un pas de trajectoire : l'acte d'un opérateur (`:δ`, `:ι` ou `:κ`) qui conduit de
l'état `avant` à l'état `apres`, accompagné de son registre.
"""
struct Pas
    operateur :: Symbol
    avant     :: Etat
    apres     :: Etat
    registre  :: Any
end

"""
    Trajectoire(etats, pas)

Une **trajectoire** (définition 7.4) : une suite finie d'états et les pas qui les
relient. `etats[1]` est l'état initial.
"""
struct Trajectoire
    etats :: Vector{Etat}
    pas   :: Vector{Pas}

    function Trajectoire(etats::AbstractVector{Etat}, pas::AbstractVector{Pas})
        length(etats) == length(pas) + 1 ||
            throw(ArgumentError("une trajectoire de n pas porte n+1 états"))
        new(collect(etats), collect(pas))
    end
end

Trajectoire(init::Etat) = Trajectoire([init], Pas[])

"""Étend une trajectoire d'un pas (opérateur, nouvel état, registre)."""
function ajouter_pas!(t::Trajectoire, operateur::Symbol, suivant::Etat, registre = nothing)
    avant = t.etats[end]
    push!(t.pas, Pas(operateur, avant, suivant, registre))
    push!(t.etats, suivant)
    return t
end

Base.length(t::Trajectoire) = length(t.pas)
etat_initial(t::Trajectoire) = t.etats[1]
etat_final(t::Trajectoire) = t.etats[end]

"""
    est_encadree(t, h)

Condition (i) de la définition 7.4 : chaque pas se laisse décrire comme un passage
réglé de la chaîne (un opérateur identifié parmi `δ`, `ι`, `κ`) et conserve la
lisibilité — les registres nécessaires au rendu de compte existent.
"""
function est_encadree(t::Trajectoire, h::Harmonie)
    for p in t.pas
        p.operateur in (:δ, :ι, :κ) || return false
        isempty(p.avant.figures) && return false
        isempty(p.apres.figures) && return false
    end
    return true
end

"""
    conserve_maat(t, h; tolerance = 1e-9)

Condition (ii) de la définition 7.4, axiome A-K5 : chaque pas ne décroît pas
l'harmonie, `µ(Ψ_{i+1}) ≥ µ(Ψ_i)`.
"""
function conserve_maat(t::Trajectoire, h::Harmonie; tolerance::Real = 1e-9)
    for p in t.pas
        if h(p.apres) < h(p.avant) - tolerance
            return false
        end
    end
    return true
end

"""
    est_admissible(t, h; tolerance = 1e-9)

Une trajectoire est **admissible** lorsque l'encadrement et la conservation sont
réunis (définition 7.4). Seules les trajectoires admissibles sont des évolutions du
cosmos.
"""
est_admissible(t::Trajectoire, h::Harmonie; tolerance::Real = 1e-9) =
    est_encadree(t, h) && conserve_maat(t, h; tolerance = tolerance)

"""
    harmonie_le_long(t, h)

Suite des degrés de Maât le long d'une trajectoire.
"""
harmonie_le_long(t::Trajectoire, h::Harmonie) = Float64[h(ψ) for ψ in t.etats]

# ----------------------------------------------------------------------------
#  A-K5⁺ — progression de Maât  (écart m_gap, inégalité de Łojasiewicz)
# ----------------------------------------------------------------------------
#  A-K5 n'exige que la conservation (µ non décroissante) : rien ne borne le nombre
#  de pas vers l'attracteur, et rien n'interdit un plateau où plusieurs états
#  partagent le degré maximal. A-K5⁺ ajoute l'exigence quantitative de la CQG
#  (A4 : « δS_eff = 0 ⟹ ∃! minimum global, m_gap > 0 ») : la pesée qui tranche
#  progresse au moins selon une inégalité de Łojasiewicz, et le degré maximal est
#  atteint sur une classe unique.
# ----------------------------------------------------------------------------

"""
    ecart_maat(h, Ψs; tolerance = 1e-9) -> Float64

L'**écart de Maât** `m_gap` d'un ensemble accessible d'états : la différence entre le
degré maximal accessible `µ*` et le meilleur degré **distinct** qui le suit.

C'est la lecture computationnelle de `m_gap > 0` (axiome A4 de la CQG). Un écart **nul**
signifie que le maximum n'est pas strictement dominant : l'ensemble présente un
*plateau* (vacua dégénérés) et l'attracteur n'est pas unique — la décision serait alors
arbitraire, ce que la non-compensation (`principe 26.1`) interdit.
"""
function ecart_maat(h::Harmonie, Ψs::AbstractVector{Etat}; tolerance::Real = 1e-9)
    length(Ψs) >= 2 || return 0.0
    degres = sort!([h(ψ) for ψ in Ψs]; rev = true)
    for k in 2:length(degres)
        (degres[1] - degres[k]) > tolerance && return degres[1] - degres[k]
    end
    return 0.0
end

"""
    verifie_progression_maat(t, h; c = 1.0, p = 1.0, tolerance = 1e-9) -> Bool

**A-K5⁺ — Progression de Maât.** Le renforcement quantitatif de `A-K5` : il existe
`c > 0` et `p ≥ 1` tels que, pour toute **pesée** admissible (`operateur = :κ`) où un
accroissement est encore possible — c'est-à-dire lorsque `µ(Ψ_k) < µ*`, `µ*` étant le
degré maximal atteint le long de la trajectoire —, on ait l'inégalité de Łojasiewicz

    µ(Ψ_{k+1}) − µ(Ψ_k) ≥ c · (µ* − µ(Ψ_k))^p.

La progression porte sur la **pesée** : `κ` est le seul opérateur qui *tranche et
résout* (définitions 7.3, 10.4 ; axiome A-K2 — la résolution ne s'obtient que par une
pesée explicite). `δ` (structurer) et `ι` (composer) réorganisent la présence sans
décider ; les soumettre à la progression serait infidèle à leur définition.

L'énoncé est **vide** lorsque la pesée a déjà atteint `µ*` (aucun accroissement
possible) — c'est le cas du cosmos binaire dégénéré (`T-K1`), où `µ` est constante :
la compatibilité `G2` est ainsi préservée.
"""
function verifie_progression_maat(t::Trajectoire, h::Harmonie;
                                  c::Real = 1.0, p::Real = 1.0, tolerance::Real = 1e-9)
    c > 0.0 || throw(ArgumentError("la constante de progression c doit être > 0"))
    p >= 1.0 || throw(ArgumentError("l'exposant de Łojasiewicz p doit être ≥ 1"))
    µ = harmonie_le_long(t, h)
    isempty(µ) && return true
    µetoile = maximum(µ)
    for (k, pas) in enumerate(t.pas)
        Δ = µ[k + 1] - µ[k]
        Δ >= -tolerance || return false               # conservation (A-K5) — la pesée ne recule pas
        pas.operateur === :κ || continue              # la progression quantitative porte sur la pesée
        reste = µetoile - µ[k]
        reste <= tolerance && continue                # attracteur atteint : énoncé vide
        Δ >= c * reste^p - tolerance || return false
    end
    return true
end

"""
    estime_progression(t, h; tolerance = 1e-9) -> (c, p)

Estime la constante `c` et l'exposant `p` de l'inégalité de Łojasiewicz effectivement
vérifiée par les **pesées progressives** d'une trajectoire (`reste > 0`, `gain > 0`).

- `p` est obtenu par régression linéaire de `log(gain)` sur `log(reste)` (la pente) ;
- `c` est le **minimum** des rapports `gain / reste^p` — une borne inférieure
  *certifiée*, non un ajustement moyen : `verifie_progression_maat(t, h; c = c, p = p)`
  doit donc réussir.

Une trajectoire sans pesée progressive (plateau ou attracteur d'emblée) retourne
`(1.0, 1.0)` : la valeur neutre, correspondant à l'énoncé vide.
"""
function estime_progression(t::Trajectoire, h::Harmonie; tolerance::Real = 1e-9)
    µ = harmonie_le_long(t, h)
    isempty(µ) && return (1.0, 1.0)
    µetoile = maximum(µ)
    xs = Float64[]; ys = Float64[]
    for (k, pas) in enumerate(t.pas)
        pas.operateur === :κ || continue
        reste = µetoile - µ[k]
        gain = µ[k + 1] - µ[k]
        (reste > tolerance && gain > tolerance) || continue
        push!(xs, log(reste)); push!(ys, log(gain))
    end
    m = length(xs)
    m == 0 && return (1.0, 1.0)
    x̄ = sum(xs) / m; ȳ = sum(ys) / m
    den = sum((xs[k] - x̄)^2 for k in 1:m)
    p = den <= 0.0 ? 1.0 : max(1.0, sum((xs[k] - x̄) * (ys[k] - ȳ) for k in 1:m) / den)
    c = minimum(exp(ys[k] - p * xs[k]) for k in 1:m)
    return (c, p)
end

"""
    borne_pas_progression(reste0, ε; c = 1.0, p = 1.0) -> Int

Nombre de pesées **suffisant**, garanti par l'inégalité de Łojasiewicz (`A-K5⁺`), pour
réduire l'écart à l'attracteur de `reste0 = µ* − µ(Ψ₀)` à au plus `ε`.

- `p = 1` : borne **logarithmique** `⌈ln(reste0/ε) / ln(1/(1−c))⌉` — et `1` si `c ≥ 1`
  (la pesée atteint l'attracteur en un pas) — soit `O((1/c) · log(1/ε))`.
- `p > 1` : borne **polynomiale** `⌈(ε^{1−p} − reste0^{1−p}) / (c(p−1))⌉`.

Cette borne est le gain calculatoire de `A-K5⁺` : le nombre de pas cesse d'être
qualitatif (« ça converge ») pour devenir explicite.
"""
function borne_pas_progression(reste0::Real, ε::Real; c::Real = 1.0, p::Real = 1.0)
    c > 0.0 || throw(ArgumentError("la constante de progression c doit être > 0"))
    p >= 1.0 || throw(ArgumentError("l'exposant de Łojasiewicz p doit être ≥ 1"))
    ε > 0.0 || throw(ArgumentError("la tolérance ε doit être > 0"))
    reste0 <= ε && return 0
    if p == 1.0
        c >= 1.0 && return 1
        return ceil(Int, log(reste0 / ε) / log(1.0 / (1.0 - c)))
    end
    return ceil(Int, (ε^(1.0 - p) - reste0^(1.0 - p)) / (c * (p - 1.0)))
end

# ----------------------------------------------------------------------------
#  A-K4⁺ — invariance de signature
# ----------------------------------------------------------------------------
#  A2 de la CQG : « l'univers se déploie librement dans ses configurations métriques,
#  mais jamais en violation de ses invariants caractéristiques ». Côté computationnel,
#  un pas admissible ne peut donc pas *perdre* une sous-figure minimale : toute figure
#  présente après le pas raffine une figure présente avant. La signature — classe de
#  raffinement et profil topologique — des figures transportées est ainsi préservée.

"""
    verifie_invariance_signature(G::Porteur, t::Trajectoire) -> Bool

**A-K4⁺ — Invariance de signature.** Chaque figure de l'état `apres` d'un pas
**raffine** une figure de l'état `avant` (`f ≺ g`) : aucun pas admissible ne crée une
figure *ex nihilo* ni ne perd une sous-figure minimale située. Les figures transportées
gardent donc leur signature, et toute figure nouvelle porte les invariants
topologiques de sa source.

`δ` (identité) et `κ` (sélection d'une figure déjà présente) la satisfont par
construction ; `ι` la satisfait par la loi `a ≺ a ⊙ b` (définition de `⊙`). Un pas qui
*oublierait* un site — ou composerait hors du porteur — la viole.
"""
function verifie_invariance_signature(G::Porteur, t::Trajectoire)
    for p in t.pas
        for g in p.apres.figures
            any(f -> f ≺ g, p.avant.figures) || return false
        end
    end
    return true
end
