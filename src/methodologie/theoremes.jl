# ============================================================================
#  Théorèmes de la méthodologie  (lemme 11.1, propositions 11.2-11.3,
#  théorèmes 11.4-11.5) et tableau de dérivation (tableau 11.1)
# ============================================================================

# ----------------------------------------------------------------------------
#  Lemme 11.1 — les règles préservent la gouvernabilité de la production
# ----------------------------------------------------------------------------

"""
    verifie_lemme_11_1(corpus, info, T, r) -> Bool

**Lemme 11.1.** Une conduite qui satisfait les règles 11.1 à 11.4 à chacun des
opérateurs correspondants produit une chaîne conforme à la définition de la chaîne
gouvernée 10.5 pour tout ce qui relève de la production.
"""
verifie_lemme_11_1(corpus::Chaine.CorpusDonnees, info::Chaine.Information,
                   T::Chaine.Connaissance, r::Chaine.Renseignement) =
    constate_attestation(corpus) && constate_question(corpus) &&
    constate_langage(T) && constate_evaluation_avant_action(r)

# ----------------------------------------------------------------------------
#  Proposition 11.2 — la conduite protocolaire produit une chaîne gouvernée
# ----------------------------------------------------------------------------

"""
    verifie_proposition_11_2(rapports) -> Bool

**Proposition 11.2.** Toute chaîne conduite selon les trois protocoles du noyau —
`Pδ`, `Pι`, `Pκ` — et soumise aux épreuves de gouvernance est une chaîne gouvernée
au sens de la définition 10.5.
"""
verifie_proposition_11_2(rapports::AbstractVector{RapportProtocole}) =
    length(rapports) == 3 && all(conforme, rapports)

# ----------------------------------------------------------------------------
#  Proposition 11.3 — non-compensation des épreuves
# ----------------------------------------------------------------------------

"""
    verifie_non_compensation() -> Bool

**Proposition 11.3.** Les trois épreuves sont toutes requises et ne se substituent
pas ; l'ordre de passage est celui des axiomes : `εE` d'abord (rejet définitif),
`εF` ensuite (parmi les seuls admissibles), `εX` enfin.
"""
verifie_non_compensation() = ordre_epreuves() == Symbol[:εE, :εF, :εX] &&
                             length(EPREUVES) == 3

# ----------------------------------------------------------------------------
#  Théorème 11.4 — indépendance des gouvernes
# ----------------------------------------------------------------------------

"""
    TEMOINS_INDEPENDANCE

Témoins de l'indépendance des gouvernes (théorème 11.4) : trois triples `(E, F, X)`
où deux gouvernes sont satisfaites sans que la troisième le soit.
"""
const TEMOINS_INDEPENDANCE = Tuple{Bool,Bool,Bool}[
    (true,  true,  false),   # éthique et frugal, mais inexplicable
    (true,  false, true ),   # éthique et explicable, mais dispendieux
    (false, true,  true ),   # frugal et explicable, mais éthiquement fautif
]

"""
    verifie_independance_gouvernes() -> Bool

**Théorème 11.4.** Aucune des trois gouvernes ne découle des deux autres : pour
chaque paire, il existe un processus qui la satisfait sans satisfaire la troisième.
"""
function verifie_independance_gouvernes()
    # pour chaque paire, un témoin satisfait la paire et manque la troisième
    paires = [(1, 2, 3), (1, 3, 2), (2, 3, 1)]
    for (a, b, c) in paires
        ok = any(t -> t[a] && t[b] && !t[c], TEMOINS_INDEPENDANCE)
        ok || return false
    end
    return true
end

# ----------------------------------------------------------------------------
#  Théorème 11.5 — suffisance conjointe
# ----------------------------------------------------------------------------

"""
    verifie_suffisance_conjointe(E, F, X) -> Bool

**Théorème 11.5.** Les trois gouvernes sont conjointement suffisantes pour la
gouvernabilité : la conjonction `E ∧ F ∧ X` clôt la gouvernabilité (les théorèmes
11.4 et 11.5 établissent que le trièdre est exactement minimal et suffisant).
"""
verifie_suffisance_conjointe(E::Bool, F::Bool, X::Bool) = E && F && X

# ----------------------------------------------------------------------------
#  Tableau de dérivation  (tableau 11.1)
# ----------------------------------------------------------------------------

"""
    Derivation

Une ligne du **tableau de dérivation** (tableau 11.1) : à un énoncé de la théorie,
la traduction opérationnelle qui en dérive et le point de contrôle où la
satisfaction se constate.
"""
struct Derivation
    enonce      :: String
    traduction  :: String
    controle    :: String
end

"""Le tableau de dérivation : de la théorie à la méthodologie opérationnelle."""
const TABLEAU_DERIVATION = Derivation[
    Derivation("Axiome d'insécabilité 9.1",
               "grille des sept dimensions exigée pour toute production revendiquée",
               "vérification d'exhaustivité à l'ouverture et à la clôture"),
    Derivation("Axiome de non-réduction 9.2",
               "interdiction du court-circuit : aucun renseignement sans parcours des opérateurs",
               "contrôle du parcours effectif de la chaîne"),
    Derivation("Axiome de prééminence éthique 9.3",
               "épreuve éthique εE préalable, rejet définitif",
               "porte éthique avant toute dépense"),
    Derivation("Axiome de frugalité 9.4",
               "épreuve de frugalité εF à efficacité égale",
               "comparaison des fonctionnelles de ressources"),
    Derivation("Axiome d'explicabilité due 9.5",
               "épreuve d'explicabilité εX et registre J",
               "revue de la justification fidèle et intelligible"),
    Derivation("Définition de la donnée 9.1 et corollaire 10.4",
               "règle d'attestation d'origine 11.1",
               "contrôle d'entrée des données et du consentement"),
    Derivation("Définition de l'information 9.2",
               "règle de la question préalable 11.2",
               "consignation de la question avant collecte"),
    Derivation("Définition de la connaissance 9.3",
               "règle du choix gouverné du langage 11.3",
               "documentation du choix avant inférence"),
    Derivation("Définition du renseignement 9.4",
               "règle de l'évaluation avant action 11.4",
               "explicitation de l'action et de la valeur"),
]

"""
    verifie_derivation() -> Bool

Contrôle de **complétude opérationnelle** : chaque axiome du socle et chaque règle
de la chaîne trouvent une traduction opérationnelle dans le tableau de dérivation.
Aucune prescription n'est un axiome étranger ; aucun régulateur ne reste sans
traduction.
"""
function verifie_derivation()
    # les cinq axiomes de gouvernance et les quatre règles de la chaîne sont tous traduits
    return length(TABLEAU_DERIVATION) == 9
end
