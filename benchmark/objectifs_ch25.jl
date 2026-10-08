# ============================================================================
#  Benchmark de conformité — catégorie 12 : « Optimisation et recherche
#  opérationnelle » (chapitre 25 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la douzième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 25, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 25.1 `descente_par_harmonisation` : pesée des voies, descente
#       vers l'optimum de Maât, registre, cas limites et rejets ;               (Categories)
#    3. la borne `borne_harmonique` : produit des degrés tranchés et des maxima
#       restants — la borne de Maât d'une branche, jamais un compteur ;          (Categories)
#    4. la méthode 25.2 `elagage_par_pesee` : voies sous le seuil écartées sans
#       être payées, registre, cas limites et rejets ;                           (Categories)
#    5. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch25.jl
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

"""Porteur situé : `a`—`b`—`d`—`c` (voisinage attesté, chaque site localisé)."""
function porteur_voisinages()
    G = S.Porteur()
    S.ajouter_site!(G, :a; lieu = "A", voisins = [:b])
    S.ajouter_site!(G, :b; lieu = "B", voisins = [:a, :d])
    S.ajouter_site!(G, :c; lieu = "C", voisins = [:d])
    S.ajouter_site!(G, :d; lieu = "D", voisins = [:b, :c])
    return G
end

"""État à quatre figures situées, de poids 0,4 / 0,3 / 0,2 / 0,1."""
etat_quatre() = S.Etat([S.Figure([:a]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])],
                       [0.4, 0.3, 0.2, 0.1])

"""Question favorisant la figure portant `a` (valuation 1 pour `[:a]`, 0 sinon)."""
question_proche_a() = S.Question(:proche, S.Proposition("proche de A", f -> :a in f.sites))

"""Harmonie canonique : compatibilité de raffinement `κ`."""
harmonie_canonique() = S.HarmonieRaffinement()

# --- recalculs indépendants des règles de la catégorie 12 -------------------

"""
    descente_recalee(Ψ, q, h; λ, η, max_iter, tolerance) -> (figure, valeur, iterations)

Rejoue la règle énoncée par la méthode 25.1 : peser les voies par `scores_pesee`,
puis repondérer la présence vers la figure d'argmax d'un pas `η`, jusqu'à ce que la
valeur optimale se stabilise (`tolerance`) ou que `max_iter` soit atteint.
"""
function descente_recalee(Ψ::S.Etat, q::S.Question, h::S.Harmonie;
                          λ::Real = 0.5, η::Real = 0.5,
                          max_iter::Integer = 64, tolerance::Real = 1e-4)
    courant = Ψ
    iterations = 0
    precedent = -1.0
    while iterations < max_iter
        sc = S.scores_pesee(courant, q, h; λ = λ)
        i = argmax(sc.scores)
        valeur = sc.scores[i]
        abs(valeur - precedent) < tolerance && return (courant.figures[i], valeur, iterations)
        precedent = valeur
        facteurs = ones(length(courant.figures))
        facteurs[i] = 1.0 + η
        courant = S.redistribuer(courant, facteurs)
        iterations += 1
    end
    sc = S.scores_pesee(courant, q, h; λ = λ)
    i = argmax(sc.scores)
    return (courant.figures[i], sc.scores[i], iterations)
end

"""Recalcul indépendant de la borne harmonique : produit des degrés bornés à [0, 1]."""
function borne_recalee(tranches, maxima_restants)
    b = 1.0
    for d in tranches
        b *= clamp(float(d), 0.0, 1.0)
    end
    for d in maxima_restants
        b *= clamp(float(d), 0.0, 1.0)
    end
    return b
end

"""Recalcul indépendant de l'élagage : retenues = bornes `≥ seuil` (degrés bornés à [0, 1])."""
function elagage_recale(bornes; seuil::Real = 0.5)
    retenues = Int[]; ecartees = Int[]
    for k in eachindex(bornes)
        b = clamp(float(bornes[k]), 0.0, 1.0)
        b >= seuil ? push!(retenues, k) : push!(ecartees, k)
    end
    return retenues, ecartees
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 12 : Optimisation et recherche opérationnelle\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 25) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[12]
verifier("douzième entrée de la carte = « Optimisation et recherche opérationnelle »",
         cat.nom == "Optimisation et recherche opérationnelle")
verifier("chapitre 25 consigné", cat.chapitre == 25)
verifier("trois problèmes attestés (programmes linéaires, combinatoire, voisinages)",
         cat.problemes == ["programmes linéaires", "combinatoire", "voisinages"])
verifier("méthodes consignées (harmonisation, élagage par pesée des voies)",
         "harmonisation" in cat.methodes && "élagage par pesée des voies" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Optimisation").chapitre == 25)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Optimisation et recherche opérationnelle") &&
         all(haskey(cov["Optimisation et recherche opérationnelle"], k)
             for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 25.1 — descente_par_harmonisation
# ----------------------------------------------------------------------------
section("2. Méthode 25.1 — descente_par_harmonisation : pesée des voies, optimum de Maât")

G  = porteur_voisinages()
Ψ  = etat_quatre()
h  = harmonie_canonique()
q  = question_proche_a()

verifier("fixture située : les quatre figures du support sont attestées dans le porteur",
         all(f -> S.verifier_appartenance(G, f), Ψ.figures))

dop = K.descente_par_harmonisation(Ψ, q, h)

verifier("intégrité : la figure optimale appartient au support de l'état",
         dop.figure in Ψ.figures)
verifier("la valeur optimale est un degré de l'ordre M ([0, 1])",
         0.0 <= dop.valeur <= 1.0)
verifier("compteur d'itérations non négatif", dop.iterations >= 0)

# OBJECTIF AFFICHÉ : « la descente converge vers l'optimum de Maât : la présence
# se concentre sur une figure »
sc0   = S.scores_pesee(Ψ, q, h)
best0 = maximum(sc0.scores)
verifier("objectif : la présence se concentre sur la figure portant la question (`a`)",
         dop.figure == S.Figure([:a]))
verifier("objectif : l'optimum atteint n'est pas inférieur au meilleur score initial",
         dop.valeur >= best0 - 1e-12)
@printf("      meilleur score initial = %.6f ⇒ valeur optimale atteinte = %.6f en %d itération(s)\n",
        best0, dop.valeur, dop.iterations)

# respect de la règle énoncée — recalcul indépendant
f_re, v_re, i_re = descente_recalee(Ψ, q, h)
verifier("règle respectée : figure et valeur recalculées à l'identique",
         f_re == dop.figure && isapprox(v_re, dop.valeur; atol = 1e-12))
verifier("nombre d'itérations recalculé à l'identique", i_re == dop.iterations)
verifier("registre consigné (entête + issue)",
         length(dop.registre) == 2 && occursin("optimum atteint", dop.registre[2]))

verifier("descente déterministe (même entrée ⇒ même figure, valeur et itérations)",
         (dop2 = K.descente_par_harmonisation(Ψ, q, h);
          dop2.figure == dop.figure && dop2.valeur == dop.valeur &&
          dop2.iterations == dop.iterations))

# cas limites
dlim = K.descente_par_harmonisation(Ψ, q, h; max_iter = 1)
verifier("cas limite : max_iter = 1 ⇒ issue « limite d'itérations atteinte » consignée",
         dlim.iterations == 1 && occursin("limite", dlim.registre[2]))
verifier("cas limite : à une itération, le candidat optimal est encore la figure `a`",
         dlim.figure == S.Figure([:a]) && dlim.valeur <= dop.valeur + 1e-12)

# rejets
rejette("λ hors de [0, 1] refusé", () -> K.descente_par_harmonisation(Ψ, q, h; λ = 1.5))
rejette("λ négatif refusé",       () -> K.descente_par_harmonisation(Ψ, q, h; λ = -0.1))

# ----------------------------------------------------------------------------
#  3. Borne harmonique — borne_harmonique
# ----------------------------------------------------------------------------
section("3. Borne harmonique — borne_harmonique : produit des degrés (borne de branche)")

b = K.borne_harmonique([0.8], [0.9, 0.5])
verifier("valeur de référence : produit 0,8 · 0,9 · 0,5 = 0,36",
         isapprox(b, 0.36; atol = 1e-12))
verifier("la borne est un degré de l'ordre M ([0, 1])", 0.0 <= b <= 1.0)
verifier("formule recalculée à l'identique (produit des degrés bornés à [0, 1])",
         isapprox(b, borne_recalee([0.8], [0.9, 0.5]); atol = 1e-12))

# OBJECTIF AFFICHÉ : « la borne de Maât d'une branche — jamais un simple compteur »
verifier("objectif : ce n'est pas un compteur (0,8 · 0,9 · 0,5 = 0,36 ≠ 3)",
         !isapprox(b, 3.0; atol = 1e-12))
verifier("objectif : la borne minore la branche (raffiner une tranche ne peut que la réduire)",
         K.borne_harmonique([0.8, 0.5], [0.9]) <= b + 1e-12)
verifier("objectif : la borne minore chacun de ses facteurs",
         b <= min(0.8, 0.9, 0.5) + 1e-12)

# cas limites
verifier("sans degré tranché ni maximum : borne neutre = 1,0",
         isapprox(K.borne_harmonique(Float64[], Float64[]), 1.0; atol = 1e-12))
verifier("une tranche nulle annule la borne (branche élaguée)",
         K.borne_harmonique([0.0], [0.9, 0.9]) == 0.0)
verifier("degrés hors de [0, 1] bornés (clamp) avant produit",
         K.borne_harmonique([1.5], [0.5]) == 0.5)
verifier("produit croissant en chaque degré (monotonie)",
         K.borne_harmonique([0.9], [0.5]) >= K.borne_harmonique([0.4], [0.5]))
rejette("degré non fini (NaN) refusé par l'ordre M",
        () -> K.borne_harmonique([NaN], [0.5]))

# ----------------------------------------------------------------------------
#  4. Méthode 25.2 — elagage_par_pesee
# ----------------------------------------------------------------------------
section("4. Méthode 25.2 — elagage_par_pesee : voies sous le seuil écartées sans être payées")

bornes = [0.9, 0.4, 0.6, 0.5, 0.2]
el = K.elagage_par_pesee(bornes; seuil = 0.5)

verifier("chaque voie est retenue ou écartée (partition de l'index)",
         sort(vcat(el.retenues, el.ecartees)) == collect(1:5) &&
         isempty(intersect(el.retenues, el.ecartees)))
rt, et = elagage_recale(bornes; seuil = 0.5)
verifier("retenues = voies dont la borne atteint le seuil (recalcul indépendant)",
         el.retenues == rt)
verifier("écartées = voies dont la borne tombe sous le seuil (recalcul indépendant)",
         el.ecartees == et)
verifier("valeur de référence : retenues [1, 3, 4], écartées [2, 5]",
         el.retenues == [1, 3, 4] && el.ecartees == [2, 5])

# OBJECTIF AFFICHÉ : « toute voie dont la borne tombe sous seuil est écartée sans être payée »
verifier("objectif : toute retenue a une borne ≥ seuil, toute écartée une borne < seuil",
         all(k -> clamp(float(bornes[k]), 0.0, 1.0) >= 0.5, el.retenues) &&
         all(k -> clamp(float(bornes[k]), 0.0, 1.0) < 0.5, el.ecartees))
verifier("registre : entête + une ligne par voie écartée + pied",
         length(el.registre) == length(el.ecartees) + 2)
verifier("le registre nomme chaque voie écartée",
         all(k -> any(l -> occursin("voie $k ", l), el.registre), el.ecartees))

verifier("élagage déterministe (même entrée ⇒ même partition)",
         (e2 = K.elagage_par_pesee(bornes; seuil = 0.5);
          e2.retenues == el.retenues && e2.ecartees == el.ecartees))

# cas limites
verifier("borne exactement au seuil : retenue (≥ seuil)",
         K.elagage_par_pesee([0.5]; seuil = 0.5).retenues == [1])
verifier("aucune écartée quand tout atteint le seuil (registre : entête + pied)",
         (e = K.elagage_par_pesee([0.9, 0.7]; seuil = 0.5);
          isempty(e.ecartees) && length(e.registre) == 2))
verifier("degrés hors de [0, 1] bornés (clamp) avant comparaison au seuil",
         (e = K.elagage_par_pesee([1.5, -0.5]; seuil = 0.5);
          e.retenues == [1] && e.ecartees == [2]))
rejette("aucune voie à élaguer refusée", () -> K.elagage_par_pesee(Float64[]; seuil = 0.5))

# ----------------------------------------------------------------------------
#  5. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("5. Fidélité au socle et reproductibilité (G5)")

verifier("la descente ne fait que lire κ et les valuations (optimum = pesée du socle)",
         dop.figure == S.Figure([:a]) && dop.valeur >= best0 - 1e-12)
verifier("la borne harmonique ne fait que multiplier les degrés consignés",
         isapprox(K.borne_harmonique([0.8], [0.9, 0.5]),
                  prod(clamp.([0.8, 0.9, 0.5], 0.0, 1.0)); atol = 1e-12))
verifier("l'élagage ne fait que comparer les bornes au seuil (aucune voie inventée)",
         el.retenues == rt && el.ecartees == et)
verifier("résultats reproductibles (bornes recalculées par le socle)",
         isapprox(K.borne_harmonique([0.9, 0.6], [0.5]), 0.27; atol = 1e-12))

# ----------------------------------------------------------------------------
#  6. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 12 (ch. 25) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 12 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 12.")
println("="^70)
