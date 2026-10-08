# ============================================================================
#  Benchmark de conformité — catégorie 6 : « Calcul haute performance »
#  (chapitre 19 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la sixième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 19, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 19.1 `execution_par_harmonie` : affectation complète,
#       regroupement par compatibilité µ cumulée, harmonie totale intra-worker,
#       registre, cas limites et rejets ;                                        (Categories)
#    3. la méthode 19.2 `reponderation_sous_charge` : gain net = gain − coût de
#       trajet, seuil de rentabilité, voies écartées consignées, registre, cas
#       limites et rejets ;                                                      (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch19.jl
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

"""État à quatre figures en deux grappes A = {a1,a2}, B = {b1,b2} (poids égaux)."""
etat_grappes() = S.Etat([S.Figure([:a1]), S.Figure([:a2]), S.Figure([:b1]), S.Figure([:b2])],
                        [0.25, 0.25, 0.25, 0.25])

"""Compatibilité de grappes : κ = 1 à l'intérieur d'une grappe, 0,1 entre grappes."""
const _MU_GRAPPES = Dict((:a1, :a2) => 1.0, (:b1, :b2) => 1.0)
kappa_grappes(g::S.Figure, hh::S.Figure) =
    only(g.sites) == only(hh.sites) ? 1.0 :
    get(_MU_GRAPPES, (min(only(g.sites), only(hh.sites)), max(only(g.sites), only(hh.sites))), 0.1)

"""Harmonie totale recalculée à partir de l'affectation : somme des κ intra-worker."""
function harmonie_intra(aff::Vector{Int}, Ψ::S.Etat, h::S.Harmonie)
    total = 0.0
    for w in unique(aff)
        idx = findall(==(w), aff)
        for x in 1:length(idx), y in (x + 1):length(idx)
            total += clamp(float(h.compatibilite(Ψ.figures[idx[x]], Ψ.figures[idx[y]])), 0.0, 1.0)
        end
    end
    return total
end

"""
    respecte_regle_harmonie(aff, Ψ, h, workers) -> Bool

Vrai si chaque figure a été affectée au worker **non saturé** où la compatibilité
**cumulée** avec les figures **déjà placées** est maximale (à égalité, le plus petit
indice), la charge d'un worker étant bornée à `⌈n / workers⌉` — la règle même de la
méthode 19.1, recalculée indépendamment.
"""
function respecte_regle_harmonie(aff::Vector{Int}, Ψ::S.Etat, h::S.Harmonie, workers::Int)
    n = length(Ψ.figures)
    capacite = cld(n, workers)
    charge = zeros(Int, workers)
    att = zeros(Int, n)
    for i in 1:n
        meilleur = 0
        meilleure_coh = -1.0
        for w in 1:workers
            charge[w] >= capacite && continue     # worker saturé : hors de la pesée
            coh = 0.0
            for j in 1:(i - 1)
                att[j] == w || continue
                coh += clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
            end
            if coh > meilleure_coh
                meilleure_coh = coh
                meilleur = w
            end
        end
        att[i] = meilleur
        charge[meilleur] += 1
    end
    return att == aff
end

"""Gains bruts attendus d'une repondération : gain net = gain − coût pour chaque voie."""
gain_net(gains::Vector{Float64}, couts::Vector{Float64}; tolerance::Real = 0.0) =
    Float64[float(gains[k]) - float(couts[k]) for k in eachindex(gains)]

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 6 : Calcul haute performance\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 19) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[6]
verifier("sixième entrée de la carte = « Calcul haute performance »",
         cat.nom == "Calcul haute performance")
verifier("chapitre 19 consigné", cat.chapitre == 19)
verifier("trois problèmes attestés (partitionnement, communications, équilibrage)",
         cat.problemes == ["partitionnement", "communications", "équilibrage"])
verifier("méthodes consignées (grille de pesée, exécution par harmonie)",
         "grille de pesée" in cat.methodes && "exécution par harmonie" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("haute performance").chapitre == 19)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Calcul haute performance") &&
         all(haskey(cov["Calcul haute performance"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 19.1 — execution_par_harmonie
# ----------------------------------------------------------------------------
section("2. Méthode 19.1 — execution_par_harmonie : regroupement et harmonie intra-worker")

Ψg = etat_grappes()
hg = S.Harmonie(kappa_grappes)
gr = K.execution_par_harmonie(Ψg, hg; workers = 2)

verifier("affectation complète (une unité par figure)", length(gr) == 4 && length(gr.affectation) == 4)
verifier("affectations bornées dans 1..workers", all(w -> 1 <= w <= 2, gr.affectation))
verifier("règle de regroupement respectée (chaque figure rejoint le worker de compatibilité cumulée maximale)",
         respecte_regle_harmonie(gr.affectation, Ψg, hg, 2))
verifier("harmonie totale = somme des κ intra-worker (recalculée)",
         isapprox(gr.harmonie, harmonie_intra(gr.affectation, Ψg, hg); atol = 1e-12))
verifier("harmonie totale dans [0, n(n−1)/2]",
         0.0 <= gr.harmonie <= 6.0)
verifier("registre consigné (entête + une ligne par figure + harmonie totale)",
         length(gr.registre) == 6 && occursin("harmonie totale intra-worker", gr.registre[end]))
verifier("exécution déterministe (même entrée ⇒ même affectation)",
         K.execution_par_harmonie(Ψg, hg; workers = 2).affectation == gr.affectation)

# OBJECTIF AFFICHÉ : « en regroupant celles dont la compatibilité µ est haute »
verifier("objectif de regroupement : les deux figures de la grappe A partagent un worker",
         gr.affectation[1] == gr.affectation[2])
verifier("objectif de regroupement : les deux figures de la grappe B partagent un worker",
         gr.affectation[3] == gr.affectation[4])
@printf("      affectation réelle (workers = 2) : %s ; workers occupés = %s\n",
        gr.affectation, sort(unique(gr.affectation)))
verifier("objectif de regroupement : l'harmonie intra-worker couvre les deux grappes (≥ 2,0)",
         gr.harmonie >= 2.0 - 1e-12)

# OBJECTIF DÉCLARÉ : répartition équilibrée (chaque worker au plus ⌈n / workers⌉ figures)
verifier("objectif de répartition : les 2 workers sont occupés pour 4 figures et 2 workers",
         length(unique(gr.affectation)) == 2)
@printf("      affectation réelle (workers = 4) : %s ; workers occupés = %s\n",
        K.execution_par_harmonie(Ψg, hg; workers = 4).affectation,
        sort(unique(K.execution_par_harmonie(Ψg, hg; workers = 4).affectation)))
verifier("objectif de répartition : les 4 workers sont occupés pour 4 figures et 4 workers",
         length(unique(K.execution_par_harmonie(Ψg, hg; workers = 4).affectation)) == 4)

# OBJECTIF AFFICHÉ : « L'harmonie totale rendue est la somme des compatibilités intra-worker »
verifier("objectif d'harmonie : aucune compatibilité inter-worker n'entre dans le total",
         isapprox(gr.harmonie,
                  sum(clamp(float(kappa_grappes(Ψg.figures[i], Ψg.figures[j])), 0.0, 1.0)
                      for i in 1:4 for j in (i + 1):4 if gr.affectation[i] == gr.affectation[j]);
                  atol = 1e-12))

# cas limites et rejets
gr1 = K.execution_par_harmonie(S.Etat([S.Figure([:a1])], [1.0]), hg; workers = 3)
verifier("cas n = 1 : une figure, worker 1, harmonie 0,0 (aucune paire)",
         gr1.affectation == [1] && gr1.harmonie == 0.0 && length(gr1.registre) == 3)
grs = K.execution_par_harmonie(Ψg, hg; workers = 1)
verifier("cas workers = 1 : toutes les figures sur l'unique worker",
         grs.affectation == [1, 1, 1, 1])
rejette("grille à zéro worker refusée", () -> K.execution_par_harmonie(Ψg, hg; workers = 0))
rejette("grille à worker négatif refusée", () -> K.execution_par_harmonie(Ψg, hg; workers = -1))

# ----------------------------------------------------------------------------
#  3. Méthode 19.2 — reponderation_sous_charge
# ----------------------------------------------------------------------------
section("3. Méthode 19.2 — reponderation_sous_charge : gain net et seuil de rentabilité")

gains = [3.0, 2.0, 0.5]
couts = [1.0, 0.5, 1.0]
rc = K.reponderation_sous_charge(gains, couts)
net = gain_net(gains, couts)

verifier("retenues ⊂ voies", all(k -> 1 <= k <= 3, rc.retenues))
verifier("règle de rentabilité : voie retenue ssi gain net > 0 (recalculée)",
         rc.retenues == findall(>(0.0), net))
verifier("gain net total = somme des gains nets retenus (recalculé)",
         isapprox(rc.gain_net, sum(net[k] for k in eachindex(net) if net[k] > 0.0); atol = 1e-12))
verifier("repondere = au moins une voie retenue", rc.repondere == !isempty(rc.retenues))
verifier("registre consigné (entête + une ligne par voie)", length(rc.registre) == 4)

# OBJECTIF AFFICHÉ : « la voie n'est retenue que si le gain net dépasse tolerance »
verifier("objectif : la 3ᵉ voie (gain net négatif) est écartée et consignée",
         !(3 in rc.retenues) &&
         any(l -> occursin("voie 3", l) && occursin("écartée", l), rc.registre))
verifier("objectif « pesée avant paiement » : gain net = gain − coût de trajet exactement",
         isapprox(rc.gain_net, (gains[1] - couts[1]) + (gains[2] - couts[2]); atol = 1e-12))
@printf("      gains %s · coûts %s ⇒ voies retenues %s ; gain net %.4f\n",
        gains, couts, rc.retenues, rc.gain_net)

# seuil et frontière
rc_seuil = K.reponderation_sous_charge(gains, couts; tolerance = 1.6)
verifier("tolerance : seule la voie au gain net > 1,6 est retenue", rc_seuil.retenues == [1])
@printf("      tolerance 1,6 ⇒ voies retenues %s (gain net %.4f)\n",
        rc_seuil.retenues, rc_seuil.gain_net)
rc_front = K.reponderation_sous_charge([1.0], [0.0]; tolerance = 1.0)
verifier("frontière : gain net = tolerance ⇒ voie écartée (inégalité stricte)",
         isempty(rc_front.retenues) && rc_front.gain_net == 0.0 && !rc_front.repondere)

# reproductibilité
verifier("repondération déterministe (même entrée ⇒ mêmes retenues et même gain net)",
         (r2 = K.reponderation_sous_charge(gains, couts);
          r2.retenues == rc.retenues && r2.gain_net == rc.gain_net))

# cas limites et rejets
rejette("un gain et un coût par voie exigés",
        () -> K.reponderation_sous_charge([1.0, 2.0], [1.0]))
rejette("aucune voie à peser refusée",
        () -> K.reponderation_sous_charge(Float64[], Float64[]))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("l'exécution ne fait que lire κ (harmonie recalculée à l'identique)",
         isapprox(gr.harmonie, harmonie_intra(gr.affectation, Ψg, hg); atol = 1e-12))
verifier("la repondération ne fait que lire gains et coûts (aucun chiffre inventé)",
         K.reponderation_sous_charge(gains, couts).gain_net ==
         (gains[1] - couts[1]) + (gains[2] - couts[2]))
verifier("exécution reproductible (même entrée ⇒ même affectation et même harmonie)",
         (e1 = K.execution_par_harmonie(Ψg, hg; workers = 2);
          e2 = K.execution_par_harmonie(Ψg, hg; workers = 2);
          e1.affectation == e2.affectation && e1.harmonie == e2.harmonie))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 6 (ch. 19) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 6 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 6.")
println("="^70)
