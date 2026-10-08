# ============================================================================
#  Benchmark de conformité — catégorie 1 : « Architectures des ordinateurs »
#  (chapitre 14 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la première catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 14, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 14.1 `placement_par_pesee` : intégrité de l'affectation,
#       règle de pesée (compatibilité cumulée maximale), harmonie locale,
#       registre, cas limites et rejets ;                                        (Categories)
#    3. la méthode 14.2 `flot_par_composition` : chemin, débit (maillon le plus
#       faible), optimalité, cas limites et rejets ;                             (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch14.jl
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

"""Compatibilité de grappes : κ = 1 à l'intérieur d'une grappe, 0,2 entre grappes."""
const _MU_GRAPPES = Dict((:a1, :a2) => 1.0, (:b1, :b2) => 1.0)
kappa_grappes(g::S.Figure, hh::S.Figure) =
    only(g.sites) == only(hh.sites) ? 1.0 :
    get(_MU_GRAPPES, (min(only(g.sites), only(hh.sites)), max(only(g.sites), only(hh.sites))), 0.2)

"""Porteur orienté à deux routes de `s` à `t` (goulots 0,1 par `p` et 0,5 par `q`)."""
function porteur_route()
    G = S.Porteur()
    S.ajouter_site!(G, :s;  voisins = [:p, :q1])
    S.ajouter_site!(G, :p;  voisins = [:t])
    S.ajouter_site!(G, :q1; voisins = [:q2])
    S.ajouter_site!(G, :q2; voisins = [:t])
    S.ajouter_site!(G, :t)
    return G
end
const _MU_ROUTE = Dict((:s, :p) => 0.9, (:p, :t) => 0.1,
                       (:s, :q1) => 0.5, (:q1, :q2) => 0.5, (:q2, :t) => 0.5)
kappa_route(g::S.Figure, hh::S.Figure) =
    only(g.sites) == only(hh.sites) ? 1.0 :
    get(_MU_ROUTE, (min(only(g.sites), only(hh.sites)), max(only(g.sites), only(hh.sites))), 0.5)

"""Porteur déconnecté : `s`—`m` d'un côté, `t` isolé de l'autre (aucun chemin s→t)."""
function porteur_deconnecte()
    G = S.Porteur()
    S.ajouter_site!(G, :s; voisins = [:m])
    S.ajouter_site!(G, :m; voisins = [:s])
    S.ajouter_site!(G, :t)
    return G
end

"""Chaîne de `n` sites c1 — c2 — … — cn."""
function porteur_chaine(n::Int)
    G = S.Porteur()
    S.ajouter_site!(G, :c1; voisins = [:c2])
    for i in 2:(n - 1)
        S.ajouter_site!(G, Symbol("c", i); voisins = [Symbol("c", i - 1), Symbol("c", i + 1)])
    end
    S.ajouter_site!(G, Symbol("c", n); voisins = [Symbol("c", n - 1)])
    return G
end

# --- contrôle de la règle de pesée (méthode 14.1) ---------------------------

"""
    respecte_regle_placement(r, Ψ, h, ateliers) -> Bool

Vrai si chaque figure a été affectée à l'atelier **non saturé** où la compatibilité
cumulée avec les figures **déjà placées** est maximale (à égalité, le plus petit indice),
la charge d'un atelier étant bornée à `⌈n / ateliers⌉` — la règle même de la méthode 14.1.
"""
function respecte_regle_placement(r::K.ResultatPlacement, Ψ::S.Etat, h::S.Harmonie, ateliers::Int)
    aff = r.affectation
    n = length(Ψ.figures)
    capacite = cld(n, ateliers)
    charge = zeros(Int, ateliers)
    for i in 1:n
        attendu = 0
        meilleure = -1.0
        for a in 1:ateliers
            charge[a] >= capacite && continue     # atelier saturé : hors de la pesée
            coh = 0.0
            for j in 1:(i - 1)
                aff[j] == a || continue
                coh += clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
            end
            coh > meilleure && (meilleure = coh; attendu = a)
        end
        aff[i] == attendu || return false
        charge[aff[i]] += 1
    end
    return true
end

"""Harmonie locale recalculée à partir de l'affectation : moyenne des κ intra-atelier."""
function harmonie_recalee(aff::Vector{Int}, Ψ::S.Etat, h::S.Harmonie)
    s = 0.0
    paires = 0
    for a in unique(aff)
        idx = findall(==(a), aff)
        for x in 1:length(idx), y in (x + 1):length(idx)
            s += clamp(float(h.compatibilite(Ψ.figures[idx[x]], Ψ.figures[idx[y]])), 0.0, 1.0)
            paires += 1
        end
    end
    return paires == 0 ? 1.0 : s / paires
end

"""Maillon le plus faible (min des µ) le long d'un chemin de sites du porteur."""
function goulot(G::S.Porteur, chemin::Vector{Symbol}, h::S.Harmonie)
    m = 1.0
    for t in 2:length(chemin)
        m = min(m, clamp(float(h.compatibilite(S.Figure([chemin[t - 1]]), S.Figure([chemin[t]]))),
                         0.0, 1.0))
    end
    return m
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 1 : Architectures des ordinateurs\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 14) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[1]
verifier("première entrée de la carte = « Architectures des ordinateurs »",
         cat.nom == "Architectures des ordinateurs")
verifier("chapitre 14 consigné", cat.chapitre == 14)
verifier("trois problèmes attestés (placement, pipelines, hiérarchie mémoire)",
         cat.problemes == ["placement", "pipelines", "hiérarchie mémoire"])
verifier("méthodes consignées (réseau d'ateliers pesés, placement par pesée harmonique)",
         "placement par pesée harmonique" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Architectures").chapitre == 14)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Architectures des ordinateurs") &&
         all(haskey(cov["Architectures des ordinateurs"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 14.1 — placement_par_pesee
# ----------------------------------------------------------------------------
section("2. Méthode 14.1 — placement_par_pesee : intégrité, règle de pesée, harmonie")

Ψg = etat_grappes()
hg = S.Harmonie(kappa_grappes)
pl = K.placement_par_pesee(Ψg, hg; ateliers = 2)

verifier("affectation complète (une unité par figure)", length(pl) == 4 && length(pl.affectation) == 4)
verifier("affectations bornées dans 1..ateliers", all(a -> 1 <= a <= 2, pl.affectation))
verifier("règle de pesée respectée (chaque figure rejoint l'atelier de compatibilité cumulée maximale)",
         respecte_regle_placement(pl, Ψg, hg, 2))
verifier("harmonie locale = moyenne des κ intra-atelier (recalculée)",
         isapprox(pl.harmonie_locale, harmonie_recalee(pl.affectation, Ψg, hg); atol = 1e-12))
verifier("harmonie locale dans [0, 1]", 0.0 <= pl.harmonie_locale <= 1.0)
verifier("registre consigné (entête + une ligne de justification par figure)",
         length(pl.registre) == 5)
verifier("placement déterministe (même entrée ⇒ même affectation)",
         K.placement_par_pesee(Ψg, hg; ateliers = 2).affectation == pl.affectation)

# OBJECTIF AFFICHÉ : « répartit les figures … entre ateliers unités de calcul »
occupe = sort(unique(pl.affectation))
verifier("objectif de répartition : ≥ 2 ateliers occupés pour 4 figures et 2 ateliers",
         length(occupe) >= 2)
@printf("      affectation réelle (ateliers = 2) : %s ; ateliers occupés = %s\n",
        pl.affectation, occupe)
for A in (3, 4)
    r = K.placement_par_pesee(Ψg, hg; ateliers = A)
    @printf("      affectation réelle (ateliers = %d) : %s ; ateliers occupés = %s\n",
            A, r.affectation, sort(unique(r.affectation)))
end
verifier("objectif de répartition : ≥ 3 ateliers occupés pour 4 figures et 4 ateliers",
         length(unique(K.placement_par_pesee(Ψg, hg; ateliers = 4).affectation)) >= 3)

# cas limites et rejets
pl1 = K.placement_par_pesee(S.Etat([S.Figure([:a1])], [1.0]), hg; ateliers = 3)
verifier("cas n = 1 : une figure, atelier 1, harmonie 1,0 (aucune paire)",
         pl1.affectation == [1] && pl1.harmonie_locale == 1.0)
rejette("réseau à zéro atelier refusé", () -> K.placement_par_pesee(Ψg, hg; ateliers = 0))
rejette("réseau à atelier négatif refusé", () -> K.placement_par_pesee(Ψg, hg; ateliers = -1))

# ----------------------------------------------------------------------------
#  3. Méthode 14.2 — flot_par_composition
# ----------------------------------------------------------------------------
section("3. Méthode 14.2 — flot_par_composition : chemin, débit (goulot), optimalité")

Gr = porteur_route()
hr = S.Harmonie(kappa_route)
fl = K.flot_par_composition(Gr, :s, :t, hr)

verifier("un chemin est trouvé de la source au puits", K.trouve(fl))
verifier("le chemin relie bien source → puits (bornes : s … t)",
         first(fl.chemin) == :s && last(fl.chemin) == :t)
verifier("débit = maillon le plus faible du chemin (min des µ, recalculé)",
         isapprox(fl.debit, goulot(Gr, fl.chemin, hr); atol = 1e-12))
verifier("débit conservateur (≤ µ de chaque arête du chemin — « paiement avant engagement »)",
         all(clamp(float(hr.compatibilite(S.Figure([fl.chemin[t - 1]]), S.Figure([fl.chemin[t]]))),
                   0.0, 1.0) >= fl.debit - 1e-12 for t in 2:length(fl.chemin)))
verifier("optimalité : le chemin de débit maximal est retenu (0,5 par q ≻ 0,1 par p)",
         isapprox(fl.debit, 0.5; atol = 1e-12) && fl.chemin == [:s, :q1, :q2, :t])
verifier("registre consigné (chemin et débit)", length(fl.registre) == 2)

# none path
Gd = porteur_deconnecte()
fd = K.flot_par_composition(Gd, :s, :t, hg)
verifier("aucun chemin : résultat vide et débit −1 consigné",
         isempty(fd.chemin) && fd.debit == -1.0 && !K.trouve(fd))
rejette("source non attestée refusée", () -> K.flot_par_composition(Gr, :zz, :t, hr))
rejette("puits non attesté refusé", () -> K.flot_par_composition(Gr, :s, :zz, hr))

# borne de profondeur
Gc = porteur_chaine(7)
h0 = S.HarmonieRaffinement()
fl_court = K.flot_par_composition(Gc, :c1, :c7, h0; max_profondeur = 4)
fl_long  = K.flot_par_composition(Gc, :c1, :c7, h0; max_profondeur = 7)
verifier("borne de profondeur respectée (max_profondeur = 4 < 7 ⇒ aucun chemin)",
         isempty(fl_court.chemin) && fl_court.debit == -1.0)
verifier("profondeur suffisante (max_profondeur = 7) ⇒ chemin trouvé",
         K.trouve(fl_long) && length(fl_long.chemin) == 7)

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et au déterminisme (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("placement déterministe sur un état d'anneau (HarmonieRaffinement)",
         K.placement_par_pesee(S.Etat([S.Figure([:s1, :s2]), S.Figure([:s2, :s3]), S.Figure([:s3, :s4])],
                                      [0.5, 0.3, 0.2]), h0; ateliers = 3).affectation ==
         K.placement_par_pesee(S.Etat([S.Figure([:s1, :s2]), S.Figure([:s2, :s3]), S.Figure([:s3, :s4])],
                                      [0.5, 0.3, 0.2]), h0; ateliers = 3).affectation)
verifier("le flot rend le même débit que le goulot du socle sur l'anneau",
         (G8 = porteur_chaine(8);
          f8 = K.flot_par_composition(G8, :c1, :c8, h0; max_profondeur = 8);
          isapprox(f8.debit, goulot(G8, f8.chemin, h0); atol = 1e-12)))
verifier("aucune méthode de la catégorie n'altère un chiffre consigné de κ (résultats = lecture de κ)",
         K.flot_par_composition(Gr, :s, :t, hr).debit == 0.5 &&
         pl.harmonie_locale == harmonie_recalee(pl.affectation, Ψg, hg))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 1 (ch. 14) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 1 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 1.")
println("="^70)
