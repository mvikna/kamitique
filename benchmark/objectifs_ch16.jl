# ============================================================================
#  Benchmark de conformité — catégorie 3 : « Langages de programmation »
#  (chapitre 16 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la troisième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 16, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. le type public `TypeDegres` : un type en degrés est une position
#       graduée, non une étiquette binaire (degrés conservés, bornes de M) ;      (Categories)
#    3. le helper public `compatibilite_types` : 1 − écart moyen à largeur
#       égale, incompatibilité franche (0,0) à largeurs différentes ;            (Categories)
#    4. la méthode 16.1 `compilation_par_composition` : composition pesée des
#       formes, coupure M→{0,1} différée, registre, cas limites et rejets ;       (Categories)
#    5. la méthode 16.2 `evaluation_consignee` : évaluation degré par degré,
#       étapes consignées, valeur = un degré, cas limites et rejets ;            (Categories)
#    6. la fidélité au socle : aucun chiffre rendu ne s'écarte de la lecture des
#       degrés consignés (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch16.jl
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

"""Type en degrés de largeur 3 : entier {1, 0, 1} dans l'ordre de pesée M."""
type_entier() = K.TypeDegres(:entier, [1.0, 0.0, 1.0])

"""Type en degrés de largeur 3 : réel {0, 1, 1} dans l'ordre de pesée M."""
type_reel() = K.TypeDegres(:reel, [0.0, 1.0, 1.0])

# --- contrôle de compatibilite_types (helper public) ------------------------

"""
    compatibilite_recalee(a, b) -> Float64

Recalcul indépendant du degré de compatibilité : `1 − écart moyen` des degrés à
largeur égale (1,0 si la largeur est nulle), et `0,0` à largeurs différentes.
"""
function compatibilite_recalee(a::K.TypeDegres, b::K.TypeDegres)
    length(a.degres) == length(b.degres) || return 0.0
    isempty(a.degres) && return 1.0
    return clamp(1.0 - sum(abs.(a.degres .- b.degres)) / length(a.degres), 0.0, 1.0)
end

# --- contrôle de compilation_par_composition (méthode 16.1) -----------------

"""Recalcul indépendant de la forme compilée : moyenne successive des degrés."""
function composition_recalee(instructions::AbstractVector{K.TypeDegres})
    forme = copy(instructions[1].degres)
    for k in 2:length(instructions)
        forme = (forme .+ instructions[k].degres) ./ 2
    end
    return forme
end

"""Vrai si la forme porte au moins un degré non dégénéré (strictement dans ]0, 1[)."""
porte_degres_non_degeneres(forme::Vector{Float64}) = any(d -> 0.0 < d < 1.0, forme)

# --- contrôle de evaluation_consignee (méthode 16.2) ------------------------

"""
    evaluation_recalee(instructions, entree) -> Vector{Float64}

Recalcul indépendant de la suite des étapes consignées : produit degré par degré
(moyenne consignée à chaque étape), l'entrée étant d'abord ramenée dans M.
"""
function evaluation_recalee(instructions::AbstractVector{K.TypeDegres},
                            entree::AbstractVector{<:Real})
    n = length(instructions[1].degres)
    courant = clamp.(float.(collect(entree)), 0.0, 1.0)
    etapes = Float64[sum(courant) / n]
    for ins in instructions
        courant = clamp.(courant .* ins.degres, 0.0, 1.0)
        push!(etapes, sum(courant) / n)
    end
    return etapes
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 3 : Langages de programmation\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 16) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[3]
verifier("troisième entrée de la carte = « Langages de programmation »",
         cat.nom == "Langages de programmation")
verifier("chapitre 16 consigné", cat.chapitre == 16)
verifier("trois problèmes attestés (syntaxe, typage, sémantique opératoire)",
         cat.problemes == ["syntaxe", "typage", "sémantique opératoire"])
verifier("méthodes consignées (formes composées, types en degrés, évaluation consignée)",
         "formes composées" in cat.methodes &&
         "types en degrés" in cat.methodes &&
         "évaluation consignée" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Langages").chapitre == 16)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Langages de programmation") &&
         all(haskey(cov["Langages de programmation"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Type public — TypeDegres
# ----------------------------------------------------------------------------
section("2. Type public — TypeDegres : position graduée, bornes de l'ordre M")

t1 = type_entier()
verifier("type en degrés : nom et vecteur de degrés consignés",
         t1.nom == :entier && t1.degres == [1.0, 0.0, 1.0])
verifier("largeur du type = longueur du vecteur de degrés", length(t1) == 3)
verifier("degrés ramenés dans l'ordre M ([0, 1])", all(d -> 0.0 <= d <= 1.0, t1.degres))

# OBJECTIF AFFICHÉ : « un type n'est pas une étiquette binaire : c'est une position graduée »
t_fin = K.TypeDegres(:fin, [0.3, 0.7, 0.5])
verifier("objectif de type gradué : un degré fractionnaire est conservé tel quel (non tranché en 0/1)",
         t_fin.degres == [0.3, 0.7, 0.5])
@printf("      type gradué réel : %s → degrés %s\n", t_fin.nom, t_fin.degres)

# cas limites et rejets
rejette("degré de type hors de [0, 1] refusé (valider_degre)",
        () -> K.TypeDegres(:faux, [1.5]))
rejette("degré de type négatif refusé", () -> K.TypeDegres(:faux, [-0.1]))

# ----------------------------------------------------------------------------
#  3. Helper public — compatibilite_types
# ----------------------------------------------------------------------------
section("3. Helper public — compatibilite_types : 1 − écart moyen, incompatibilité de largeur")

t2 = type_reel()
verifier("compatibilité d'un type avec lui-même = 1,0",
         isapprox(K.compatibilite_types(t1, t1), 1.0; atol = 1e-12))
verifier("compatibilité = 1 − écart moyen (recalculée indépendamment)",
         isapprox(K.compatibilite_types(t1, t2), compatibilite_recalee(t1, t2); atol = 1e-12))
verifier("compatibilité de {1,0,1} et {0,1,1} = 1/3",
         isapprox(K.compatibilite_types(t1, t2), 1 / 3; atol = 1e-9))
verifier("compatibilité bornée dans [0, 1]", 0.0 <= K.compatibilite_types(t1, t2) <= 1.0)
verifier("compatibilité symétrique",
         isapprox(K.compatibilite_types(t1, t2), K.compatibilite_types(t2, t1); atol = 1e-12))

# OBJECTIF AFFICHÉ : « deux types de largeurs différentes sont incompatibles (0.0) »
large = K.TypeDegres(:large, [0.5, 0.5])
verifier("objectif de largeur : deux types de largeurs différentes sont incompatibles (0,0)",
         K.compatibilite_types(t1, large) == 0.0 && K.compatibilite_types(large, t1) == 0.0)
@printf("      compatibilité (%s, %s) = %.6f ; (%s, %s) = %.1f\n",
        t1.nom, t2.nom, K.compatibilite_types(t1, t2), t1.nom, large.nom, K.compatibilite_types(t1, large))
verifier("cas limite : deux types de largeur nulle sont compatibles (1,0)",
         (v = K.TypeDegres(:vide, Float64[]); K.compatibilite_types(v, v) == 1.0))

# ----------------------------------------------------------------------------
#  4. Méthode 16.1 — compilation_par_composition
# ----------------------------------------------------------------------------
section("4. Méthode 16.1 — compilation_par_composition : composition pesée, coupure différée")

cc = K.compilation_par_composition([t1, t2])
verifier("forme compilée = moyenne des formes (recalculée indépendamment)",
         isapprox(cc.forme, composition_recalee([t1, t2]); atol = 1e-12))
verifier("forme de {1,0,1} puis {0,1,1} = {0.5, 0.5, 1.0}",
         isapprox(cc.forme, [0.5, 0.5, 1.0]; atol = 1e-12))
verifier("forme bornée dans l'ordre M ([0, 1])", all(d -> 0.0 <= d <= 1.0, cc.forme))
verifier("registre consigné (entête + verdict de coupure)", length(cc.registre) == 2)
verifier("compilation déterministe (même entrée ⇒ même forme et même verdict)",
         (r = K.compilation_par_composition([t1, t2]);
          r.forme == cc.forme && r.coupure_differee == cc.coupure_differee))

# OBJECTIF AFFICHÉ : « la coupure M→{0,1} est différée tant que la forme porte des degrés non dégénérés »
verifier("objectif de coupure différée : forme à degré non dégénéré (0,5) ⇒ coupure ajournée",
         porte_degres_non_degeneres(cc.forme) && cc.coupure_differee)
verifier("registre : la coupure est annoncée différée, remise à plus tard",
         any(l -> occursin("différée", l), cc.registre))
@printf("      composition de %s et %s ⇒ forme %s ; coupure différée = %s\n",
        t1.nom, t2.nom, cc.forme, cc.coupure_differee)

# forme déjà tranchée : aucune coupure nécessaire
cc_bin = K.compilation_par_composition([t1, t1])
verifier("objectif de coupure différée : forme déjà en {0,1} ⇒ aucune coupure nécessaire",
         cc_bin.forme == [1.0, 0.0, 1.0] && !cc_bin.coupure_differee)
verifier("registre : aucune coupure nécessaire signalée pour une forme déjà tranchée",
         any(l -> occursin("aucune coupure", l), cc_bin.registre))

# cas limites et rejets
cc1 = K.compilation_par_composition([t1])
verifier("cas d'une seule instruction : forme inchangée", cc1.forme == [1.0, 0.0, 1.0])
rejette("programme vide refusé", () -> K.compilation_par_composition(K.TypeDegres[]))
rejette("formes de largeur incompatible refusées",
        () -> K.compilation_par_composition([t1, K.TypeDegres(:court, [0.5, 0.5])]))

# ----------------------------------------------------------------------------
#  5. Méthode 16.2 — evaluation_consignee
# ----------------------------------------------------------------------------
section("5. Méthode 16.2 — evaluation_consignee : étapes consignées, valeur = un degré")

ev = K.evaluation_consignee([t1], [0.5, 0.5, 0.5])
verifier("une étape par instruction, plus l'entrée (étapes = n_instructions + 1)",
         length(ev.etapes) == 2)
verifier("suite des étapes = évaluation recalculée (produit degré par degré)",
         isapprox(ev.etapes, evaluation_recalee([t1], [0.5, 0.5, 0.5]); atol = 1e-12))
verifier("valeur rendue = moyenne de la forme finale = dernière étape",
         isapprox(ev.valeur, ev.etapes[end]; atol = 1e-12))
verifier("valeur de {0.5,0.5,0.5} sous {1,0,1} = 1/3",
         isapprox(ev.valeur, 1 / 3; atol = 1e-9))
verifier("étapes bornées dans l'ordre M ([0, 1])", all(v -> 0.0 <= v <= 1.0, ev.etapes))
verifier("registre consigné (entête + une ligne par instruction)", length(ev.registre) == 2)
verifier("évaluation déterministe (même entrée ⇒ mêmes étapes)",
         K.evaluation_consignee([t1], [0.5, 0.5, 0.5]).etapes == ev.etapes)

# OBJECTIF AFFICHÉ : « un degré, non un drapeau »
verifier("objectif de valeur graduée : la valeur est un degré strict (1/3), non un drapeau {0,1}",
         0.0 < ev.valeur < 1.0)
@printf("      entrée %s sous %s ⇒ étapes %s ; valeur = %.6f\n",
        [0.5, 0.5, 0.5], t1.nom, ev.etapes, ev.valeur)

# séquence de deux instructions
ev2 = K.evaluation_consignee([t1, t2], [1.0, 1.0, 1.0])
verifier("deux instructions ⇒ trois étapes consignées", length(ev2.etapes) == 3)
verifier("évaluation multi-instruction = produit consigné recalculé",
         isapprox(ev2.etapes, evaluation_recalee([t1, t2], [1.0, 1.0, 1.0]); atol = 1e-12))

# cas limite : entrée ramenée dans l'ordre M, cas limites et rejets
evc = K.evaluation_consignee([t1], [2.0, -1.0, 0.5])
verifier("cas limite : l'entrée est ramenée dans l'ordre M (clamp) — 1ʳᵉ étape = 0,5",
         isapprox(evc.etapes[1], 0.5; atol = 1e-12))
rejette("évaluation d'un programme vide refusée",
        () -> K.evaluation_consignee(K.TypeDegres[], [1.0]))
rejette("largeur d'entrée incompatible refusée",
        () -> K.evaluation_consignee([t1], [1.0, 0.5]))
rejette("largeur d'instruction incompatible refusée",
        () -> K.evaluation_consignee([t1, K.TypeDegres(:court, [0.5, 0.5])], [1.0, 0.5, 1.0]))

# ----------------------------------------------------------------------------
#  6. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("6. Fidélité au socle et reproductibilité (G5)")

verifier("la compilation ne fait que lire les degrés des instructions (aucun chiffre inventé)",
         K.compilation_par_composition([t1, t2]).forme == composition_recalee([type_entier(), type_reel()]))
verifier("l'évaluation ne fait que lire les degrés des instructions et l'entrée",
         K.evaluation_consignee([t1], [0.5, 0.5, 0.5]).valeur ==
         evaluation_recalee([type_entier()], [0.5, 0.5, 0.5])[end])
verifier("la compatibilité des types ne fait que mesurer l'écart des degrés (aucune altération)",
         K.compatibilite_types(t1, t2) == compatibilite_recalee(type_entier(), type_reel()))
verifier("compilation reproductible (même entrée ⇒ même forme, même verdict et même registre)",
         (r1 = K.compilation_par_composition([t1, t2]);
          r2 = K.compilation_par_composition([t1, t2]);
          r1.forme == r2.forme && r1.coupure_differee == r2.coupure_differee && r1.registre == r2.registre))

# ----------------------------------------------------------------------------
#  7. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 3 (ch. 16) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 3 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 3.")
println("="^70)
