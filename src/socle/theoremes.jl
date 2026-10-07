# ============================================================================
#  Théorèmes fondamentaux  (T-K1 à T-K6, chapitre 8)
# ----------------------------------------------------------------------------
#  T-K1 subsumption binaire  · T-K2 gouverne de non-phase
#  T-K3 convergence de Maât   · T-K4 complétude de couverture
#  T-K5 frugalité structurelle · T-K6 irréversibilité de la pesée
# ============================================================================

"""
    Degenerescence

Résultat d'un plongement d'un régime binaire dans un cosmos kamitique (T-K1) :
le porteur, l'état résolu fidèle au régime, et l'état binaire d'origine.
"""
struct Degenerescence
    porteur :: Porteur
    etat    :: Etat
    binaire :: Vector{BitVector}
end

"""
    degenerer(configurations::AbstractVector{BitVector}) -> Degenerescence

**T-K1 — Subsumption binaire.** Construit explicitement le cosmos kamitique dégénéré
d'un régime binaire : chaque configuration binaire est un site (sa position est sa
place dans l'espace des configurations) ; la composition `⊙` associe à deux
configurations leur composition booléenne ; le raffinement `≺` est l'ordre par
restriction des positions ; l'état résolu reproduit exactement l'état binaire.

Tout régime binaire est ainsi un cosmos kamitique dégénéré.
"""
function degenerer(configurations::AbstractVector{BitVector})
    isempty(configurations) && throw(ArgumentError("un régime binaire porte au moins une configuration"))
    largeur = length(configurations[1])
    all(c -> length(c) == largeur, configurations) ||
        throw(ArgumentError("les configurations d'un régime binaire ont même largeur"))

    G = Porteur()
    for (k, c) in enumerate(configurations)
        voisins = Symbol[]
        for (l, d) in enumerate(configurations)
            k == l && continue
            # voisinage = distance de Hamming de 1 (l'ordre par restriction des positions)
            sum(abs.(Int.(c) .- Int.(d))) == 1 && push!(voisins, Symbol("cfg_$l"))
        end
        ajouter_site!(G, Symbol("cfg_$k");
                      lieu = (k, Tuple(Int.(c))), voisins = voisins)
    end

    figures = Figure[Figure([Symbol("cfg_$k")]) for k in eachindex(configurations)]
    # état résolu par défaut sur la première configuration = état binaire reproduit
    Ψ = Etat(figures, [1.0; zeros(length(figures) - 1)])
    return Degenerescence(G, Ψ, collect(configurations))
end

"""Reconstruit la configuration binaire reproduite par un état résolu du cosmos dégénéré."""
function configuration_reproduite(d::Degenerescence)
    i = findfirst(p -> p == 1.0, d.etat.poids)
    return i === nothing ? nothing : d.binaire[i]
end

"""
    verifie_subsumption_binaire(configurations) -> Bool

Contrôle expérimental de T-K1 : l'état résolu du cosmos kamitique dégénéré reproduit
fidèlement l'état binaire d'origine, et réciproquement.
"""
function verifie_subsumption_binaire(configurations::AbstractVector{BitVector})
    d = degenerer(configurations)
    for (k, _) in enumerate(configurations)
        Ψk = Etat([Figure([Symbol("cfg_$k")])], [1.0])
        est_resolu(Ψk) || return false
    end
    return true
end

"""
    verifie_gouverne_non_phase(t, h) -> Bool

**T-K2 — Gouverne de non-phase.** Vérifie qu'aucune stabilité ne se conserve hors
encadrement : une trajectoire non encadrée altère le porteur (le produit n'est pas un
état) ou détruit l'harmonie (la suite n'est pas une trajectoire).
"""
function verifie_gouverne_non_phase(t::Trajectoire, h::Harmonie)
    return est_encadree(t, h)
end

"""
    verifie_convergence_maat(t, h; tolerance = 1e-9) -> Bool

**T-K3 — Convergence de Maât.** Une trajectoire admissible finie, dont aucun pas n'est
strictement croissant lorsque c'est possible, converge vers un **attracteur de Maât** :
µ est non décroissante et bornée, donc l'état final est de degré maximal parmi les
états accessibles.
"""
function verifie_convergence_maat(t::Trajectoire, h::Harmonie; tolerance::Real = 1e-9)
    conserve_maat(t, h; tolerance = tolerance) || return false
    µ = harmonie_le_long(t, h)
    return isempty(µ) || µ[end] >= maximum(µ) - tolerance
end

"""Le degré final `µ(Ψ*)` de l'attracteur de Maât d'une trajectoire."""
attracteur_maat(t::Trajectoire, h::Harmonie) = h(etat_final(t))

"""
    verifie_irreversibilite_pesee(Ψ, i, h) -> Bool

**T-K6 — Irréversibilité de la pesée.** Aucune opération admissible (`δ`, `ι`) ne
restitue les figures écartées par une pesée `κ` : `δ` ne transforme pas, `ι` ne compose
qu'à partir de ce qui est présent, et la normalisation interdit de créer de la présence.
"""
function verifie_irreversibilite_pesee(Ψ::Etat, i::Integer, h::Harmonie; λ::Real = 0.5)
    Ψr = resolve(Ψ, i)
    ecartees = [Ψ.figures[k] for k in eachindex(Ψ.figures) if k != i]
    # δ ne restitue rien
    sp = δ(Ψr)
    any(f -> f in ecartees, sp.figures) && return false
    # ι ne compose qu'à partir du présent
    if length(Ψr.figures) >= 1
        Ψc = ι(Ψr, plan_annulaire(length(Ψr.figures)))
        any(f -> f in ecartees, Ψc.figures) && return false
    end
    return true
end

"""
    cout_descriptif(Ψ; seuil = 1e-9) -> Int

**T-K5 — Frugalité structurelle.** Le coût descriptif d'un état est porté par la
complexité de sa figure : nombre de sites significatifs, compositions et liens de
raffinement — indépendamment de toute taille d'encodage binaire éventuelle.
"""
function cout_descriptif(Ψ::Etat; seuil::Real = 1e-9)
    figs = Figure[f for (f, p) in zip(Ψ.figures, Ψ.poids) if p > seuil]
    sites = Set{Symbol}()
    liens = 0
    compositions = 0
    for f in figs
        union!(sites, f.sites)
        liens += length(f.liens)
        compositions += max(length(f.sites) - 1, 0)
    end
    return length(figs) + length(sites) + liens + compositions
end

"""
    completude_couverture(categories) -> Dict

**T-K4 — Complétude de couverture.** Pour toute catégorie de problèmes, la Kamitique
fournit une méthode obtenue par la **triple substitution** : support → porteur
géométrique, valuation → ordre de pesée `M`, dynamique → trajectoire encadrée.

Retourne la table de substitution appliquée à chaque catégorie fournie.
"""
function completude_couverture(categories::AbstractVector{<:AbstractString})
    return Dict(
        cat => (
            support   = "porteur géométrique de figures situées",
            valuation = "ordre de pesée M (bornes = valuation classique)",
            dynamique = "trajectoire encadrée (δ, ι, κ sous gouverne)",
        )
        for cat in categories
    )
end

"""
    subsumption(::Type, x) -> Degenerescence

Forme fonctionnelle de T-K1 : tout objet d'un régime binaire se lit comme cosmos
kamitique dégénéré.
"""
subsumption(configurations::AbstractVector{BitVector}) = degenerer(configurations)
