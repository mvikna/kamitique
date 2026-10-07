# ============================================================================
#  Les règles opérationnelles  (définition 11.1, règles 11.1 à 11.4)
# ----------------------------------------------------------------------------
#  Une règle opérationnelle est un énoncé r = (c, α) : c est la condition de
#  portée (la classe des conduites visées), α l'acte prescrit — obligation,
#  interdiction ou exigence de consignation. Une règle est opérationnelle si sa
#  satisfaction se constate par un tiers : elle laisse des traces objectives.
# ============================================================================

"""
    Regle

Une **règle opérationnelle** `r = (c, α)` (définition 11.1) :

- `code`      — l'identifiant (`:R11_1` …) ;
- `portee`    — la condition de portée `c` ;
- `acte`      — la nature de l'acte `α` (`:obligation`, `:interdiction`, `:consignation`) ;
- `enonce`    — la prescription en clair ;
- `fondement` — l'énoncé théorique dont la règle dérive.
"""
struct Regle
    code      :: Symbol
    portee    :: String
    acte      :: Symbol
    enonce    :: String
    fondement :: String
end

function Base.show(io::IO, r::Regle)
    print(io, "Regle(", r.code, ", ", r.acte, ")")
end

"""Les quatre règles opérationnelles de la chaîne (règles 11.1 à 11.4)."""
const REGLES = Regle[
    Regle(:R11_1, "toute donnée entrant dans la chaîne", :consignation,
          "Toute donnée porte sa métadonnée d'attestation — source, mode d'acquisition, horodatage, et consentement lorsqu'elle concerne des personnes ou des communautés. Aucune donnée non attestée n'entre ; aucune attestation n'est remplacée par une présomption.",
          "corollaire 10.4 : l'abstraction est irréversible"),
    Regle(:R11_2, "toute collecte ou structuration de données", :interdiction,
          "Aucune collecte ni structuration ne s'engage sans une question q explicitée et consignée, relativement à laquelle l'information sera évaluée comme réduction d'incertitude.",
          "définition 9.2 (l'information est relation à une question) et axiome 9.4"),
    Regle(:R11_3, "le choix du langage, de la base et de l'inférence", :obligation,
          "Le choix de L, de KB et de ⊢ est documenté avant toute inférence, au regard des trois gouvernes : admissibilité éthique, frugalité des moyens d'inférence, disponibilité d'une justification.",
          "définition 9.3 et triple signature des opérateurs"),
    Regle(:R11_4, "toute constitution d'un renseignement", :obligation,
          "Aucun renseignement n'est constitué sans l'explicitation préalable de l'action a et de l'échelle de valeur v au regard de laquelle ses issues seront évaluées.",
          "définition 9.4 (le renseignement est un triplet) et axiome 9.5"),
]

"""Retourne la règle de code donné."""
regle(code::Symbol) = REGLES[findfirst(r -> r.code == code, REGLES)]

# ----------------------------------------------------------------------------
#  Constatation des règles — la satisfaction laisse des traces objectives
# ----------------------------------------------------------------------------

"""
    constate_attestation(corpus) -> Bool

Constatation de la règle 11.1 : toutes les données du corpus sont attestées.
"""
constate_attestation(corpus::Chaine.CorpusDonnees) =
    all(d -> Chaine.est_attestee(d), corpus.donnees)

"""
    constate_question(corpus) -> Bool

Constatation de la règle 11.2 : une question est consignée.
"""
constate_question(corpus::Chaine.CorpusDonnees) = corpus.question != Symbol("")

"""
    constate_langage(T) -> Bool

Constatation de la règle 11.3 : le langage et l'inférence de la théorie sont explicites.
"""
constate_langage(T::Chaine.Connaissance) =
    !isempty(T.langue) && T.inference in (:deductive, :inductive, :expertale)

"""
    constate_evaluation_avant_action(r) -> Bool

Constatation de la règle 11.4 : le renseignement porte une action explicite et une
échelle de valeur.
"""
constate_evaluation_avant_action(r::Chaine.Renseignement) =
    !isempty(r.action) && r.valeur !== nothing
