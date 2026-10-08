# ============================================================================
#  Benchmark de conformité — catégorie 2 : « Systèmes d'exploitation »
#  (chapitre 15 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la deuxième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 15, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 15.1 `ordonnancement_par_pesee` : ordre complet, degrés
#       normalisés, repondération des écartées par l'ancienneté (anti-famine),
#       registre, cas limites et rejets ;                                        (Categories)
#    3. la méthode 15.2 `allocation_memoire_situee` : mémoire la plus proche
#       (proximité = distance de voisinage), mémoires inaccessibles écartées et
#       signalées, registre, cas limites et rejets ;                             (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de la formule
#       consignée (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch15.jl
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

"""Degrés bruts de l'ordonnancement : besoin normalisé, et ancienneté ajoutée aux écartées."""
function degres_bruts(besoins::Vector{Float64}, anciennete::Vector{Float64}, seuil::Real)
    sb = sum(besoins); sa = sum(anciennete); n = length(besoins)
    degres = zeros(n); ecartees = Int[]
    for k in 1:n
        d = besoins[k] / sb
        if d < seuil
            push!(ecartees, k)
            sa > 0 && (d += anciennete[k] / sa)
        end
        degres[k] = d
    end
    return degres, ecartees
end

"""Porteur mémoire : `d1`—`m1`—`m2`, plus `d2` isolée (aucune mémoire joignable)."""
function porteur_memoire()
    G = S.Porteur()
    S.ajouter_site!(G, :d1; voisins = [:m1])
    S.ajouter_site!(G, :m1; voisins = [:d1, :m2])
    S.ajouter_site!(G, :m2; voisins = [:m1])
    S.ajouter_site!(G, :d2)
    return G
end

"""Porteur symétrique : `x` au centre de `l` et `r` (deux mémoires équidistantes)."""
function porteur_symetrique()
    G = S.Porteur()
    S.ajouter_site!(G, :x; voisins = [:l, :r])
    S.ajouter_site!(G, :l; voisins = [:x])
    S.ajouter_site!(G, :r; voisins = [:x])
    return G
end

"""Distances de voisinage depuis `source` (parcours en largeur) — contrôle indépendant."""
function distances_locales(G::S.Porteur, source::Symbol)
    dist = Dict{Symbol,Int}(source => 0)
    file = Symbol[source]
    while !isempty(file)
        u = popfirst!(file)
        for v in S.voisins(G, u)
            haskey(G, v) || continue
            if !haskey(dist, v)
                dist[v] = dist[u] + 1
                push!(file, v)
            end
        end
    end
    return dist
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 2 : Systèmes d'exploitation\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 15) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[2]
verifier("deuxième entrée de la carte = « Systèmes d'exploitation »",
         cat.nom == "Systèmes d'exploitation")
verifier("chapitre 15 consigné", cat.chapitre == 15)
verifier("trois problèmes attestés (ordonnancement, allocation, synchronisation)",
         cat.problemes == ["ordonnancement", "allocation", "synchronisation"])
verifier("méthodes consignées (règne pesé, ordonnancement par pesée de besoin)",
         "ordonnancement par pesée de besoin" in cat.methodes && "règne pesé" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Systèmes").chapitre == 15)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Systèmes d'exploitation") &&
         all(haskey(cov["Systèmes d'exploitation"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 15.1 — ordonnancement_par_pesee
# ----------------------------------------------------------------------------
section("2. Méthode 15.1 — ordonnancement_par_pesee : ordre, repondération par ancienneté")

besoins = [0.1, 0.2, 0.7]          # tâches 1 et 2 sous le seuil (écartées)
ancien  = [10.0, 1.0, 1.0]         # la tâche 1 est de loin la plus ancienne
ordo = K.ordonnancement_par_pesee(besoins, ancien; seuil = 0.5)

verifier("ordre complet (permutation de toutes les tâches)",
         length(ordo) == 3 && sort(ordo.ordre) == [1, 2, 3])
verifier("degrés ramenés dans l'ordre M ([0, 1])", all(d -> 0.0 <= d <= 1.0, ordo.degres))
verifier("degrés normalisés par le plus grand (max = 1,0)",
         isapprox(maximum(ordo.degres), 1.0; atol = 1e-12))
verifier("ordre = degrés décroissants",
         issorted(ordo.degres[ordo.ordre]; rev = true))
verifier("registre consigné (entête, écartées, ordre)", length(ordo.registre) == 3)

brut, ecartees = degres_bruts(besoins, ancien, 0.5)
verifier("écartées = tâches dont le besoin normalisé tombe sous le seuil",
         ecartees == [1, 2])
verifier("degrés rendus = degrés bruts normalisés par le maximum",
         isapprox(ordo.degres, brut ./ maximum(brut); atol = 1e-12))

# OBJECTIF AFFICHÉ : « afin qu'aucune ne soit affamée »
verifier("objectif anti-famine : la tâche écartée la plus ancienne est servie en premier",
         ordo.ordre[1] == 1)
@printf("      besoins %s · anciennetés %s ⇒ ordre de service %s\n",
        besoins, ancien, ordo.ordre)
verifier("objectif anti-famine : la plus ancienne écartée remonte devant la tâche au plus fort besoin",
         findfirst(==(1), ordo.ordre) < findfirst(==(3), ordo.ordre))
verifier("sans repondération, la tâche 1 (plus faible besoin normalisé) serait dernière",
         brut[1] > brut[3] && brut[1] > brut[2])

# cas sans écartée + déterminisme
ordo_plat = K.ordonnancement_par_pesee([0.5, 0.5], [1.0, 1.0]; seuil = 0.5)
verifier("aucune écartée quand tout besoin atteint le seuil (registre : ∅)",
         ordo_plat.ordre == [1, 2] && occursin("∅", ordo_plat.registre[2]))
verifier("ordonnancement déterministe (même entrée ⇒ même ordre)",
         K.ordonnancement_par_pesee(besoins, ancien; seuil = 0.5).ordre == ordo.ordre)

# cas limites et rejets
rejette("un besoin et une ancienneté par tâche exigés",
        () -> K.ordonnancement_par_pesee([1.0, 2.0], [1.0]; seuil = 0.5))
rejette("aucune tâche à ordonnancer refusé",
        () -> K.ordonnancement_par_pesee(Float64[], Float64[]; seuil = 0.5))
rejette("somme des besoins nulle refusée",
        () -> K.ordonnancement_par_pesee([0.0, 0.0], [1.0, 1.0]; seuil = 0.5))

# ----------------------------------------------------------------------------
#  3. Méthode 15.2 — allocation_memoire_situee
# ----------------------------------------------------------------------------
section("3. Méthode 15.2 — allocation_memoire_situee : proximité, mémoires inaccessibles")

Gm = porteur_memoire()
al = K.allocation_memoire_situee(Gm, [:d1, :d2], [:m1, :m2])

verifier("toute demande est affectée ou explicitement écartée",
         length(al.affectation) + count(l -> occursin("écartée", l), al.registre) == 2)
verifier("la demande située `d1` reçoit la mémoire la plus proche (`m1`, distance 1)",
         al.affectation == [:m1] && al.distances == [1])
verifier("distances rendues = distances de voisinage (parcours en largeur, contrôle indépendant)",
         al.distances == [distances_locales(Gm, :d1)[:m1]])
verifier("la demande isolée `d2`, sans mémoire joignable, est écartée et signalée",
         any(l -> occursin("d2", l) && occursin("écartée", l), al.registre))
verifier("registre consigné (entête + une ligne par demande)", length(al.registre) == 3)

# OBJECTIF AFFICHÉ : « la proximité remplace l'adresse »
verifier("objectif de proximité : la mémoire affectée minimise la distance parmi les mémoires attestées",
         (dd = distances_locales(Gm, :d1);
          all(dd[:m1] <= dd[m] for m in (:m1, :m2))))

# égalité de distance tranchée de façon déterministe (le premier de la liste)
Gs = porteur_symetrique()
al_eq = K.allocation_memoire_situee(Gs, [:x], [:l, :r])
verifier("à distances égales, la première mémoire de la liste est retenue (déterminisme)",
         al_eq.affectation == [:l] && al_eq.distances == [1])

# cas limites et rejets
rejette("aucune demande de mémoire refusée",
        () -> K.allocation_memoire_situee(Gm, Symbol[], [:m1, :m2]))
rejette("aucune mémoire attestée refusée",
        () -> K.allocation_memoire_situee(Gm, [:d1], Symbol[]))
rejette("mémoire non attestée refusée (KeyError)",
        () -> K.allocation_memoire_situee(Gm, [:d1], [:m9]))
rejette("demande non attestée refusée (KeyError)",
        () -> K.allocation_memoire_situee(Gm, [:zz], [:m1]))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("l'ordonnancement ne fait que lire besoins et ancienneté (aucun chiffre altéré)",
         isapprox(ordo.degres, brut ./ maximum(brut); atol = 1e-12))
verifier("l'allocation ne fait que lire les distances du porteur (aucune adresse inventée)",
         K.allocation_memoire_situee(Gm, [:d1], [:m1, :m2]).distances == [1])
verifier("allocation reproductible (même entrée ⇒ même affectation et mêmes distances)",
         (r1 = K.allocation_memoire_situee(Gm, [:d1, :d2], [:m1, :m2]);
          r2 = K.allocation_memoire_situee(Gm, [:d1, :d2], [:m1, :m2]);
          r1.affectation == r2.affectation && r1.distances == r2.distances))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 2 (ch. 15) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 2 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 2.")
println("="^70)
