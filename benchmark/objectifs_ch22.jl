# ============================================================================
#  Benchmark de conformité — catégorie 9 : « Big data »
#  (chapitre 22 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la neuvième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 22, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 22.1 `partitionnement_geometrique` : intégrité, clôture sous ⊙
#       (aucune figure coupée, figures partageant un site jamais séparées),
#       affectation à la partition d'harmonie cumulée maximale, registre, cas
#       limites et rejets ;                                                      (Categories)
#    3. la méthode 22.2 `agregation_harmonique` : recomposition de l'agrégat
#       (aucun site perdu), harmonie d'agrégat (compatibilité moyenne des paires),
#       registre, cas limites et rejets ;                                        (Categories)
#    4. la fidélité au socle : aucun site inventé, aucun chiffre rendu qui ne soit
#       lecture de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch22.jl
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

"""Compatibilité de sites : κ = 1 sur la diagonale, 0,9 pour les paires attirées,
0,1 sinon (valeur toujours dans [0, 1])."""
const _KAPPA_PAIRES = Dict((:a, :b) => 0.9, (:c, :d) => 0.9)
kappa_site(x::Symbol, y::Symbol) = x == y ? 1.0 :
    get(_KAPPA_PAIRES, (min(x, y), max(x, y)), 0.1)

"""Compatibilité de figures : moyenne des compatibilités de sites — contrôle
indépendant, symétrique, à valeurs dans [0, 1]."""
kappa_figures(g::S.Figure, hh::S.Figure) =
    sum(kappa_site(x, y) for x in g.sites, y in hh.sites) / (length(g.sites) * length(hh.sites))

"""Partage à clôturer : `[:a,:b]` et `[:b]` se partagent le site `:b` ; `[:c]` et
`[:d]` sont disjoints."""
partage_ferme() = S.Figure[S.Figure([:a, :b]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])]

"""Partitions d'agrégation : trois figures closes et disjointes, dont la paire
`(:c,:d)` est fortement compatible."""
partitions_agregat() = S.Figure[S.Figure([:a, :b]), S.Figure([:c]), S.Figure([:d])]

# --- contrôle de la clôture sous ⊙ (méthode 22.1) ---------------------------

"""Composantes connexes recalculées indépendamment : deux figures qui partagent un
site sont réunies (clôture sous ⊙), sans jamais être coupées."""
function composantes_recalc(figures::Vector{S.Figure})
    n = length(figures)
    groupe = collect(1:n)
    trouve(x) = groupe[x] == x ? x : (groupe[x] = trouve(groupe[x]))
    for i in 1:n, j in (i + 1):n
        any(s -> s in figures[j].sites, figures[i].sites) && (groupe[trouve(j)] = trouve(i))
    end
    acc = Dict{Int,S.Figure}()
    for i in 1:n
        r = trouve(i)
        acc[r] = haskey(acc, r) ? acc[r] ⊙ figures[i] : figures[i]
    end
    return S.Figure[acc[r] for r in sort!(collect(keys(acc)))]
end

"""Règle du partitionnement géométrique recalculée indépendamment : chaque composante
close rejoint la partition **non saturée** d'harmonie cumulée la plus haute (à égalité,
la première), la charge d'une partition étant bornée à `⌈composantes / parts⌉`."""
function respecte_regle_partitionnement(figures::Vector{S.Figure}, h::S.Harmonie, parts::Int)
    comps = composantes_recalc(figures)
    capacite = cld(length(comps), parts)
    charge = zeros(Int, parts)
    parts_vec = S.Figure[S.figure_vide() for _ in 1:parts]
    for c in comps
        attendu = 0
        meilleure = -1.0
        for p in 1:parts
            charge[p] >= capacite && continue     # partition saturée : hors de la pesée
            coh = isempty(parts_vec[p]) ? 0.0 :
                  clamp(float(h.compatibilite(c, parts_vec[p])), 0.0, 1.0)
            coh > meilleure && (meilleure = coh; attendu = p)
        end
        parts_vec[attendu] = parts_vec[attendu] ⊙ c
        charge[attendu] += 1
    end
    return parts_vec
end

# --- contrôle de l'harmonie d'agrégat (méthode 22.2) ------------------------

"""Harmonie d'agrégat recalculée indépendamment : moyenne des compatibilités des
paires de partitions (1,0 s'il n'y a aucune paire)."""
function harmonie_agregat(partitions::Vector{S.Figure}, h::S.Harmonie)
    s = 0.0
    paires = 0
    for i in 1:length(partitions), j in (i + 1):length(partitions)
        s += clamp(float(h.compatibilite(partitions[i], partitions[j])), 0.0, 1.0)
        paires += 1
    end
    return paires == 0 ? 1.0 : s / paires
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 9 : Big data\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 22) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[9]
verifier("neuvième entrée de la carte = « Big data »",
         cat.nom == "Big data")
verifier("chapitre 22 consigné", cat.chapitre == 22)
verifier("trois problèmes attestés (partitionnement, agrégation, distribution)",
         cat.problemes == ["partitionnement", "agrégation", "distribution"])
verifier("méthodes consignées (partitionnement géométrique, agrégation harmonique)",
         "partitionnement géométrique" in cat.methodes && "agrégation harmonique" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Big data").chapitre == 22)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Big data") &&
         all(haskey(cov["Big data"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 22.1 — partitionnement_geometrique
# ----------------------------------------------------------------------------
section("2. Méthode 22.1 — partitionnement_geometrique : clôture sous ⊙, aucun découpage")

figs = partage_ferme()
h = S.Harmonie(kappa_figures)
pa1 = K.partitionnement_geometrique(figs, h; parts = 1)
pa2 = K.partitionnement_geometrique(figs, h; parts = 2)

verifier("un résultat porte autant de partitions que demandé",
         length(pa2) == 2 && length(pa2.partitions) == 2)
verifier("parts = 1 : une seule partition portant tous les sites",
         length(pa1.partitions) == 1 && Set(pa1.partitions[1].sites) == Set([:a, :b, :c, :d]))
verifier("aucun site perdu : l'union des partitions = l'union des figures d'entrée",
         union((Set(p.sites) for p in pa2.partitions)...) == Set([:a, :b, :c, :d]))
verifier("figures partageant un site jamais séparées (clôture sous ⊙ : :a et :b ensemble)",
         any(p -> :a in p.sites && :b in p.sites, pa2.partitions))
verifier("on ne coupe jamais une figure (chaque partition reste close sous ⊙)",
         all(p -> Set(p.sites) ⊆ Set([:a, :b, :c, :d]), pa2.partitions))
verifier("règle de partitionnement respectée (chaque composante close → partition d'harmonie cumulée maximale)",
         [Set(p.sites) for p in pa2.partitions] ==
         [Set(p.sites) for p in respecte_regle_partitionnement(figs, h, 2)])
verifier("registre consigné (entête + une ligne par composante close)",
         length(pa1.registre) == 1 + length(composantes_recalc(figs)))
verifier("entête de registre mentionne les composantes closes sous ⊙",
         occursin("composante", pa1.registre[1]) && occursin("close", pa1.registre[1]))

# OBJECTIF AFFICHÉ : « les figures qui partagent des sites sont closes sous ⊙ …
#                     On ne coupe jamais une figure. »
n_occupees = count(p -> !isempty(p), pa2.partitions)
@printf("      figures %s ⇒ partitions (parts = 2) : %s\n",
        [f.sites for f in figs], [p.sites for p in pa2.partitions])
@printf("      partitions occupées : %d / %d\n", n_occupees, length(pa2.partitions))
verifier("objectif de clôture : les deux figures liées par :b forment une composante insécable",
         any(p -> :a in p.sites && :b in p.sites, pa2.partitions))
verifier("objectif de non-découpage : chaque figure d'entrée est incluse dans une seule partition",
         all(f -> count(p -> Set(f.sites) ⊆ Set(p.sites), pa2.partitions) == 1, figs))
verifier("objectif de répartition : les 2 partitions sont occupées (capacité ⌈composantes/parts⌉)",
         n_occupees == 2)

# reproductibilité et cas limites
verifier("partitionnement déterministe (même entrée ⇒ mêmes partitions)",
         [p.sites for p in K.partitionnement_geometrique(figs, h; parts = 2).partitions] ==
         [p.sites for p in pa2.partitions])
pa_solo = K.partitionnement_geometrique([S.Figure([:a])], h; parts = 2)
verifier("cas n = 1 : une composante, une seule partition occupée",
         count(p -> !isempty(p), pa_solo.partitions) == 1 &&
         Set(pa_solo.partitions[1].sites) == Set([:a]))
rejette("aucune figure à partitionner refusée",
        () -> K.partitionnement_geometrique(S.Figure[], h; parts = 2))
rejette("zéro partition refusé",
        () -> K.partitionnement_geometrique(figs, h; parts = 0))
rejette("partition négative refusée",
        () -> K.partitionnement_geometrique(figs, h; parts = -1))

# ----------------------------------------------------------------------------
#  3. Méthode 22.2 — agregation_harmonique
# ----------------------------------------------------------------------------
section("3. Méthode 22.2 — agregation_harmonique : recomposition, harmonie d'agrégat")

parts = partitions_agregat()
ag = K.agregation_harmonique(parts, h)

verifier("la figure agrégée est la composition ⊙ des partitions (aucun site perdu)",
         Set(ag.agregee.sites) == union((Set(p.sites) for p in parts)...))
verifier("harmonie d'agrégat = moyenne des κ sur les paires (recalculée indépendamment)",
         isapprox(ag.harmonie, harmonie_agregat(parts, h); atol = 1e-12))
verifier("harmonie d'agrégat dans [0, 1]", 0.0 <= ag.harmonie <= 1.0)
verifier("registre consigné (entête, figure agrégée, harmonie — 3 lignes)",
         length(ag.registre) == 3)

# OBJECTIF AFFICHÉ : « L'agrégat ne perd aucun site : il recompose. »
@printf("      partitions %s ⇒ agrégat %s ; harmonie = %.4f\n",
        [p.sites for p in parts], ag.agregee.sites, ag.harmonie)
verifier("objectif de recomposition : l'agrégat porte exactement la réunion des sites",
         sort(ag.agregee.sites) == sort(collect(union((Set(p.sites) for p in parts)...))))
h0 = S.HarmonieRaffinement()
ag_ab = K.agregation_harmonique([S.Figure([:a]), S.Figure([:b])], h0)
verifier("figures disjointes sous l'harmonie du socle : agrégat {a,b}, harmonie 0,8",
         Set(ag_ab.agregee.sites) == Set([:a, :b]) && isapprox(ag_ab.harmonie, 0.8; atol = 1e-9))

# cas limites et rejets
ag_solo = K.agregation_harmonique([S.Figure([:a, :b])], h)
verifier("cas n = 1 : agrégat = la partition, harmonie 1,0 (aucune paire)",
         Set(ag_solo.agregee.sites) == Set([:a, :b]) && ag_solo.harmonie == 1.0)
rejette("aucune partition à agréger refusée",
        () -> K.agregation_harmonique(S.Figure[], h))
verifier("agrégation reproductible (même entrée ⇒ même agrégat et même harmonie)",
         (r1 = K.agregation_harmonique(parts, h); r2 = K.agregation_harmonique(parts, h);
          r1.harmonie == r2.harmonie && r1.agregee.sites == r2.agregee.sites))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("le partitionnement ne fait que lire κ (partitions rendues = partitions recalculées)",
         [Set(p.sites) for p in K.partitionnement_geometrique(figs, h; parts = 2).partitions] ==
         [Set(p.sites) for p in respecte_regle_partitionnement(figs, h, 2)])
verifier("l'agrégation ne fait que lire κ (harmonie rendue = moyenne des paires recalculée)",
         K.agregation_harmonique(parts, h).harmonie == harmonie_agregat(parts, h))
verifier("aucune méthode n'invente de site : l'agrégat est exactement la réunion des partitions",
         Set(ag.agregee.sites) == union((Set(p.sites) for p in parts)...))
verifier("clôture sous ⊙ indépendante de κ : le socle ne découpe jamais une figure partagée",
         (px = K.partitionnement_geometrique(figs, h0; parts = 2);
          any(p -> :a in p.sites && :b in p.sites, px.partitions) &&
          union((Set(p.sites) for p in px.partitions)...) == Set([:a, :b, :c, :d])))

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 9 (ch. 22) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 9 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 9.")
println("="^70)
