# ============================================================================
#  Benchmark de conformité — catégorie 4 : « Structures de données »
#  (chapitre 17 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la quatrième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 17, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. les quatre structures natives du socle mobilisées par la catégorie —
#       Site, Figure, Porteur, Etat — et leurs invariants de structure ;         (Socle)
#    3. la méthode 17.1 `tri_par_pesee` : ordre de degrés par pesée harmonique,
#       registre, cas limites et rejets ;                                        (Categories)
#    4. la méthode 17.2 `parcours_regle` : parcours réglé, journal des pas,
#       arrêt sur cul-de-sac, cas limites et rejets ;                            (Categories)
#    5. la fidélité au socle : le tri ne fait que ranger les scores de
#       `scores_pesee` et le parcours ne fait que lire `G` (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch17.jl
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

"""Porteur situé : `a`—`b`—`d`—`c` (chaîne attestée, ordres de voisinage consignés)."""
function porteur_situe()
    G = S.Porteur()
    S.ajouter_site!(G, :a; lieu = "A", voisins = [:b])
    S.ajouter_site!(G, :b; lieu = "B", voisins = [:a, :d])
    S.ajouter_site!(G, :c; lieu = "C", voisins = [:d])
    S.ajouter_site!(G, :d; lieu = "D", voisins = [:b, :c])
    return G
end

"""État à quatre figures-sites : la présence décroît de `a` vers `d`."""
etat_situe() = S.Etat([S.Figure([:a]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])],
                      [0.4, 0.3, 0.2, 0.1])

"""Question de proximité à `a` : une seule proposition, portée par `a` seul."""
question_proche() = S.Question(:proche, S.Proposition("proche de A", f -> :a in f.sites))

# --- contrôle de tri_par_pesee (méthode 17.1) -------------------------------

"""
    scores_recales(Ψ, q, h; λ = 0.5) -> Vector{Float64}

Recalcul indépendant des scores de pesée, dans l'ordre du support : `ν_moyen` sur les
propositions de `q`, cohérence `Σ αj·κ(i, j)` avec la présence totale, puis
`(1 − λ)·ν_moyen + λ·cohérence`, ramené dans l'ordre de pesée `M` — la formule même de
`tri_par_pesee`.
"""
function scores_recales(Ψ::S.Etat, q::S.Question, h::S.Harmonie; λ::Real = 0.5)
    n = length(Ψ.figures)
    ν = zeros(n)
    for i in 1:n
        ν[i] = isempty(q.propositions) ? 1.0 :
            clamp(sum(clamp(float(p.verdict(Ψ.figures[i])), 0.0, 1.0) for p in q.propositions) /
                  length(q.propositions), 0.0, 1.0)
    end
    coh = zeros(n)
    for i in 1:n
        c = 0.0
        for j in 1:n
            c += Ψ.poids[j] * clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
        end
        coh[i] = clamp(c, 0.0, 1.0)
    end
    return clamp.((1 - λ) .* ν .+ λ .* coh, 0.0, 1.0)
end

# --- contrôle de parcours_regle (méthode 17.2) ------------------------------

"""
    parcours_recale(G, depart; regle, max_pas) -> Vector{Symbol}

Recalcul indépendant du parcours réglé : parcourt `G` depuis `depart` en ne franchissant
qu'un voisin attesté non visité vérifiant `regle(site)`, et s'arrête sur un cul-de-sac,
une répétition ou `max_pas` — la règle même de la méthode 17.2.
"""
function parcours_recale(G::S.Porteur, depart::Symbol;
                         regle::Function = _ -> true, max_pas::Integer = typemax(Int))
    haskey(G, depart) || throw(KeyError(depart))
    visite = Symbol[]
    courant = depart
    while courant !== nothing && !(courant in visite) && length(visite) < max_pas
        push!(visite, courant)
        suivant = nothing
        for v in S.voisins(G, courant)
            haskey(G, v) || continue
            v in visite && continue
            if regle(S.site(G, v))
                suivant = v
                break
            end
        end
        courant = suivant
    end
    return visite
end

"""Vrai si la suite de sites forme une marche : chaque pas est une arête attestée."""
function pas_attestes(G::S.Porteur, chemin::Vector{Symbol})
    for k in 2:length(chemin)
        (haskey(G, chemin[k]) && (chemin[k] in S.voisins(G, chemin[k - 1]))) || return false
    end
    return true
end

"""Vrai si aucun site n'apparaît deux fois dans la suite."""
sites_distincts(s::Vector{Symbol}) = length(unique(s)) == length(s)

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 4 : Structures de données\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 17) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[4]
verifier("quatrième entrée de la carte = « Structures de données »",
         cat.nom == "Structures de données")
verifier("chapitre 17 consigné", cat.chapitre == 17)
verifier("quatre problèmes attestés (modélisation, indexation, requête, jointure)",
         cat.problemes == ["modélisation", "indexation", "requête", "jointure"])
verifier("méthodes consignées (quatre structures natives, parcours réglé, tri par pesée harmonique)",
         "quatre structures natives" in cat.methodes &&
         "parcours réglé" in cat.methodes &&
         "tri par pesée harmonique" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Structures").chapitre == 17)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Structures de données") &&
         all(haskey(cov["Structures de données"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Les quatre structures natives du socle — Site, Figure, Porteur, Etat
# ----------------------------------------------------------------------------
section("2. Les quatre structures natives du socle — Site, Figure, Porteur, Etat")

G = porteur_situe()
fa, fb = S.Figure([:a]), S.Figure([:b])

sx = S.Site(:x, "X"; voisins = [:y, :y], echelle = 2)
verifier("structure native `Site` : champs (id, lieu, voisins, echelle)",
         isstructtype(S.Site) && fieldnames(S.Site) == (:id, :lieu, :voisins, :echelle))
verifier("un site ne porte aucune valeur (un lieu, un voisinage dédupliqué, une échelle ≥ 1)",
         (:valeur ∉ fieldnames(S.Site)) && sx.id == :x && sx.lieu == "X" &&
         sx.voisins == [:y] && sx.echelle == 2)
rejette("échelle de site < 1 refusée", () -> S.Site(:z; echelle = 0))

fig = S.Figure([:b, :a, :b])
verifier("structure native `Figure` : champs (sites, liens)",
         isstructtype(S.Figure) && fieldnames(S.Figure) == (:sites, :liens))
verifier("une figure conserve son arrangement (sites dédupliqués, ordre préservé)",
         fig.sites == [:b, :a] && isempty(fig.liens))
verifier("composition ⊙ : figure vide neutre et réunion des sites dans l'ordre",
         S.composer(S.figure_vide(), fig) == fig &&
         S.composer(S.Figure([:a]), S.Figure([:b])).sites == [:a, :b])

verifier("structure native `Porteur` : champs (sites,)",
         isstructtype(S.Porteur) && fieldnames(S.Porteur) == (:sites,))
verifier("le porteur rassemble ses sites attestés (quatre sites, voisinage consigné)",
         length(G) == 4 && sort(S.identifiants(G)) == [:a, :b, :c, :d] &&
         S.voisins(G, :b) == [:a, :d])
rejette("site non attesté refusé (KeyError)", () -> S.site(G, :absent))

verifier("structure native `Etat` : champs (figures, poids)",
         isstructtype(S.Etat) && fieldnames(S.Etat) == (:figures, :poids))
verifier("un état normalise la présence (poids positifs, somme 1)",
         S.Etat([fa, fb], [2.0, 2.0]).poids == [0.5, 0.5] &&
         isapprox(sum(S.Etat([fa, fb], [2.0, 2.0]).poids), 1.0; atol = 1e-12))
rejette("état à figures et poids de longueurs différentes refusé",
        () -> S.Etat([fa], [0.5, 0.5]))
rejette("état vide refusé", () -> S.Etat(S.Figure[], Float64[]))
rejette("état à poids négatif refusé", () -> S.Etat([fa, fb], [-0.1, 1.1]))

# ----------------------------------------------------------------------------
#  3. Méthode 17.1 — tri_par_pesee
# ----------------------------------------------------------------------------
section("3. Méthode 17.1 — tri_par_pesee : ordre de degrés par pesée harmonique")

Ψ = etat_situe()
q = question_proche()
h = S.HarmonieRaffinement()
tri = K.tri_par_pesee(Ψ, q, h)

verifier("tri complet (une figure du support par position)",
         length(tri) == 4 && length(tri.figures) == 4)
verifier("degrés rendus dans l'ordre de pesée M ([0, 1])",
         all(d -> 0.0 <= d <= 1.0, tri.degres))
verifier("degrés rangés par ordre décroissant", issorted(tri.degres; rev = true))

sc = scores_recales(Ψ, q, h)
ordre = sortperm(sc; rev = true)
verifier("ordre = scores recalculés (1 − λ)·ν_moyen + λ·cohérence, décroissants",
         tri.figures == Ψ.figures[ordre] && isapprox(tri.degres, sc[ordre]; atol = 1e-12))
verifier("registre consigné (entête, λ, degrés)", length(tri.registre) == 3)
verifier("le registre nomme la question et le λ consignés",
         occursin(string(q.nom), tri.registre[1]) && occursin("0.5", tri.registre[2]))
verifier("tri déterministe (même entrée ⇒ même ordre et mêmes degrés)",
         (t2 = K.tri_par_pesee(Ψ, q, h); t2.figures == tri.figures && t2.degres == tri.degres))

# OBJECTIF AFFICHÉ : « le tri rend un ordre de degrés … plutôt qu'un drapeau »
verifier("objectif affiché : le tri rend un ordre de degrés, non un drapeau (degrés non binaires)",
         any(d -> 0.0 < d < 1.0, tri.degres))
verifier("objectif affiché : la figure portant la proposition `proche de A` est en tête",
         tri.figures[1] == fa)
@printf("      ordre réel : %s ; degrés = %s\n",
        [f.sites for f in tri.figures], round.(tri.degres; digits = 3))

# cas limites et rejets
tri1 = K.tri_par_pesee(S.Etat([fa], [1.0]), q, h)
verifier("cas n = 1 : une seule figure, degré 1,0 (valuation et cohérence maximales)",
         length(tri1) == 1 && tri1.figures == [fa] && tri1.degres == [1.0])
rejette("λ hors de [0, 1] refusé", () -> K.tri_par_pesee(Ψ, q, h; λ = 1.5))

# ----------------------------------------------------------------------------
#  4. Méthode 17.2 — parcours_regle
# ----------------------------------------------------------------------------
section("4. Méthode 17.2 — parcours_regle : parcours réglé et consigné")

par = K.parcours_regle(G, :a)
verifier("le parcours rend une figure (le chemin parcouru)", par.chemin isa S.Figure)
verifier("le parcours est une marche dans le porteur (chaque pas est une arête attestée)",
         pas_attestes(G, par.chemin.sites))
verifier("le parcours ne repasse jamais par un site déjà visité",
         sites_distincts(par.chemin.sites))
verifier("parcours attendu sur le porteur situé : a → b → d → c",
         par.chemin.sites == parcours_recale(G, :a) && par.chemin.sites == [:a, :b, :d, :c])
verifier("chaque pas est consigné (une entrée de journal par site visité)",
         length(par.journal) == length(par.chemin.sites) &&
         all(k -> occursin(string(par.chemin.sites[k]), par.journal[k]), eachindex(par.chemin.sites)))
verifier("parcours déterministe (même entrée ⇒ même chemin et même journal)",
         (p2 = K.parcours_regle(G, :a); p2.chemin == par.chemin && p2.journal == par.journal))

# OBJECTIF AFFICHÉ : « … en ne franchissant un voisin que si regle(site) est vérifiée »
verifier("objectif affiché : la règle gouverne le franchissement (voisin refusé ⇒ arrêt)",
         K.parcours_regle(G, :a; regle = site_v -> site_v.id != :d).chemin.sites == [:a, :b])
verifier("objectif affiché : une règle qui refuse tout voisin ⇒ parcours d'un seul site",
         K.parcours_regle(G, :a; regle = _ -> false).chemin.sites == [:a])
verifier("objectif affiché : `regle` est évaluée sur le site visé (`regle(site(G, v))`)",
         K.parcours_regle(G, :a; regle = site_v -> site_v.lieu != "D").chemin.sites == [:a, :b])
@printf("      porteur %s ⇒ parcours %s ; journal = %d pas\n",
        sort(S.identifiants(G)), par.chemin.sites, length(par.journal))

# cas limites et rejets
par2 = K.parcours_regle(G, :a; max_pas = 2)
verifier("cas limite : le parcours s'arrête à max_pas (deux pas)",
         par2.chemin.sites == [:a, :b] && length(par2.journal) == 2)

Giso = S.Porteur()
S.ajouter_site!(Giso, :seul; lieu = "S")
piso = K.parcours_regle(Giso, :seul)
verifier("cas limite : un site isolé (cul-de-sac) donne un parcours d'un seul pas",
         piso.chemin.sites == [:seul] && length(piso.journal) == 1)

rejette("site de départ non attesté refusé (KeyError)", () -> K.parcours_regle(G, :absent))
rejette("porteur vide sans site de départ refusé (KeyError)",
        () -> K.parcours_regle(S.Porteur(), :a))

# ----------------------------------------------------------------------------
#  5. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("5. Fidélité au socle et reproductibilité (G5)")

Ψf = etat_situe()
avant = (copy(Ψf.figures), copy(Ψf.poids))
_ = K.tri_par_pesee(Ψf, q, h)
verifier("le tri ne fait que lire l'état (support et poids inchangés — G5)",
         Ψf.figures == avant[1] && Ψf.poids == avant[2])
verifier("les degrés du tri sont exactement les scores du socle `scores_pesee`, triés",
         isapprox(tri.degres, sort(S.scores_pesee(Ψ, q, h).scores; rev = true); atol = 1e-12))
verifier("le tri ne range que des figures réellement présentes (aucune figure inventée)",
         all(f -> any(f == g for g in Ψ.figures), tri.figures))

ids = S.identifiants(G)
voi = S.voisins(G, :b)
_ = K.parcours_regle(G, :a)
verifier("le parcours ne fait que lire le porteur (sites et voisinages inchangés — G5)",
         sort(S.identifiants(G)) == sort(ids) && S.voisins(G, :b) == voi)
verifier("le parcours ne franchit que des arêtes attestées par `voisins`",
         all(par.chemin.sites[k] in S.voisins(G, par.chemin.sites[k - 1])
             for k in 2:length(par.chemin.sites)))

# ----------------------------------------------------------------------------
#  6. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 4 (ch. 17) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 4 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 4.")
println("="^70)
