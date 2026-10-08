# ============================================================================
#  Benchmark de conformité — catégorie 8 : « Bases de données »
#  (chapitre 21 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la huitième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 21, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode `recherche_par_relaxation` : la figure retenue fait partie du
#       support, le degré rendu est ν(f, p) mesuré, la relaxation n'est pas
#       cachée (seuil emporté), registre, cas limites et rejets ;                (Categories)
#    3. la méthode `jointure_par_composition` (composition située `⊙`) : la figure
#       jointe réunit les sites, porte les liens attestés par le porteur, consigne
#       les sites partagés, cas limites et reproductibilité ;                    (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de ν ou des liens
#       attestés de `G` (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch21.jl
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

"""Porteur situé en chaîne `a — b — c — d` (sites et voisinages attestés)."""
function porteur_bd()
    G = S.Porteur()
    S.ajouter_site!(G, :a; lieu = "A", voisins = [:b])
    S.ajouter_site!(G, :b; lieu = "B", voisins = [:a, :c])
    S.ajouter_site!(G, :c; lieu = "C", voisins = [:b, :d])
    S.ajouter_site!(G, :d; lieu = "D", voisins = [:c])
    return G
end

"""État de recherche : degrés fractionnaires (1/3, 2/3) — aucune figure ne sature à 1,0."""
etat_recherche() = S.Etat([S.Figure([:a]), S.Figure([:a, :b]), S.Figure([:b])],
                          [0.4, 0.4, 0.2])

"""Proposition à degré fractionnaire : proportion du support (bornée à 1)."""
proposition_densite() =
    S.Proposition("densité du support", f -> min(1.0, length(f.sites) / 3.0))

"""Proposition binaire : la figure porte le site `c` (degré 0 ou 1)."""
proposition_porte_c() = S.proposition_binaire("porte le site c", f -> :c in f.sites)

# --- contrôle de la relaxation (méthode `recherche_par_relaxation`) ----------

"""
    relaxation_attendue(Ψ, p, seuils) -> (figure, degré, seuil)

Recalcul **indépendant** de la règle énoncée : la première figure du support, dans
l'ordre de `Ψ`, dont le degré ν(f, p) atteint le premier seuil de `seuils` (parcourus
dans l'ordre donné) — `(nothing, 0.0, 0.0)` si aucun seuil n'est atteint.
"""
function relaxation_attendue(Ψ::S.Etat, p::S.Proposition, seuils)
    for s in seuils
        for f in Ψ.figures
            d = S.valuation(S.Etat([f], [1.0]), p)
            d >= s && return (f, d, float(s))
        end
    end
    return (nothing, 0.0, 0.0)
end

# --- contrôle de la jointure (méthode `jointure_par_composition`) -----------

"""
    liens_attestes(G, a, b) -> Set{Tuple{Symbol,Symbol}}

Recalcul **indépendant** des liens que le porteur `G` atteste entre un site de `a`
et un site de `b` (dans un sens ou dans l'autre).
"""
function liens_attestes(G::S.Porteur, a::S.Figure, b::S.Figure)
    ls = Set{Tuple{Symbol,Symbol}}()
    for x in a.sites, y in b.sites
        ((haskey(G, x) && y in S.voisins(G, x)) ||
         (haskey(G, y) && x in S.voisins(G, y))) && push!(ls, S.paire_canonique(x, y))
    end
    return ls
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 8 : Bases de données\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 21) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[8]
verifier("huitième entrée de la carte = « Bases de données »",
         cat.nom == "Bases de données")
verifier("chapitre 21 consigné", cat.chapitre == 21)
verifier("trois problèmes attestés (requêtes, jointures, transactions)",
         cat.problemes == ["requêtes", "jointures", "transactions"])
verifier("méthodes consignées (recherche par relaxation, jointure par composition)",
         "recherche par relaxation" in cat.methodes &&
         "jointure par composition" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Bases").chapitre == 21)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Bases de données") &&
         all(haskey(cov["Bases de données"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode `recherche_par_relaxation` (ch. 21)
# ----------------------------------------------------------------------------
section("2. Méthode `recherche_par_relaxation` (ch. 21) : relaxation, degré mesuré, seuil")

Ψa = etat_recherche()
p_frac = proposition_densite()
seuils_defaut = [1.0, 0.75, 0.5, 0.25, 0.0]
rec = K.recherche_par_relaxation(Ψa, p_frac)

f_att, d_att, s_att = relaxation_attendue(Ψa, p_frac, seuils_defaut)

verifier("un résultat est rendu (figure retenue, non un drapeau nu)", K.trouve(rec))
verifier("la figure retenue appartient au support de l'état", rec.figure in Ψa.figures)
verifier("figure retenue = première atteignant le seuil emporté (recalcul indépendant)",
         rec.figure == f_att)
verifier("degré rendu = ν(f, p) mesuré (recalcul indépendant)",
         isapprox(rec.degre, d_att; atol = 1e-12))
verifier("seuil emporté = premier seuil atteint (recalcul indépendant)",
         rec.seuil == s_att)
verifier("le degré rendu atteint effectivement le seuil emporté (ν ≥ seuil)",
         rec.degre >= rec.seuil - 1e-12)
verifier("registre consigné (seuil de relaxation + degré mesuré)", length(rec.registre) == 2)
verifier("registre : le premier poste annonce la relaxation jusqu'au seuil",
         occursin("relaxation jusqu'au seuil", rec.registre[1]))
verifier("registre : le second poste consigne le degré mesuré ν(f, p)",
         occursin("degré mesuré", rec.registre[2]) && occursin(p_frac.nom, rec.registre[2]))
verifier("trouve(r) ⇔ figure ≠ nothing",
         K.trouve(rec) == (rec.figure !== nothing))

# OBJECTIF AFFICHÉ : « la recherche ne cache pas sa relaxation : elle rend le degré
# atteint et le seuil qui l'a emporté »
verifier("objectif affiché : la relaxation n'est pas cachée — aucune figure ne sature le seuil 1,0",
         all(f -> S.valuation(S.Etat([f], [1.0]), p_frac) < 1.0, Ψa.figures) && rec.seuil < 1.0)
@printf("      degrés réels par figure : %s ⇒ seuil emporté %.2f · figure retenue %s\n",
        [S.valuation(S.Etat([f], [1.0]), p_frac) for f in Ψa.figures],
        rec.seuil, rec.figure.sites)
verifier("objectif affiché : le seuil affiché est bien celui qui a emporté (premier atteint)",
         rec.seuil == 0.5 && isapprox(rec.degre, 2 / 3; atol = 1e-12))

# cas binaire (0/1), à la manière du testset
Ψb = S.Etat([S.Figure([:a]), S.Figure([:b, :c]), S.Figure([:a, :b, :c])], [0.3, 0.3, 0.4])
p_bin = proposition_porte_c()
rec_b = K.recherche_par_relaxation(Ψb, p_bin; seuils = [1.0, 0.5, 0.0])
verifier("degré binaire : le seuil 1,0 est atteint par la première figure le portant",
         K.trouve(rec_b) && rec_b.figure == S.Figure([:b, :c]) &&
         isapprox(rec_b.degre, 1.0; atol = 1e-12) && rec_b.seuil == 1.0)

# cas : aucun seuil atteint
rec_none = K.recherche_par_relaxation(Ψa, p_frac; seuils = [1.0, 0.75])
verifier("aucune figure n'atteint les seuils : figure = nothing, degré 0, seuil 0",
         rec_none.figure === nothing && rec_none.degre == 0.0 &&
         rec_none.seuil == 0.0 && !K.trouve(rec_none))
verifier("registre consigné en l'absence de résultat (une ligne)",
         length(rec_none.registre) == 1 && occursin("aucune figure", rec_none.registre[1]))

# cas : relâchement jusqu'au seuil 0,0
rec0 = K.recherche_par_relaxation(Ψa, p_frac; seuils = [0.99, 0.0])
verifier("seuil relâché jusqu'à 0,0 : la première figure du support est retenue",
         K.trouve(rec0) && rec0.figure == Ψa.figures[1] && rec0.seuil == 0.0 &&
         isapprox(rec0.degre, 1 / 3; atol = 1e-12))

# cas limite n = 1
rec1 = K.recherche_par_relaxation(S.Etat([S.Figure([:b, :c])], [1.0]), p_bin;
                                  seuils = [1.0, 0.5, 0.0])
verifier("cas limite n = 1 : l'unique figure est retenue au seuil 1,0",
         K.trouve(rec1) && rec1.figure == S.Figure([:b, :c]) && rec1.seuil == 1.0)

# déterminisme et rejets
verifier("recherche déterministe (même entrée ⇒ même figure, degré et seuil)",
         (r = K.recherche_par_relaxation(Ψa, p_frac);
          r.figure == rec.figure && r.degre == rec.degre && r.seuil == rec.seuil))
p_nan = S.Proposition("verdict hors de M", f -> NaN)
rejette("proposition dont le verdict n'est pas un degré de M refusée",
        () -> K.recherche_par_relaxation(Ψa, p_nan))

# ----------------------------------------------------------------------------
#  3. Méthode `jointure_par_composition` (ch. 21) — composition située ⊙
# ----------------------------------------------------------------------------
section("3. Méthode `jointure_par_composition` (ch. 21) : composition ⊙, liens attestés, sites partagés")

G = porteur_bd()
fa = S.Figure([:a]); fb = S.Figure([:b]); fc = S.Figure([:c])
jo = K.jointure_par_composition(G, fa, fb)

verifier("la figure jointe est exactement la composition située ⊙(G, a, b) du socle",
         jo.composee == (S.:⊙)(G, fa, fb))
verifier("la figure jointe réunit les sites des deux figures (ordre préservé)",
         jo.composee.sites == [:a, :b])
verifier("aucun site n'est inventé ni perdu (réunion = sites des opérandes)",
         sort(jo.composee.sites) == sort(unique(vcat(fa.sites, fb.sites))))
verifier("liens de la figure jointe = liens internes ⊕ liens attestés par G (recalcul indépendant)",
         jo.composee.liens == union(S.composer(fa, fb).liens, liens_attestes(G, fa, fb)))
verifier("la figure jointe porte le lien attesté par G entre les deux figures",
         S.paire_canonique(:a, :b) in jo.composee.liens)
verifier("sites partagés consignés (∅ ici)", isempty(jo.communes))
verifier("registre consigné (en-tête + sites partagés + figure jointe)", length(jo.registre) == 3)
verifier("registre : les sites partagés nuls sont consignés « ∅ »", occursin("∅", jo.registre[2]))
verifier("registre : la figure jointe consigne sites et liens",
         occursin("sites", jo.registre[3]) && occursin("liens", jo.registre[3]))

# OBJECTIF AFFICHÉ : « la figure jointe porte, en plus de leur réunion, les liens
# que le porteur G atteste entre elles »
verifier("objectif affiché : la jointure d'éléments liés porte bien les liens attestés",
         !isempty(jo.composee.liens))

# cas : deux figures non adjacentes (aucun lien attesté)
jo_vide = K.jointure_par_composition(G, fa, fc)
verifier("jointure d'éléments non adjacents : aucun lien inventé (réunion seule)",
         jo_vide.composee.sites == [:a, :c] && isempty(jo_vide.composee.liens))
verifier("objectif affiché : sans lien attesté, la composition se réduit à la réunion",
         isempty(jo_vide.composee.liens) && isempty(jo_vide.communes))

# cas : deux figures qui se recouvrent (site partagé)
jo_part = K.jointure_par_composition(G, S.Figure([:a, :b]), S.Figure([:b, :c]))
verifier("sites partagés détectés et consignés (le site b)",
         jo_part.communes == [:b] && occursin("b", jo_part.registre[2]))
verifier("figure jointe d'opérandes qui se recouvrent : réunion sans doublon",
         jo_part.composee.sites == [:a, :b, :c])
verifier("liens attestés entre les deux opérandes ajoutés (a—b et b—c)",
         S.paire_canonique(:a, :b) in jo_part.composee.liens &&
         S.paire_canonique(:b, :c) in jo_part.composee.liens)
verifier("jointure déterministe (même entrée ⇒ même figure composée)",
         K.jointure_par_composition(G, fa, fb).composee == jo.composee)

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("le degré de recherche est une pure lecture de ν (aucun chiffre fabriqué)",
         isapprox(rec.degre, S.valuation(S.Etat([rec.figure], [1.0]), p_frac); atol = 1e-12))
verifier("la recherche n'altère pas l'état (support et poids inchangés)",
         length(Ψa.figures) == 3 && isapprox(sum(Ψa.poids), 1.0; atol = 1e-12))
verifier("la jointure ne fait que lire les voisinages attestés du porteur (aucun lien inventé)",
         jo_vide.composee.liens == liens_attestes(G, fa, fc))
verifier("la figure jointe reste une figure située (sites tous attestés dans G)",
         S.verifier_appartenance(G, jo.composee) &&
         S.verifier_appartenance(G, jo_part.composee))
verifier("figure neutre : a ⊙ vide = a (cohérence de la composition du socle)",
         S.composer(fa, S.figure_vide()) == fa)
verifier("recherche et jointure reproductibles (même entrée ⇒ mêmes résultats)",
         (r = K.recherche_par_relaxation(Ψa, p_frac);
          j = K.jointure_par_composition(G, fa, fb);
          r.figure == rec.figure && r.seuil == rec.seuil && j.composee == jo.composee))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 8 (ch. 21) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 8 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 8.")
println("="^70)
