# ============================================================================
#  Benchmark de conformité — la Kamitique atteint-elle TOUS ses objectifs ?
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que le package tient ce qu'il consigne :
#
#    1. la racine fondationnelle — la CQG (A1…A4, Loi Universelle, Heka,
#       manifestation) et la dérivation `ΣK ⇐ {A1…A4}` ;                        (Loi)
#    2. les sept axiomes `ΣK` (A-K1 … A-K7) et les renforcements `A-K4⁺`/`A-K5⁺` ; (Socle)
#    3. les six théorèmes `T-K1` … `T-K6` ;                                       (Socle)
#    4. les quatre écarts `E1`–`E4` (coupure R₀, attracteur, clôture, signature) ;
#    5. la chaîne épistémologique (7 dimensions, axiomes/théorèmes) ;            (Chaine)
#    6. le trièdre `εE/εF/εX` (épreuves de gouvernance, non-compensation) ;      (Méthodologie)
#    7. les cinq critères d'admissibilité et les quatre de conformité ;          (Dispositif)
#    8. la couverture des 17 catégories (tableau 13.1) ;                         (Dispositif)
#    9. le registre extensible des savoirs africains (Ethnomatique) ;
#   10. les gains mesurés `M-04`, `M-05`, `M-06` (reproduction, `G5`).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs.jl
# ============================================================================

using Printf
using Kamitique

const S  = Kamitique.Socle
const P  = Kamitique.Pesee
const C  = Kamitique.Chaine
const M  = Kamitique.Methodologie
const D  = Kamitique.Dispositif
const K  = Kamitique.Categories
const E  = Kamitique.Ethnomatique
const L  = Kamitique.Loi

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

"""Meilleur temps et allocations minimales sur `reps` exécutions (après échauffement)."""
function mesurer(f; reps::Int = 3)
    f()
    tmin = Inf
    bmin = typemax(Int)
    for _ in 1:reps
        r = @timed f()
        tmin = min(tmin, r.time)
        bmin = min(bmin, r.bytes)
    end
    return (temps = tmin, octets = bmin)
end

fmt_temps(t) =
    t < 1e-6 ? @sprintf("%8.1f ns", t * 1e9) :
    t < 1e-3 ? @sprintf("%8.2f µs", t * 1e6) :
    t < 1.0  ? @sprintf("%8.2f ms", t * 1e3) :
               @sprintf("%8.3f s ", t)

"""Nombre de nœuds développés, lu dans le registre d'une recherche (0 si élagage)."""
function noeuds(r::K.ResultatRechercheHeuristique)
    m = match(r"(\d+)\s+nœud", join(r.registre, " "))
    return m === nothing ? 0 : parse(Int, m.captures[1])
end

# ----------------------------------------------------------------------------
#  Fixtures — porteurs situés, bornés, reproductibles
# ----------------------------------------------------------------------------

"""Porteur d'exemple (3 sites, tous à l'échelle 1) — fixture du socle."""
function porteur_exemple()
    G = S.Porteur()
    S.ajouter_site!(G, :g1; lieu = "signe",    voisins = [:g2, :g3])
    S.ajouter_site!(G, :g2; lieu = "source",   voisins = [:g1])
    S.ajouter_site!(G, :g3; lieu = "contexte", voisins = [:g1])
    return G
end

"""Porteur en anneau de N sites (chaque site a deux voisins)."""
function anneau(N::Int)
    G = S.Porteur()
    for i in 1:N
        S.ajouter_site!(G, Symbol("s", i); lieu = "anneau-$i",
                        voisins = [Symbol("s", mod1(i - 1, N)), Symbol("s", mod1(i + 1, N))])
    end
    return G
end

"""Porteur à deux composantes disjointes (anneaux N1 et N2)."""
function composantes(N1::Int, N2::Int)
    G = S.Porteur()
    for i in 1:N1
        S.ajouter_site!(G, Symbol("a", i); lieu = ("A", i),
                        voisins = [Symbol("a", mod1(i - 1, N1)), Symbol("a", mod1(i + 1, N1))])
    end
    for i in 1:N2
        S.ajouter_site!(G, Symbol("b", i); lieu = ("B", i),
                        voisins = [Symbol("b", mod1(i - 1, N2)), Symbol("b", mod1(i + 1, N2))])
    end
    return G
end

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — la Kamitique atteint-elle ses objectifs ?\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. La racine fondationnelle — la CQG dont ΣK dérive
# ----------------------------------------------------------------------------
section("1. Racine fondationnelle — la CQG (chap. 1–4) et la dérivation ΣK ⇐ {A1…A4}")

verifier("quatre axiomes fondamentaux consignés (A1 Noun, A2 Kheper, A3 Spirale, A4 Maât)",
         length(L.AXIOMES_CQG) == 4)
verifier("les quatre axiomes sont tous sollicités par ΣK",
         Set(values(L.DERIVATION_SIGMA_K)) == Set(keys(L.AXIOMES_CQG)))
verifier("sept axiomes ΣK consignés (A-K1 … A-K7)", length(S.AXIOMES) == 7)
verifier("chaque A-K a un motif de dérivation déclaré",
         all(haskey(L.MOTIFS_DERIVATION, ak) for ak in keys(L.DERIVATION_SIGMA_K)))
verifier("dérivation vérifiée : ΣK ⇐ {A1,A2,A3,A4}", L.verifier_derivation())
verifier("nombre d'or — identité φ² = φ + 1", L.verifie_nombre_or())
verifier("spirale d'or — auto-similarité conforme (quart de tour = φ)", L.verifie_autosimilarite())
verifier("coupure conforme R₀ ≠ 0 (A3)", L.COUPURE_R0 != 0)
rejette("coupure R₀ nulle refusée", () -> L.coupure_r0(0.0))
verifier("Ennéade : 9 degrés de liberté topologiques", L.DOF_TOPOLOGIQUES == 9)
verifier("22 Métous consignés (algèbre non commutative)", L.NB_METOUS == 22)
verifier("trois secteurs d'énergie (éther, jauge, morphique)", length(L.SECTEURS_ENERGIE) == 3)
verifier("principe de manifestation — triade Atoum ∘ Ptah ∘ Khnoum", L.verifie_manifestation())

# ----------------------------------------------------------------------------
#  2. Les sept axiomes ΣK — et les renforcements A-K4⁺ / A-K5⁺
# ----------------------------------------------------------------------------
section("2. Axiomes ΣK (A-K1 … A-K7) — vérifiés sur un porteur, un état et une trajectoire")

G = porteur_exemple()
a = S.Figure([:g1]); b = S.Figure([:g2]); c = S.Figure([:g3])
Ψ0 = S.Etat([a, b, c], [0.5, 0.3, 0.2])
h  = S.HarmonieRaffinement()
q  = S.Question(:attestation, S.Proposition("attesté", f -> :g1 in f.sites))
Ψ1, _ = S.κ(Ψ0, q, h)                       # la pesée résout l'état
t = S.Trajectoire(Ψ0)
S.ajouter_pas!(t, :δ, Ψ0, nothing)          # δ : pas horizontal (µ inchangée)
S.ajouter_pas!(t, :κ, Ψ1, (:pesee, q.nom))  # κ : la pesée qui tranche

r = S.verifier_axiomes(G, Ψ0; trajectoire = t, h = h, propositions = q.propositions)

verifier("A-K1 totalité géométrique (figures situées)", r[:AK1])
verifier("A-K2 superposition (présence normalisée, non résolue)", r[:AK2])
verifier("A-K3 valuation continue (degrés dans l'ordre M)", r[:AK3])
verifier("A-K4 processualité gouvernée (pas encadrés)", r[:AK4])
verifier("A-K5 conservation de Maât (µ non décroissante)", r[:AK5])
verifier("A-K6 coupure de résolution (stratification finie et cohérente)", r[:AK6])
verifier("A-K7 fermeture canonique du support (figures closes)", r[:AK7])
verifier("rapport d'axiomes : les sept sont conformes", all(r))

# Renforcements
verifier("A-K4⁺ invariance de signature le long des pas", S.verifie_ak4plus(G, t, h))
verifier("A-K4⁺ : un pas ex nihilo est refusé",
         !S.verifie_invariance_signature(G,
             (let t_ko = S.Trajectoire(S.Etat([S.Figure([:g1])], [1.0]));
                  S.ajouter_pas!(t_ko, :ι, S.Etat([S.Figure([:g2])], [1.0]), nothing)
                  t_ko end)))
verifier("A-K5⁺ progression de Maât (Łojasiewicz)", S.verifie_progression_maat(t, h))
c_est, p_est = S.estime_progression(t, h)
verifier("A-K5⁺ estimation (c,p) certifiée",
         c_est > 0 && p_est >= 1 && S.verifie_progression_maat(t, h; c = c_est, p = p_est))
verifier("A-K5⁺ borne de pas logarithmique (p = 1, c ≥ 1 ⇒ un pas)",
         S.borne_pas_progression(1.0 - h(Ψ0), 1e-9; c = 1.0, p = 1.0) == 1)
rejette("A-K5⁺ constante c = 0 refusée", () -> S.verifie_progression_maat(t, h; c = 0.0))

# ----------------------------------------------------------------------------
#  3. Les six théorèmes fondamentaux T-K1 … T-K6
# ----------------------------------------------------------------------------
section("3. Théorèmes fondamentaux T-K1 … T-K6 (chap. 8)")

configs = [BitVector([0, 0]), BitVector([0, 1]), BitVector([1, 1])]
verifier("T-K1 subsumption binaire (tout régime binaire est un cosmos dégénéré)",
         S.verifie_subsumption_binaire(configs))
d0 = S.degenerer(configs)
verifier("T-K1 l'état résolu reproduit la configuration binaire",
         S.configuration_reproduite(d0) in configs)
verifier("T-K2 gouverne de non-phase (aucune stabilité hors encadrement)",
         S.verifie_gouverne_non_phase(t, h))
verifier("T-K3 convergence de Maât (l'état final est l'attracteur)",
         S.verifie_convergence_maat(t, h))
verifier("T-K3 degré de l'attracteur de Maât µ* = 1", S.attracteur_maat(t, h) ≈ 1.0)
cov = S.completude_couverture([cat.nom for cat in K.CARTE_CATEGORIES])
verifier("T-K4 complétude de couverture (triple substitution par catégorie)",
         length(cov) == 17 &&
         all(haskey(cov[n], :support) && haskey(cov[n], :valuation) && haskey(cov[n], :dynamique)
             for n in keys(cov)))
verifier("T-K5 frugalité structurelle (coût descriptif fini)",
         S.cout_descriptif(Ψ0) >= 0 && S.cout_descriptif(Ψ0) == S.cout_descriptif(Ψ0))
verifier("T-K6 irréversibilité de la pesée (aucune figure écartée n'est restituée)",
         S.verifie_irreversibilite_pesee(Ψ0, 1, h))

# ----------------------------------------------------------------------------
#  4. Les quatre écarts E1–E4 — réparés (M-01 … M-04)
# ----------------------------------------------------------------------------
section("4. Écarts E1–E4 — réajustements M-01 … M-04")

# E1 (M-01) — coupure de résolution R₀ : porteur stratifié fini
Gp = S.Porteur()
S.ajouter_site!(Gp, :a; echelle = 1)
S.ajouter_site!(Gp, :b; echelle = 3, voisins = [:a])
verifier("E1 / M-01 : R₀ explicite — profondeur finie et vérifiable",
         S.profondeur(G) == 1 && S.verifie_ak6(G))
verifier("E1 / M-01 : un saut d'échelle est refusé (contiguïté des voisinages)",
         !S.verifie_ak6(Gp) && S.verifie_ak6(Gp; ecart = 2))

# E2 (M-02) — attracteur unique, écart m_gap > 0
verifier("E2 / M-02 : écart de Maât strict m_gap > 0 (attracteur séparé)",
         S.ecart_maat(h, [Ψ0, Ψ1]) > 0.0)
verifier("E2 / M-02 : plateau ⇒ m_gap = 0 (vacua dégénérés détectés)",
         S.ecart_maat(h, [Ψ1, S.Etat([a], [1.0])]) == 0.0)

# E3 (M-03) — clôture canonique du support
ab_nu  = S.Figure([:g1, :g2])
ab_clos = S.Figure([:g1, :g2]; liens = [(:g1, :g2)])
verifier("E3 / M-03 : clôture idempotente et canonique",
         S.cloture(G, S.cloture(G, ab_nu)) == S.cloture(G, ab_nu) &&
         S.cloture(G, ab_nu) == ab_clos)
verifier("E3 / M-03 : une figure non close est refusée (A-K7)",
         !S.est_close(G, ab_nu) && S.est_close(G, ab_clos))

# E4 (M-04) — invariance de signature
sig = S.signature(G, ab_clos)
verifier("E4 / M-04 : signature décidable (classe de raffinement + profil β₀/β₁)",
         sig.composantes == 1 && sig.cycles == 0)

# ----------------------------------------------------------------------------
#  5. La chaîne épistémologique (7 dimensions, axiomes et théorèmes)
# ----------------------------------------------------------------------------
section("5. Chaîne épistémologique — 7 dimensions, axiomes et théorèmes (chap. 9–12)")

verifier("sept dimensions : 4 étapes de production + 3 gouvernes",
         length(C.DIMENSIONS) == 7 && length(C.etapes()) == 4 && length(C.gouvernes()) == 3)
verifier("axiome 9.1 — insécabilité des sept dimensions", C.verifie_insécabilite())
verifier("axiome 9.3 — prééminence éthique (E = 0 ⇒ rejet)",
         C.verifie_preeminence_ethique(true) && !C.verifie_preeminence_ethique(false))
verifier("axiome 9.4 — frugalité conditionnée à efficacité égale",
         C.verifie_frugalite_conditionnee(1.0, 2.0) && !C.verifie_frugalite_conditionnee(2.0, 1.0))
verifier("axiome 9.5 — explicabilité due (fidélité + intelligibilité)",
         C.verifie_explicabilite_due(C.Justification("juste", true, true)) &&
         !C.verifie_explicabilite_due(C.Justification("flou", true, false)))
d1 = C.Donnee("s", C.Metadonnee("src1", "mode", "t1"))
d2 = C.Donnee("s", C.Metadonnee("src2", "mode", "t2"))
verifier("théorème 10.3 — irréversibilité de l'abstraction (δ non injectif)",
         C.verifie_irreversibilite_abstraction(d1, d2))
info = C.Information("schéma", [d1], [:x], 1.0, 0.3)
T = C.Connaissance("L", ["p"], :deductive)
verifier("axiome 9.2 — non-réduction de la donnée", C.verifie_non_reduction(info, T))
verifier("dérivation opérationnelle complète (tableau 11.1)", M.verifie_derivation())

# ----------------------------------------------------------------------------
#  6. Le trièdre εE / εF / εX — épreuves de gouvernance
# ----------------------------------------------------------------------------
section("6. Trièdre de gouvernance εE/εF/εX (chap. 11) — ordre non compensable")

verifier("trois épreuves, ordre εE → εF → εX non compensable",
         M.ordre_epreuves() == Symbol[:εE, :εF, :εX] && length(M.EPREUVES) == 3)
verifier("proposition 11.3 — non-compensation des épreuves", M.verifie_non_compensation())
verifier("théorème 11.4 — indépendance des trois gouvernes", M.verifie_independance_gouvernes())
verifier("théorème 11.5 — suffisance conjointe E ∧ F ∧ X",
         M.verifie_suffisance_conjointe(true, true, true) &&
         !M.verifie_suffisance_conjointe(true, true, false))

# Processus candidats : sobre, gaspilleur (même efficacité), fautif (meilleure efficacité)
f_bon     = S.Figure([:g1])
f_fautif  = S.Figure([:g2])
contrainte_g1 = P.ContrainteEthique(:attestation, "les savoirs mobilisés sont attestés",
                                    f -> :g1 in f.sites)
j_valide = C.Justification("rendu de compte fidèle et intelligible", true, true)
p_sobre = M.Processus("sobre", f_bon, C.Ressources(1.0, 1.0, 1.0), 2.0, j_valide)
p_gaspi = M.Processus("gaspilleur", f_bon, C.Ressources(9.0, 9.0, 9.0), 2.0, j_valide)
p_fautif = M.Processus("fautif", f_fautif, C.Ressources(0.1, 0.1, 0.1), 100.0, j_valide)

rap = M.passer_epreuves([p_sobre, p_gaspi, p_fautif], C.Frugalite();
                        contraintes = [contrainte_g1])
verifier("εE d'abord (rejet définitif de l'inadmissible)", rap.epsilon_E.conforme)
verifier("εF retient la fonctionnelle minimale à efficacité égale (le sobre)",
         rap.epsilon_F.retenu == 1 && rap.retenu == "sobre")
verifier("εX validée pour le processus retenu", rap.epsilon_X.conforme)
verifier("non-compensation : la meilleure efficacité ne rachète pas un rejet éthique",
         rap.retenu != "fautif")
rap_tout = M.passer_epreuves([p_fautif], C.Frugalite(); contraintes = [contrainte_g1])
verifier("εE seule écarte toutes les candidatures ⇒ rejet définitif",
         rap_tout.rejet_definitif && rap_tout.retenu === nothing)

# ----------------------------------------------------------------------------
#  7. Critères d'admissibilité (5) et de conformité (4)
# ----------------------------------------------------------------------------
section("7. Critères — admissibilité des méthodes (déf. 13.2) et conformité (déf. 13.3)")

verifier("cinq critères d'admissibilité consignés", length(D.CRITERES_ADMISSIBILITE) == 5)
adm = D.AdmissibiliteMethode([true, true, true, true, true])
adm_ko = D.AdmissibiliteMethode([true, false, true, false, true])
verifier("conjonction des cinq critères ⇒ méthode admissible",
         D.admissible(adm) && !D.admissible(adm_ko))
verifier("critères manquants identifiés (registre de la justification)",
         D.criteres_manquants(adm_ko) == [:conduite_chaine, :continuite_classique])

verifier("quatre critères de conformité au socle consignés", length(D.CRITERES_CONFORMITE) == 4)
conf = D.ConformiteSocle([true, true, true, true])
part = D.ConformiteSocle([true, false, true, false])
verifier("conjonction des quatre critères ⇒ structure conforme",
         D.est_conforme(conf) && !D.est_conforme(part))
verifier("mobilisabilité partielle (constituants conformes retenus)",
         D.mobilisable(part) == [:figures_situees, :conduite_encadree])

# ----------------------------------------------------------------------------
#  8. Couverture — les 17 catégories du tableau 13.1
# ----------------------------------------------------------------------------
section("8. Couverture — 17 catégories de problèmes computationnels")

verifier("dix-sept catégories à la carte (tableau 13.1)", length(K.CARTE_CATEGORIES) == 17)
verifier("chapitres 14 à 30 couverts (un chapitre par catégorie)",
         sort([cat.chapitre for cat in K.CARTE_CATEGORIES]) == collect(14:30))
verifier("chaque catégorie porte au moins un problème et une méthode",
         all(!isempty(cat.problemes) && !isempty(cat.methodes) for cat in K.CARTE_CATEGORIES))
verifier("résolution d'une catégorie par nom (recherche par sous-chaîne)",
         K.categorie("Réseaux").chapitre == 23 &&
         K.categorie("apprentissage").chapitre == 30)
rejette("catégorie inconnue refusée", () -> K.categorie("astrologie"))

# ----------------------------------------------------------------------------
#  9. Ethnomatique — le registre extensible des savoirs
# ----------------------------------------------------------------------------
section("9. Ethnomatique — registre extensible des savoirs africains")

verifier("registre non vide et savoir fondateur présent (numération)",
         !isempty(E.savoirs()) && E.savoir_existe(:numeration))
verifier("au moins cinq savoirs effectivement implémentés",
         length(E.savoirs_implementes()) >= 5)
verifier("domaines attestés dans le registre", !isempty(E.domaines_savoirs()))
@printf("      savoirs : %d au total, %d implémentés, %d domaines\n",
        length(E.savoirs()), length(E.savoirs_implementes()), length(E.domaines_savoirs()))

# ----------------------------------------------------------------------------
#  10. Gains mesurés — reproduction de M-04, M-05, M-06
# ----------------------------------------------------------------------------
section("10. Gains mesurés — M-04 (élagage β₀), M-05 (index), M-06 (champ d'attraction)")

# ---- M-04 : A-K4⁺ élague exactement hors de la composante β₀ de départ ----
Gc = composantes(120, 120)
r_faux = K.recherche_par_pesee_de_promesse(Gc, :a1, :b1, h; max_noeuds = length(Gc) + 8,
                                          invariant = false)
r_vrai = K.recherche_par_pesee_de_promesse(Gc, :a1, :b1, h; max_noeuds = length(Gc) + 8,
                                          invariant = true)
n_faux, n_vrai = noeuds(r_faux), noeuds(r_vrai)
@printf("      M-04 : inter-composantes — %d nœud(s) sans invariant vs %d avec (élagage exact)\n",
        n_faux, n_vrai)
verifier("M-04 : l'invariant β₀ élide exactement (0 nœud) là où la recherche nue explore en vain",
         n_vrai == 0 && isempty(r_vrai.chemin) && n_faux > 0 && isempty(r_faux.chemin))
r0i = K.recherche_par_pesee_de_promesse(Gc, :a1, :a60, h; max_noeuds = length(Gc) + 8)
r1i = K.recherche_par_pesee_de_promesse(Gc, :a1, :a60, h; max_noeuds = length(Gc) + 8,
                                        invariant = true)
verifier("M-04 : intra-composantes — l'invariant ne coupe aucune solution (résultats identiques)",
         r0i.chemin == r1i.chemin && r0i.promesse == r1i.promesse && r0i.registre == r1i.registre)

# ---- M-05 : IndexPesee amortit la recherche répétée ----
Gm5 = anneau(1000)
idx5 = K.IndexPesee(Gm5, h)
paires = [(Symbol("s", i), Symbol("s", mod1(i + 250, 1000))) for i in 1:200]

# équivalence stricte sur un échantillon
equi5 = all(paires[1:5]) do (dep, but)
    rd = K.recherche_par_pesee_de_promesse(Gm5, dep, but, h; max_noeuds = 1008)
    ri = K.recherche_par_pesee_de_promesse(idx5, dep, but; max_noeuds = 1008)
    (rd.chemin == ri.chemin) && (rd.promesse == ri.promesse) && (rd.registre == ri.registre)
end
verifier("M-05 : l'index rend exactement la forme directe (chemin, promesse, registre)",
         equi5)

m_dir5 = mesurer(() -> (for (dep, but) in paires
                            K.recherche_par_pesee_de_promesse(Gm5, dep, but, h; max_noeuds = 1008)
                        end); reps = 3)
m_idx5 = mesurer(() -> (for (dep, but) in paires
                            K.recherche_par_pesee_de_promesse(idx5, dep, but; max_noeuds = 1008)
                        end); reps = 3)
gain5_t = m_dir5.temps / m_idx5.temps
gain5_b = m_dir5.octets / max(m_idx5.octets, 1)
@printf("      M-05 : direct %s / index %s ⇒ gain temps %.1f×, alloc %.1f×\n",
        fmt_temps(m_dir5.temps), fmt_temps(m_idx5.temps), gain5_t, gain5_b)
verifier("M-05 : gain de temps significatif et d'allocation significatif",
         gain5_t > 5.0 && gain5_b > 10.0)

# ---- M-06 : le champ d'attraction remplace l'exploration ----
Gm6 = anneau(400)
idx6 = K.IndexPesee(Gm6, h)
cible = Symbol("s", 200)
sources = [Symbol("s", i) for i in 1:400]
m_expl6 = mesurer(() -> (for s in sources
                             K.recherche_par_pesee_de_promesse(idx6, s, cible; max_noeuds = 408)
                         end); reps = 2)
m_champ6 = mesurer(() -> K.champ_vers(idx6, cible); reps = 3)
gain6_t = m_expl6.temps / m_champ6.temps
@printf("      M-06 : exploration %s / une passe %s ⇒ gain %.1f× (n sources → 1 cible)\n",
        fmt_temps(m_expl6.temps), fmt_temps(m_champ6.temps), gain6_t)
verifier("M-06 : une seule passe couvre toutes les sources (gain significatif)", gain6_t > 5.0)

champ6 = K.champ_vers(idx6, cible)
dch = K.descente_par_champ(champ6, Symbol("s", 1))
rex = K.recherche_par_pesee_de_promesse(idx6, Symbol("s", 1), cible; max_noeuds = 408)
verifier("M-06 : la descente recompose l'optimum (bit-exact avec l'exploration, κ constante)",
         dch.promesse == rex.promesse && dch.chemin == rex.chemin)

# ---- M-06 (qualité) : contre-exemple « diamant » — κ variable, l'exploration est sous-optimale
Gd = S.Porteur()
S.ajouter_site!(Gd, :s; voisins = [:a, :b])
S.ajouter_site!(Gd, :a; voisins = [:s, :v])
S.ajouter_site!(Gd, :b; voisins = [:s, :v])
S.ajouter_site!(Gd, :v; voisins = [:a, :b, :t])
S.ajouter_site!(Gd, :t; voisins = [:v])
const _MU_DIAMANT = Dict((:a, :s) => 0.90, (:b, :s) => 0.99, (:a, :v) => 0.90,
                         (:b, :v) => 0.01, (:t, :v) => 0.90)
kappa_diamant(g::S.Figure, hh::S.Figure) =
    (only(g.sites) == only(hh.sites)) ? 1.0 :
    get(_MU_DIAMANT, (min(only(g.sites), only(hh.sites)), max(only(g.sites), only(hh.sites))), 0.8)
hd = S.Harmonie(kappa_diamant)
idx_d = K.IndexPesee(Gd, hd)
r_exp_d = K.recherche_par_pesee_de_promesse(idx_d, :s, :t; max_noeuds = 50)
champ_d = K.champ_vers(idx_d, :t)
r_ch_d = K.descente_par_champ(champ_d, :s)
gain_qual = r_ch_d.promesse / max(r_exp_d.promesse, eps(Float64))
@printf("      M-06 : κ variable — exploration %.6f vs champ %.6f ⇒ qualité %.1f×\n",
        r_exp_d.promesse, r_ch_d.promesse, gain_qual)
verifier("M-06 : en κ variable, le champ atteint l'optimum manqué par l'exploration (> 50×)",
         gain_qual > 50.0)

# ----------------------------------------------------------------------------
#  11. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la Kamitique atteint-elle ses objectifs ?")
println("="^70)

sections = unique([r[1] for r in _RESULTATS])
for s in sections
    n_ok = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    marque = n_ok == n_tot ? "✓" : "✗"
    @printf("  [%s] %-58s %2d/%2d\n", marque, s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN GLOBAL : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements consignés sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements ne sont PAS tenus — voir les lignes [✗] ci-dessus.")
end
println("="^70)
println("  Fin du benchmark de conformité.")
println("="^70)
