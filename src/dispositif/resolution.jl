# ============================================================================
#  Le dispositif unifié de résolution  (définition 13.1)
# ----------------------------------------------------------------------------
#  La procédure générale par laquelle la Kamitique traite toute catégorie de
#  problèmes : un socle (la CQG), une chaîne (la méthode), quatre mouvements.
#  Le dispositif est dit unifié lorsqu'il produit, pour toute catégorie, des
#  méthodes satisfaisant les axiomes ΣK (théorème 8.5, complétude de couverture).
# ============================================================================

"""
    Dispositif

Le **dispositif unifié de résolution** (définition 13.1) : la méthodologie
opérationnelle `M = (R, P, Γ)` qu'il met en acte, et les quatre mouvements.
"""
struct Dispositif
    regles     :: Vector{Methodologie.Regle}
    protocoles :: Vector{Methodologie.Protocole}
    epreuves   :: Vector{Methodologie.Epreuve}
end

function Dispositif()
    protocoles = Methodologie.Protocole[Methodologie.protocole(s) for s in (:δ, :ι, :κ)]
    return Dispositif(copy(Methodologie.REGLES), protocoles, copy(Methodologie.EPREUVES))
end

Base.length(::Dispositif) = length(MOUVEMENTS)

"""
    Resolution

Le produit du dispositif : le rapport de chacun des quatre mouvements, et le
résultat restitué avec son registre.
"""
struct Resolution
    problematisation :: RapportMouvement
    geometrisation   :: RapportMouvement
    calcul           :: RapportMouvement
    pesee            :: RapportMouvement
    resultat         :: Any
end

"""Le dispositif est-il allé au bout ? (les quatre mouvements sont conformes.)"""
reussie(r::Resolution) = r.problematisation.conforme && r.geometrisation.conforme &&
                         r.calcul.conforme && r.pesee.conforme

function Base.show(io::IO, r::Resolution)
    print(io, "Resolution(", reussie(r) ? "aboutie" : "interrompue", ")")
end

"""
    resoudre(d::Dispositif, corpus, ch, sub, Ψ, q, h; λ, contraintes, decision_engageante)
        -> Resolution

Déroule les **quatre mouvements** du dispositif unifié (définition 13.1) :

1. **Problématisation** — la question est consignée et les données attestées
   (règles 11.1 et 11.2) ;
2. **Géométrisation** — la triple substitution `sub` porte un porteur de figures
   situées, l'ordre de pesée `M` et la trajectoire encadrée ;
3. **Calcul non-binaire** — les opérateurs `δ`, `ι`, `κ` sont déroulés par la
   chaîne gouvernée `ch`, sous les trois gouvernes ;
4. **Pesée et rendu** — la balance tranche la question `q` sur l'état `Ψ` et
   restitue le résultat avec son registre.
"""
function resoudre(d::Dispositif, corpus::Chaine.CorpusDonnees, ch::Chaine.ChaineGouvernee,
                  sub::TripleSubstitution, Ψ::Etat, q::Question, h::Harmonie;
                  λ::Real = 0.5,
                  contraintes::AbstractVector{Pesee.ContrainteEthique} =
                      Pesee.contraintes_ethiques_canoniques(),
                  decision_engageante::Bool = false)

    # ---- mouvement 1 : problématisation ------------------------------------
    prob_ok = Methodologie.constate_attestation(corpus) &&
              Methodologie.constate_question(corpus)
    mvt1 = RapportMouvement(:problematisation, prob_ok,
                            prob_ok ? "question consignée, données attestées" :
                                      "question ou attestation manquante", corpus)

    # ---- mouvement 2 : géométrisation (triple substitution) ----------------
    geo_ok = length(sub.support) > 0 && !isempty(sub.valuation) && !isempty(sub.dynamique)
    mvt2 = RapportMouvement(:geometrisation, geo_ok,
                            geo_ok ? "support → porteur, valuation → M, dynamique → trajectoire encadrée" :
                                     "triple substitution incomplète", sub)
    geo_ok || return Resolution(mvt1, mvt2, RapportMouvement(:calcul_non_binaire, false,
                                "mouvement 3 non atteint", nothing),
                               RapportMouvement(:pesee_et_rendu, false,
                                "mouvement 4 non atteint", nothing), nothing)

    # ---- mouvement 3 : calcul non-binaire ----------------------------------
    rc = Chaine.derouler(ch, corpus)
    calc_ok = Chaine.verifie_gouvernabilite(rc)
    mvt3 = RapportMouvement(:calcul_non_binaire, calc_ok,
                            calc_ok ? "δ, ι, κ déroulés sous E, F, X" :
                                      "gouvernes non satisfaites", rc)
    calc_ok || return Resolution(mvt1, mvt2, mvt3,
                                 RapportMouvement(:pesee_et_rendu, false,
                                    "mouvement 4 non atteint", nothing), rc)

    # ---- mouvement 4 : pesée et rendu --------------------------------------
    rp = Pesee.balance(Ψ, q, h; λ = λ, contraintes = contraintes,
                       decision_engageante = decision_engageante)
    mvt4 = RapportMouvement(:pesee_et_rendu, true,
                            "état résolu, résultat restitué avec son registre", rp)

    return Resolution(mvt1, mvt2, mvt3, mvt4, (chaine = rc, pesee = rp))
end
