# ============================================================================
#  Suite de tests de la Kamitique
# ----------------------------------------------------------------------------
#  Vérifie, module par module, la conformité de l'implémentation au document de
#  référence (Kamitique — Théories, Méthodes et Algorithmes) et au livre de la
#  Cosmologie Quantique Géométrique dont elle dérive.
# ============================================================================
using Test
using Random
using Kamitique

const S = Kamitique.Socle
const P = Kamitique.Pesee
const C = Kamitique.Chaine
const M = Kamitique.Methodologie
const D = Kamitique.Dispositif
const K = Kamitique.Categories
const E = Kamitique.Ethnomatique
const L = Kamitique.Loi

# ----------------------------------------------------------------------------
#  Fixtures communes
# ----------------------------------------------------------------------------
function porteur_exemple()
    G = S.Porteur()
    S.ajouter_site!(G, :g1; lieu = "signe", voisins = [:g2, :g3])
    S.ajouter_site!(G, :g2; lieu = "source", voisins = [:g1])
    S.ajouter_site!(G, :g3; lieu = "contexte", voisins = [:g1])
    return G
end

f1() = S.Figure([:g1]); f2() = S.Figure([:g2]); f3() = S.Figure([:g3])

# ============================================================================
@testset "Socle — le socle formel (CQG)" begin
    G = porteur_exemple()
    a, b, c = f1(), f2(), f3()

    @testset "composition ⊙ et raffinement ≺" begin
        @test (a ⊙ b) ⊙ c == a ⊙ (b ⊙ c)          # associativité
        @test a ⊙ S.figure_vide() == a             # figure neutre
        @test a ≺ (a ⊙ b)                          # compatibilité composition/raffinement
        @test (a ⊙ b).sites == [:g1, :g2]
        @test S.verifier_appartenance(G, a ⊙ b)
    end

    @testset "état en superposition pondérée" begin
        Ψ = S.Etat([a, b, c], [5.0, 3.0, 2.0])
        @test isapprox(sum(Ψ.poids), 1.0; atol = 1e-12)   # la présence est une totalité
        @test isapprox(Ψ.poids[1], 0.5; atol = 1e-12)     # normalisation automatique
        @test S.support_effectif(Ψ) == 3
        @test !S.est_resolu(Ψ)                            # jamais nativement résolu
        @test_throws ArgumentError S.Etat([a], [-1.0])    # poids positifs
    end

    @testset "valuation et harmonie" begin
        Ψ = S.Etat([a, b, c], [0.5, 0.3, 0.2])
        q = S.Question(:attestation, S.Proposition("attesté", f -> :g1 in f.sites))
        @test isapprox(S.valuation(Ψ, q.propositions[1]), 0.5; atol = 1e-12)
        h = S.HarmonieRaffinement()
        @test 0.0 <= h(Ψ) <= 1.0
    end

    @testset "axiomes A-K1 et A-K2" begin
        Ψ = S.Etat([a, b, c], [0.5, 0.3, 0.2])
        @test S.verifie_ak2(Ψ)
        @test S.verifie_ak1(G, Ψ)
    end

    @testset "opérateurs δ et κ" begin
        Ψ = S.Etat([a, b, c], [0.5, 0.3, 0.2])
        h = S.HarmonieRaffinement()
        q = S.Question(:attestation, S.Proposition("attesté", f -> :g1 in f.sites))
        spec = S.δ(Ψ, G)
        @test length(spec.figures) == 3
        Ψr, sc = S.κ(Ψ, q, h)
        @test S.est_resolu(Ψr)                     # la pesée résout
        @test length(sc.scores) == 3
        @test argmax(sc.scores) == 1               # g1 porté par la question l'emporte
    end

    @testset "théorème T-K1 — subsumption binaire" begin
        confs = [BitVector([0, 0]), BitVector([0, 1]), BitVector([1, 0]), BitVector([1, 1])]
        d = S.degenerer(confs)
        @test S.configuration_reproduite(d) == confs[1]   # le binaire est cas dégénéré du kamitique
        @test S.verifie_subsumption_binaire(confs)
    end

    @testset "axiome A-K6 — coupure de résolution" begin
        Gs = S.Porteur()
        S.ajouter_site!(Gs, :r1; echelle = 1, voisins = [:r2])
        S.ajouter_site!(Gs, :r2; echelle = 2, voisins = [:r1, :r3])
        S.ajouter_site!(Gs, :r3; echelle = 3, voisins = [:r2])
        @test S.echelles(Gs) == [1, 2, 3]
        @test S.profondeur(Gs) == 3                        # coupure de résolution finie R = 3
        @test S.verifie_ak6(Gs)
        # un voisinage qui saute une échelle rompt la hiérarchie ordonnée
        Gp = S.Porteur()
        S.ajouter_site!(Gp, :a; echelle = 1, voisins = [:b])
        S.ajouter_site!(Gp, :b; echelle = 3, voisins = [:a])
        @test !S.verifie_ak6(Gp)
        @test S.verifie_ak6(Gp; ecart = 2)
        # le porteur d'exemple, non stratifié (échelle 1 partout), satisfait A-K6
        @test S.profondeur(G) == 1
        @test S.verifie_ak6(G)
        # G2 (T-K1) : le cosmos binaire dégénéré satisfait A-K6 trivialement
        @test S.verifie_ak6(S.degenerer([BitVector([0, 0]), BitVector([0, 1])]).porteur)
        # A-K6 entre dans le rapport d'axiomes
        @test S.verifier_axiomes(G, S.Etat([a], [1.0]))[:AK6]
    end

    @testset "axiome A-K5⁺ — progression de Maât" begin
        h = S.HarmonieRaffinement()
        q = S.Question(:attestation, S.Proposition("attesté", f -> :g1 in f.sites))

        Ψ0 = S.Etat([a, b, c], [0.5, 0.3, 0.2])
        Ψ1, _ = S.κ(Ψ0, q, h)                     # la pesée résout : µ(Ψ1) = 1
        @test S.est_resolu(Ψ1)
        @test h(Ψ1) > h(Ψ0)

        # trajectoire : une structuration (pas horizontal) puis la pesée qui tranche
        t = S.Trajectoire(Ψ0)
        S.ajouter_pas!(t, :δ, Ψ0, nothing)        # δ ne transforme pas ⇒ µ inchangée
        S.ajouter_pas!(t, :κ, Ψ1, (:pesee, q.nom))

        # A-K5 (conservation) est incluse ; A-K5⁺ ajoute la progression
        @test S.verifie_ak5(t, h)
        @test S.verifie_progression_maat(t, h)
        @test S.verifie_progression_maat(t, h; c = 1.0, p = 1.0)   # gain = reste ⇒ c = 1
        @test !S.verifie_progression_maat(t, h; c = 2.0, p = 1.0)  # la borne mord
        @test_throws ArgumentError S.verifie_progression_maat(t, h; c = 0.0)
        @test_throws ArgumentError S.verifie_progression_maat(t, h; p = 0.5)

        # estimation mesurée de (c, p) : la constante est une borne inférieure certifiée
        c, p = S.estime_progression(t, h)
        @test p >= 1.0
        @test c > 0.0
        @test S.verifie_progression_maat(t, h; c = c, p = p)

        # borne de pas : logarithmique pour p = 1
        reste0 = 1.0 - h(Ψ0)
        @test S.borne_pas_progression(reste0, 1e-9; c = 1.0, p = 1.0) == 1   # c ≥ 1 ⇒ un pas
        @test S.borne_pas_progression(reste0, 1e-9; c = 0.1, p = 1.0) >= 1
        @test S.borne_pas_progression(reste0, 1e-3; c = 0.1, p = 1.0) <
              S.borne_pas_progression(reste0, 1e-9; c = 0.1, p = 1.0)        # O(log(1/ε))
        @test S.borne_pas_progression(0.0, 1e-9) == 0

        # écart de Maât m_gap : strict ici, nul sur un plateau (attracteur non unique)
        @test S.ecart_maat(h, [Ψ0, Ψ1]) > 0.0
        @test S.ecart_maat(h, [Ψ1, S.Etat([a], [1.0])]) == 0.0

        # A-K5 = conservation + progression entre dans le rapport d'axiomes
        @test S.verifier_axiomes(G, Ψ0; trajectoire = t, h = h)[:AK5]

        # G2 (T-K1) : dans le cosmos dégénéré µ est constante ⇒ énoncé de progression vide
        d = S.degenerer([BitVector([0, 0]), BitVector([0, 1])])
        @test S.verifie_progression_maat(S.Trajectoire(d.etat), h)
        @test S.ecart_maat(h, [d.etat, d.etat]) == 0.0             # plateau : m_gap nul
    end

    @testset "axiome A-K7 — fermeture canonique du support" begin
        # une figure atomique est close : aucun lien interne
        @test S.est_close(G, a)
        @test S.cloture(G, a) == a

        # A-K7 comble les liens attestés omis : (:g1, :g2) est attesté par G
        ab_nu = S.Figure([:g1, :g2])
        ab_clos = S.Figure([:g1, :g2]; liens = [(:g1, :g2)])
        @test S.cloture(G, ab_nu) == ab_clos
        @test !S.est_close(G, ab_nu)
        @test S.est_close(G, ab_clos)
        @test S.est_close(G, S.site(G, :g1) ⊙ S.site(G, :g2))       # ⊙ porte le lien attesté

        # idempotence : la clôture d'une figure close est elle-même
        @test S.cloture(G, S.cloture(G, ab_nu)) == S.cloture(G, ab_nu)

        # canonicité : deux figures de même arrangement et de liens différents coïncident
        @test S.cloture(G, ab_nu) == S.cloture(G, ab_clos)

        # un lien NON attesté est exclu : une figure close ne porte que des liens situés
        cd = S.Figure([:g2, :g3]; liens = [(:g2, :g3)])
        @test S.cloture(G, cd) == S.Figure([:g2, :g3])
        @test !S.est_close(G, cd)

        # monotonie : le raffinement est préservé par la clôture
        @test S.cloture(G, a) ≺ S.cloture(G, ab_nu)

        # demi-treillis supérieur : reunion est un majorant clos, idempotent, borné
        u = S.reunion(G, a, b)
        @test a ≺ u && b ≺ u
        @test S.reunion(G, a, b) == S.cloture(G, a ⊙ b)
        @test S.est_close(G, u)
        @test S.reunion(G, a, a) == S.cloture(G, a)
        @test S.reunion(G, S.figure_vide(), a) == S.cloture(G, a)   # figure_vide : bas
        @test S.est_close(G, S.figure_totale(G))                    # figure_totale : haut
        @test S.cloture(G, S.figure_totale(G)) == S.figure_totale(G)

        # la clôture du support est la figure_totale restreinte à l'union des sites
        fa, fb, fc = S.Figure([:g1]), S.Figure([:g2]), S.Figure([:g3])
        Ψ = S.Etat([fa, fb, fc], [0.5, 0.3, 0.2])
        su = S.cloture_support(G, Ψ)
        @test su.sites == [:g1, :g2, :g3]
        @test (:g1, :g2) in su.liens && (:g1, :g3) in su.liens

        # A-K7 : un état dont une figure n'est pas close n'est pas admissible
        @test S.verifie_ak7(G, Ψ)
        @test !S.verifie_ak7(G, S.Etat([ab_nu], [1.0]))
        @test S.verifie_ak7(G, S.Etat([S.cloture(G, ab_nu)], [1.0]))

        # canoniser : deux figures de même clôture fusionnent (poids additionnés)
        Ψc = S.canoniser(G, S.Etat([ab_nu, ab_clos], [0.5, 0.5]))
        @test length(Ψc) == 1
        @test Ψc.figures[1] == ab_clos
        @test isapprox(sum(Ψc.poids), 1.0; atol = 1e-12)
        @test S.verifie_ak7(G, Ψc)

        # A-K7 entre dans le rapport d'axiomes
        @test S.verifier_axiomes(G, Ψ)[:AK7]

        # G2 (T-K1) : le cosmos binaire dégénéré est clos (figures atomiques, sans lien)
        d = S.degenerer([BitVector([0, 0]), BitVector([0, 1])])
        @test S.verifie_ak7(d.porteur, d.etat)
        # la clôture du support coïncide avec la figure_totale à l'arrangement près
        su = S.cloture_support(d.porteur, d.etat)
        ft = S.figure_totale(d.porteur)
        @test Set(su.sites) == Set(ft.sites) && su.liens == ft.liens
    end

    @testset "axiome A-K4⁺ — invariance de signature" begin
        h = S.HarmonieRaffinement()
        q = S.Question(:attestation, S.Proposition("attesté", f -> :g1 in f.sites))
        fa, fb, fc = S.Figure([:g1]), S.Figure([:g2]), S.Figure([:g3])
        Ψ0 = S.Etat([fa, fb, fc], [0.5, 0.3, 0.2])

        # signature : classe de raffinement (figure close) + profil topologique (β₀, β₁)
        sa = S.signature(G, fa)
        @test sa.classe == fa                         # figure atomique : déjà close
        @test sa.composantes == 1 && sa.cycles == 0
        ab = S.Figure([:g1, :g2])
        sab = S.signature(G, ab)
        @test sab.classe == S.cloture(G, ab)          # la classe de raffinement est close
        @test sab.composantes == 1 && sab.cycles == 0 # {g1, g2} : un arbre
        @test S.signature(G, fa).classe ≺ S.signature(G, ab).classe  # atomes conservés

        # un triangle attesté porte un cycle indépendant : β₁ = 1
        Gt = S.Porteur()
        S.ajouter_site!(Gt, :x; voisins = [:y, :z])
        S.ajouter_site!(Gt, :y; voisins = [:x, :z])
        S.ajouter_site!(Gt, :z; voisins = [:x, :y])
        st = S.signature(Gt, S.Figure([:x, :y, :z]))
        @test st.composantes == 1 && st.cycles == 1
        # le porteur d'exemple n'atteste pas (g2, g3) : pas de cycle
        @test S.signature(G, S.Figure([:g1, :g2, :g3])).cycles == 0

        # β₀ : composantes connexes de voisinage attesté
        Gd = S.Porteur()
        S.ajouter_site!(Gd, :p; voisins = [:q])
        S.ajouter_site!(Gd, :q; voisins = [:p])
        S.ajouter_site!(Gd, :r)                       # site isolé
        cGd = S.composantes_connexes(Gd)
        @test cGd[:p] == cGd[:q] && cGd[:r] != cGd[:p]
        @test S.meme_composante(Gd, :p, :q)
        @test !S.meme_composante(Gd, :p, :r)

        # voisinage non réciproque : la composante est *faible* (parcours des deux sens),
        # donc l'élagage reste une sur-approximation — aucune solution n'est coupée
        Ga = S.Porteur()
        S.ajouter_site!(Ga, :u; voisins = [:v])       # u → v, sans réciproque
        S.ajouter_site!(Ga, :v)
        @test S.meme_composante(Ga, :u, :v)
        @test S.meme_composante(Ga, :v, :u)
        @test K.trouve(K.recherche_par_pesee_de_promesse(Ga, :u, :v, h; invariant = true))
        # la voie dirigée :v → :u n'existe pas — l'invariant ne la fabrique pas
        @test !K.trouve(K.recherche_par_pesee_de_promesse(Ga, :v, :u, h; invariant = true))

        # invariance : δ (identité) puis κ (sélection) préservent la signature
        Ψ1, _ = S.κ(Ψ0, q, h)
        t = S.Trajectoire(Ψ0)
        S.ajouter_pas!(t, :δ, Ψ0, nothing)
        S.ajouter_pas!(t, :κ, Ψ1, (:pesee, q.nom))
        @test S.verifie_invariance_signature(G, t)
        @test S.verifie_ak4plus(G, t, h)
        @test S.verifier_axiomes(G, Ψ0; trajectoire = t, h = h)[:AK4]

        # un pas qui produirait une figure ex nihilo viole A-K4⁺
        t_ko = S.Trajectoire(S.Etat([S.Figure([:g1])], [1.0]))
        S.ajouter_pas!(t_ko, :ι, S.Etat([S.Figure([:g2])], [1.0]), nothing)
        @test !S.verifie_invariance_signature(G, t_ko)
        @test !S.verifie_ak4plus(G, t_ko, h)

        # G2 (T-K1) : le cosmos dégénéré (figures atomiques, sans lien) satisfait
        # l'invariance automatiquement (aucune figure ne peut être raffinée)
        d = S.degenerer([BitVector([0, 0]), BitVector([0, 1])])
        @test S.verifie_invariance_signature(d.porteur, S.Trajectoire(d.etat))
    end
end

# ============================================================================
@testset "Pesee — la balance de Maât" begin
    G = porteur_exemple()
    Ψ = S.Etat([f1(), f2(), f3()], [0.5, 0.3, 0.2])
    h = S.HarmonieRaffinement()
    q = S.Question(:attestation, S.Proposition("attesté", f -> :g1 in f.sites))

    @testset "balance et registre" begin
        r = P.balance(Ψ, q, h; contraintes = P.contraintes_ethiques_canoniques())
        @test P.est_resolue(r)
        @test r.registre.question == :attestation
        @test length(r.registre.degres) == 1
        @test P.figure_retenue(r) == "g1"
        @test !P.derniere_pesee_humaine(r)
    end

    @testset "dernière pesée humaine (proposition 8.8)" begin
        r = P.balance(Ψ, q, h; decision_engageante = true)
        @test P.derniere_pesee_humaine(r)
    end

    @testset "non-compensation (proposition 8.7)" begin
        # une contrainte qui écarte g3 : il est écarté avant comparaison de degrés
        c = P.ContrainteEthique(:sans_g3, "g3 non admis", f -> !(:g3 in f.sites))
        r = P.balance(Ψ, q, h; contraintes = [c])
        @test "g3" in r.registre.ecartees
        # une contrainte qui rejette tout : la pesée est rejetée définitivement
        ctout = P.ContrainteEthique(:tout, "rejette tout", _ -> false)
        @test_throws ArgumentError P.balance(Ψ, q, h; contraintes = [ctout])
    end

    @testset "aucune pesée sans question consignée" begin
        @test_throws ArgumentError P.balance(Ψ, S.Question(:vide), h)
    end
end

# ============================================================================
@testset "Chaine — la chaîne épistémologique gouvernée" begin
    d1 = C.Donnee("température 31", C.Metadonnee("capteur A", "mesure", "2026-01-01"))
    d2 = C.Donnee("humidité 78", C.Metadonnee("capteur B", "mesure", "2026-01-01"))
    corpus = C.CorpusDonnees([d1, d2], :climat, "table mesures")

    @testset "sept dimensions : 4 étapes, 3 gouvernes" begin
        @test length(C.DIMENSIONS) == 7
        @test length(C.etapes()) == 4
        @test length(C.gouvernes()) == 3
        @test C.verifie_insécabilite()
        @test [d.nom for d in C.etapes()] == [:donnee, :information, :connaissance, :renseignement]
        @test [d.nom for d in C.gouvernes()] == [:ethique, :frugalite, :explicabilite]
    end

    @testset "attestation d'origine (règle 11.1)" begin
        @test C.est_attestee(d1)
        non_attestee = C.Donnee("x", C.Metadonnee("", "", ""))
        @test !C.est_attestee(non_attestee)
        @test length(C.donnees_attestees(corpus)) == 2
    end

    @testset "opérateurs δ, ι, κ de la chaîne" begin
        info = C.δ(corpus; variables = [:temp, :hum], entropie_q = 1.0, entropie_conditionnelle = 0.3)
        @test info isa C.Information
        @test isapprox(C.reduction_incertitude(info), 0.7; atol = 1e-12)
        T = C.ι(info, "langage climatique"; inference = :inductive)
        @test T isa C.Connaissance
        @test T.inference == :inductive
        r = C.κ(T, "irriguer", x -> 1.0 - x)
        @test r isa C.Renseignement
        @test isapprox(C.evaluer(r, 0.25), 0.75; atol = 1e-12)
    end

    @testset "chaîne gouvernée (définition 10.5)" begin
        ch = C.ChaineGouvernee(; question = :climat, schema = "table mesures",
                               langue = "langage climatique", action = "irriguer",
                               valeur = x -> 1.0 - x,
                               frugalite = C.Frugalite(1, 1, 1),
                               ressources = C.Ressources(2.0, 3.0, 1.0))
        rc = C.derouler(ch, corpus)
        @test rc.e_ethique
        @test rc.x_justifiee
        @test isapprox(rc.f_frugalite, 6.0; atol = 1e-12)
        @test C.verifie_gouvernabilite(rc)
        @test length(rc.journal.entrees) >= 3
    end

    @testset "théorème 10.3 — irréversibilité de l'abstraction" begin
        da = C.Donnee("même signe", C.Metadonnee("A", "mesure", "t1"))
        db = C.Donnee("même signe", C.Metadonnee("B", "mesure", "t2"))
        @test C.verifie_irreversibilite_abstraction(da, db)
    end
end

# ============================================================================
@testset "Methodologie — M = (R, P, Γ)" begin
    d1 = C.Donnee("demande A", C.Metadonnee("guichet", "dépôt", "2026-01-01"))
    corpus = C.CorpusDonnees([d1], :urgence, "table demandes")
    info = C.δ(corpus)
    T = C.ι(info, "langage des demandes"; inference = :inductive)
    r = C.κ(T, "traiter", identity)

    @testset "les quatre règles opérationnelles" begin
        @test length(M.REGLES) == 4
        @test M.regle(:R11_1).acte == :consignation
        @test M.constate_attestation(corpus)
        @test M.constate_question(corpus)
        @test M.constate_langage(T)
        @test M.constate_evaluation_avant_action(r)
        @test M.verifie_lemme_11_1(corpus, info, T, r)
    end

    @testset "les trois protocoles" begin
        @test length(M.PROTOCOLES) == 3
        rpδ = M.controler_Pdelta(corpus, info; signalees = 0)
        rpι = M.controler_Piota(info, T)
        rpκ = M.controler_Pkappa(T, r)
        @test M.conforme(rpδ) && M.conforme(rpι) && M.conforme(rpκ)
        @test M.verifie_proposition_11_2([rpδ, rpι, rpκ])
    end

    @testset "les trois épreuves et leur ordre non compensable" begin
        @test M.ordre_epreuves() == [:εE, :εF, :εX]
        @test M.verifie_non_compensation()
        @test M.epreuve_ethique(f1()).conforme
        j_ok = C.Justification("claire et exacte", true, true)
        j_ko = C.Justification("opaque", true, false)
        @test M.epreuve_explicabilite(j_ok).conforme
        @test !M.epreuve_explicabilite(j_ko).conforme
    end

    @testset "εF ne s'applique qu'entre admissibles, à efficacité égale" begin
        ressources = [C.Ressources(1.0, 1.0, 1.0), C.Ressources(9.0, 9.0, 9.0)]
        eff = [0.9, 0.9]
        issue = M.epreuve_frugalite(ressources, eff, C.Frugalite(1, 1, 1))
        @test issue.retenu == 1
        @test isapprox(issue.valeur, 3.0; atol = 1e-12)
    end

    @testset "passage ordonné : εE d'abord, rejet définitif" begin
        j_ok = C.Justification("justifié", true, true)
        admissibles = M.Processus[
            M.Processus("léger", f1(), C.Ressources(1, 1, 1), 0.9, j_ok),
            M.Processus("lourd", f2(), C.Ressources(9, 9, 9), 0.9, j_ok),
        ]
        rap = M.passer_epreuves(admissibles, C.Frugalite(1, 1, 1))
        @test rap.retenu == "léger"
        @test !rap.rejet_definitif

        ctout = P.ContrainteEthique(:tout, "rejette tout", _ -> false)
        rap2 = M.passer_epreuves(admissibles, C.Frugalite(1, 1, 1); contraintes = [ctout])
        @test rap2.rejet_definitif
        @test rap2.retenu === nothing
    end

    @testset "théorèmes 11.4 et 11.5, tableau de dérivation" begin
        @test M.verifie_independance_gouvernes()
        @test M.verifie_suffisance_conjointe(true, true, true)
        @test !M.verifie_suffisance_conjointe(true, true, false)
        @test length(M.TABLEAU_DERIVATION) == 9
        @test M.verifie_derivation()
    end
end

# ============================================================================
@testset "Dispositif — le dispositif unifié de résolution" begin
    G = porteur_exemple()
    Ψ = S.Etat([f1(), f2(), f3()], [0.5, 0.3, 0.2])
    h = S.HarmonieRaffinement()
    q = S.Question(:urgence, S.Proposition("urgente", f -> :g1 in f.sites))

    @testset "les quatre mouvements" begin
        @test length(D.MOUVEMENTS) == 4
        @test [m.nom for m in D.MOUVEMENTS] ==
              [:problematisation, :geometrisation, :calcul_non_binaire, :pesee_et_rendu]
    end

    @testset "cinq critères d'admissibilité des méthodes (définition 13.2)" begin
        @test length(D.CRITERES_ADMISSIBILITE) == 5
        @test D.admissible(D.AdmissibiliteMethode([true, true, true, true, true]))
        a = D.AdmissibiliteMethode([true, true, true, false, true])
        @test !D.admissible(a)
        @test :continuite_classique in D.criteres_manquants(a)
    end

    @testset "critères de conformité au socle (définition 13.3)" begin
        @test length(D.CRITERES_CONFORMITE) == 4
        cf = D.ConformiteSocle([true, true, false, true])
        @test !D.est_conforme(cf)
        @test D.mobilisable(cf) == [:figures_situees, :decisions_pesees, :decision_humaine_rendue]
    end

    @testset "la carte des catégories (tableau 13.1)" begin
        @test length(D.CARTE_CATEGORIES) == 17
        @test D.categorie("réseaux").chapitre == 23
        @test D.categorie("cryptologie").chapitre == 24
    end

    @testset "résolution : les quatre mouvements aboutis" begin
        d1 = C.Donnee("demande A", C.Metadonnee("guichet", "dépôt", "2026-01-01"))
        corpus = C.CorpusDonnees([d1], :urgence, "table demandes")
        sub = D.TripleSubstitution(G, "ordre de pesée M", "trajectoire encadrée")
        ch = C.ChaineGouvernee(; question = :urgence, schema = "table demandes",
                               langue = "langage des demandes", action = "traiter d'abord",
                               valeur = x -> 1.0 - x)
        res = D.resoudre(D.Dispositif(), corpus, ch, sub, Ψ, q, h;
                         decision_engageante = true)
        @test D.reussie(res)
        @test P.derniere_pesee_humaine(res.resultat.pesee)
    end
end

# ============================================================================
@testset "Categories — les méthodes par catégorie" begin
    G = S.Porteur()
    S.ajouter_site!(G, :a; lieu = "A", voisins = [:b])
    S.ajouter_site!(G, :b; lieu = "B", voisins = [:a, :d])
    S.ajouter_site!(G, :c; lieu = "C", voisins = [:d])
    S.ajouter_site!(G, :d; lieu = "D", voisins = [:b, :c])
    fa, fb, fc, fd = S.Figure([:a]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])
    Ψ = S.Etat([fa, fb, fc, fd], [0.4, 0.3, 0.2, 0.1])
    h = S.HarmonieRaffinement()
    q = S.Question(:proche, S.Proposition("proche de A", f -> :a in f.sites))

    @testset "structures de données (ch. 17)" begin
        tri = K.tri_par_pesee(Ψ, q, h)
        @test length(tri.figures) == 4
        @test tri.figures[1] == fa                    # la figure la plus proche en tête
        @test issorted(tri.degres; rev = true)
        par = K.parcours_regle(G, :a)
        @test par.chemin.sites == [:a, :b, :d, :c]
    end

    @testset "bases de données (ch. 21)" begin
        rec = K.recherche_par_relaxation(Ψ, q.propositions[1]; seuils = [1.0, 0.5, 0.0])
        @test K.trouve(rec)
        @test rec.figure == fa
        @test isapprox(rec.degre, 1.0; atol = 1e-12)
        jo = K.jointure_par_composition(G, fa, fb)
        @test jo.composee.sites == [:a, :b]
    end

    @testset "réseaux (ch. 23)" begin
        ro = K.routage_par_harmonie(G, :a, :d, h)
        @test K.trouve(ro)
        @test first(ro.chemin) == :a && last(ro.chemin) == :d
        @test ro.harmonie > 0
    end

    @testset "cryptologie (ch. 24)" begin
        e1 = K.hachage_par_pesee(fa, q.propositions)
        e2 = K.hachage_par_pesee(fa, q.propositions)
        @test e1 == e2
        @test length(e1) == 1
        clé = [2.0, 1.0, 1.0, 0.5]
        Ψc = K.chiffrement_par_redistribution(Ψ, clé)
        Ψd = K.dechiffrement_par_redistribution(Ψc, clé)
        @test isapprox(Ψd.poids, Ψ.poids; atol = 1e-12)   # clair retrouvé à l'échelle près
    end

    @testset "apprentissage automatique (ch. 30)" begin
        rap = K.reponderation_sous_encadrement(Ψ, [0.5, 0.2, 0.0, 0.0], h)
        @test rap.finale isa S.Etat
        @test isapprox(sum(rap.finale.poids), 1.0; atol = 1e-12)
    end
end

# ============================================================================
@testset "Categories — extensions (ch. 14, 15, 16, 18, 19, 20, 22, 25 à 29)" begin
    G = S.Porteur()
    S.ajouter_site!(G, :a; lieu = "A", voisins = [:b])
    S.ajouter_site!(G, :b; lieu = "B", voisins = [:a, :d])
    S.ajouter_site!(G, :c; lieu = "C", voisins = [:d])
    S.ajouter_site!(G, :d; lieu = "D", voisins = [:b, :c])
    fa, fb, fc, fd = S.Figure([:a]), S.Figure([:b]), S.Figure([:c]), S.Figure([:d])
    Ψ = S.Etat([fa, fb, fc, fd], [0.4, 0.3, 0.2, 0.1])
    h = S.HarmonieRaffinement()
    q = S.Question(:proche, S.Proposition("proche de A", f -> :a in f.sites))

    @testset "architectures des ordinateurs (ch. 14)" begin
        pl = K.placement_par_pesee(Ψ, h; ateliers = 2)
        @test length(pl.affectation) == 4
        @test all(a -> 1 <= a <= 2, pl.affectation)
        @test 0.0 <= pl.harmonie_locale <= 1.0
        fl = K.flot_par_composition(G, :a, :d, h)
        @test K.trouve(fl)
        @test first(fl.chemin) == :a && last(fl.chemin) == :d
        @test isapprox(fl.debit, 0.8; atol = 1e-9)          # le maillon le plus faible
    end

    @testset "systèmes d'exploitation (ch. 15)" begin
        ordo = K.ordonnancement_par_pesee([8.0, 1.0, 1.0], [0.0, 1.0, 2.0]; seuil = 0.5)
        @test ordo.ordre == [1, 3, 2]                       # les écartées repondérées par l'ancienneté
        @test all(d -> 0.0 <= d <= 1.0, ordo.degres)
        al = K.allocation_memoire_situee(G, [:a, :c], [:b, :d])
        @test al.affectation == [:b, :d]                    # mémoire la plus proche
        @test al.distances == [1, 1]
    end

    @testset "langages de programmation (ch. 16)" begin
        t1 = K.TypeDegres(:entier, [1.0, 0.0, 1.0])
        t2 = K.TypeDegres(:reel, [0.0, 1.0, 1.0])
        @test isapprox(K.compatibilite_types(t1, t1), 1.0; atol = 1e-12)
        @test isapprox(K.compatibilite_types(t1, t2), 1 / 3; atol = 1e-9)
        cc = K.compilation_par_composition([t1, t2])
        @test cc.coupure_differee                           # la coupure M→{0,1} est différée
        @test isapprox(cc.forme, [0.5, 0.5, 1.0]; atol = 1e-12)
        ev = K.evaluation_consignee([t1], [0.5, 0.5, 0.5])
        @test length(ev.etapes) == 2
        @test isapprox(ev.valeur, 1 / 3; atol = 1e-9)
    end

    @testset "calcul scientifique (ch. 18)" begin
        rr = K.resolution_par_descente([1.0, 0.0, 0.0]; seuil = 0.25)
        @test rr.iterations == 2
        @test rr.subdivisions[1] == 3                       # on raffine là où le désaccord pèse
        @test isapprox(rr.residu, 0.25; atol = 1e-12)
        rh = K.convergence_par_harmonisation(Ψ, h)
        @test rh.harmonie_apres >= rh.harmonie_avant - 1e-9 # la gouverne est respectée
    end

    @testset "calcul haute performance (ch. 19)" begin
        gr = K.execution_par_harmonie(Ψ, h; workers = 2)
        @test length(gr.affectation) == 4
        @test gr.harmonie >= 0.0
        rc = K.reponderation_sous_charge([3.0, 2.0, 0.5], [1.0, 0.5, 1.0])
        @test rc.retenues == [1, 2]                         # la 3ᵉ voie : gain net ≤ 0
        @test isapprox(rc.gain_net, 3.5; atol = 1e-12)
        @test rc.repondere
    end

    @testset "informatique quantique (ch. 20)" begin
        mq = K.calcul_par_superposition(Ψ, q, h)
        @test mq.figure == fa                               # la mesure est une pesée
        @test 0.0 <= mq.degre <= 1.0
        co = K.correction_par_harmonisation(Ψ, h)
        @test co.corrigee isa S.Etat
        @test isapprox(sum(co.corrigee.poids), 1.0; atol = 1e-12)
        @test co.harmonie_apres >= co.harmonie_avant - 1e-9
    end

    @testset "big data (ch. 22)" begin
        pa = K.partitionnement_geometrique([S.Figure([:a, :b]), S.Figure([:b])], h; parts = 1)
        @test length(pa.partitions) == 1
        @test Set(pa.partitions[1].sites) == Set([:a, :b])  # figure jamais coupée (clôture sous ⊙)
        ag = K.agregation_harmonique([fa, fb], h)
        @test Set(ag.agregee.sites) == Set([:a, :b])
        @test isapprox(ag.harmonie, 0.8; atol = 1e-9)
    end

    @testset "optimisation et recherche opérationnelle (ch. 25)" begin
        dop = K.descente_par_harmonisation(Ψ, q, h)
        @test dop.figure == fa                              # optimum de Maât
        @test dop.valeur > 0.9
        @test isapprox(K.borne_harmonique([0.8], [0.9, 0.5]), 0.36; atol = 1e-12)
        el = K.elagage_par_pesee([0.9, 0.4, 0.6]; seuil = 0.5)
        @test el.retenues == [1, 3]
        @test el.ecartees == [2]
    end

    @testset "aide multicritère à la décision (ch. 26)" begin
        criteres = [0.9 0.2 0.6; 0.5 0.8 0.8]
        cl = K.classement_par_pesee_harmonique(criteres; non_negociables = [true, false, false])
        @test cl.ordre == [2, 1]
        @test isapprox(cl.degres[1], 0.4; atol = 1e-12)     # plafonnée par le non-négociable
        @test isapprox(cl.degres[2], 0.5; atol = 1e-12)
        ng = K.negociation_par_reponderation(criteres, [0.0, 0.0, 1.0];
                                             non_negociables = [true, false, false])
        @test ng.ordre == [1, 2]                             # le regard change fait basculer
    end

    @testset "théorie des jeux (ch. 27)" begin
        gains = [0.9 0.1; 0.2 0.8]
        eq = K.pesee_mutuelle(gains)
        @test eq.profil == [1, 2]                            # équilibre de Maât
        @test isapprox(eq.harmonie, 0.8; atol = 1e-12)
        cp = K.conception_par_attracteur(gains)
        @test cp.profil == [1, 2]                            # attracteur harmonique
    end

    @testset "ingénierie des connaissances (ch. 28)" begin
        ac = K.acquisition_par_pesee(G, [fa, fb], h)
        @test ac.attestee
        @test Set(ac.figure.sites) == Set([:a, :b])
        @test ac.etapes == K.ETAPES_ACQUISITION
        rs = K.raisonnement_par_composition([fa, fb, fc], f -> :c in f.sites; G = G)
        @test rs.conclusion.sites == [:c]
        @test rs.retenues == [3]
        @test rs.ecartees == [1, 2]
    end

    @testset "recherche heuristique (ch. 29)" begin
        he = K.recherche_par_pesee_de_promesse(G, :a, :d, h)
        @test K.trouve(he)
        @test he.chemin == [:a, :b, :d]
        @test isapprox(he.promesse, 0.64; atol = 1e-9)
        regles = Function[p -> p == "fait" ? "conclusion" : nothing]
        inf = K.inference_gouvernee(["fait"], regles;
                                    justification = C.Justification("fidèle et claire", true, true))
        @test inf.conforme
        @test inf.conclusion == "conclusion"
        inf_ko = K.inference_gouvernee(["fait"], regles;
                                       justification = C.Justification("opaque", true, false))
        @test !inf_ko.conforme                               # εX échouée : aucune conclusion retenue
        @test inf_ko.conclusion === nothing

        # invariant A-K4⁺ : mêmes résultats, et élagage exact hors composante
        @test K.recherche_par_pesee_de_promesse(G, :a, :d, h; invariant = true).chemin == [:a, :b, :d]
        Gc = S.Porteur()
        S.ajouter_site!(Gc, :a; voisins = [:b])
        S.ajouter_site!(Gc, :b; voisins = [:a])
        S.ajouter_site!(Gc, :z)                       # composante isolée
        sans = K.recherche_par_pesee_de_promesse(Gc, :a, :z, h)
        avec = K.recherche_par_pesee_de_promesse(Gc, :a, :z, h; invariant = true)
        @test !K.trouve(sans) && !K.trouve(avec)      # aucune solution coupée
        @test any(r -> occursin("A-K4⁺", r), avec.registre)

        # API amortie : l'index précalculé rend *exactement* la forme directe
        idx = K.IndexPesee(G, h)
        @test length(idx) == 4
        for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d]
            r0 = K.recherche_par_pesee_de_promesse(G, x, y, h)
            r1 = K.recherche_par_pesee_de_promesse(idx, x, y)
            r2 = K.recherche_par_pesee_de_promesse(idx, x, y; invariant = true)
            @test r1.chemin == r0.chemin
            @test r1.promesse == r0.promesse
            @test r1.registre == r0.registre
            @test r2.chemin == r0.chemin             # même composante : l'invariant ne coupe rien
            @test r2.promesse == r0.promesse
            @test r2.registre == r0.registre
        end
        @test K.recherche_par_pesee_de_promesse(idx, :a, :d).chemin == [:a, :b, :d]
        @test_throws KeyError K.recherche_par_pesee_de_promesse(idx, :a, :zzz)

        # élagage β₀ porté par l'index : même registre que la forme directe (0 nœud)
        idxc = K.IndexPesee(Gc, h)
        av = K.recherche_par_pesee_de_promesse(idxc, :a, :z; invariant = true)
        @test !K.trouve(av)
        @test av.registre == avec.registre

        # promesse nulle : la voie est écartée *en le consignant*, comme dans la forme directe
        nulle = K.recherche_par_pesee_de_promesse(idx, :a, :d; heuristique = _ -> 0.0)
        @test !K.trouve(nulle)
        @test any(r -> occursin("promesse nulle", r), nulle.registre)

        # champ d'attraction de Maât (A4) : une passe, toutes les sources
        champ = K.champ_vers(G, h, :d)
        @test champ.but == :d
        @test length(champ.valeur) == 4
        @test isapprox(K.promesse_optimale(champ, :d), 1.0; rtol = 1e-12)
        @test isapprox(K.promesse_optimale(champ, :b), 0.8; rtol = 1e-12)
        @test isapprox(K.promesse_optimale(champ, :a), 0.64; rtol = 1e-12)
        @test isapprox(K.promesse_optimale(champ, :c), 0.8; rtol = 1e-12)
        dc = K.descente_par_champ(champ, :a)
        @test K.trouve(dc)
        @test dc.chemin == [:a, :b, :d]                      # chemin certifié optimal
        @test isapprox(dc.promesse, 0.64; rtol = 1e-12)
        @test K.descente_par_champ(champ, :d).chemin == [:d] # chemin vide : promesse 1
        @test K.descente_par_champ(champ, :c).chemin == [:c, :d]
        @test any(r -> occursin("0 nœud développé", r), dc.registre)

        # équivalence avec l'exploration : même promesse, chemin jamais plus long
        for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d]
            ch = K.champ_vers(idx, y)
            r = K.descente_par_champ(ch, x)
            r0 = K.recherche_par_pesee_de_promesse(idx, x, y)
            @test K.trouve(r) == K.trouve(r0)
            @test isapprox(r.promesse, r0.promesse; rtol = 1e-12)
            @test length(r.chemin) <= length(r0.chemin)
            @test r.chemin[1] == x && r.chemin[end] == y
        end

        # témoin indépendant : le routage exhaustif du ch. 23 maximise le *même* objectif
        rt = K.routage_par_harmonie(G, :a, :c, h)
        @test rt.chemin == [:a, :b, :d, :c]
        @test isapprox(K.promesse_optimale(K.champ_vers(G, h, :c), :a), rt.harmonie; rtol = 1e-12)

        # le facteur heuristique entre dans le champ comme dans l'exploration
        heur = v -> v == :b ? 0.5 : 1.0
        ch_b = K.champ_vers(idx, :d; heuristique = heur)
        @test isapprox(K.promesse_optimale(ch_b, :a), 0.32; rtol = 1e-12)
        @test isapprox(K.recherche_par_pesee_de_promesse(idx, :a, :d; heuristique = heur).promesse,
                       0.32; rtol = 1e-12)

        # hors du bassin : A-K4⁺ obtenu de surcroît, sans garde par requête
        champ_z = K.champ_vers(idxc, :z)
        hors = K.descente_par_champ(champ_z, :a)
        @test !K.trouve(hors)
        @test any(r -> occursin("hors du bassin", r), hors.registre)
        @test K.promesse_optimale(K.champ_vers(idxc, :a), :z) == 0.0
        @test_throws KeyError K.champ_vers(idx, :zzz)
        @test_throws KeyError K.descente_par_champ(champ, :zzz)

        # ====================================================================
        #  Résolutions des réserves honnêtes de M-06 (r1 à r5)
        # ====================================================================

        # R1 — dualité avant/arrière : « une source → toutes les cibles » en UNE passe.
        # `champ_depuis(source)` remplace `champ_vers(but)` quand la source est commune.
        cd = K.champ_depuis(idx, :a)
        @test cd.source == :a
        @test isapprox(K.promesse_depuis(cd, :a), 1.0; rtol = 1e-12)
        @test isapprox(K.promesse_depuis(cd, :b), 0.8; rtol = 1e-12)
        @test isapprox(K.promesse_depuis(cd, :d), 0.64; rtol = 1e-12)
        @test isapprox(K.promesse_depuis(cd, :c), 0.512; rtol = 1e-12)
        @test K.chemin_depuis(cd, :a).chemin == [:a]
        @test K.chemin_depuis(cd, :d).chemin == [:a, :b, :d]
        @test K.chemin_depuis(cd, :c).chemin == [:a, :b, :d, :c]
        @test any(r -> occursin("0 nœud développé", r), K.chemin_depuis(cd, :d).registre)
        @test K.chemin_depuis(cd, :c).chemin == K.routage_par_harmonie(G, :a, :c, h).chemin
        # dualité : champ *avant* depuis `x` = champ *arrière* vers `y`, et = exploration
        for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d]
            cv = K.champ_vers(idx, y)
            cd2 = K.champ_depuis(idx, x)
            @test isapprox(K.promesse_depuis(cd2, y), K.promesse_optimale(cv, x); rtol = 1e-12)
            r0 = K.recherche_par_pesee_de_promesse(idx, x, y)
            rc = K.chemin_depuis(cd2, y)
            @test K.trouve(rc) == K.trouve(r0)
            @test isapprox(rc.promesse, r0.promesse; rtol = 1e-12)
            @test length(rc.chemin) <= length(r0.chemin)
        end
        @test_throws KeyError K.champ_depuis(idx, :zzz)
        @test_throws KeyError K.chemin_depuis(cd, :zzz)
        @test_throws KeyError K.promesse_depuis(cd, :zzz)

        # R5 — recomposition gauche→droite : la descente / remontée rend *au bit près* la
        # promesse de l'exploration sur le MÊME chemin (plus de « à la réassociation près »)
        for x in [:a, :b, :c, :d], y in [:a, :b, :c, :d]
            r0 = K.recherche_par_pesee_de_promesse(idx, x, y)
            K.trouve(r0) || continue
            r = K.descente_par_champ(K.champ_vers(idx, y), x)
            r.chemin == r0.chemin && @test r.promesse === r0.promesse
            rc = K.chemin_depuis(K.champ_depuis(idx, x), y)
            rc.chemin == r0.chemin && @test rc.promesse === r0.promesse
        end

        # R2 — la réserve « gain de coût seulement, JAMAIS de qualité » est FAUSSE : à `κ`
        # variable, l'exploration ferme `visite` à l'insertion et fige un nœud sur une voie
        # sous-optimale → elle rate l'optimum ; le champ, non (gain de qualité mesuré 81,8×)
        Gg = S.Porteur()
        S.ajouter_site!(Gg, :s; voisins = [:a, :b])
        S.ajouter_site!(Gg, :a; voisins = [:s, :v])
        S.ajouter_site!(Gg, :b; voisins = [:s, :v])
        S.ajouter_site!(Gg, :v; voisins = [:a, :b, :t])
        S.ajouter_site!(Gg, :t; voisins = [:v])
        kap = Dict((:s, :a) => 0.90, (:s, :b) => 0.99,
                   (:a, :v) => 0.90, (:b, :v) => 0.01, (:v, :t) => 0.90)
        hg = S.Harmonie((g, hh) -> begin
            u, w = first(g.sites), first(hh.sites)
            u == w ? 1.0 : get(kap, (u, w), get(kap, (w, u), 0.0))
        end)
        idxg = K.IndexPesee(Gg, hg)
        r0g = K.recherche_par_pesee_de_promesse(idxg, :s, :t)
        rg = K.descente_par_champ(K.champ_vers(idxg, :t), :s)
        @test rg.chemin == [:s, :a, :v, :t]                 # le champ : l'optimum
        @test r0g.chemin != rg.chemin                       # l'exploration : sous-optimale
        @test isapprox(rg.promesse, 0.9^3; rtol = 1e-12)
        @test rg.promesse / r0g.promesse > 80               # ≈ 81,8× de gain de QUALITÉ
        rgg = K.chemin_depuis(K.champ_depuis(idxg, :s), :t) # le dual retrouve le même optimum
        @test rgg.chemin == rg.chemin
        @test isapprox(rgg.promesse, rg.promesse; rtol = 1e-12)

        # R3 — `κ ∈ (0, 1]` : une compatibilité > 1 est saturée à 1 *identiquement* dans le
        # champ et l'exploration (même `clamp`) : aucune divergence, et `κ > 1` est REFUSÉ
        # (saturé) plutôt qu'honoré — sinon la « monotonie » tomberait (plus long = meilleur)
        hsat = S.Harmonie((g, hh) -> 5.0)
        idxsat = K.IndexPesee(G, hsat)
        csat = K.champ_vers(idxsat, :d)
        @test isapprox(K.promesse_optimale(csat, :a), 1.0; rtol = 1e-12)  # 1^L = 1
        @test isapprox(K.recherche_par_pesee_de_promesse(idxsat, :a, :d).promesse,
                       1.0; rtol = 1e-12)
        @test K.descente_par_champ(csat, :a).promesse === 1.0

        # R4 — `µ = 0` : « hors du bassin » (aucune chaîne) vs « promesse nulle » (chaîne à
        # `µ = 0`) — l'ambiguïté de `valeur = 0` est levée par `hors_bassin`
        Gz = S.Porteur()
        S.ajouter_site!(Gz, :p; voisins = [:q])
        S.ajouter_site!(Gz, :q; voisins = [:p, :r])
        S.ajouter_site!(Gz, :r; voisins = [:q])
        S.ajouter_site!(Gz, :iso)
        hz = S.Harmonie((g, hh) -> begin
            u, w = first(g.sites), first(hh.sites)
            ((u == :q && w == :r) || (u == :r && w == :q)) ? 0.0 : 0.8
        end)
        idxz = K.IndexPesee(Gz, hz)
        chz = K.champ_vers(idxz, :r)
        @test K.promesse_optimale(chz, :p) == 0.0
        @test !K.hors_bassin(chz, :p)                       # chaîne existe : promesse nulle
        rz = K.descente_par_champ(chz, :p)
        @test !K.trouve(rz)
        @test any(r -> occursin("promesse nulle", r), rz.registre)
        @test K.hors_bassin(chz, :iso)                      # aucune chaîne : hors du bassin
        riz = K.descente_par_champ(chz, :iso)
        @test !K.trouve(riz)
        @test any(r -> occursin("aucune chaîne dirigée", r), riz.registre)
        # le dual porte la même distinction
        cdz = K.champ_depuis(idxz, :iso)
        @test K.hors_bassin(cdz, :r)
        @test_throws KeyError K.hors_bassin(chz, :zzz)
    end
end

# ============================================================================
@testset "Ethnomatique — les savoirs africains formalisés" begin

    @testset "registre extensible des savoirs" begin
        @test length(E.savoirs()) == 11
        @test length(E.savoirs_implementes()) == 5
        @test E.savoir_existe(:numeration)
        @test E.savoir_existe("geomancie")               # identifiant accepté en chaîne
        @test !E.savoir_existe(:savoir_inexistant)
        @test E.savoir(:motifs).domaine == :motifs
        @test E.savoir(:motifs).etat == :implemente
        @test E.savoir(:textile).etat == :prevu           # place réservée, non implémentée
        @test_throws KeyError E.savoir(:zzz)
        # l'enregistrement est explicite : un id déjà pris est refusé (G5)
        @test_throws ArgumentError E.enregistrer_savoir!(E.Savoir(:numeration;
            nom = "doublon", domaine = :numerations))
        # recensement : (implémentés, total) par domaine
        rec = E.recensement_savoirs()
        @test rec[:numerations] == (1, 1)
        @test rec[:corps] == (0, 3)                        # masques, textile, tresse : prévus
        @test sum(t for (_, t) in values(rec)) == 11
        @test sum(imp for (imp, _) in values(rec)) == 5
        @test :geomancie in E.domaines_savoirs()
        @test occursin("Registre des savoirs", E.aide_ethnomatique())
    end

    @testset "numérations africaines" begin
        @test E.numerer_base(13; base = 10) == [3, 1]      # poids faible en tête
        @test E.numerer_base(13; base = 2) == [1, 0, 1, 1]
        @test E.numerer_base(0) == [0]
        @test E.numerer_chaine(13; base = 2) == "1101"
        @test E.numerer_chaine(13) == "13"
        @test_throws ArgumentError E.numerer_base(5; base = 1)
        @test_throws ArgumentError E.numerer_base(-1)

        # égyptien : décimal additif
        @test E.numerer_egyptien(1234) == [(1000, 1), (100, 2), (10, 3), (1, 4)]
        @test sum(p * q for (p, q) in E.numerer_egyptien(1234)) == 1234
        @test isempty(E.numerer_egyptien(0))

        # fractions égyptiennes : glouton de Sylvester, dénominateurs croissants
        den = E.fraction_egyptienne(5, 6)
        @test den == [2, 3]
        @test issorted(den) && allunique(den)
        @test E.somme_unitaire(den) == 5 // 6
        @test E.somme_unitaire(E.fraction_egyptienne(3, 7)) == 3 // 7
        @test_throws ArgumentError E.fraction_egyptienne(6, 5)   # fraction impropre refusée

        # œil d'Horus : parts binaires 1/2 … 1/64, reste en « ro » = 1/320
        @test E.PARTS_OEIL_HORUS == [1 // 2, 1 // 4, 1 // 8, 1 // 16, 1 // 32, 1 // 64]
        @test E.VALEUR_RO == 1 // 320
        oh = E.oeil_horus(1, 2)
        @test oh.parts == [1 // 2] && oh.ro == 0 && oh.exact
        oh2 = E.oeil_horus(7, 8)
        @test sum(oh2.parts) + oh2.ro * E.VALEUR_RO == 7 // 8
        @test oh2.exact

        # vigésimal soustractif (yoruba / igbo)
        @test E.numerer_vigesimal(15).sens === :moins      # 20 − 5 = 15
        @test E.numerer_vigesimal(15).base == 20
        @test E.numerer_vigesimal(12).sens === :plus       # 10 + 2 = 12
        @test E.numerer_vigesimal(12).base == 10
        @test E.numerer_vigesimal(20).sens === :exact
        @test E.numerer_yoruba(7).mot == "èje"
        @test E.MOTS_YORUBA_UNITES[2] == "ọ̀kan"

        # guèze / éthiopien
        g = E.numerer_geez(1984)
        @test sum(v for (v, _) in g) == 1984
        @test g[1][1] == 1900 && g[end][1] == 84
        @test E.numerer_geez(1000) == [(1000, "፲፻")]       # milliers = dizaines de centaines
        @test E.numerer_geez(100) == [(100, "፻")]
        @test E.numerer_geez(10000) == [(10000, "፼")]
        @test isempty(E.numerer_geez(0))

        # cauris : groupements par 20 puis par 5
        @test E.numerer_cauris(27) == (n = 27, paquets20 = 1, paquets5 = 1, unites = 2)
        @test E.numerer_cauris(20) == (n = 20, paquets20 = 1, paquets5 = 0, unites = 0)
    end

    @testset "jeux de semailles (awalé / oware)" begin
        p = E.awele_initialiser()
        @test E.awele_total(p) == 48                       # invariant : 12 trous × 4
        @test length(p.graines) == 12
        @test length(E.awele_coups(p)) == 6                # les 6 trous du camp au trait
        @test E.awele_jouable(p)

        # conservation de l'invariant au cours des coups
        p2, _ = E.awele_semer(p, 1)
        @test E.awele_total(p2) == 48
        @test p2.camp == 2                                 # le trait passe à l'adversaire
        @test_throws ArgumentError E.awele_semer(p, 7)     # trou hors camp

        # partie complète déterministe
        r1 = E.awele_partie(graine = 0)
        r2 = E.awele_partie(graine = 0)
        @test r1.score1 == r2.score1 && r1.score2 == r2.score2   # reproductibilité
        @test E.awele_total(r1.plateau) == 48
        @test r1.score1 + r1.score2 + sum(r1.plateau.graines) == 48
        @test 1 <= r1.gagnant <= 2 || r1.gagnant == 0

        # tirage aléatoire ensemencé : reproductible
        ra = E.awele_partie(strategie1 = :aleatoire, strategie2 = :aleatoire, graine = 42)
        rb = E.awele_partie(strategie1 = :aleatoire, strategie2 = :aleatoire, graine = 42)
        @test ra.score1 == rb.score1
        @test E.awele_total(ra.plateau) == 48

        @test haskey(E.awele_variantes(), :oware)
        @test occursin("2×6", E.VARIANTES_SEMAILLES[:oware])
    end

    @testset "géomancie (sikidy / ifa / cauris)" begin
        # addition = XOR ligne à ligne, neutre Populus (0), involutive
        @test E.geomancie_addition(0, 5) == 5
        @test E.geomancie_addition(7, 7) == 0
        @test E.geomancie_addition(3, 5) == E.geomancie_addition(5, 3)
        # inversion = complément 4 bits, autoinverse
        @test E.geomancie_inversion(E.geomancie_inversion(9)) == 9
        @test E.geomancie_inversion(0) == 15
        # réversion : renversement haut ↔ bas
        @test E.geomancie_reversion(E.geomancie_reversion(12)) == 12
        # actifs : nombre de traits simples
        @test E.geomancie_actifs(15) == 4
        @test E.geomancie_actifs(0) == 0
        @test E.geomancie_nom(0) == "Populus"
        @test_throws ArgumentError E.geomancie_addition(16, 0)

        # bouclier : le juge est le XOR des deux témoins
        b = E.geomancie_bouclier([1, 2, 4, 8])
        @test length(b.meres) == 4 && length(b.filles) == 4
        @test length(b.nieces) == 4 && length(b.temoins) == 2
        @test b.juge == xor(b.temoins[1], b.temoins[2])
        @test E.geomancie_filles([1, 2, 4, 8]) == b.filles

        # ifa : 16 figures par jambe, 256 Odu au total
        @test length(collect(E.ifa_figures())) == 16
        @test E.ifa_odu_total() == 256
        odu = E.ifa_odu(3, 5)
        @test odu.indice == 3 * 16 + 5
        @test odu.nom_premier == E.geomancie_nom(3)

        # sikidy : reny puis zanaka, reproductible
        rng = Random.MersenneTwister(1)
        reny = E.sikidy_reny(rng)
        @test length(reny) == 4
        @test all(0 .<= reny .<= 15)
        @test E.sikidy_zanaka(reny) == E.geomancie_filles(reny)
        rng2 = Random.MersenneTwister(1)
        @test E.sikidy_reny(rng2) == reny                 # tirage reproductible

        # cauris
        rng3 = Random.MersenneTwister(1)
        @test 0 <= E.cauris_figure(rng3) <= 15
        @test 0 <= E.cauris_oracle(rng3).code <= 15
    end

    @testset "motifs et symétries (adinkra, frises, sona)" begin
        @test length(E.OPERATIONS_D4) == 8

        # D4 : le carré plein est invariant sous les 8 opérations
        carre = [1 1; 1 1]
        gs = E.groupe_symetrie(carre)
        @test gs.ordre == 8 && gs.nom == :diedral4
        # un motif sans symétrie : groupe trivial
        asym = [1 1; 0 1]
        @test E.groupe_symetrie(asym).nom == :trivial
        @test E.groupe_symetrie(asym).ordre == 1
        # chaque transformation laisse bien le carré invariant
        @test all(E.transformer_d4(carre, op) == carre for op in E.OPERATIONS_D4)

        # groupes de frise : bande alternée → translation + demi-tour
        bande = [1 0 1 0; 0 1 0 1]
        gf = E.groupe_frise(bande)
        @test :translation in gf.operations
        @test :rotation_180 in gf.operations
        @test gf.nom == :p112
        @test length(E.GROUPES_FRISE) == 7
        @test length(E.GROUPES_PAPIER) == 17

        # adinkra : table déclarative
        @test length(E.adinkra()) == 8
        @test haskey(E.ADINKRA, :sankofa)
        @test occursin("Retourne", E.ADINKRA[:sankofa])

        # sona : tracé monolinéaire (un seul trait fermé)
        aretes = [((1, 1), (1, 2)), ((1, 2), (2, 2)), ((2, 2), (2, 1)), ((2, 1), (1, 1))]
        @test E.sona_monolineaire(aretes)
        @test E.sona_lignes(aretes) == 1
        circ = E.sona_circuit(aretes)
        @test length(circ) == 5 && circ[1] == circ[end]    # fermé
        @test length(E.sona_grille(2, 3)) == 6
        # deux lignes disjointes : pas un sona
        deux = [((1, 1), (1, 2)), ((1, 1), (1, 2)),
                ((2, 1), (2, 2)), ((2, 1), (2, 2))]
        @test !E.sona_monolineaire(deux)
    end

    @testset "artefacts à encoches (Ishango, Lebombo)" begin
        a = E.ishango_analyse()
        @test a.sommes == Dict(:G => 60, :M => 48, :D => 60)
        @test a.modulo == 12
        @test a.multiples[:G] == 5 && a.multiples[:M] == 4 && a.multiples[:D] == 5
        @test a.colonnes_premieres[:G]                     # 11, 13, 17, 19 : premiers
        @test !a.colonnes_premieres[:M]                    # 3,6,4,… : contient des non-premiers
        @test E.ishango_somme(:G) == 60
        @test_throws ArgumentError E.ishango_somme(:Z)

        # Lebombo : 29 encoches ≈ lunaison
        ls = E.lebombo_lunaison()
        @test ls.encoches == 29
        @test ls.proche_lunaison
        @test ls.ecart_jours < 1.0

        # talles : groupement par module
        @test E.compter_encoches(27) == (n = 27, modulo = 5, paquets = 5, libres = 2)
        @test E.compter_encoches(27; modulo = 20) == (n = 27, modulo = 20, paquets = 1, libres = 7)
        @test Set(keys(E.SYSTEMES_ENCOCHES)) == Set([5, 10, 20])
        @test_throws ArgumentError E.compter_encoches(27; modulo = 1)
    end
end

# ============================================================================
#  Module Loi — la Loi fondamentale de la CQG (chap. 1–4)
# ============================================================================
@testset "Loi — la Loi fondamentale de la CQG" begin

    @testset "axiomatique fondamentale (A1 … A4)" begin
        @test length(L.AXIOMES_CQG) == 4
        @test Set(keys(L.AXIOMES_CQG)) == Set([:A1, :A2, :A3, :A4])
        @test L.axiome_cqg(:A1).nom == "Substrat primordial"
        @test L.figure_cqg(:A1) == "Le Noun"
        @test L.figure_cqg(:A2) == "Kheper et l'Ennéade"
        @test L.figure_cqg(:A3) == "La Spirale d'or"
        @test L.figure_cqg(:A4) == "La Maât"
        for a in (:A1, :A2, :A3, :A4)
            @test !isempty(L.enonce_cqg(a))
            @test !isempty(L.apport_cqg(a))
            @test !isempty(L.axiome_cqg(a).formule)
        end
        @test_throws KeyError L.axiome_cqg(:A9)
    end

    @testset "dérivation ΣK ⇐ quatre axiomes" begin
        @test L.verifier_derivation()
        @test Set(values(L.DERIVATION_SIGMA_K)) == Set([:A1, :A2, :A3, :A4])
        @test L.source_cqg(:AK1) == :A1
        @test L.source_cqg(:AK2) == :A1
        @test L.source_cqg(:AK3) == :A4
        @test L.source_cqg(:AK4) == :A2
        @test L.source_cqg(:AK5) == :A4
        @test L.source_cqg(:AK6) == :A3
        @test L.source_cqg(:AK7) == :A1
        @test L.axiomes_derives(:A1) == [:AK1, :AK2, :AK7]
        @test L.axiomes_derives(:A4) == [:AK3, :AK5]
        @test L.derivation_ak(:AK6).cqg == :A3
        @test !isempty(L.derivation_ak(:AK6).motif)
        @test_throws ArgumentError L.axiomes_derives(:A9)
    end

    @testset "spirale d'or (A3)" begin
        @test L.NOMBRE_OR == (1 + sqrt(5)) / 2
        @test L.B_SPIRALE == log(L.NOMBRE_OR) / (π / 2)
        @test L.verifie_nombre_or()                        # φ² = φ + 1 ⟺ φ − 1 = 1/φ
        @test L.verifie_autosimilarite()
        @test isapprox(L.spirale_rayon(0.0), 1.0; atol = 1e-12)
        @test isapprox(L.spirale_rayon(π / 2), L.NOMBRE_OR; atol = 1e-12)   # quart de tour → φ
        @test L.facteur_quart_tour() == L.NOMBRE_OR
        @test isapprox(L.echelle_conforme(0; r0 = 2.0), 2.0; atol = 1e-12)
        @test isapprox(L.echelle_conforme(3; r0 = 2.0), 2.0 * L.NOMBRE_OR^3; atol = 1e-12)
        @test isapprox(L.facteur_conforme(π / 2), L.NOMBRE_OR^2; atol = 1e-12)  # e^{2bθ} → φ²
        @test_throws ArgumentError L.coupure_r0(0.0)       # A3 : R₀ ≠ 0
        @test_throws ArgumentError L.spirale_rayon(1.0; r0 = 0.0)
    end

    @testset "Loi Universelle (chap. 2)" begin
        eth = L.SecteurEther(6.0, 1.0, 2.0)
        jau = L.SecteurJauge(4.0)
        mor = L.SecteurMorphique(0.5)
        lag = L.LagrangienUnifie(eth, jau, mor, 1.0)
        @test L.densite_ether(eth) == 1.0                  # (6 − 2)/(2·2)
        @test L.densite_jauge(jau) == -1.0                 # −¼·4
        @test L.densite_morphique(mor) == 0.5
        @test L.densite_lagrangien(lag) == 0.5             # √−g·(1 − 1 + 0.5)
        @test length(L.secteurs(lag)) == 3
        @test_throws ArgumentError L.densite_ether(L.SecteurEther(1.0, 0.0, 0.0))  # κ ≠ 0
        @test occursin("F^a_μν", L.LOI_UNIVERSELLE)

        # tenseur de jauge : rappel structurant (linéaire) + commutateur Seth
        A = [0.0 1.0im; -1.0im 0.0]
        @test all(iszero, L.tenseur_jauge(A, A, zero(A), zero(A)))          # [A,A] = 0
        σ₁ = [0.0 1.0; 1.0 0.0]
        σ₂ = [0.0 -1.0im; 1.0im 0.0]
        F = L.tenseur_jauge(σ₁, σ₂, zero(σ₁), zero(σ₂))                     # g[σ₁,σ₂] = 2i σ₃
        @test isapprox(F, 2im * [1.0 0.0; 0.0 -1.0]; atol = 1e-12)
    end

    @testset "énergie du Noun — Heka (chap. 3)" begin
        ψ = ComplexF64[1.0, 0.0] / sqrt(2)
        H = ComplexF64[1.0 0.0; 0.0 2.0]
        h = L.Heka(ψ, H)
        @test isapprox(L.energie_noun(h), 0.5; atol = 1e-12)   # ⟨Ψ|Ĥ|Ψ⟩ = ½·1
        d = L.decomposition_energie(1.0, -0.5, 0.25)           # éq. 9
        @test d.total == 0.75
        @test (d.ether, d.jauge, d.morph) == (1.0, -0.5, 0.25)
        @test L.SECTEURS_ENERGIE == (:ether, :jauge, :morph)
        @test L.verifie_conservation_energie(h, 0.0:0.05:1.0)  # dE/ds = 0 (éq. 10)
        @test_throws ArgumentError L.Heka(ψ, ComplexF64[1.0 0.0; 0.0 2.0; 0.0 0.0])
        @test_throws ArgumentError L.verifie_conservation_energie(h, [0.0])
    end

    @testset "principe de manifestation (chap. 4)" begin
        @test L.verifie_manifestation()                        # triade exhaustive et co-présente
        @test [s.nom for s in L.manifestation_triadique()] == [:Atoum, :Ptah, :Khnoum]
        @test L.secteur_manifestation(:Ptah).registre == "Commande informationnelle"
        @test_throws ArgumentError L.secteur_manifestation(:Rê)
        fm = L.composer_manifestation(x -> 2x, x -> x + 1, x -> x^2)
        @test fm(3) == 20                                      # Â∘P̂∘Ĝ : 2·(3² + 1)
        @test L.composer_manifestation([2.0;;], [3.0;;], [4.0;;]) == [24.0;;]
    end

    @testset "espace des phases (ℋ_Noun, M₄, {ℳ_k}²²)" begin
        @test L.constituants() == [:Khat, :Khaibit, :Ren, :Ba, :Ka, :Ib, :Sekhem, :Sahu, :Akh]
        @test length(L.CONSTITUANTS) == 9
        @test L.ordre_constituant(:Ba) == 4
        @test L.ordre_constituant(:inconnu) === nothing
        e = L.Entite(collect(1.0:9.0))
        @test L.constituant(e, :Ba) == 4.0
        @test L.constituant(e, :Akh) == 9.0
        @test_throws ArgumentError L.Entite(collect(1.0:8.0))
        @test_throws ArgumentError L.constituant(e, :inconnu)

        @test L.DOF_TOPOLOGIQUES == 9                          # dim DOF_top = 9 (A2)
        @test L.enneade_valide(collect(1:9))
        @test !L.enneade_valide(collect(1:8))
        @test length(L.FAMILLES_INVARIANTS) == 3

        @test L.NB_METOUS == 22
        @test L.metous() == collect(1:22)
        @test L.famille_metou(1) == :cephaliques
        @test L.famille_metou(4) == :cephaliques
        @test L.famille_metou(5) == :membres_superieurs
        @test L.famille_metou(9) == :tronc
        @test L.famille_metou(22) == :membres_inferieurs
        @test_throws ArgumentError L.famille_metou(23)
        @test sum(length(r) for r in values(L.FAMILLES_METOUS)) == 22

        # algèbre de Lie (so(3) plongée dans 22 Métous) : antisymétrie + Jacobi
        f = zeros(22, 22, 22)
        f[1, 2, 3] = 1.0; f[2, 3, 1] = 1.0; f[3, 1, 2] = 1.0
        f[2, 1, 3] = -1.0; f[3, 2, 1] = -1.0; f[1, 3, 2] = -1.0
        alg = L.AlgebreMetous(f)
        @test L.verifie_antisymetrie_metous(alg)               # f_jkl = −f_kjl
        @test L.verifie_jacobi_metous(alg)                     # éq. 18
        @test_throws ArgumentError L.AlgebreMetous(zeros(2, 2, 2))

        esp = L.espace_phases(alg)
        @test esp isa L.EspacePhases
        @test esp.substrat == :Noun
        @test esp.variete == :M4
    end
end
