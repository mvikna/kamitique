# ============================================================================
#  Benchmark de conformité — catégorie 5 : « Calcul scientifique »
#  (chapitre 18 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la cinquième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 18, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 18.1 `resolution_par_descente` : intégrité de l'éventail,
#       règle de raffinement (la cellule la plus en désaccord), registre, cas
#       limites et rejets ;                                                       (Categories)
#    3. la méthode 18.2 `convergence_par_harmonisation` : montée gouvernée de µ
#       (µ ne décroît pas), convergence sous tolérance, registre, cas limites
#       et rejets ;                                                              (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch18.jl
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

"""Éventail de discrétisation : désaccord concentré sur la cellule 1 (1,0 · 0,0 · 0,0)."""
eventail() = [1.0, 0.0, 0.0]

"""État à deux cellules sous le seuil : aucune subdivision nécessaire."""
eventail_calme() = [0.1, 0.1]

"""État à quatre cellules disjointes (poids décroissants) — éventail de discrétisation."""
etat_cellules() = S.Etat([S.Figure([:c1]), S.Figure([:c2]), S.Figure([:c3]), S.Figure([:c4])],
                         [0.4, 0.3, 0.2, 0.1])

"""Compatibilité de cellules : κ = 1 sur une cellule, 0,5 entre deux cellules distinctes."""
kappa_cellules(g::S.Figure, hh::S.Figure) =
    only(g.sites) == only(hh.sites) ? 1.0 : 0.5

# --- contrôle de la règle de descente (méthode 18.1) -----------------------

"""
    descente_recalee(residus; seuil, max_iter) -> (subdivisions, residu, iterations)

Recalcule **indépendamment** la descente de raffinement de la méthode 18.1 : on
raffine itérativement (division par deux) la cellule dont le résidu est le plus
élevé, la cellule d'indice le plus petit l'emportant à égalité, jusqu'à ce que le
résidu maximal passe sous `seuil` ou après `max_iter` itérations.
"""
function descente_recalee(residus::AbstractVector{<:Real}; seuil::Real = 1e-6,
                          max_iter::Integer = 64)
    r = Float64[abs(float(x)) for x in residus]
    subdivisions = ones(Int, length(r))
    iterations = 0
    while maximum(r) > seuil && iterations < max_iter
        i = argmax(r)
        r[i] = r[i] / 2
        subdivisions[i] += 1
        iterations += 1
    end
    return subdivisions, maximum(r), iterations
end

# --- contrôle de la règle d'harmonisation (méthode 18.2) -------------------

"""
    harmonisation_recalee(Ψ, h; tolerance, max_iter) -> (avant, apres, converge, iterations)

Recalcule **indépendamment** la convergence par harmonisation gouvernée de la
méthode 18.2 : repondération itérative de la présence vers les figures les plus
cohérentes (`1 + 0,5·coh`), jusqu'à ce que l'harmonie ne progresse plus de plus de
`tolerance` ou après `max_iter` itérations.
"""
function harmonisation_recalee(Ψ::S.Etat, h::S.Harmonie; tolerance::Real = 1e-3,
                               max_iter::Integer = 64)
    courant = Ψ
    h0 = float(h(courant))
    iterations = 0
    converge = false
    while iterations < max_iter
        n = length(courant.figures)
        coh = zeros(n)
        for i in 1:n
            c = 0.0
            for j in 1:n
                courant.poids[j] == 0 && continue
                c += courant.poids[j] *
                     clamp(float(h.compatibilite(courant.figures[i], courant.figures[j])),
                           0.0, 1.0)
            end
            coh[i] = c
        end
        hprev = float(h(courant))
        courant = S.redistribuer(courant, 1.0 .+ 0.5 .* coh)
        hnew = float(h(courant))
        iterations += 1
        if abs(hnew - hprev) < tolerance
            converge = true
            break
        end
    end
    return h0, float(h(courant)), converge, iterations
end

"""Harmonie analytique de `mu = 0,5 + 0,5·Σαᵢ²` pour κ = 1 (diagonale) et 0,5 (hors diagonale)."""
harmonie_analytique(Ψ::S.Etat) = 0.5 + 0.5 * sum(abs2, Ψ.poids)

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 5 : Calcul scientifique\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 18) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[5]
verifier("cinquième entrée de la carte = « Calcul scientifique »",
         cat.nom == "Calcul scientifique")
verifier("chapitre 18 consigné", cat.chapitre == 18)
verifier("trois problèmes attestés (discrétisation, solveurs, estimation d'erreur)",
         cat.problemes == ["discrétisation", "solveurs", "estimation d'erreur"])
verifier("méthodes consignées (éventail de discrétisation, résolution par descente de raffinement)",
         "éventail de discrétisation" in cat.methodes &&
         "résolution par descente de raffinement" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Calcul scientifique").chapitre == 18)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Calcul scientifique") &&
         all(haskey(cov["Calcul scientifique"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 18.1 — resolution_par_descente
# ----------------------------------------------------------------------------
section("2. Méthode 18.1 — resolution_par_descente : intégrité, raffinement situé, registre")

η = eventail()
rd = K.resolution_par_descente(η; seuil = 0.25)

verifier("intégrité : une subdivision par cellule de l'éventail",
         length(rd.subdivisions) == length(η))
verifier("intégrité : résidu maximal rendu ≥ 0", rd.residu >= 0.0)
verifier("intégrité : registre consigné (entête, descente, résidu)",
         length(rd.registre) == 3)

sub, res, it = descente_recalee(η; seuil = 0.25, max_iter = 64)
verifier("règle de descente respectée (subdivisions recalculées indépendamment)",
         rd.subdivisions == sub)
verifier("règle de descente respectée (résidu maximal recalculé)",
         isapprox(rd.residu, res; atol = 1e-12) && rd.iterations == it)

# OBJECTIF AFFICHÉ : « raffine la cellule dont le résidu est le plus élevé — non uniformément »
verifier("objectif de raffinement situé : la cellule la plus en désaccord est la plus raffinée",
         argmax(abs.(η)) == 1 && rd.subdivisions[1] == maximum(rd.subdivisions) &&
         rd.subdivisions[1] > 1)
verifier("objectif de raffinement situé : les cellules déjà sous le seuil restent intactes",
         rd.subdivisions[2] == 1 && rd.subdivisions[3] == 1)
@printf("      éventail %s ⇒ subdivisions %s ; résidu maximal %.4g ; %d itération(s)\n",
        η, rd.subdivisions, rd.residu, rd.iterations)

η2 = [0.0, 1.0, 0.0]
rd2 = K.resolution_par_descente(η2; seuil = 0.25)
verifier("objectif de raffinement situé : c'est bien la cellule au plus fort résidu qui est raffinée",
         argmax(abs.(η2)) == 2 && rd2.subdivisions == [1, 3, 1])

verifier("registre détaillé (éventail, descente, résidu maximal)",
         occursin("éventail", rd.registre[1]) &&
         occursin("descente de raffinement", rd.registre[2]) &&
         occursin("résidu maximal", rd.registre[3]))
verifier("descente déterministe (même entrée ⇒ mêmes subdivisions et résidu)",
         K.resolution_par_descente(η; seuil = 0.25).subdivisions == rd.subdivisions &&
         K.resolution_par_descente(η; seuil = 0.25).residu == rd.residu)

# cas limites et rejets
rd_calme = K.resolution_par_descente(eventail_calme(); seuil = 0.25)
verifier("cas limite : éventail déjà sous le seuil ⇒ aucune itération, subdivisions unitaires",
         rd_calme.iterations == 0 && rd_calme.subdivisions == [1, 1] &&
         isapprox(rd_calme.residu, 0.1; atol = 1e-12))
rd_neg = K.resolution_par_descente([-1.0, 0.0]; seuil = 0.25)
verifier("cas limite : résidus ramenés en valeur absolue (traitement identique)",
         rd_neg.subdivisions == [3, 1] && isapprox(rd_neg.residu, 0.25; atol = 1e-12))
rd_court = K.resolution_par_descente([1.0]; seuil = 0.0, max_iter = 3)
verifier("cas limite : borne d'itérations respectée (max_iter = 3 ⇒ résidu non nul)",
         rd_court.iterations == 3 && rd_court.subdivisions == [4] &&
         isapprox(rd_court.residu, 0.125; atol = 1e-12))
rejette("éventail vide refusé", () -> K.resolution_par_descente(Float64[]))

# ----------------------------------------------------------------------------
#  3. Méthode 18.2 — convergence_par_harmonisation
# ----------------------------------------------------------------------------
section("3. Méthode 18.2 — convergence_par_harmonisation : montée gouvernée de µ")

Ψ = etat_cellules()
h = S.Harmonie(kappa_cellules)
rh = K.convergence_par_harmonisation(Ψ, h)

verifier("intégrité : harmonie avant et après dans l'ordre M ([0, 1])",
         0.0 <= rh.harmonie_avant <= 1.0 && 0.0 <= rh.harmonie_apres <= 1.0)
verifier("intégrité : le verdict de convergence est un booléen", rh.converge isa Bool)
verifier("intégrité : registre consigné (entête, itérations, verdict)",
         length(rh.registre) == 3)

avant, apres, conv, its = harmonisation_recalee(Ψ, h)
verifier("règle d'harmonisation respectée (harmonie avant et après recalculées)",
         isapprox(rh.harmonie_avant, avant; atol = 1e-12) &&
         isapprox(rh.harmonie_apres, apres; atol = 1e-12) && rh.converge == conv)

# OBJECTIF AFFICHÉ : « la gouverne est respectée : µ ne décroît pas »
verifier("objectif affiché : µ ne décroît pas (harmonie après ≥ harmonie avant)",
         rh.harmonie_apres >= rh.harmonie_avant - 1e-12)
verifier("objectif affiché : la montée est effective sur cet éventail (µ croît)",
         rh.harmonie_apres > rh.harmonie_avant)
@printf("      µ avant %.4f → µ après %.4f ; convergence = %s ; %d itération(s)\n",
        rh.harmonie_avant, rh.harmonie_apres, rh.converge, its)

verifier("registre détaillé (harmonisation gouvernée + verdict)",
         occursin("harmonisation gouvernée", rh.registre[1]) &&
         (occursin("convergence atteinte", rh.registre[3]) ||
          occursin("limite d'itérations atteinte", rh.registre[3])))
verifier("harmonisation déterministe (même entrée ⇒ même harmonie finale et même verdict)",
         (r2 = K.convergence_par_harmonisation(Ψ, h);
          isapprox(r2.harmonie_apres, rh.harmonie_apres; atol = 1e-12) && r2.converge == rh.converge))

# cas limites et rejets
rh0 = K.convergence_par_harmonisation(Ψ, h; max_iter = 0)
verifier("cas limite : max_iter = 0 ⇒ aucune itération, µ inchangée, non convergée",
         isapprox(rh0.harmonie_apres, rh0.harmonie_avant; atol = 1e-12) &&
         !rh0.converge && occursin("limite d'itérations atteinte", rh0.registre[3]))
rh_large = K.convergence_par_harmonisation(Ψ, h; tolerance = 10.0)
verifier("cas limite : tolérance large ⇒ convergence dès la première itération",
         rh_large.converge)
Ψ1 = S.Etat([S.Figure([:c1])], [1.0])
rh1 = K.convergence_par_harmonisation(Ψ1, h)
verifier("cas limite : état d'une seule figure, déjà harmonieux (µ = 1, à point fixe)",
         isapprox(rh1.harmonie_apres, 1.0; atol = 1e-12) && rh1.converge)
rejette("un état vide est refusé avant l'harmonisation (garde du socle)",
        () -> K.convergence_par_harmonisation(S.Etat(S.Figure[], Float64[]), h))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("la descente ne fait que lire l'éventail (aucune subdivision inventée)",
         K.resolution_par_descente(η; seuil = 0.25).subdivisions == descente_recalee(η; seuil = 0.25)[1])
verifier("l'harmonisation ne fait que lire κ (µ initiale = formule analytique de κ)",
         isapprox(h(Ψ), harmonie_analytique(Ψ); atol = 1e-12))
verifier("aucune méthode de la catégorie n'altère un chiffre consigné de κ (résultats = lecture de κ)",
         (res1 = K.resolution_par_descente(η; seuil = 0.25);
          res2 = K.resolution_par_descente(η; seuil = 0.25);
          isapprox(res1.residu, res2.residu; atol = 1e-12) &&
          isapprox(rh.harmonie_apres, harmonisation_recalee(Ψ, h)[2]; atol = 1e-12)))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 5 (ch. 18) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 5 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 5.")
println("="^70)
