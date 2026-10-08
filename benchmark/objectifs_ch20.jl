# ============================================================================
#  Benchmark de conformité — catégorie 7 : « Informatique quantique »
#  (chapitre 20 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la septième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 20, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 20.1 `calcul_par_superposition` : pesée des branches (score
#       λ·cohérence + (1−λ)·valuation), mesure d'un degré avec sa branche et non
#       d'un bit avec une adresse, registre, cas limites et rejets ;             (Categories)
#    3. la méthode 20.2 `correction_par_harmonisation` : branche la moins
#       cohérente repondérée à la baisse et renormalisée, gouverne (µ non
#       décroissante), registre, cas limites et rejets ;                         (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch20.jl
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

"""État à quatre branches `[:a]`—`[:d]` de poids décroissants (0,4 · 0,3 · 0,2 · 0,1)."""
etat_branches() = S.Etat([S.Figure([:a]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])],
                         [0.4, 0.3, 0.2, 0.1])

"""Question de mesure « proche de A » : seule la branche `[:a]` la porte."""
question_proche_a() = S.Question(:proche, S.Proposition("proche de A", f -> :a in f.sites))

"""Harmonie du socle : cohérence de l'emboîtement par le raffinement ≺."""
harmonie_socle() = S.HarmonieRaffinement()

# --- contrôle de la pesée (méthode 20.1) ------------------------------------

"""
    valuation_moyenne(f, q) -> Float64

Valuation moyenne d'une figure sur les propositions de `q` (1,0 si le faisceau est vide),
recalcul indépendant de la valuation portée par une branche candidate.
"""
function valuation_moyenne(f::S.Figure, q::S.Question)
    isempty(q.propositions) && return 1.0
    return sum(clamp(float(p.verdict(f)), 0.0, 1.0) for p in q.propositions) / length(q.propositions)
end

"""
    scores_recales(Ψ, q, h; λ = 0.5) -> Vector{Float64}

Recalcul indépendant du score de pesée : `(1−λ)·ν_moyen + λ·cohérence`, borné à `M = [0, 1]`.
"""
function scores_recales(Ψ::S.Etat, q::S.Question, h::S.Harmonie; λ::Real = 0.5)
    ν = Float64[valuation_moyenne(f, q) for f in Ψ.figures]
    coh = coherence_branches(Ψ, h)
    return clamp.((1 - λ) .* ν .+ λ .* coh, 0.0, 1.0)
end

# --- contrôle de la correction (méthode 20.2) -------------------------------

"""
    coherence_branches(Ψ, h) -> Vector{Float64}

Cohérence de chaque branche avec le reste de la présence : `Σ_j α_j · κ(figure_i, figure_j)`,
les poids nuls étant ignorés — la quantité même dont la méthode 20.2 prend le minimum.
"""
function coherence_branches(Ψ::S.Etat, h::S.Harmonie)
    n = length(Ψ.figures)
    coh = zeros(n)
    for i in 1:n
        c = 0.0
        for j in 1:n
            Ψ.poids[j] == 0 && continue
            c += Ψ.poids[j] * clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
        end
        coh[i] = c
    end
    return coh
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 7 : Informatique quantique\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 20) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[7]
verifier("septième entrée de la carte = « Informatique quantique »",
         cat.nom == "Informatique quantique")
verifier("chapitre 20 consigné", cat.chapitre == 20)
verifier("quatre problèmes attestés (superposition, intrication, mesure, correction)",
         cat.problemes == ["superposition", "intrication", "mesure", "correction"])
verifier("méthodes consignées (pesée quantique, correction par harmonisation)",
         "pesée quantique" in cat.methodes && "correction par harmonisation" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("quantique").chapitre == 20)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Informatique quantique") &&
         all(haskey(cov["Informatique quantique"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 20.1 — calcul_par_superposition
# ----------------------------------------------------------------------------
section("2. Méthode 20.1 — calcul_par_superposition : pesée des branches, degré mesuré")

Ψ = etat_branches()
q = question_proche_a()
h = harmonie_socle()
mq = K.calcul_par_superposition(Ψ, q, h)

verifier("une branche est retenue (figure du support)", mq.figure !== nothing && mq.figure in Ψ.figures)
verifier("degré mesuré borné dans l'ordre de pesée M ([0, 1])", 0.0 <= mq.degre <= 1.0)

sc = scores_recales(Ψ, q, h)
i_branche = argmax(sc)
verifier("branche retenue = branche de score de pesée maximal (recalculé indépendamment)",
         mq.figure == Ψ.figures[i_branche])
verifier("degré rendu = score de la branche retenue (recalculé indépendamment)",
         isapprox(mq.degre, sc[i_branche]; atol = 1e-12))
verifier("registre consigné (superposition native, pesée, branche retenue)",
         length(mq.registre) == 3)
verifier("calcul déterministe (même entrée ⇒ même branche et même degré)",
         (mq2 = K.calcul_par_superposition(Ψ, q, h);
          mq2.figure == mq.figure && mq2.degre == mq.degre))

# OBJECTIF AFFICHÉ : « on ne coupe pas la superposition, on la pèse … La mesure rend
#                     un degré avec sa branche, non un bit avec une adresse »
verifier("objectif de pesée : la branche retenue est celle que la question atteste (`[a]`)",
         mq.figure == S.Figure([:a]))
verifier("objectif de mesure : le degré est gradué (strictement dans ]0, 1[), non un bit",
         0.0 < mq.degre < 1.0)
@printf("      branches %s · scores de pesée %s\n",
        [f.sites for f in Ψ.figures], round.(sc; digits = 6))
@printf("      branche retenue : %s ; degré mesuré = %.6f\n", mq.figure.sites, mq.degre)

# la pesée est une position dans l'ordre, gouvernée par λ
mq_val = K.calcul_par_superposition(Ψ, q, h; λ = 0.0)   # valuation seule
verifier("pesée gouvernée par λ : à λ = 0, la branche de valuation maximale est retenue",
         mq_val.figure == S.Figure([:a]) &&
         isapprox(mq_val.degre, maximum([valuation_moyenne(f, q) for f in Ψ.figures]); atol = 1e-12))

# cas limites et rejets
rejette("λ hors de [0, 1] refusé (λ = 1,5)",
        () -> K.calcul_par_superposition(Ψ, q, h; λ = 1.5))
rejette("λ négatif refusé (λ = −0,1)",
        () -> K.calcul_par_superposition(Ψ, q, h; λ = -0.1))

# ----------------------------------------------------------------------------
#  3. Méthode 20.2 — correction_par_harmonisation
# ----------------------------------------------------------------------------
section("3. Méthode 20.2 — correction_par_harmonisation : repondération gouvernée")

co = K.correction_par_harmonisation(Ψ, h)

verifier("l'état corrigé est un état du socle", co.corrigee isa S.Etat)
verifier("présence renormalisée (somme des poids = 1)",
         isapprox(sum(co.corrigee.poids), 1.0; atol = 1e-12))
verifier("même support de branches après correction", co.corrigee.figures == Ψ.figures)
verifier("harmonie avant = µ(Ψ) (recalculée)", isapprox(co.harmonie_avant, h(Ψ); atol = 1e-12))
verifier("harmonie après = µ(état corrigé) (recalculée)",
         isapprox(co.harmonie_apres, h(co.corrigee); atol = 1e-12))

coh = coherence_branches(Ψ, h)
i_decoh = argmin(coh)
verifier("branche décohérente = branche de plus faible cohérence au reste (recalculée)",
         occursin("branche $i_decoh", co.registre[1]))
verifier("registre consigné (décohérence localisée, µ avant → après, verdict)",
         length(co.registre) == 3)

# OBJECTIF AFFICHÉ : « on repondère sa présence à la baisse et l'on renormalise »
facteurs = ones(length(Ψ.poids))
facteurs[i_decoh] = 0.5
brut = Ψ.poids .* facteurs
attendu = brut ./ sum(brut)
verifier("objectif : la branche décohérente est repondérée à la baisse (facteur ½) puis renormalisée",
         isapprox(co.corrigee.poids, attendu; atol = 1e-12))
verifier("objectif : la part de la branche décohérente a diminué",
         co.corrigee.poids[i_decoh] < Ψ.poids[i_decoh])
@printf("      branche décohérente : %d (%s) ; cohérences %s\n",
        i_decoh, Ψ.figures[i_decoh].sites, round.(coh; digits = 6))
@printf("      µ : %.6f → %.6f\n", co.harmonie_avant, co.harmonie_apres)

# OBJECTIF AFFICHÉ : « La correction est gouvernée — elle n'est admise que si µ ne décroît pas »
verifier("objectif de gouverne : la correction admet µ non décroissante (µ_après ≥ µ_avant − ε)",
         co.harmonie_apres >= co.harmonie_avant - 1e-9)
verifier("registre : verdict de gouverne consigné (admise / refusée)",
         any(l -> occursin("correction", l) &&
                  (occursin("admise", l) || occursin("refusée", l)), co.registre))
verifier("correction déterministe (même entrée ⇒ même état corrigé)",
         (co2 = K.correction_par_harmonisation(Ψ, h);
          co2.corrigee.poids == co.corrigee.poids && co2.harmonie_apres == co.harmonie_apres))

# cas limite : une seule branche, aucune décohérence localisée
co1 = K.correction_par_harmonisation(S.Etat([S.Figure([:a])], [1.0]), h)
verifier("cas n = 1 : état inchangé, aucune décohérence localisée",
         co1.harmonie_avant == co1.harmonie_apres && length(co1.registre) == 1 &&
         occursin("une seule branche", co1.registre[1]))

# rejets : aucun état incohérent ne peut être présenté à la correction
rejette("état à figures et poids désaccordés refusé",
        () -> S.Etat([S.Figure([:a])], [0.5, 0.5]))
rejette("état vide refusé", () -> S.Etat(S.Figure[], Float64[]))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("la mesure ne fait que lire les scores de pesée du socle (aucun chiffre inventé)",
         isapprox(K.calcul_par_superposition(Ψ, q, h).degre, maximum(scores_recales(Ψ, q, h));
                  atol = 1e-12))
verifier("la correction ne fait que redistribuer la présence (aucune harmonie inventée)",
         (cc = K.correction_par_harmonisation(Ψ, h);
          isapprox(cc.harmonie_apres, h(cc.corrigee); atol = 1e-12)))
verifier("calcul reproductible (même entrée ⇒ même branche, degré et registre)",
         (r1 = K.calcul_par_superposition(Ψ, q, h); r2 = K.calcul_par_superposition(Ψ, q, h);
          r1.figure == r2.figure && r1.degre == r2.degre && r1.registre == r2.registre))
verifier("correction reproductible (même entrée ⇒ même état corrigé et même registre)",
         (c1 = K.correction_par_harmonisation(Ψ, h); c2 = K.correction_par_harmonisation(Ψ, h);
          c1.corrigee.poids == c2.corrigee.poids && c1.registre == c2.registre))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 7 (ch. 20) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 7 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 7.")
println("="^70)
