# ============================================================================
#  Benchmark de conformité — catégorie 10 : « Réseaux »
#  (chapitre 23 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la dixième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 23, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 23.1 `routage_par_harmonie` : intégrité du chemin retenu,
#       harmonie cumulée (produit des µ, non un compteur de sauts), optimalité,
#       registre, cas limites et rejets ;                                        (Categories)
#    3. la méthode 23.2 `resilience_par_pesee_locale` : voie de contournement
#       d'un site en panne, verdict de résilience pesé par un seuil d'harmonie,
#       registre, cas limites et rejets ;                                        (Categories)
#    4. la méthode 23.3 `protocole_par_composition` : un protocole réseau lu comme
#       figure stratifiée (couches = échelles, A-K6), accord cumulé, conformité
#       (pas de saut d'échelle, trame close A-K7), rejets ;                      (Categories)
#    5. la méthode 23.4 `transmission_longue_portee` : gros contenu fragmenté puis
#       recomposé par ⊙, rendement mesuré (sites livrés / relais), intégrité et
#       cas limites — sans revendication de débit physique ;                     (Categories)
#    6. la méthode 23.5 `resoudre_adresse` / `naviguer_toile` : la toile par figures —
#       un document est un site (adresse = lieu, hyperlien = voisinage attesté),
#       résolution relationnelle par pesée, navigation par harmonie (A-K7) ;      (Categories)
#    7. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ (G5).
#
#  La carte consigne cinq méthodes pour cette catégorie — « routage par harmonie »,
#  « résilience par pesée locale », « protocole par composition », « transmission
#  longue portée » et « toile par figures » — toutes exposées par le module Categories
#  (cf. src/categories/Categories.jl).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch23.jl
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

"""Porteur réseau : trois routes de `s` à `t` de longueurs croissantes."""
function porteur_reseau()
    G = S.Porteur()
    S.ajouter_site!(G, :s;  voisins = [:t, :p, :q1])
    S.ajouter_site!(G, :p;  voisins = [:t])
    S.ajouter_site!(G, :q1; voisins = [:q2])
    S.ajouter_site!(G, :q2; voisins = [:t])
    S.ajouter_site!(G, :t)
    return G
end

"""Compatibilité des pas : µ(s,t) = 0,6 ; µ par p = 0,9 ; µ par q = 0,95."""
const _MU_RESEAU = Dict((:s, :t) => 0.6,
                        (:s, :p) => 0.9,  (:p, :t)  => 0.9,
                        (:s, :q1) => 0.95, (:q1, :q2) => 0.95, (:q2, :t) => 0.95)
"""κ symétrique : la table est consultée dans les deux ordres de la paire."""
function kappa_reseau(g::S.Figure, hh::S.Figure)
    a, b = only(g.sites), only(hh.sites)
    a == b && return 1.0
    return get(_MU_RESEAU, (a, b), get(_MU_RESEAU, (b, a), 0.8))
end

"""Porteur déconnecté : `s`—`m` d'un côté, `t` isolé de l'autre (aucun chemin s→t)."""
function porteur_isole()
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

"""Pile de protocole : cinq couches contiguës (échelles 1..5) plus une couche
homonyme d'échelle 2 (`:liaison2`) pour éprouver le cas « même échelle »."""
function porteur_pile()
    G = S.Porteur()
    S.ajouter_site!(G, :physique;    echelle = 1, voisins = [:liaison])
    S.ajouter_site!(G, :liaison;     echelle = 2, voisins = [:physique, :reseau, :liaison2])
    S.ajouter_site!(G, :liaison2;    echelle = 2, voisins = [:liaison])
    S.ajouter_site!(G, :reseau;      echelle = 3, voisins = [:liaison, :transport])
    S.ajouter_site!(G, :transport;   echelle = 4, voisins = [:reseau, :application])
    S.ajouter_site!(G, :application; echelle = 5, voisins = [:transport])
    return G
end

"""Réseau longue portée : chaîne de `n` relais `r1 — … — rn`, plus `m` unités de
contenu isolées `u1 … um` (les trames d'un contenu : voix, image)."""
function porteur_longue_portee(n::Int, m::Int)
    G = S.Porteur()
    S.ajouter_site!(G, :r1; voisins = [:r2])
    for i in 2:(n - 1)
        S.ajouter_site!(G, Symbol("r", i); voisins = [Symbol("r", i - 1), Symbol("r", i + 1)])
    end
    S.ajouter_site!(G, Symbol("r", n); voisins = [Symbol("r", n - 1)])
    for j in 1:m
        S.ajouter_site!(G, Symbol("u", j))
    end
    return G
end

"""Toile kamitique : documents adressés par `lieu` (échelles 1..4 contiguës, A-K6),
reliés d'abord par voisinage, puis par un hyperlien posé par `lier!`."""
function porteur_toile()
    G = S.Porteur()
    S.ajouter_site!(G, :accueil;   lieu = "kamitique/accueil",   echelle = 1, voisins = [:theorie])
    S.ajouter_site!(G, :theorie;   lieu = "kamitique/theorie",   echelle = 2, voisins = [:accueil, :reseaux])
    S.ajouter_site!(G, :reseaux;   lieu = "kamitique/reseaux",   echelle = 3, voisins = [:theorie])
    S.ajouter_site!(G, :glossaire; lieu = "kamitique/glossaire", echelle = 4)
    K.lier!(G, :reseaux, :glossaire)
    return G
end

"""κ de la toile : raffinement (0,8 entre documents disjoints) sauf pour les homonymes
de lieu, où le voisinage du requérant départage."""
const _MU_TOILE = Dict((:requerant, :mairie_centre) => 0.95,
                       (:requerant, :mairie_nord)   => 0.6)
function kappa_toile(g::S.Figure, hh::S.Figure)
    a, b = only(g.sites), only(hh.sites)
    a == b && return 1.0
    return get(_MU_TOILE, (a, b), get(_MU_TOILE, (b, a), 0.8))
end

# --- contrôle indépendant de la règle de routage (méthode 23.1) -------------

"""Produit des compatibilités µ des pas successifs d'un chemin (recalcul indépendant)."""
function harmonie_cumulee(chemin::Vector{Symbol}, h::S.Harmonie)
    p = 1.0
    for t in 2:length(chemin)
        p *= clamp(float(h.compatibilite(S.Figure([chemin[t - 1]]), S.Figure([chemin[t]]))),
                   0.0, 1.0)
    end
    return p
end

"""Énumère exhaustivement les chemins simples de `depart` à `arrivee` (contrôle indépendant)."""
function chemins_simples(G::S.Porteur, depart::Symbol, arrivee::Symbol)
    resultats = Vector{Symbol}[]
    function explorer(chemin::Vector{Symbol})
        courant = chemin[end]
        courant == arrivee && (push!(resultats, copy(chemin)); return)
        for v in S.voisins(G, courant)
            haskey(G, v) || continue
            v in chemin && continue
            explorer(vcat(chemin, v))
        end
    end
    explorer(Symbol[depart])
    return resultats
end

"""Harmonie cumulée maximale sur tous les chemins simples (−1,0 si aucun chemin)."""
function harmonie_maximale(G::S.Porteur, depart::Symbol, arrivee::Symbol, h::S.Harmonie)
    best = -1.0
    for c in chemins_simples(G, depart, arrivee)
        best = max(best, harmonie_cumulee(c, h))
    end
    return best
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 10 : Réseaux\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 23) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[10]
verifier("dixième entrée de la carte = « Réseaux »",
         cat.nom == "Réseaux")
verifier("chapitre 23 consigné", cat.chapitre == 23)
verifier("sept problèmes attestés (routage, équilibrage, résilience, protocoles, transmission longue portée, nommage, navigation)",
         cat.problemes == ["routage", "équilibrage", "résilience", "protocoles", "transmission longue portée",
                           "nommage", "navigation"])
verifier("méthodes consignées (routage par harmonie, résilience par pesée locale, protocole par composition, transmission longue portée, toile par figures)",
         all(m in cat.methodes for m in ["routage par harmonie", "résilience par pesée locale",
                                         "protocole par composition", "transmission longue portée",
                                         "toile par figures"]))
verifier("résolution de la catégorie par nom", K.categorie("Réseaux").chapitre == 23)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Réseaux") &&
         all(haskey(cov["Réseaux"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 23.1 — routage_par_harmonie
# ----------------------------------------------------------------------------
section("2. Méthode 23.1 — routage_par_harmonie : chemin, harmonie cumulée, optimalité")

Gr = porteur_reseau()
hr = S.Harmonie(kappa_reseau)
fl = K.routage_par_harmonie(Gr, :s, :t, hr)

verifier("un chemin est trouvé de la source au puits", K.trouve(fl))
verifier("le chemin relie bien source → puits (bornes : s … t)",
         first(fl.chemin) == :s && last(fl.chemin) == :t)
verifier("le chemin ne mobilise que des sites attestés du porteur",
         all(s -> haskey(Gr, s), fl.chemin))
verifier("le chemin est simple (aucun site visité deux fois)",
         length(unique(fl.chemin)) == length(fl.chemin))
verifier("chemin retenu = produit des µ le plus haut (3 pas par q ≻ 2 par p ≻ direct)",
         fl.chemin == [:s, :q1, :q2, :t])
verifier("harmonie = produit des compatibilités µ des pas (recalculée)",
         isapprox(fl.harmonie, harmonie_cumulee(fl.chemin, hr); atol = 1e-12))
verifier("harmonie dans [0, 1]", 0.0 <= fl.harmonie <= 1.0)
verifier("optimalité : harmonie = maximum sur tous les chemins simples (énumération exhaustive)",
         isapprox(fl.harmonie, harmonie_maximale(Gr, :s, :t, hr); atol = 1e-12))
verifier("registre consigné (chemin retenu + harmonie cumulée)", length(fl.registre) == 2)
verifier("le registre nomme l'harmonie cumulée",
         any(l -> occursin("harmonie cumulée", l), fl.registre))

# OBJECTIF AFFICHÉ : « Le routage conserve une harmonie, non un compteur de sauts »
verifier("objectif affiché : le chemin retenu ne minimise pas les sauts (3 pas ≻ la route directe)",
         length(fl.chemin) > 2)
verifier("objectif affiché : l'harmonie du chemin retenu dépasse celle de la route directe",
         fl.harmonie > _MU_RESEAU[(:s, :t)])
@printf("      routes s→t : directe (µ 0,6) · par p (µ 0,81) · par q (µ %.4f)\n",
        _MU_RESEAU[(:s, :q1)] * _MU_RESEAU[(:q1, :q2)] * _MU_RESEAU[(:q2, :t)])
@printf("      chemin retenu : %s ; harmonie cumulée = %.6f\n", fl.chemin, fl.harmonie)

# déterminisme
verifier("routage déterministe (même entrée ⇒ même chemin et même harmonie)",
         (r = K.routage_par_harmonie(Gr, :s, :t, hr);
          r.chemin == fl.chemin && r.harmonie == fl.harmonie))

# cas limite : aucun chemin
Gi = porteur_isole()
fi = K.routage_par_harmonie(Gi, :s, :t, hr)
verifier("aucun chemin : chemin vide, harmonie −1,0 et non trouvé",
         isempty(fi.chemin) && fi.harmonie == -1.0 && !K.trouve(fi))
verifier("aucun chemin : registre consigné (une ligne, « aucun chemin »)",
         length(fi.registre) == 1 && occursin("aucun chemin", fi.registre[1]))

# borne de profondeur
Gc = porteur_chaine(7)
h0 = S.HarmonieRaffinement()
fl_court = K.routage_par_harmonie(Gc, :c1, :c7, h0; max_profondeur = 4)
fl_long  = K.routage_par_harmonie(Gc, :c1, :c7, h0; max_profondeur = 7)
verifier("borne de profondeur respectée (max_profondeur = 4 < 7 ⇒ aucun chemin)",
         isempty(fl_court.chemin) && fl_court.harmonie == -1.0)
verifier("profondeur suffisante (max_profondeur = 7) ⇒ chemin trouvé",
         K.trouve(fl_long) && length(fl_long.chemin) == 7)

# rejets
rejette("source non attestée refusée", () -> K.routage_par_harmonie(Gr, :zz, :t, hr))
rejette("puits non attesté refusé", () -> K.routage_par_harmonie(Gr, :s, :zz, hr))

# ----------------------------------------------------------------------------
#  3. Méthode 23.2 — resilience_par_pesee_locale
# ----------------------------------------------------------------------------
section("3. Méthode 23.2 — resilience_par_pesee_locale : contournement, seuil de résilience")

# la voie par q (µ ≈ 0,857) évite p ; la voie par p (µ = 0,81) évite q1
re_q1 = K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :q1)
re_p  = K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :p)

verifier("une voie de contournement est trouvée quand elle subsiste", K.trouve(re_q1))
verifier("la voie retenue relie bien source → puits (s … t)",
         first(re_q1.chemin) == :s && last(re_q1.chemin) == :t)
verifier("le site en panne est évité (aucune occurrence de :q1)", !(:q1 in re_q1.chemin))
verifier("harmonie = produit des µ des pas (recalculée indépendamment)",
         isapprox(re_q1.harmonie, harmonie_cumulee(re_q1.chemin, hr); atol = 1e-12))
verifier("contournement optimal : panne :q1 ⇒ meilleure voie restante par p (µ 0,81)",
         isapprox(re_q1.harmonie, 0.81; atol = 1e-12) && re_q1.chemin == [:s, :p, :t])
verifier("contournement optimal : panne :p ⇒ meilleure voie restante par q (µ 0,857375)",
         isapprox(re_p.harmonie, 0.857375; atol = 1e-12) && re_p.chemin == [:s, :q1, :q2, :t])
verifier("registre consigné (voie, harmonie, verdict)", length(re_q1.registre) == 3)

# OBJECTIF AFFICHÉ : « résilient si une voie subsiste et que son harmonie atteint seuil »
verifier("objectif : résilient (voie subsiste et harmonie ≥ seuil 0,0)", re_q1.resilient)
re_haut = K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :q1, seuil = 0.9)
verifier("objectif : seuil 0,9 non atteint (µ 0,81) ⇒ non résilient, la voie pourtant trouvée",
         !re_haut.resilient && K.trouve(re_haut))
@printf("      panne :q1 ⇒ voie %s (µ %.6f) ; seuil 0,9 ⇒ résilient = %s\n",
        re_q1.chemin, re_q1.harmonie, re_haut.resilient)

# panne qui coupe toute voie
re_t = K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :t)
verifier("panne sur le puits ⇒ aucune voie, non résilient",
         !re_t.resilient && isempty(re_t.chemin))
verifier("aucune voie : registre consigné (une ligne, « aucune voie »)",
         length(re_t.registre) == 1 && occursin("aucune voie", re_t.registre[1]))

# déterminisme et rejets
verifier("résilience déterministe (même entrée ⇒ même voie, même verdict)",
         (a = K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :q1);
          b = K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :q1);
          a.chemin == b.chemin && a.harmonie == b.harmonie && a.resilient == b.resilient))
rejette("panne non attestée refusée",
        () -> K.resilience_par_pesee_locale(Gr, :s, :t, hr; panne = :zz))
rejette("source non attestée refusée",
        () -> K.resilience_par_pesee_locale(Gr, :zz, :t, hr; panne = :q1))
rejette("puits non attesté refusé",
        () -> K.resilience_par_pesee_locale(Gr, :s, :zz, hr; panne = :q1))

# ----------------------------------------------------------------------------
#  4. Méthode 23.3 — protocole_par_composition
# ----------------------------------------------------------------------------
section("4. Méthode 23.3 — protocole_par_composition : pile stratifiée, accord, conformité (A-K6/A-K7)")

# couches distinctes ⇒ µ = 0,8 entre couches contiguës (raffinement, figures disjointes)
hp = S.HarmonieRaffinement()
Gp = porteur_pile()
proto = K.protocole_par_composition(Gp, [:application, :physique, :transport, :reseau, :liaison], hp)

verifier("les couches sont ordonnées par échelle croissante (encapsulation du bas vers le haut)",
         proto.couches == [:physique, :liaison, :reseau, :transport, :application])
verifier("la trame compose les cinq couches (aucun site perdu, A-K7)",
         length(proto.trame.sites) == 5)
verifier("la trame est close sous ⊙ (est_close : A-K7)", S.est_close(Gp, proto.trame))
verifier("accord cumulé = produit des µ des couches contiguës (recalcul indépendant)",
         isapprox(proto.harmonie, 0.8^4; atol = 1e-12))
verifier("accord dans [0, 1]", 0.0 <= proto.harmonie <= 1.0)
verifier("pile contiguë (échelles 1..5) ⇒ conforme (A-K6)", proto.conforme)
verifier("registre consigné (ordre, échelles, accord, verdict)", length(proto.registre) == 5)

# OBJECTIF AFFICHÉ : « la hiérarchie ne saute pas d'échelle sans passer par les intermédiaires »
saut = K.protocole_par_composition(Gp, [:physique, :reseau], hp)          # échelles 1 puis 3
meme = K.protocole_par_composition(Gp, [:liaison, :liaison2], hp)         # échelles 2 puis 2
verifier("objectif affiché : pile qui saute une couche (1 → 3) ⇒ non conforme",
         !saut.conforme)
verifier("deux couches de même échelle (2, 2) ⇒ non conforme (ce n'est pas une encapsulation)",
         !meme.conforme)
@printf("      pile contiguë 1..5 : conforme = %s ; pile 1→3 : conforme = %s ; pile 2,2 : conforme = %s\n",
        proto.conforme, saut.conforme, meme.conforme)

# couche unique : produit vide
p1 = K.protocole_par_composition(Gp, [:reseau], hp)
verifier("couche unique : accord 1,0 (produit vide) et conforme",
         isapprox(p1.harmonie, 1.0; atol = 1e-12) && p1.conforme)

# déterminisme
verifier("protocole déterministe (même entrée ⇒ mêmes couches, même trame, même accord)",
         (q = K.protocole_par_composition(Gp, [:application, :physique, :transport, :reseau, :liaison], hp);
          q.couches == proto.couches && q.trame == proto.trame && q.harmonie == proto.harmonie))

# rejets
rejette("aucune couche refusée", () -> K.protocole_par_composition(Gp, Symbol[], hp))
rejette("couche non attestée refusée", () -> K.protocole_par_composition(Gp, [:physique, :zz], hp))

# ----------------------------------------------------------------------------
#  5. Méthode 23.4 — transmission_longue_portee
# ----------------------------------------------------------------------------
section("5. Méthode 23.4 — transmission_longue_portee : fragmentation, recomposition, rendement mesuré")

# contenu de 1000 unités (trames) porté par une voie de 19 relais ; MTU du lien = 242
Gl = porteur_longue_portee(20, 1000)
hl = S.HarmonieRaffinement()
message = S.Figure([Symbol("u", j) for j in 1:1000])
voie_lr = [Symbol("r", i) for i in 1:20]                 # r1 → r20 (19 relais)
tr = K.transmission_longue_portee(Gl, message, :r1, :r20, hl; capacite = 242, max_profondeur = 32)

verifier("message intégralement recomposé (aucun site de contenu perdu, A-K7)",
         tr.integre && tr.message.sites == message.sites)
verifier("fragmentation : ⌈1000/242⌉ = 5 fragments (consigné au registre)",
         occursin("5 fragment", tr.registre[1]))
verifier("coût = fragments × relais (5 × 19 = 95)",
         tr.cout == 5 * 19)
verifier("harmonie = harmonie cumulée de la voie retenue (recalcul indépendant)",
         isapprox(tr.harmonie, harmonie_cumulee(voie_lr, hl); atol = 1e-12))
verifier("rendement mesuré = sites utiles livrés / relais consommés",
         isapprox(tr.rendement, 1000 / (5 * 19); atol = 1e-12))

# OBJECTIF AFFICHÉ : « l'efficacité est mesurée, et une capacité plus large l'accroît »
tr_grand = K.transmission_longue_portee(Gl, message, :r1, :r20, hl; capacite = 1000, max_profondeur = 32)
verifier("objectif affiché : capacité 1000 ⇒ 1 seul fragment ⇒ coût réduit à 19 relais",
         tr_grand.integre && tr_grand.cout == 19)
verifier("objectif affiché : rendement accru par la capacité (1000/19 ≻ 1000/95)",
         tr_grand.rendement > tr.rendement)
@printf("      contenu 1000 sites · voie 19 relais : MTU 242 → %d fragments, rendement %.4f ; MTU 1000 → 1 fragment, rendement %.4f\n",
        cld(1000, 242), tr.rendement, tr_grand.rendement)

# réseau coupé : aucune voie de r1 à r2 (r2 isolé)
Gcut = S.Porteur()
S.ajouter_site!(Gcut, :r1; voisins = [:x])
S.ajouter_site!(Gcut, :x;  voisins = [:r1])
S.ajouter_site!(Gcut, :r2)
for j in 1:3
    S.ajouter_site!(Gcut, Symbol("u", j))
end
tr_cut = K.transmission_longue_portee(Gcut, S.Figure([:u1, :u2, :u3]), :r1, :r2, hl; capacite = 1)
verifier("réseau coupé : aucune voie ⇒ message non intégral (aucun site livré)",
         !tr_cut.integre && length(tr_cut.message.sites) == 0)
verifier("réseau coupé : harmonie nulle et rendement nul (rien ne passe)",
         tr_cut.harmonie == 0.0 && tr_cut.rendement == 0.0)

# déterminisme
verifier("transmission déterministe (même entrée ⇒ même message, même coût, même rendement)",
         (u = K.transmission_longue_portee(Gl, message, :r1, :r20, hl; capacite = 242, max_profondeur = 32);
          u.message == tr.message && u.cout == tr.cout && u.rendement == tr.rendement))

# rejets
rejette("contenu vide refusé", () -> K.transmission_longue_portee(Gl, S.figure_vide(), :r1, :r20, hl))
rejette("capacité nulle refusée", () -> K.transmission_longue_portee(Gl, message, :r1, :r20, hl; capacite = 0))
rejette("site de contenu non attesté refusé",
        () -> K.transmission_longue_portee(Gl, S.Figure([:zz]), :r1, :r20, hl))
rejette("départ non attesté refusé", () -> K.transmission_longue_portee(Gl, message, :zz, :r20, hl))
rejette("arrivée non attestée refusée", () -> K.transmission_longue_portee(Gl, message, :r1, :zz, hl))

# ----------------------------------------------------------------------------
#  6. Méthode 23.5 — toile par figures
# ----------------------------------------------------------------------------
section("6. Méthode 23.5 — toile par figures : adressage relationnel, hyperliens, navigation (A-K7)")

htoile = S.Harmonie(kappa_toile)
Gweb = porteur_toile()

verifier("la toile est stratifiée sans saut d'échelle (A-K6, échelles 1..4)",
         S.verifie_ak6(Gweb))

# adressage relationnel : un nom se résout en un document
r_acc = K.resoudre_adresse(Gweb, "kamitique/accueil", htoile)
verifier("une adresse connue se résout en son document", K.trouve(r_acc) && r_acc.document == :accueil)
verifier("adresse unique : un seul document candidat", length(r_acc) == 1)
verifier("registre consigné (adresse, document, harmonie)", length(r_acc.registre) == 3)
r_abs = K.resoudre_adresse(Gweb, "kamitique/inexistant", htoile)
verifier("adresse inconnue : aucun document retenu (document = nothing, non trouvé)",
         !K.trouve(r_abs) && r_abs.document === nothing && r_abs.harmonie == 0.0)
verifier("résolution déterministe (même adresse ⇒ même document)",
         K.resoudre_adresse(Gweb, "kamitique/reseaux", htoile).document == :reseaux)

# homonymes départagés par le voisinage (pesée), non par une racine globale
Gho = S.Porteur()
S.ajouter_site!(Gho, :requerant)
S.ajouter_site!(Gho, :mairie_centre; lieu = "mairie")
S.ajouter_site!(Gho, :mairie_nord;   lieu = "mairie")
rh = K.resoudre_adresse(Gho, "mairie", htoile; depuis = :requerant)
verifier("homonymes : deux documents candidats pour un même lieu", length(rh) == 2)
verifier("objectif affiché : le requérant le plus harmonieux l'emporte (mairie_centre, µ 0,95)",
         rh.document == :mairie_centre && isapprox(rh.harmonie, 0.95; atol = 1e-12))
rh0 = K.resoudre_adresse(Gho, "mairie", htoile)
verifier("sans requérant : document d'identifiant minimal retenu (résolution déterministe)",
         rh0.document == :mairie_centre)
@printf("      « mairie » : candidats %s ; depuis :requerant ⇒ %s (µ %.2f)\n",
        rh.candidats, rh.document, rh.harmonie)

# hyperlien attesté (symétrique) posé par lier!
verifier("lier! atteste l'hyperlien symétrique (:reseaux ↔ :glossaire)",
         :glossaire in S.voisins(Gweb, :reseaux) && :reseaux in S.voisins(Gweb, :glossaire))

# navigation par hyperliens
nav = K.naviguer_toile(Gweb, :accueil, :glossaire, htoile)
verifier("un parcours par hyperliens relie l'accueil au glossaire", K.trouve(nav))
verifier("le parcours relie bien les bornes (accueil … glossaire)",
         first(nav.chemin) == :accueil && last(nav.chemin) == :glossaire)
verifier("la figure rendue est close (A-K7 : hyperliens situés)", S.est_close(Gweb, nav.figure))
verifier("la figure porte les quatre documents traversés",
         nav.figure.sites == [:accueil, :theorie, :reseaux, :glossaire])
verifier("harmonie cumulée = produit des µ des sauts (recalcul indépendant)",
         isapprox(nav.harmonie, 0.8^3; atol = 1e-12))
verifier("registre consigné (sauts, documents, harmonie)", length(nav.registre) == 3)
verifier("navigation déterministe (même entrée ⇒ même chemin, même harmonie)",
         (n = K.naviguer_toile(Gweb, :accueil, :glossaire, htoile);
          n.chemin == nav.chemin && n.harmonie == nav.harmonie))
@printf("      navigation accueil → glossaire : %s ; harmonie %.6f\n", nav.chemin, nav.harmonie)

# toile non connexe : aucun hyperlien
Gis = S.Porteur()
S.ajouter_site!(Gis, :x; lieu = "x")
S.ajouter_site!(Gis, :y; lieu = "y")
nav_vide = K.naviguer_toile(Gis, :x, :y, htoile)
verifier("aucun hyperlien : chemin vide, figure vide et harmonie nulle",
         !K.trouve(nav_vide) && isempty(nav_vide.figure.sites) && nav_vide.harmonie == 0.0)

# rejets
rejette("document non attesté (lier!) refusé", () -> K.lier!(Gweb, :accueil, :zz))
rejette("hyperlien réflexif refusé", () -> K.lier!(Gweb, :accueil, :accueil))
rejette("requérant non attesté (résolution) refusé",
        () -> K.resoudre_adresse(Gweb, "kamitique/accueil", htoile; depuis = :zz))
rejette("document de départ non attesté (navigation) refusé",
        () -> K.naviguer_toile(Gweb, :zz, :glossaire, htoile))
rejette("document d'arrivée non attesté (navigation) refusé",
        () -> K.naviguer_toile(Gweb, :accueil, :zz, htoile))

# ----------------------------------------------------------------------------
#  7. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("7. Fidélité au socle et reproductibilité (G5)")

verifier("le routage ne fait que lire κ (aucune figure ni chiffre inventé)",
         isapprox(fl.harmonie, harmonie_cumulee(fl.chemin, hr); atol = 1e-12))
verifier("routage reproductible (deux appels ⇒ chemin et harmonie identiques)",
         (a = K.routage_par_harmonie(Gr, :s, :t, hr);
          b = K.routage_par_harmonie(Gr, :s, :t, hr);
          a.chemin == b.chemin && a.harmonie == b.harmonie))
verifier("l'harmonie rendue égale le goulot harmonique du chemin retenu (lecture de κ)",
         (G8 = porteur_chaine(8);
          f8 = K.routage_par_harmonie(G8, :c1, :c8, h0; max_profondeur = 8);
          isapprox(f8.harmonie, harmonie_cumulee(f8.chemin, h0); atol = 1e-12)))
verifier("aucune méthode de la catégorie n'altère un chiffre consigné de κ (résultat = lecture de κ)",
         K.routage_par_harmonie(Gr, :s, :t, hr).harmonie ==
         _MU_RESEAU[(:s, :q1)] * _MU_RESEAU[(:q1, :q2)] * _MU_RESEAU[(:q2, :t)])
verifier("le protocole ne fait que lire κ (accord = produit des µ, aucune valeur inventée)",
         isapprox(proto.harmonie, 0.8^4; atol = 1e-12))
verifier("la transmission ne fait que lire κ (harmonie = produit des µ de la voie)",
         isapprox(tr.harmonie, harmonie_cumulee(voie_lr, hl); atol = 1e-12))
verifier("la résolution d'adresse ne fait que lire κ (harmonie = µ(requérant, document))",
         isapprox(rh.harmonie, 0.95; atol = 1e-12))
verifier("la navigation ne fait que lire κ (harmonie = produit des µ des sauts)",
         isapprox(nav.harmonie, 0.8^3; atol = 1e-12))

# ----------------------------------------------------------------------------
#  8. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 10 (ch. 23) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 10 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 10.")
println("="^70)
