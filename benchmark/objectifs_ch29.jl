# ============================================================================
#  Benchmark de conformité — catégorie 16 : « Recherche heuristique et
#  systèmes experts »  (chapitre 29 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la seizième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 29, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 29.1 `recherche_par_pesee_de_promesse` : intégrité de la voie,
#       promesse cumulative (recalcul indépendant), voie de promesse nulle
#       écartée en le consignant, invariant β₀ (A-K4⁺), registre, cas limites et
#       rejets ;                                                                 (Categories)
#    3. l'API amortie `IndexPesee` : elle rend *exactement* la forme directe
#       (chemin, promesse, registre) pour toutes les paires de sites ;           (Categories)
#    4. le champ d'attraction de Maât (axiome A4) : `champ_vers`,
#       `promesse_optimale`, `descente_par_champ` — l'optimum se *calcule* (0 nœud
#       développé), le chemin est certifié optimal, hors bassin / promesse nulle
#       distingués ;                                                             (Categories)
#    5. le dual du champ `champ_depuis` / `chemin_depuis` : une source → toutes
#       les cibles en une passe, promesse et chemin identiques ;                 (Categories)
#    6. la méthode 29.2 `inference_gouvernee` : aucune conclusion retenue si
#       l'épreuve d'explicabilité εX échoue ;                                    (Categories)
#    7. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch29.jl
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

"""Porteur de référence : `a`—`b`—`d`, plus `c`—`d` (une seule voie de `a` à `d`)."""
function porteur_reference()
    G = S.Porteur()
    S.ajouter_site!(G, :a; voisins = [:b])
    S.ajouter_site!(G, :b; voisins = [:a, :d])
    S.ajouter_site!(G, :c; voisins = [:d])
    S.ajouter_site!(G, :d; voisins = [:b, :c])
    return G
end

"""Porteur de deux voies de `s` à `t` : par `p` (µ = 0,9) et par `q` (µ = 0,5)."""
function porteur_voies()
    G = S.Porteur()
    S.ajouter_site!(G, :s; voisins = [:p, :q])
    S.ajouter_site!(G, :p; voisins = [:t])
    S.ajouter_site!(G, :q; voisins = [:t])
    S.ajouter_site!(G, :t)
    return G
end

const _MU_VOIES = Dict((:s, :p) => 0.9, (:p, :t) => 0.9,
                       (:s, :q) => 0.5, (:q, :t) => 0.5)
function kappa_voies(g::S.Figure, hh::S.Figure)
    u, w = only(g.sites), only(hh.sites)
    u == w && return 1.0
    return get(_MU_VOIES, (u, w), get(_MU_VOIES, (w, u), 0.4))
end

"""Porteur à composante isolée : `a`—`b` d'un côté, `z` seul de l'autre."""
function porteur_isole()
    G = S.Porteur()
    S.ajouter_site!(G, :a; voisins = [:b])
    S.ajouter_site!(G, :b; voisins = [:a])
    S.ajouter_site!(G, :z)
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

"""Porteur « piège » : `s`—`a`—`v`—`t` (µ fortes) concurrencé par `s`—`b`—`v` (µ faible)."""
function porteur_piege()
    G = S.Porteur()
    S.ajouter_site!(G, :s; voisins = [:a, :b])
    S.ajouter_site!(G, :a; voisins = [:s, :v])
    S.ajouter_site!(G, :b; voisins = [:s, :v])
    S.ajouter_site!(G, :v; voisins = [:a, :b, :t])
    S.ajouter_site!(G, :t; voisins = [:v])
    return G
end

const _KAPPA_PIEGE = Dict((:s, :a) => 0.90, (:s, :b) => 0.99,
                          (:a, :v) => 0.90, (:b, :v) => 0.01, (:v, :t) => 0.90)
function kappa_piege(g::S.Figure, hh::S.Figure)
    u, w = only(g.sites), only(hh.sites)
    return u == w ? 1.0 : get(_KAPPA_PIEGE, (u, w), get(_KAPPA_PIEGE, (w, u), 0.0))
end

"""Porteur à arête `µ = 0` : `p`—`q`—`r`, plus `iso` isolé (µ(q,r) = 0)."""
function porteur_zero()
    G = S.Porteur()
    S.ajouter_site!(G, :p; voisins = [:q])
    S.ajouter_site!(G, :q; voisins = [:p, :r])
    S.ajouter_site!(G, :r; voisins = [:q])
    S.ajouter_site!(G, :iso)
    return G
end

function kappa_zero(g::S.Figure, hh::S.Figure)
    u, w = only(g.sites), only(hh.sites)
    return u == w ? 1.0 : (((u == :q && w == :r) || (u == :r && w == :q)) ? 0.0 : 0.8)
end

# --- contrôle indépendant de la promesse (méthode 29.1) ---------------------

"""
    promesse_chemin(chemin, h; heuristique) -> Float64

Promesse d'un chemin **recomposée de la gauche vers la droite** : produit des
compatibilités `µ` des arêtes et des `heuristique(site)` de **tous les sites sauf le
départ** — l'ordre d'évaluation même de la recherche et de la descente (contrôle
indépendant, non un appel à `src/`).
"""
function promesse_chemin(chemin::Vector{Symbol}, h::S.Harmonie; heuristique::Function = _ -> 1.0)
    p = 1.0
    for t in 2:length(chemin)
        c = clamp(float(h.compatibilite(S.Figure([chemin[t - 1]]), S.Figure([chemin[t]]))), 0.0, 1.0)
        p = (p * c) * clamp(float(heuristique(chemin[t])), 0.0, 1.0)
    end
    return p
end

"""
    meilleure_promesse(G, depart, but, h; heuristique) -> Float64

**Oracle exhaustif** : promesse maximale parmi tous les chemins simples dirigés de
`depart` à `but` (énumération indépendante). `0.0` si aucune chaîne n'existe.
"""
function meilleure_promesse(G::S.Porteur, depart::Symbol, but::Symbol, h::S.Harmonie;
                            heuristique::Function = _ -> 1.0)
    meilleur = 0.0
    pile = Tuple{Vector{Symbol},Float64}[(Symbol[depart], 1.0)]
    while !isempty(pile)
        chemin, p = pop!(pile)
        c = chemin[end]
        if c == but
            meilleur = max(meilleur, p)
            continue
        end
        for v in S.voisins(G, c)
            haskey(G, v) || continue
            v in chemin && continue
            cc = clamp(float(h.compatibilite(S.Figure([c]), S.Figure([v]))), 0.0, 1.0)
            push!(pile, (vcat(chemin, v), p * cc * clamp(float(heuristique(v)), 0.0, 1.0)))
        end
    end
    return meilleur
end

"""Nombre de nœuds effectivement développés, lu dans le registre (0 si élagué)."""
function noeuds_developpes(registre::Vector{String})
    for ligne in registre
        m = match(r"(\d+) nœud", ligne)
        m === nothing || return parse(Int, m.captures[1])
    end
    return 0
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 16 : Recherche heuristique et systèmes experts\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 29) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[16]
verifier("seizième entrée de la carte = « Recherche heuristique et systèmes experts »",
         cat.nom == "Recherche heuristique et systèmes experts")
verifier("chapitre 29 consigné", cat.chapitre == 29)
verifier("trois problèmes attestés (exploration, planification, inférence)",
         cat.problemes == ["exploration", "planification", "inférence"])
verifier("méthodes consignées (pesée de promesse, inférence gouvernée)",
         "pesée de promesse" in cat.methodes && "inférence gouvernée" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("heuristique").chapitre == 29)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Recherche heuristique et systèmes experts") &&
         all(haskey(cov["Recherche heuristique et systèmes experts"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 29.1 — recherche_par_pesee_de_promesse
# ----------------------------------------------------------------------------
section("2. Méthode 29.1 — recherche_par_pesee_de_promesse : promesse, voie nulle, élagage β₀")

Gv = porteur_voies()
hv = S.Harmonie(kappa_voies)
r = K.recherche_par_pesee_de_promesse(Gv, :s, :t, hv)

verifier("une voie est trouvée de la source au but", K.trouve(r))
verifier("la voie relie bien source → but (bornes : s … t)",
         first(r.chemin) == :s && last(r.chemin) == :t)
verifier("promesse = produit des µ le long de la voie (recomposé de gauche à droite)",
         isapprox(r.promesse, promesse_chemin(r.chemin, hv); atol = 1e-12))
verifier("promesse bornée dans [0, 1]", 0.0 <= r.promesse <= 1.0)
verifier("registre consigné (entête + ligne de verdict)",
         length(r.registre) == 2 && r.registre[1] == "recherche par pesée de promesse")
verifier("recherche déterministe (même entrée ⇒ même chemin et même promesse)",
         K.recherche_par_pesee_de_promesse(Gv, :s, :t, hv).chemin == r.chemin &&
         K.recherche_par_pesee_de_promesse(Gv, :s, :t, hv).promesse == r.promesse)

# OBJECTIF AFFICHÉ : « on développe toujours la voie de plus haute promesse »
verifier("objectif : la voie retenue porte la promesse maximale parmi les voies possibles",
         isapprox(r.promesse, meilleure_promesse(Gv, :s, :t, hv); atol = 1e-12))
verifier("objectif : la voie forte (0,9·0,9) est préférée à la voie faible (0,5·0,5)",
         r.chemin == [:s, :p, :t] && isapprox(r.promesse, 0.81; atol = 1e-12))
@printf("      voies : s→p→t = %.4f · s→q→t = %.4f ⇒ voie retenue %s (promesse %.4f)\n",
        0.9 * 0.9, 0.5 * 0.5, r.chemin, r.promesse)

# le facteur heuristique entre dans la promesse comme dans le champ
heur = v -> v == :b ? 0.5 : 1.0
Gr = porteur_reference()
hr = S.HarmonieRaffinement()
rh = K.recherche_par_pesee_de_promesse(Gr, :a, :d, hr; heuristique = heur)
verifier("le facteur heuristique pondère la promesse (a→b→d : 0,8·0,5·0,8)",
         rh.chemin == [:a, :b, :d] && isapprox(rh.promesse, 0.32; atol = 1e-12))

# cas limite : départ = but
verifier("cas depart = but : chemin réduit à [s] et promesse 1,0",
         K.recherche_par_pesee_de_promesse(Gv, :s, :s, hv).chemin == [:s] &&
         K.recherche_par_pesee_de_promesse(Gv, :s, :s, hv).promesse == 1.0)

# OBJECTIF AFFICHÉ : « une voie de promesse nulle est écartée en le consignant, jamais tuée en silence »
nulle = K.recherche_par_pesee_de_promesse(Gv, :s, :t, hv; heuristique = _ -> 0.0)
verifier("objectif : une promesse nulle écarte la voie — le registre le consigne",
         !K.trouve(nulle) && any(l -> occursin("promesse nulle", l), nulle.registre))

# invariant β₀ (A-K4⁺) : élagage exact, sans développer de nœud
Gi = porteur_isole()
sans = K.recherche_par_pesee_de_promesse(Gi, :a, :z, hr)
avec = K.recherche_par_pesee_de_promesse(Gi, :a, :z, hr; invariant = true)
verifier("invariant β₀ : une cible hors composante reste introuvable (aucune solution coupée)",
         !K.trouve(sans) && !K.trouve(avec))
verifier("invariant β₀ : l'espace est élagué sans développer un seul nœud",
         any(l -> occursin("A-K4⁺", l), avec.registre) && noeuds_developpes(avec.registre) == 0)
verifier("sans invariant, l'exploration développe bien des nœuds",
         noeuds_developpes(sans.registre) > 0)

# borne de ressources : max_noeuds
Gc = porteur_chaine(6)
court = K.recherche_par_pesee_de_promesse(Gc, :c1, :c6, hr; max_noeuds = 3)
long_ = K.recherche_par_pesee_de_promesse(Gc, :c1, :c6, hr; max_noeuds = 6)
verifier("borne de ressources respectée (max_noeuds = 3 ⇒ but non atteint)",
         !K.trouve(court))
verifier("ressources suffisantes (max_noeuds = 6) ⇒ la chaîne entière est trouvée",
         K.trouve(long_) && length(long_.chemin) == 6)

# rejets
rejette("site de départ non attesté refusé (KeyError)",
        () -> K.recherche_par_pesee_de_promesse(Gv, :zz, :t, hv))
rejette("site de but non attesté refusé (KeyError)",
        () -> K.recherche_par_pesee_de_promesse(Gv, :s, :zz, hv))

# ----------------------------------------------------------------------------
#  3. Méthode 29.1 amortie — IndexPesee rend exactement la forme directe
# ----------------------------------------------------------------------------
section("3. Méthode 29.1 amortie — IndexPesee : exactitude pour toutes les paires")

idxr = K.IndexPesee(Gr, hr)
verifier("l'index recense tous les sites du porteur", length(idxr) == 4)

exact = all(begin
        r0 = K.recherche_par_pesee_de_promesse(Gr, x, y, hr)
        r1 = K.recherche_par_pesee_de_promesse(idxr, x, y)
        r1.chemin == r0.chemin && r1.promesse == r0.promesse && r1.registre == r0.registre
    end for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d])
verifier("l'index rend *exactement* la forme directe (chemin, promesse, registre) — toutes paires",
         exact)

idxv = K.IndexPesee(Gv, hv)
av = K.recherche_par_pesee_de_promesse(idxv, :s, :t; invariant = true)
verifier("l'index porte l'élagage β₀ : même registre que la forme directe, 0 nœud",
         av.chemin == r.chemin && av.promesse == r.promesse && av.registre == r.registre)

idxi = K.IndexPesee(Gi, hr)
avi = K.recherche_par_pesee_de_promesse(idxi, :a, :z; invariant = true)
verifier("l'index reproduit l'élagage hors composante (A-K4⁺, registre identique)",
         !K.trouve(avi) && avi.registre == avec.registre)

rejette("l'index refuse un site non attesté (KeyError)",
        () -> K.recherche_par_pesee_de_promesse(idxr, :a, :zzz))

# ----------------------------------------------------------------------------
#  4. Champ d'attraction de Maât (A4) — champ_vers, descente_par_champ
# ----------------------------------------------------------------------------
section("4. Champ d'attraction de Maât (A4) — champ_vers, promesse_optimale, descente_par_champ")

champ = K.champ_vers(Gv, hv, :t)
verifier("le champ vise la cible demandée et couvre tous les sites",
         champ.but == :t && length(champ.valeur) == 4)
verifier("promesse du but à lui-même = 1,0 (chemin vide)",
         isapprox(K.promesse_optimale(champ, :t), 1.0; atol = 1e-12))
verifier("promesse optimale du départ = oracle exhaustif (0,81)",
         isapprox(K.promesse_optimale(champ, :s), meilleure_promesse(Gv, :s, :t, hv); atol = 1e-12) &&
         isapprox(K.promesse_optimale(champ, :s), 0.81; atol = 1e-12))
verifier("registre consigné (entête + bassin) — aucune exploration",
         length(champ.registre) == 2 && any(l -> occursin("0 nœud développé", l), champ.registre))

dc = K.descente_par_champ(champ, :s)
verifier("objectif : la promesse guide la descente — voie certifiée optimale s→p→t",
         K.trouve(dc) && dc.chemin == [:s, :p, :t] &&
         isapprox(dc.promesse, meilleure_promesse(Gv, :s, :t, hv); atol = 1e-12))
verifier("objectif : la descente ne développe aucun nœud (l'optimum se calcule)",
         any(l -> occursin("0 nœud développé", l), dc.registre))
verifier("descente sur le but : chemin réduit à [t], promesse 1,0",
         K.descente_par_champ(champ, :t).chemin == [:t] &&
         isapprox(K.descente_par_champ(champ, :t).promesse, 1.0; atol = 1e-12))

# équivalence champ / exploration sur le porteur de référence
equiv = all(begin
        ch = K.champ_vers(idxr, y)
        rd = K.descente_par_champ(ch, x)
        r0 = K.recherche_par_pesee_de_promesse(idxr, x, y)
        (K.trouve(rd) == K.trouve(r0)) && isapprox(rd.promesse, r0.promesse; rtol = 1e-12) &&
        (K.trouve(rd) ? (rd.chemin[1] == x && rd.chemin[end] == y) : true)
    end for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d])
verifier("le champ et l'exploration s'accordent (trouvé, promesse, bornes) — toutes paires", equiv)
verifier("recomposition gauche→droite : promesse de la descente identique *au bit près* à l'exploration",
         (r0 = K.recherche_par_pesee_de_promesse(idxv, :s, :t);
          K.descente_par_champ(K.champ_vers(idxv, :t), :s).promesse === r0.promesse))

# OBJECTIF DE QUALITÉ (A4) : là où l'exploration fige un nœud sous-optimal, le champ trouve l'optimum
Gp = porteur_piege()
hp = S.Harmonie(kappa_piege)
idxp = K.IndexPesee(Gp, hp)
rp = K.descente_par_champ(K.champ_vers(idxp, :t), :s)
r0p = K.recherche_par_pesee_de_promesse(idxp, :s, :t)
verifier("champ : le chemin certifié optimal s→a→v→t est retenu",
         rp.chemin == [:s, :a, :v, :t] && isapprox(rp.promesse, 0.9^3; rtol = 1e-12))
verifier("exploration : la fermeture de `visite` à l'insertion fige une voie sous-optimale",
         r0p.chemin != rp.chemin && rp.promesse > r0p.promesse)
@printf("      piège : exploration %s (%.6f) vs champ %s (%.6f) — gain %.1f×\n",
        r0p.chemin, r0p.promesse, rp.chemin, rp.promesse, rp.promesse / r0p.promesse)

# hors bassin (A-K4⁺ obtenu de surcroît) et promesse nulle distinguée
champ_z = K.champ_vers(idxi, :z)
hors = K.descente_par_champ(champ_z, :a)
verifier("hors du bassin : la descente ne trouve rien et le registre le dit",
         !K.trouve(hors) && any(l -> occursin("hors du bassin", l), hors.registre))
verifier("promesse optimale nulle pour une cible hors du bassin",
         K.promesse_optimale(K.champ_vers(idxi, :a), :z) == 0.0)

Gz = porteur_zero()
hz = S.Harmonie(kappa_zero)
idxz = K.IndexPesee(Gz, hz)
chz = K.champ_vers(idxz, :r)
verifier("µ = 0 sur une chaîne existante ⇒ promesse nulle (et non « hors du bassin »)",
         K.promesse_optimale(chz, :p) == 0.0 && !K.hors_bassin(chz, :p))
rz = K.descente_par_champ(chz, :p)
verifier("objectif : la promesse nulle est refusée en le consignant (configuration inadmissible A4)",
         !K.trouve(rz) && any(l -> occursin("promesse nulle", l), rz.registre))
verifier("aucune chaîne dirigée ⇒ « hors du bassin » (et non « promesse nulle »)",
         K.hors_bassin(chz, :iso) &&
         any(l -> occursin("aucune chaîne dirigée", l), K.descente_par_champ(chz, :iso).registre))

# rejets
rejette("champ_vers refuse une cible non attestée (KeyError)", () -> K.champ_vers(idxr, :zzz))
rejette("descente_par_champ refuse un départ non attesté (KeyError)",
        () -> K.descente_par_champ(champ, :zzz))
rejette("promesse_optimale refuse un départ non attesté (KeyError)",
        () -> K.promesse_optimale(champ, :zzz))

# ----------------------------------------------------------------------------
#  5. Dual du champ (une source → toutes les cibles) — champ_depuis, chemin_depuis
# ----------------------------------------------------------------------------
section("5. Dual du champ — champ_depuis, promesse_depuis, chemin_depuis")

cd = K.champ_depuis(idxv, :s)
verifier("le champ dual part de la source demandée", cd.source == :s)
verifier("promesse de la source à elle-même = 1,0",
         isapprox(K.promesse_depuis(cd, :s), 1.0; atol = 1e-12))
verifier("promesse optimale s→t = oracle exhaustif (0,81)",
         isapprox(K.promesse_depuis(cd, :t), meilleure_promesse(Gv, :s, :t, hv); atol = 1e-12))
cdf = K.chemin_depuis(cd, :t)
verifier("objectif : la remontée rend la voie certifiée optimale s→p→t",
         cdf.chemin == [:s, :p, :t] && isapprox(cdf.promesse, 0.81; atol = 1e-12))
verifier("objectif : la remontée ne développe aucun nœud (le champ se calcule)",
         any(l -> occursin("0 nœud développé", l), cdf.registre))

dual = all(begin
        cv = K.champ_vers(idxr, y)
        cd2 = K.champ_depuis(idxr, x)
        rc0 = K.recherche_par_pesee_de_promesse(idxr, x, y)
        rc = K.chemin_depuis(cd2, y)
        isapprox(K.promesse_depuis(cd2, y), K.promesse_optimale(cv, x); rtol = 1e-12) &&
        (K.trouve(rc) == K.trouve(rc0)) && isapprox(rc.promesse, rc0.promesse; rtol = 1e-12)
    end for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d])
verifier("dualité avant/arrière : champ_depuis(x) ≡ champ_vers(y) et ≡ exploration — toutes paires",
         dual)

cdz = K.champ_depuis(idxz, :iso)
verifier("le dual porte la même distinction : `iso` ne peut atteindre `r` (hors du champ)",
         K.hors_bassin(cdz, :r) &&
         any(l -> occursin("aucune chaîne dirigée", l), K.chemin_depuis(cdz, :r).registre))

rejette("champ_depuis refuse une source non attestée (KeyError)", () -> K.champ_depuis(idxr, :zzz))
rejette("chemin_depuis refuse une cible non attestée (KeyError)", () -> K.chemin_depuis(cd, :zzz))
rejette("promesse_depuis refuse une cible non attestée (KeyError)", () -> K.promesse_depuis(cd, :zzz))

# ----------------------------------------------------------------------------
#  6. Méthode 29.2 — inference_gouvernee : épreuve d'explicabilité εX
# ----------------------------------------------------------------------------
section("6. Méthode 29.2 — inference_gouvernee : l'épreuve d'explicabilité gouverne")

regles = Function[p -> p == "fait" ? "conclusion" : nothing]
inf = K.inference_gouvernee(["fait"], regles;
                            justification = Kamitique.Justification("fidèle et claire", true, true))
verifier("une inférence justifiée retient sa conclusion", inf.conforme && inf.conclusion == "conclusion")
verifier("le registre consigne l'application de la règle",
         length(inf.registre) == 2 && any(l -> occursin("règle 1", l), inf.registre))

inf_ko = K.inference_gouvernee(["fait"], regles;
                               justification = Kamitique.Justification("opaque", true, false))
# OBJECTIF AFFICHÉ : « une inférence non justifiée est refusée, même productive »
verifier("objectif : εX échouée ⇒ aucune conclusion retenue, même productive",
         !inf_ko.conforme && inf_ko.conclusion === nothing)
verifier("objectif : l'échec de εX est consigné au registre",
         any(l -> occursin("εX", l), inf_ko.registre))

vide = K.inference_gouvernee(["inconnu"], regles;
                             justification = Kamitique.Justification("fidèle et claire", true, true))
verifier("aucune règle applicable : pas de conclusion, mais justification conforme",
         vide.conclusion === nothing && vide.conforme &&
         any(l -> occursin("aucune règle", l), vide.registre))

verifier("justification valide ssi fidèle *et* intelligible",
         Kamitique.justification_valide(Kamitique.Justification("x", true, true)) &&
         !Kamitique.justification_valide(Kamitique.Justification("x", true, false)) &&
         !Kamitique.justification_valide(Kamitique.Justification("x", false, true)))
verifier("inférence reproductible (même entrée ⇒ même conclusion et même registre)",
         (i1 = K.inference_gouvernee(["fait"], regles;
                                     justification = Kamitique.Justification("fidèle et claire", true, true));
          i2 = K.inference_gouvernee(["fait"], regles;
                                     justification = Kamitique.Justification("fidèle et claire", true, true));
          i1.conclusion == i2.conclusion && i1.registre == i2.registre))

# ----------------------------------------------------------------------------
#  7. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("7. Fidélité au socle et reproductibilité (G5)")

verifier("la recherche ne fait que lire κ et l'heuristique (aucun chiffre inventé)",
         isapprox(rh.promesse, promesse_chemin(rh.chemin, hr; heuristique = heur); atol = 1e-12))
verifier("le champ ne fait que lire κ : valeur = produit recomposé sur le même chemin",
         isapprox(K.descente_par_champ(K.champ_vers(idxr, :d), :a).promesse,
                  promesse_chemin(K.descente_par_champ(K.champ_vers(idxr, :d), :a).chemin, hr); atol = 1e-12))
verifier("recherche reproductible sur le porteur de référence",
         K.recherche_par_pesee_de_promesse(idxr, :a, :d).chemin ==
         K.recherche_par_pesee_de_promesse(idxr, :a, :d).chemin)
verifier("champ reproductible (mêmes valeurs et mêmes successeurs)",
         (c1 = K.champ_vers(idxr, :d); c2 = K.champ_vers(idxr, :d);
          c1.valeur == c2.valeur && c1.succ == c2.succ))
verifier("aucune méthode de la catégorie n'altère un chiffre consigné de κ (résultats = lecture de κ)",
         r.chemin == [:s, :p, :t] && isapprox(r.promesse, 0.81; atol = 1e-12) &&
         isapprox(K.promesse_optimale(K.champ_vers(idxv, :t), :s), 0.81; atol = 1e-12))

# ----------------------------------------------------------------------------
#  8. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 16 (ch. 29) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 16 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 16.")
println("="^70)
