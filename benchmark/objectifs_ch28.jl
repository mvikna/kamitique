# ============================================================================
#  Benchmark de conformité — catégorie 15 : « Ingénierie des connaissances »
#  (chapitre 28 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la quinzième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 28, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la constante `ETAPES_ACQUISITION` : les cinq pas de la méthode 28.1 ;    (Categories)
#    3. la méthode 28.1 `acquisition_par_pesee` : recueillir (savoirs situés),
#       formaliser (composition ⊙), valider à deux balances (εE puis µ),
#       restituer, registre, cas limites et rejets ;                             (Categories)
#    4. la méthode 28.2 `raisonnement_par_composition` : seules les prémisses
#       satisfaisant la règle sont retenues, composition de la conclusion,
#       prémisses écartées consignées, cas limites et rejets ;                   (Categories)
#    5. la fidélité au socle : aucun chiffre rendu ne s'écarte de κ/µ (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch28.jl
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

"""Porteur de savoirs : chaîne `s1` — `s2` — `s3` (voisinages attestés)."""
function porteur_savoirs()
    G = S.Porteur()
    S.ajouter_site!(G, :s1; voisins = [:s2])
    S.ajouter_site!(G, :s2; voisins = [:s1, :s3])
    S.ajouter_site!(G, :s3; voisins = [:s2])
    return G
end

const G  = porteur_savoirs()
const fa = S.Figure([:s1])            # savoir situé
const fb = S.Figure([:s2])            # savoir situé
const fc = S.Figure([:s3])            # savoir situé
const fx = S.Figure([:x])             # savoir NON situé (hors du porteur)

"""Harmonie par défaut : cohérence de l'emboîtement par le raffinement ≺."""
const h = S.HarmonieRaffinement()

"""Harmonie constante : µ = 0,3 quelle que soit la figure (pour éprouver la balance de pesée)."""
const h_bas = S.Harmonie((g, hh) -> 0.3)

# --- contrôles indépendants -------------------------------------------------

"""µ du socle relue sur l'état résolu de la figure (contrôle indépendant)."""
mu_independante(figure::S.Figure, harmonie::S.Harmonie) =
    float(harmonie(S.Etat([figure], [1.0])))

"""
    attestation_attendue(figure, h, contraintes, seuil) -> Bool

Attestation recalculée : la conjonction des *deux balances* — éthique (εE) puis pesée
(µ ≥ seuil) — la règle même de l'étape *valider à deux balances* (méthode 28.1).
"""
function attestation_attendue(figure::S.Figure, harmonie::S.Harmonie,
                              contraintes::AbstractVector{ContrainteEthique}, seuil::Real)
    ok_ethique, _ = admissibilite(figure, contraintes)
    return ok_ethique && mu_independante(figure, harmonie) >= seuil - 1e-9
end

"""Indices des prémisses satisfaisant `regle` (contrôle indépendant de la règle 28.2)."""
retenues_par_regle(premisses::AbstractVector{S.Figure}, regle::Function) =
    Int[k for (k, f) in enumerate(premisses) if regle(f)]

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 15 : Ingénierie des connaissances\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 28) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[15]
verifier("quinzième entrée de la carte = « Ingénierie des connaissances »",
         cat.nom == "Ingénierie des connaissances")
verifier("chapitre 28 consigné", cat.chapitre == 28)
verifier("trois problèmes attestés (acquisition, organisation, inférence)",
         cat.problemes == ["acquisition", "organisation", "inférence"])
verifier("méthodes consignées (acquisition par pesée, raisonnement par composition)",
         "acquisition par pesée" in cat.methodes &&
         "raisonnement par composition" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("connaissances").chapitre == 28)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Ingénierie des connaissances") &&
         all(haskey(cov["Ingénierie des connaissances"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Constante — ETAPES_ACQUISITION (les cinq pas de la méthode 28.1)
# ----------------------------------------------------------------------------
section("2. Constante ETAPES_ACQUISITION — les cinq pas de l'acquisition")

verifier("constante ETAPES_ACQUISITION : cinq pas",
         length(K.ETAPES_ACQUISITION) == 5)
verifier("les cinq pas dans l'ordre énoncé (problématiser, recueillir, formaliser, " *
         "valider à deux balances, restituer)",
         K.ETAPES_ACQUISITION == ["problématiser", "recueillir", "formaliser",
                                  "valider à deux balances", "restituer"])
verifier("les cinq pas sont des chaînes distinctes", allunique(K.ETAPES_ACQUISITION))

ac = K.acquisition_par_pesee(G, [fa, fb], h)
verifier("toute acquisition restitue les cinq pas franchis (copie de la constante)",
         ac.etapes == K.ETAPES_ACQUISITION && length(ac.etapes) == 5)

# ----------------------------------------------------------------------------
#  3. Méthode 28.1 — acquisition_par_pesee
# ----------------------------------------------------------------------------
section("3. Méthode 28.1 — acquisition_par_pesee : recueillir, formaliser, deux balances")

verifier("formaliser par ⊙ : figure de savoir composée des deux sites",
         ac.figure.sites == [:s1, :s2])
verifier("formaliser par ⊙ : liens attestés par G conservés (s1 — s2)",
         ac.figure == S.Figure([:s1, :s2]; liens = [(:s1, :s2)]))
verifier("savoir attesté (les deux balances franchies)", ac.attestee)
verifier("registre consigné (entête, figure, deux balances, restitution)",
         length(ac.registre) == 5)

# OBJECTIF AFFICHÉ : « recueillir (n'admettre que des savoirs situés dans G) »
ac_mix = K.acquisition_par_pesee(G, [fa, fx, fb], h)
verifier("objectif de recueillement : le savoir non situé est écarté de la figure de savoir",
         !(:x in ac_mix.figure.sites))
verifier("recueillir : seuls les savoirs situés composent la figure de savoir",
         ac_mix.figure.sites == [:s1, :s2])
verifier("recueillir : l'exclusion est consignée dans le registre",
         any(l -> occursin("non situé", l), ac_mix.registre) && length(ac_mix.registre) == 6)

# OBJECTIF AFFICHÉ : « un savoir n'est attesté que s'il passe les deux balances »
verifier("balance de pesée : µ recalculée indépendamment (socle) et consignée",
         isapprox(mu_independante(ac.figure, h), 1.0; atol = 1e-12) &&
         any(l -> occursin("balance de pesée", l), ac.registre))

ac_eth = K.acquisition_par_pesee(G, [fa, fb], h;
                                 contraintes = [ContrainteEthique(:refus, "refus de test", _ -> false)])
verifier("échec de la balance éthique ⇒ savoir non attesté (malgré µ = 1)",
         !ac_eth.attestee && any(l -> occursin("violée", l), ac_eth.registre))

ac_pes = K.acquisition_par_pesee(G, [fa, fb], h_bas; seuil_harmonie = 0.5)
verifier("échec de la balance de pesée (µ < seuil) ⇒ savoir non attesté",
         !ac_pes.attestee && any(l -> occursin("non attesté", l), ac_pes.registre))

ac_pes_ok = K.acquisition_par_pesee(G, [fa, fb], h_bas; seuil_harmonie = 0.2)
verifier("balance de pesée franchie (µ ≥ seuil) ⇒ savoir attesté", ac_pes_ok.attestee)

verifier("attestation = conjonction des deux balances (recalcul indépendant)",
         ac.attestee == attestation_attendue(ac.figure, h, contraintes_ethiques_canoniques(), 0.0) &&
         ac_pes.attestee == attestation_attendue(ac_pes.figure, h_bas, contraintes_ethiques_canoniques(), 0.5))
@printf("      figure de savoir = %s · attestée = %s · pas = %s\n",
        ac.figure.sites, ac.attestee, ac.etapes)

# cas limites, déterminisme et rejets
ac1 = K.acquisition_par_pesee(G, [fa], h)
verifier("cas n = 1 : savoir unique repris tel quel (aucune composition), attesté",
         ac1.figure == fa && ac1.attestee && length(ac1.registre) == 5)
verifier("acquisition déterministe (même entrée ⇒ même figure, attestation, pas, registre)",
         (r1 = K.acquisition_par_pesee(G, [fa, fb], h);
          r2 = K.acquisition_par_pesee(G, [fa, fb], h);
          r1.figure == r2.figure && r1.attestee == r2.attestee &&
          r1.etapes == r2.etapes && r1.registre == r2.registre))
rejette("aucun savoir à recueillir refusé",
        () -> K.acquisition_par_pesee(G, S.Figure[], h))
rejette("aucun savoir situé dans le porteur refusé",
        () -> K.acquisition_par_pesee(G, [fx], h))

# ----------------------------------------------------------------------------
#  4. Méthode 28.2 — raisonnement_par_composition
# ----------------------------------------------------------------------------
section("4. Méthode 28.2 — raisonnement_par_composition : prémisses retenues, conclusion")

premisses = [fa, fb, fc]
regle = f -> !(:s3 in f.sites)
rs = K.raisonnement_par_composition(premisses, regle; G = G)

verifier("prémisses retenues = celles qui satisfont la règle (recalcul indépendant)",
         rs.retenues == retenues_par_regle(premisses, regle) && rs.retenues == [1, 2])
verifier("prémisses écartées consignées (aucune n'est tue)", rs.ecartees == [3])
verifier("conclusion composée des seules prémisses retenues", rs.conclusion.sites == [:s1, :s2])
verifier("conclusion par ⊙ : liens attestés par G conservés (s1 — s2)",
         rs.conclusion == S.Figure([:s1, :s2]; liens = [(:s1, :s2)]))
verifier("registre consigné (entête, retenues, écartées, conclusion)", length(rs.registre) == 4)
verifier("la ligne des écartées nomme les indices écartés",
         any(l -> occursin("écartées", l) && occursin("3", l), rs.registre))

# OBJECTIF AFFICHÉ : « ne retient que les prémisses qui satisfont regle »
rs_all = K.raisonnement_par_composition(premisses, _ -> true; G = G)
verifier("règle toujours vraie ⇒ toutes les prémisses retenues, aucune écartée",
         rs_all.retenues == [1, 2, 3] && isempty(rs_all.ecartees))
verifier("conclusion = composition de toutes les prémisses (trois sites)",
         rs_all.conclusion.sites == [:s1, :s2, :s3] &&
         rs_all.conclusion == S.Figure([:s1, :s2, :s3]; liens = [(:s1, :s2), (:s2, :s3)]))

rs_un = K.raisonnement_par_composition(premisses, f -> :s1 in f.sites; G = G)
verifier("une seule prémisse retenue ⇒ conclusion = cette prémisse",
         rs_un.retenues == [1] && rs_un.ecartees == [2, 3] && rs_un.conclusion == fa)

rs_sans = K.raisonnement_par_composition([fa, fb], _ -> true)
verifier("sans porteur : composition des prémisses, liens internes seuls",
         rs_sans.conclusion.sites == [:s1, :s2] && isempty(rs_sans.conclusion.liens))

@printf("      prémisses = %s · règle(⊅s3) ⇒ retenues %s · écartées %s · conclusion %s\n",
        [f.sites for f in premisses], rs.retenues, rs.ecartees, rs.conclusion.sites)

verifier("raisonnement déterministe (même entrée ⇒ retenues, écartées, conclusion, registre)",
         (r1 = K.raisonnement_par_composition(premisses, regle; G = G);
          r2 = K.raisonnement_par_composition(premisses, regle; G = G);
          r1.retenues == r2.retenues && r1.ecartees == r2.ecartees &&
          r1.conclusion == r2.conclusion && r1.registre == r2.registre))
rejette("aucune prémisse refusée",
        () -> K.raisonnement_par_composition(S.Figure[], _ -> true))
rejette("aucune prémisse ne satisfait la règle refusé",
        () -> K.raisonnement_par_composition(premisses, _ -> false))

# ----------------------------------------------------------------------------
#  5. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("5. Fidélité au socle et reproductibilité (G5)")

verifier("la figure de savoir rendue = composer_cumule du socle (aucune composition inventée)",
         ac.figure == S.composer_cumule([fa, fb]; G = G))
verifier("µ consignée = µ du socle sur l'état résolu de la figure de savoir",
         isapprox(mu_independante(ac.figure, h), float(h(S.Etat([ac.figure], [1.0]))); atol = 1e-12))
verifier("la conclusion du raisonnement = composer_cumule des prémisses retenues (socle)",
         rs.conclusion == S.composer_cumule(premisses[rs.retenues]; G = G))
verifier("reproductible : acquisition et raisonnement réexécutés rendent le même registre",
         (a1 = K.acquisition_par_pesee(G, [fa, fx, fb], h);
          a2 = K.acquisition_par_pesee(G, [fa, fx, fb], h);
          r1 = K.raisonnement_par_composition(premisses, regle; G = G);
          r2 = K.raisonnement_par_composition(premisses, regle; G = G);
          a1.registre == a2.registre && r1.registre == r2.registre))

# ----------------------------------------------------------------------------
#  6. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 15 (ch. 28) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 15 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 15.")
println("="^70)
