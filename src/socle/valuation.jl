# ============================================================================
#  Valuation et harmonie  (définitions 5.5, 5.6)
# ----------------------------------------------------------------------------
#  La valuation décide, l'harmonie mesure : la première porte sur des
#  propositions, la seconde sur des états. Ce sont deux notions distinctes.
# ============================================================================

"""
    Proposition(nom, verdict)

Une proposition `p` portée par les sites d'un état. `verdict(f)` donne, pour une
figure `f`, le degré `∈ [0, 1]` auquel cette figure porte `p`.
"""
struct Proposition
    nom     :: String
    verdict :: Function
end

"""Construit une proposition à partir d'un prédicat binaire `f -> Bool`."""
proposition_binaire(nom::AbstractString, f::Function) =
    Proposition(String(nom), fig -> f(fig) ? 1.0 : 0.0)

"""
    valuation(Ψ::Etat, p::Proposition) -> Float64

La **valuation** `ν(Ψ, p)` (définition 5.5) : le degré auquel l'état `Ψ` porte la
proposition `p`, c'est-à-dire la présence totale affectée aux figures qui portent `p` :

    ν(Ψ, p) = Σ_g αg · p(g).

La valeur appartient à l'ordre de pesée `M = [0, 1]`.
"""
function valuation(Ψ::Etat, p::Proposition)
    s = 0.0
    for (f, a) in zip(Ψ.figures, Ψ.poids)
        a > 0 || continue
        s += a * clamp(float(p.verdict(f)), 0.0, 1.0)
    end
    return valider_degre(s; nom = "valuation")
end

"""Valuations d'un état sur un faisceau de propositions (dans l'ordre donné)."""
valuation(Ψ::Etat, ps::AbstractVector{Proposition}) =
    Float64[valuation(Ψ, p) for p in ps]

"""Nomme les valuations d'un état sur un faisceau de propositions."""
function valuations_nommees(Ψ::Etat, ps::AbstractVector{Proposition})
    return Dict(p.nom => valuation(Ψ, p) for p in ps)
end

# ----------------------------------------------------------------------------
#  Harmonie
# ----------------------------------------------------------------------------

"""
    Harmonie(compatibilite)

L'**harmonie** `µ : E(G) → [0, 1]` (définition 5.6) : le degré de Maât de l'état,
sa cohérence interne.

`µ` est construite à partir d'une *compatibilité* symétrique `κ(g, h) ∈ [0, 1]` :

    µ(Ψ) = Σ_g Σ_h αg αh · κ(g, h).

Elle est maximale pour les états dont les figures cohabitent sans contradiction et
dont les poids respectent les hiérarchies du porteur.
"""
struct Harmonie
    compatibilite :: Function
    seuil_conflit :: Float64
end

Harmonie(compat::Function) = Harmonie(compat, 0.0)

"""L'harmonie par défaut : cohérence de l'emboîtement par le raffinement ≺."""
HarmonieRaffinement() = Harmonie(compatibilite_raffinement, 0.0)

function (h::Harmonie)(Ψ::Etat)
    s = 0.0
    n = length(Ψ.figures)
    # La compatibilité κ est symétrique : chaque couple {i, j} n'est évalué qu'une fois.
    # On répartit donc la contribution 2·αi·αj·κ(i,j) du triangle supérieur, le terme
    # diagonal αi²·κ(i,i) restant à part — le coût du noyau est divisé par deux.
    for i in 1:n
        ai = Ψ.poids[i]
        ai == 0.0 && continue
        s += ai * ai * clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[i])), 0.0, 1.0)
        for j in (i + 1):n
            aj = Ψ.poids[j]
            aj == 0.0 && continue
            s += 2.0 * ai * aj * clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
        end
    end
    return valider_degre(clamp(s, 0.0, 1.0); nom = "harmonie")
end

"""
    compatibilite_raffinement(g, h)

Compatibilité canonique entre deux figures :

- `1.0` si l'une est un raffinement de l'autre (emboîtement cohérent) ;
- `0.8` si elles sont disjointes (cohabitation neutre) ;
- sinon, un degré décroissant avec le recouvrement conflictuel.

Cette compatibilité **respecte le raffinement** : une figure plus fine n'est jamais
moins compatible qu'une figure grossière qu'elle raffine.
"""
function compatibilite_raffinement(g::Figure, h::Figure)
    (g ≺ h) && return 1.0
    (h ≺ g) && return 1.0
    communs = count(s -> s in h.sites, g.sites)
    communs == 0 && return 0.8
    union_ = length(g.sites) + length(h.sites) - communs
    recouvrement = communs / max(union_, 1)
    return clamp(1.0 - recouvrement, 0.0, 1.0)
end

"""Évalue `µ(Ψ)` pour une harmonie donnée."""
degre_maat(h::Harmonie, Ψ::Etat) = h(Ψ)

"""
    respecte_raffinement(h::Harmonie, grossiere, fine, poids; ...)

Vérifie la propriété exigée par la définition 5.6 : à poids égaux, une présence plus
fine n'est pas moins harmonieuse que la grossière qu'elle raffine.
"""
function respecte_raffinement(h::Harmonie, grossiere::Figure, fine::Figure;
                              poids::Real = 1.0, autres::Vector{Figure} = Figure[],
                              poids_autres::Vector{<:Real} = Float64[], tolerance::Real = 1e-9)
    Ψ1 = Etat(vcat(autres, [grossiere]), vcat(poids_autres, [poids]))
    Ψ2 = Etat(vcat(autres, [fine]), vcat(poids_autres, [poids]))
    return h(Ψ2) >= h(Ψ1) - tolerance
end
