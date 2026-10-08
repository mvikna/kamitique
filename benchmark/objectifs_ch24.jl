# ============================================================================
#  Benchmark de conformité — catégorie 11 : « Cryptologie »
#  (chapitre 24 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la onzième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 24, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 24.1 `hachage_par_pesee` : l'empreinte mesure les degrés ν(f, p)
#       sur un faisceau de regards — une position dans un ordre, non une chaîne
#       de bits ; deux figures de même empreinte occupent la même position,
#       stabilité, déterminisme et cas limites ;                                 (Categories)
#    3. la méthode 24.2 `chiffrement_par_redistribution` /
#       `dechiffrement_par_redistribution` : la présence est repondérée puis
#       renormalisée (totalité conservée, rien ne s'ajoute), le déchiffrement
#       restitue le clair, cas limites et rejets ;                               (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de ν ni de la loi
#       de redistribution (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch24.jl
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

"""Porteur situé à quatre sites : a—b—d et c—d (mêmes liens que le testset du ch. 24)."""
function porteur_situe()
    G = S.Porteur()
    S.ajouter_site!(G, :a; voisins = [:b])
    S.ajouter_site!(G, :b; voisins = [:a, :d])
    S.ajouter_site!(G, :c; voisins = [:d])
    S.ajouter_site!(G, :d; voisins = [:b, :c])
    return G
end

"""État situé à quatre figures (poids décroissants), support a, b, c, d."""
etat_situe() = S.Etat([S.Figure([:a]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])],
                      [0.4, 0.3, 0.2, 0.1])

"""Faisceau de trois regards : propositions portées par `a`, par `b` et par `d`."""
faisceau_regards() = S.Proposition[
    S.Proposition("porte a", f -> :a in f.sites),
    S.Proposition("porte b", f -> :b in f.sites),
    S.Proposition("porte d", f -> :d in f.sites),
]

"""Valuation recalculée indépendamment : ν(Ψ, p) = Σ_g αg · p(g), bornée dans [0, 1]."""
function valuation_recalee(Ψ::S.Etat, p::S.Proposition)
    s = 0.0
    for (f, a) in zip(Ψ.figures, Ψ.poids)
        a > 0 || continue
        s += a * clamp(float(p.verdict(f)), 0.0, 1.0)
    end
    return clamp(s, 0.0, 1.0)
end

"""Redistribution recalculée indépendamment : poids · facteurs, renormalisés à 1."""
function redistribution_recalee(Ψ::S.Etat, facteurs::Vector{Float64})
    bruts = Ψ.poids .* facteurs
    return bruts ./ sum(bruts)
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 11 : Cryptologie\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 24) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[11]
verifier("onzième entrée de la carte = « Cryptologie »",
         cat.nom == "Cryptologie")
verifier("chapitre 24 consigné", cat.chapitre == 24)
verifier("trois problèmes attestés (hachage, chiffrement, authentification)",
         cat.problemes == ["hachage", "chiffrement", "authentification"])
verifier("méthodes consignées (hachage par pesée, chiffrement par redistribution)",
         "hachage par pesée" in cat.methodes &&
         "chiffrement par redistribution" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Cryptologie").chapitre == 24)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Cryptologie") &&
         all(haskey(cov["Cryptologie"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 24.1 — hachage_par_pesee (Empreinte par pesée)
# ----------------------------------------------------------------------------
section("2. Méthode 24.1 — hachage_par_pesee : empreinte = position mesurée par ν")

G = porteur_situe()
regards = faisceau_regards()
fa, fb, fd = S.Figure([:a]), S.Figure([:b]), S.Figure([:d])
Ψ = etat_situe()

e = K.hachage_par_pesee(fa, regards)

verifier("une empreinte est renvoyée (type Empreinte)",
         e isa K.Empreinte)
verifier("empreinte d'une figure : une composante par regard, dans l'ordre",
         length(e) == length(regards) && length(e.degres) == 3)
verifier("degrés mesurés dans l'ordre de pesée M ([0, 1])",
         all(d -> 0.0 <= d <= 1.0, e.degres))

# règle énoncée : ν(f, p) pour chaque proposition du faisceau
verifier("règle respectée : ν(f, p) par regard (recalcul indépendant sur l'état ponctuel)",
         e.degres == [valuation_recalee(S.Etat([fa], [1.0]), p) for p in regards])
@printf("      empreinte de la figure a sur les regards %s : %s\n",
        [p.nom for p in regards], e.degres)

# empreinte d'un état : ses degrés ν(Ψ, p)
eΨ = K.hachage_par_pesee(Ψ, regards)
verifier("empreinte d'un état : degrés ν(Ψ, p) sur les regards (recalcul indépendant)",
         eΨ.degres == [valuation_recalee(Ψ, p) for p in regards])
verifier("empreinte d'un état équirépartie : ν = moyenne pondérée des porteurs de p",
         isapprox(eΨ.degres[1], 0.4; atol = 1e-12) &&
         isapprox(eΨ.degres[2], 0.3; atol = 1e-12) &&
         isapprox(eΨ.degres[3], 0.1; atol = 1e-12))

# OBJECTIF AFFICHÉ : « deux figures de même empreinte occupent la même position »
e_a1 = K.hachage_par_pesee(S.Figure([:a]), regards)
e_a2 = K.hachage_par_pesee(S.Figure([:a, :a]), regards)   # même figure (dédupliquée)
verifier("objectif : figures de même empreinte ⇒ même position",
         e_a1 == e_a2 && hash(e_a1) == hash(e_a2))
verifier("objectif : deux figures distinctes occupent des positions distinctes",
         e_a1 != K.hachage_par_pesee(fb, regards) &&
         K.hachage_par_pesee(fb, regards) != K.hachage_par_pesee(fd, regards))
@printf("      positions : a ⇒ %s · b ⇒ %s · d ⇒ %s\n",
        e_a1.degres, K.hachage_par_pesee(fb, regards).degres, K.hachage_par_pesee(fd, regards).degres)

# stabilité / déterminisme
verifier("empreinte stable (même figure ⇒ même empreinte)",
         K.hachage_par_pesee(fa, regards) == e)
verifier("hachage déterministe (même entrée ⇒ même empreinte, état)",
         K.hachage_par_pesee(Ψ, regards) == eΨ)

# cas limite : faisceau vide
e_vide = K.hachage_par_pesee(fa, S.Proposition[])
verifier("cas limite : faisceau de regards vide ⇒ empreinte vide (longueur 0)",
         length(e_vide) == 0 && isempty(e_vide.degres))

# ----------------------------------------------------------------------------
#  3. Méthode 24.2 — chiffrement / dechiffrement par redistribution
# ----------------------------------------------------------------------------
section("3. Méthode 24.2 — chiffrement_par_redistribution / dechiffrement_par_redistribution")

cle = [2.0, 1.0, 1.0, 0.5]
Ψc = K.chiffrement_par_redistribution(Ψ, cle)
Ψd = K.dechiffrement_par_redistribution(Ψc, cle)

verifier("le chiffré est un état de même support (figures conservées)",
         Ψc isa S.Etat && Ψc.figures == Ψ.figures && length(Ψc) == length(Ψ))
verifier("loi de redistribution respectée : poids repondérés multiplicativement puis renormalisés",
         isapprox(Ψc.poids, redistribution_recalee(Ψ, cle); atol = 1e-12))
verifier("déterminisme : même clair et même clé ⇒ même chiffré",
         K.chiffrement_par_redistribution(Ψ, cle).poids == Ψc.poids)

# OBJECTIF AFFICHÉ : « le message chiffré conserve la totalité de la présence »
verifier("objectif : la présence totale est conservée (Σ poids = 1 après chiffrement)",
         isapprox(sum(Ψc.poids), 1.0; atol = 1e-12))
verifier("objectif : rien ne s'ajoute, tout se réorganise (le chiffré diffère du clair)",
         Ψc.poids != Ψ.poids)
@printf("      clair %s ⇒ chiffré %s\n", Ψ.poids, Ψc.poids)

# OBJECTIF AFFICHÉ : « le déchiffrement restitue le clair »
verifier("objectif : le déchiffrement restitue le clair (à l'échelle près, support identique)",
         Ψd.figures == Ψ.figures && isapprox(Ψd.poids, Ψ.poids; atol = 1e-12))
verifier("le déchiffrement conserve lui aussi la totalité de la présence",
         isapprox(sum(Ψd.poids), 1.0; atol = 1e-12))
@printf("      déchiffré : %s\n", Ψd.poids)

# cas limites
Ψu = K.chiffrement_par_redistribution(Ψ, [1.0, 1.0, 1.0, 1.0])
verifier("cas limite : clé uniforme (facteurs 1) ⇒ chiffré = clair",
         isapprox(Ψu.poids, Ψ.poids; atol = 1e-12))
Ψr = S.Etat([fa], [1.0])
verifier("cas limite : état résolu — chiffré puis déchiffré restitue le résolu",
         isapprox(K.dechiffrement_par_redistribution(K.chiffrement_par_redistribution(Ψr, [3.0]), [3.0]).poids,
                  Ψr.poids; atol = 1e-12))

# rejets
rejette("clé d'une autre taille que le support refusée (chiffrement)",
        () -> K.chiffrement_par_redistribution(Ψ, [1.0]))
rejette("clé qui annule toute la présence refusée (Σ poids = 0)",
        () -> K.chiffrement_par_redistribution(Ψ, [0.0, 0.0, 0.0, 0.0]))
rejette("clé à facteur négatif refusée (poids hors [0, +∞[)",
        () -> K.chiffrement_par_redistribution(Ψ, [2.0, -1.0, 1.0, 0.5]))
rejette("clé de déchiffrement d'une autre taille que le support refusée",
        () -> K.dechiffrement_par_redistribution(Ψc, [1.0, 1.0]))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("le chiffrement n'est que la loi de redistribution du socle (aucun chiffre inventé)",
         K.chiffrement_par_redistribution(Ψ, cle).poids == S.redistribuer(Ψ, cle).poids)
verifier("le déchiffrement n'est que la redistribution par l'inverse de la clé (socle)",
         K.dechiffrement_par_redistribution(Ψc, cle).poids ==
         S.redistribuer(Ψc, 1.0 ./ cle).poids)
verifier("le hachage d'un état n'est que la lecture de ν sur les regards (socle)",
         K.hachage_par_pesee(Ψ, regards).degres == S.valuation(Ψ, regards))
verifier("chiffrement reproductible (même entrée ⇒ même chiffré et même clair retrouvé)",
         (c1 = K.chiffrement_par_redistribution(Ψ, cle);
          c2 = K.chiffrement_par_redistribution(Ψ, cle);
          d1 = K.dechiffrement_par_redistribution(c1, cle);
          d2 = K.dechiffrement_par_redistribution(c2, cle);
          c1.poids == c2.poids && d1.poids == d2.poids))
verifier("aucune méthode de la catégorie n'altère un chiffre consigné de ν (résultats = lecture)",
         K.hachage_par_pesee(Ψ, regards).degres == S.valuation(Ψ, regards) &&
         isapprox(K.dechiffrement_par_redistribution(Ψc, cle).poids, Ψ.poids; atol = 1e-12))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 11 (ch. 24) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 11 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 11.")
println("="^70)
