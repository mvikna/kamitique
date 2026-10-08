# ============================================================================
#  Benchmark de conformité — catégorie 17 : « Apprentissage automatique »
#  (chapitre 30 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la dix-septième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 30, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 30.1 `reponderation_sous_encadrement` : intégrité de la
#       repondération (poids renormalisés, support conservé), respect de la
#       formule `1 + performance[k]`, contrôle d'encadrement de l'objectif
#       affiché, registre, cas limites et rejets ;                              (Categories)
#    3. la fidélité au socle : le résultat n'est que la redistribution σ du
#       support (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch30.jl
# ============================================================================

using Printf
using Kamitique

const S = Kamitique.Socle
const D = Kamitique.Dispositif
const K = Kamitique.Categories

# ----------------------------------------------------------------------------
#  Instrumentation du rapport
# ----------------------------------------------------------------------------

const _RESULTATS = Tuple{String,String,Bool}[]
const _sec = Ref("—")
const _ok  = Ref(0)
const _tot = Ref(0)

"""Ouvre une section du rapport."""
function section(titre::AbstractString)
    _sec[] = titre
    println("\n", "━"^70)
    println("▶ ", titre)
end

"""Consigne un contrôle (nom, verdict) et l'affiche."""
function verifier(nom::AbstractString, cond::Bool)
    _tot[] += 1
    cond && (_ok[] += 1)
    push!(_RESULTATS, (_sec[], String(nom), cond))
    @printf("  [%s] %s\n", cond ? "✓" : "✗", nom)
    return cond
end

"""Vérifie qu'un appel échoue proprement (rejet attendu)."""
function rejette(nom::AbstractString, f)
    ok = false
    try
        f()
    catch e
        ok = e isa ArgumentError || e isa KeyError || e isa BoundsError
    end
    return verifier(nom, ok)
end

# ----------------------------------------------------------------------------
#  Fixtures — situées, bornées, reproductibles
# ----------------------------------------------------------------------------

"""État à trois exemples en degrés : `a` en conflit avec `b` et `c`, `b` et `c` cohabitants."""
etat_apprentissage() = S.Etat([S.Figure([:a]), S.Figure([:b]), S.Figure([:c])], [0.2, 0.4, 0.4])

"""Compatibilité d'apprentissage : κ = 1 à l'identique et entre `b` et `c`, 0,2 dès que `a` est en jeu."""
const _MU_APPRENTISSAGE = Dict((:b, :c) => 1.0)
kappa_apprentissage(g::S.Figure, hh::S.Figure) =
    only(g.sites) == only(hh.sites) ? 1.0 :
    get(_MU_APPRENTISSAGE, (min(only(g.sites), only(hh.sites)), max(only(g.sites), only(hh.sites))), 0.2)

"""Harmonie recalculée indépendamment : double somme Σ_i Σ_j αᵢ αⱼ κ(i, j), bornée à [0, 1]."""
function harmonie_recalculee(Ψ::S.Etat, h::S.Harmonie)
    s = 0.0
    for i in eachindex(Ψ.figures), j in eachindex(Ψ.figures)
        s += Ψ.poids[i] * Ψ.poids[j] *
             clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
    end
    return clamp(s, 0.0, 1.0)
end

"""Poids repondérés recalculés indépendamment : α · (1 + performance), renormalisé."""
function reponderation_recalee(Ψ::S.Etat, performance::Vector{Float64})
    facteurs = 1.0 .+ performance
    brut = Ψ.poids .* facteurs
    return brut ./ sum(brut)
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 17 : Apprentissage automatique\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 30) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[17]
verifier("dix-septième entrée de la carte = « Apprentissage automatique »",
         cat.nom == "Apprentissage automatique")
verifier("chapitre 30 consigné", cat.chapitre == 30)
verifier("trois problèmes attestés (supervisé, non supervisé, renforcement)",
         cat.problemes == ["supervisé", "non supervisé", "renforcement"])
verifier("méthode consignée (repondération sous encadrement)",
         "repondération sous encadrement" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Apprentissage").chapitre == 30)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Apprentissage automatique") &&
         all(haskey(cov["Apprentissage automatique"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 30.1 — reponderation_sous_encadrement
# ----------------------------------------------------------------------------
section("2. Méthode 30.1 — reponderation_sous_encadrement : intégrité, encadrement, rejets")

Ψa = etat_apprentissage()
ha = S.Harmonie(kappa_apprentissage)
perf = [2.0, 0.0, 0.0]                     # on pousse l'exemple en conflit `a`
rap = K.reponderation_sous_encadrement(Ψa, perf, ha)

verifier("le rapport porte un état repondéré (RapportReponderation de type Etat)",
         rap.initiale isa S.Etat && rap.finale isa S.Etat)
verifier("support conservé (mêmes figures, dans le même ordre)",
         rap.finale.figures == Ψa.figures && rap.initiale.figures == Ψa.figures)
verifier("l'état initial est inchangé (aucune altération du support de départ)",
         rap.initiale.poids == Ψa.poids)
verifier("poids renormalisés : Σ α = 1", isapprox(sum(rap.finale.poids), 1.0; atol = 1e-12))
verifier("poids de présence positifs ou nuls", all(>(-1e-12), rap.finale.poids))
verifier("respect de la formule : α_final ∝ α_initial · (1 + performance[k]) (recalcul indépendant)",
         isapprox(rap.finale.poids, reponderation_recalee(Ψa, perf); atol = 1e-12))
verifier("harmonie initiale = double somme Σ_i Σ_j αᵢ αⱼ κ(i, j) (recalculée)",
         isapprox(rap.harmonie_initiale, harmonie_recalculee(rap.initiale, ha); atol = 1e-12))
verifier("harmonie finale = double somme Σ_i Σ_j αᵢ αⱼ κ(i, j) (recalculée)",
         isapprox(rap.harmonie_finale, harmonie_recalculee(rap.finale, ha); atol = 1e-12))
verifier("harmonies rendues dans [0, 1]",
         0.0 <= rap.harmonie_initiale <= 1.0 && 0.0 <= rap.harmonie_finale <= 1.0)

# OBJECTIF AFFICHÉ : « la repondération est admise seulement si l'harmonie µ de
# l'état ne décroît pas » ; « le rapport dit si l'encadrement est respecté — la
# performance seule ne suffit pas à trancher ».
verifier("objectif d'encadrement : verdict = (µ_final ≥ µ_initial − tolérance)",
         rap.encadrement_respecte == (rap.harmonie_finale >= rap.harmonie_initiale - 1e-9))
verifier("performance positive mais harmonie décroissante ⇒ encadrement NON respecté (la performance seule ne tranche pas)",
         sum(perf) > 0.0 && !rap.encadrement_respecte)
@printf("      performance %s ⇒ µ %.6f → %.6f ; encadrement respecté = %s\n",
        perf, rap.harmonie_initiale, rap.harmonie_finale, rap.encadrement_respecte)

perf_neg = [-0.5, 0.0, 0.0]                # on réduit l'exemple en conflit `a`
rap_neg = K.reponderation_sous_encadrement(Ψa, perf_neg, ha)
verifier("performance négative mais harmonie croissante ⇒ encadrement respecté (la performance seule ne tranche pas)",
         sum(perf_neg) < 0.0 && rap_neg.encadrement_respecte &&
         rap_neg.harmonie_finale >= rap_neg.harmonie_initiale - 1e-9)
@printf("      performance %s ⇒ µ %.6f → %.6f ; encadrement respecté = %s\n",
        perf_neg, rap_neg.harmonie_initiale, rap_neg.harmonie_finale, rap_neg.encadrement_respecte)

# registre / show
vue_non_encadre = sprint(show, rap)        # `rap` : µ décroît ⇒ non encadré
vue_encadre     = sprint(show, rap_neg)    # `rap_neg` : µ croît ⇒ encadré
verifier("registre consigné : le show nomme le type et flèche µ_initial → µ_final",
         occursin("RapportReponderation", vue_encadre) && occursin("→", vue_encadre))
verifier("le show signale l'encadrement (« non encadré » / « encadré »)",
         occursin("non encadré", vue_non_encadre) &&
         occursin("encadré", vue_encadre) && !occursin("non encadré", vue_encadre))

# reproductibilité / déterminisme
rap_bis = K.reponderation_sous_encadrement(Ψa, perf, ha)
verifier("repondération déterministe (même entrée ⇒ mêmes poids et même verdict)",
         rap_bis.finale.poids == rap.finale.poids &&
         rap_bis.encadrement_respecte == rap.encadrement_respecte)

# cas limites
rap_nul = K.reponderation_sous_encadrement(Ψa, [0.0, 0.0, 0.0], ha)
verifier("cas limite (performance nulle) : identité admissible (poids et harmonie inchangés)",
         rap_nul.finale.poids == Ψa.poids &&
         isapprox(rap_nul.harmonie_finale, rap_nul.harmonie_initiale; atol = 1e-12) &&
         rap_nul.encadrement_respecte)
rap_neg_u = K.reponderation_sous_encadrement(Ψa, [-0.5, -0.5, -0.5], ha)
verifier("cas limite (performance négative uniforme) : facteur constant ⇒ identité renormalisée admissible",
         isapprox(rap_neg_u.finale.poids, Ψa.poids; atol = 1e-12) && rap_neg_u.encadrement_respecte)

rejette("une performance par exemple exigée (vecteur trop court)",
        () -> K.reponderation_sous_encadrement(Ψa, [1.0], ha))
rejette("une performance par exemple exigée (vecteur trop long)",
        () -> K.reponderation_sous_encadrement(Ψa, [1.0, 0.0, 0.0, 0.0], ha))

# ----------------------------------------------------------------------------
#  3. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("3. Fidélité au socle et reproductibilité (G5)")

base = S.redistribuer(Ψa, 1.0 .+ perf)
verifier("G5 : le résultat n'est que S.redistribuer(Ψ, 1 + performance) du socle (support conservé)",
         rap.finale.figures == base.figures)
verifier("G5 : le résultat n'est que S.redistribuer(Ψ, 1 + performance) du socle (poids identiques)",
         isapprox(rap.finale.poids, base.poids; atol = 1e-12))
verifier("G5 : les harmonies rendues sont des lectures de κ (aucun chiffre inventé)",
         isapprox(rap.harmonie_initiale, harmonie_recalculee(rap.initiale, ha); atol = 1e-12) &&
         isapprox(rap.harmonie_finale, harmonie_recalculee(rap.finale, ha); atol = 1e-12))

# ----------------------------------------------------------------------------
#  4. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 17 (ch. 30) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 17 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 17.")
println("="^70)
