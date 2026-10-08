# ============================================================================
#  Benchmark de conformité — catégorie 14 : « Théorie des jeux »
#  (chapitre 27 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la quatorzième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 27, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 27.1 `pesee_mutuelle` : équilibre de Maât (profil de meilleure
#       réponse stable), harmonie = satisfaction la plus faible (règle de
#       non-compensation), valuation ramenée dans [0, 1], registre, cas limites
#       et rejets ;                                                              (Categories)
#    3. la méthode 27.2 `conception_par_attracteur` : attracteur harmonique
#       (maximise la satisfaction minimale, non le gain total), registre, cas
#       limites et rejets ;                                                      (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de la matrice de
#       gains consignée (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch27.jl
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

"""Jeu de coordination : chaque joueur a une stratégie dominante (0,9 ; 0,8)."""
const _GAINS_COORD = [0.9 0.1; 0.2 0.8]

"""Jeu dissymétrique : un joueur très satisfait (1,0), l'autre très peu (0,1)."""
const _GAINS_DISSYM = [1.0 0.9; 0.1 0.05]

"""Jeu hors bornes : gain négatif (–0,2) et gain > 1 (1,5) — valuation ramenée dans [0, 1]."""
const _GAINS_HORS_BORNES = [-0.5 -0.2; 0.3 1.5]

"""Jeu décorrélé (3 joueurs) : l'attracteur ([1, 1, 1]) n'est PAS le profil de gain total maximal ([2, 2, 1])."""
const _GAINS_DECORRELE = [0.5 0.9; 0.5 0.9; 0.5 0.1]

"""Jeu à trois joueurs, deux stratégies : DOM 1, 2, 1 (harmonie de Maât 0,7)."""
const _GAINS_3J = [0.9 0.1; 0.1 0.8; 0.7 0.7]

"""Meilleure réponse de chaque joueur : argmax de sa ligne (premier index en cas d'égalité)."""
meilleures_reponses(gains::AbstractMatrix{<:Real}) =
    [argmax(view(gains, i, :)) for i in axes(gains, 1)]

"""Harmonie de Maât recalculée : min des gains du profil, ramené dans [0, 1]."""
harmonie_recalee(gains::AbstractMatrix{<:Real}, profil::Vector{Int}) =
    minimum(clamp(float(gains[i, profil[i]]), 0.0, 1.0) for i in axes(gains, 1))

"""Satisfaction minimale d'un profil (aucune borne) — contrôle indépendant."""
satisfaction_minimale(gains::AbstractMatrix{<:Real}, profil::Vector{Int}) =
    minimum(float(gains[i, profil[i]]) for i in axes(gains, 1))

"""Somme des gains d'un profil (le « gain total » que la méthode 27.2 ne maximise pas)."""
gain_total(gains::AbstractMatrix{<:Real}, profil) =
    sum(float(gains[i, profil[i]]) for i in axes(gains, 1))

"""Attracteur harmonique recalculé indépendamment : le profil qui maximise le min des gains."""
function attracteur_recale(gains::AbstractMatrix{<:Real})
    n, s = size(gains)
    meilleur = ones(Int, n)
    meilleure = -Inf
    for combo in Iterators.product((1:s for _ in 1:n)...)
        m = minimum(float(gains[i, combo[i]]) for i in 1:n)
        if m > meilleure
            meilleure = m
            meilleur = collect(combo)
        end
    end
    return meilleur, meilleure
end

"""Tous les profils possibles du jeu, dans l'ordre d'énumération de `Iterators.product`."""
profils_possibles(gains::AbstractMatrix{<:Real}) =
    collect(Iterators.product((1:size(gains, 2) for _ in 1:size(gains, 1))...))

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 14 : Théorie des jeux\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 27) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[14]
verifier("quatorzième entrée de la carte = « Théorie des jeux »",
         cat.nom == "Théorie des jeux")
verifier("chapitre 27 consigné", cat.chapitre == 27)
verifier("trois problèmes attestés (équilibres, coopération, mécanismes)",
         cat.problemes == ["équilibres", "coopération", "mécanismes"])
verifier("méthodes consignées (pesée mutuelle, équilibre de Maât)",
         "pesée mutuelle" in cat.methodes && "équilibre de Maât" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("jeux").chapitre == 27)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Théorie des jeux") &&
         all(haskey(cov["Théorie des jeux"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 27.1 — pesee_mutuelle : équilibre de Maât, harmonie (min)
# ----------------------------------------------------------------------------
section("2. Méthode 27.1 — pesee_mutuelle : équilibre (meilleure réponse stable), harmonie (min)")

n_coord = size(_GAINS_COORD, 1)
s_coord = size(_GAINS_COORD, 2)
eq = K.pesee_mutuelle(_GAINS_COORD)

verifier("un profil est rendu (une stratégie par joueur)", length(eq.profil) == n_coord)
verifier("stratégies bornées dans 1..s", all(x -> 1 <= x <= s_coord, eq.profil))
verifier("profil = meilleure réponse de chaque joueur (équilibre de Maât, recalculé)",
         eq.profil == meilleures_reponses(_GAINS_COORD))
verifier("équilibre = meilleure réponse stable (aucun joueur n'a intérêt à changer)",
         all(_GAINS_COORD[i, eq.profil[i]] >= maximum(view(_GAINS_COORD, i, :)) for i in 1:n_coord))
verifier("harmonie = min des gains du profil (recalculée)",
         isapprox(eq.harmonie, harmonie_recalee(_GAINS_COORD, eq.profil); atol = 1e-12))
verifier("harmonie dans [0, 1]", 0.0 <= eq.harmonie <= 1.0)
verifier("registre consigné (entête + équilibre + profil)", length(eq.registre) == 3)
verifier("registre : équilibre de Maât atteint", occursin("équilibre de Maât atteint", eq.registre[2]))
verifier("pesée déterministe (même entrée ⇒ même profil)",
         K.pesee_mutuelle(_GAINS_COORD).profil == eq.profil)

# OBJECTIF AFFICHÉ : « son harmonie est la satisfaction la plus faible (règle de
# non-compensation entre joueurs) »
eq_skew = K.pesee_mutuelle(_GAINS_DISSYM)
gains_skew = [ _GAINS_DISSYM[i, eq_skew.profil[i]] for i in 1:size(_GAINS_DISSYM, 1) ]
verifier("objectif de non-compensation : l'harmonie est la PLUS FAIBLE satisfaction, pas la moyenne",
         eq_skew.profil == [1, 1] && isapprox(eq_skew.harmonie, 0.1; atol = 1e-12) &&
         eq_skew.harmonie < gain_total(_GAINS_DISSYM, eq_skew.profil) / length(gains_skew))
@printf("      jeu dissymétrique : gains du profil %s ⇒ harmonie (min) = %.4f (moyenne = %.4f)\n",
        gains_skew, eq_skew.harmonie, gain_total(_GAINS_DISSYM, eq_skew.profil) / length(gains_skew))

# valuation ramenée dans [0, 1]
eq_hb = K.pesee_mutuelle(_GAINS_HORS_BORNES)
verifier("valuation ramenée dans [0, 1] : un gain négatif du profil donne une harmonie nulle",
         eq_hb.profil == [2, 2] && eq_hb.harmonie == 0.0)

# cas à trois joueurs
eq_3j = K.pesee_mutuelle(_GAINS_3J)
verifier("trois joueurs : profil à trois stratégies, harmonie = min des trois gains",
         length(eq_3j.profil) == 3 && isapprox(eq_3j.harmonie, 0.7; atol = 1e-12))

# cas limite (borne d'itérations) et rejets
eq_court = K.pesee_mutuelle(_GAINS_COORD; max_iter = 1)
verifier("max_iter = 1 : la pesée s'arrête faute d'itérations (aucun équilibre consigné)",
         occursin("aucun équilibre stable", eq_court.registre[2]))
rejette("jeu sans joueur refusé", () -> K.pesee_mutuelle(zeros(Float64, 0, 2)))
rejette("jeu sans stratégie refusé", () -> K.pesee_mutuelle(zeros(Float64, 2, 0)))

# ----------------------------------------------------------------------------
#  3. Méthode 27.2 — conception_par_attracteur : attracteur harmonique
# ----------------------------------------------------------------------------
section("3. Méthode 27.2 — conception_par_attracteur : attracteur, non le gain total")

n, s = size(_GAINS_COORD)
cp = K.conception_par_attracteur(_GAINS_COORD)
att_profil, att_min = attracteur_recale(_GAINS_COORD)

verifier("un profil visé est rendu (une stratégie par joueur)", length(cp.profil) == n)
verifier("profil borné dans 1..s", all(x -> 1 <= x <= s, cp.profil))
verifier("profil visé = attracteur harmonique (min des gains maximal, recalculé)",
         cp.profil == att_profil)
verifier("satisfaction garantie = min des gains du profil visé (recalculée)",
         isapprox(satisfaction_minimale(_GAINS_COORD, cp.profil), att_min; atol = 1e-12))
verifier("registre consigné (entête + satisfaction garantie + profil visé)", length(cp.registre) == 3)
verifier("registre : mention de l'attracteur harmonique",
         occursin("attracteur", cp.registre[1]))
verifier("conception déterministe (même entrée ⇒ même profil)",
         K.conception_par_attracteur(_GAINS_COORD).profil == cp.profil)

# OBJECTIF AFFICHÉ : « On ne maximise pas le gain total, on choisit l'attracteur : le
# profil qui rend maximale la satisfaction la plus faible. »
cp_dec = K.conception_par_attracteur(_GAINS_DECORRELE)
totaux = [gain_total(_GAINS_DECORRELE, collect(combo)) for combo in profils_possibles(_GAINS_DECORRELE)]
verifier("objectif : le profil visé n'est PAS celui du gain total maximal",
         cp_dec.profil == [1, 1, 1] &&
         gain_total(_GAINS_DECORRELE, cp_dec.profil) < maximum(totaux))
verifier("objectif : aucun profil ne fait mieux que l'attracteur sur la satisfaction minimale",
         all(satisfaction_minimale(_GAINS_DECORRELE, collect(combo)) <=
             satisfaction_minimale(_GAINS_DECORRELE, cp_dec.profil) + 1e-12
             for combo in profils_possibles(_GAINS_DECORRELE)))
@printf("      jeu décorrélé : profil visé %s (gain total %.4f) vs profil de gain total maximal %s (%.4f)\n",
        cp_dec.profil, gain_total(_GAINS_DECORRELE, cp_dec.profil),
        collect(profils_possibles(_GAINS_DECORRELE)[argmax(totaux)]), maximum(totaux))

# OBJECTIF AFFICHÉ : « le jeu attire les joueurs vers un équilibre équitable »
verifier("objectif d'équité : satisfaction garantie de l'attracteur ≥ celle de l'équilibre de Maât",
         satisfaction_minimale(_GAINS_COORD, cp.profil) >=
         satisfaction_minimale(_GAINS_COORD, eq.profil) - 1e-12)

# cas à trois joueurs
cp_3j = K.conception_par_attracteur(_GAINS_3J)
verifier("trois joueurs : attracteur = [1, 2, 1] (satisfaction minimale 0,7)",
         cp_3j.profil == [1, 2, 1])

# rejets
rejette("jeu sans joueur refusé (conception)", () -> K.conception_par_attracteur(zeros(Float64, 0, 2)))
rejette("jeu sans stratégie refusé (conception)", () -> K.conception_par_attracteur(zeros(Float64, 2, 0)))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("pesée mutuelle : aucun chiffre rendu ne s'écarte de la matrice de gains (harmonie = min lu)",
         eq.harmonie == minimum(clamp(float(_GAINS_COORD[i, eq.profil[i]]), 0.0, 1.0) for i in 1:n_coord))
verifier("conception : la satisfaction garantie est lue dans la matrice (aucune valeur inventée)",
         isapprox(satisfaction_minimale(_GAINS_COORD, cp.profil), att_min; atol = 1e-12))
verifier("pesée mutuelle reproductible (même entrée ⇒ même profil et même harmonie)",
         (a = K.pesee_mutuelle(_GAINS_3J); b = K.pesee_mutuelle(_GAINS_3J);
          a.profil == b.profil && a.harmonie == b.harmonie))
verifier("conception reproductible (même entrée ⇒ même profil)",
         (a = K.conception_par_attracteur(_GAINS_3J); b = K.conception_par_attracteur(_GAINS_3J);
          a.profil == b.profil))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 14 (ch. 27) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 14 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 14.")
println("="^70)
