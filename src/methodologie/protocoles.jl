# ============================================================================
#  Les protocoles opérationnels de conduite  (définition 11.2, protocoles 11.1-11.3)
# ----------------------------------------------------------------------------
#  Un protocole opérationnel attaché à un opérateur est un quadruplet
#  P = (Pré, Inv, Post, J) : conditions préalables, invariants de conduite,
#  conditions de sortie, registre de justification. Trois protocoles
#  correspondent aux trois opérateurs du noyau de production.
# ============================================================================

"""
    Protocole

Un **protocole opérationnel** `P = (Pré, Inv, Post, J)` (définition 11.2) :

- `operateur` — l'opérateur auquel il est attaché (`:δ`, `:ι`, `:κ`) ;
- `pre`       — les conditions préalables ;
- `inv`       — les invariants de conduite ;
- `post`      — les conditions de sortie ;
- `registre`  — ce que le registre `J` doit consigner.
"""
struct Protocole
    operateur :: Symbol
    pre       :: Vector{String}
    inv       :: Vector{String}
    post      :: Vector{String}
    registre  :: Vector{String}
end

function Base.show(io::IO, p::Protocole)
    print(io, "Protocole(", p.operateur, " : Pré=", length(p.pre),
          ", Inv=", length(p.inv), ", Post=", length(p.post), ")")
end

"""Les trois protocoles du noyau de production (protocoles 11.1 à 11.3)."""
const PROTOCOLES = Dict{Symbol,Protocole}(
    :δ => Protocole(:δ,
        ["données attestées (règle 11.1)", "question q consignée (règle 11.2)"],
        ["aucune donnée n'est écartée sans signalement",
         "l'évaluation d'incertitude (9.1) est maintenue à jour"],
        ["l'information structurée porte son schéma explicite"],
        ["justification du schéma choisi", "mention des données signalées"]),
    :ι => Protocole(:ι,
        ["information structurée conforme à Pδ",
         "choix du langage documenté (règle 11.3)"],
        ["les hypothèses de la théorie demeurent consignées",
         "la gouverne s'exerce durant l'inférence et non après"],
        ["la théorie T = (L, KB, ⊢) est munie de sa justification"],
        ["consignation des généralisations opérées et des attributs abandonnés (théorème 10.3)"]),
    :κ => Protocole(:κ,
        ["connaissance T, action a et échelle de valeur v explicitées (règle 11.4)"],
        ["les épreuves de gouvernance sont passées avant toute production",
         "l'épreuve éthique passe d'abord"],
        ["le renseignement r = (T, a, v) est accompagné de sa justification"],
        ["le compte rendu destiné à la communauté concernée"]),
)

"""Retourne le protocole attaché à un opérateur."""
protocole(operateur::Symbol) = PROTOCOLES[operateur]

"""
    RapportProtocole

Le résultat du contrôle d'un protocole : la conformité des conditions préalables,
des invariants et des conditions de sortie.
"""
struct RapportProtocole
    operateur :: Symbol
    pre_ok    :: Bool
    inv_ok    :: Bool
    post_ok   :: Bool
end

conforme(r::RapportProtocole) = r.pre_ok && r.inv_ok && r.post_ok

function Base.show(io::IO, r::RapportProtocole)
    print(io, "RapportProtocole(", r.operateur, ", ",
          conforme(r) ? "conforme" : "non conforme", ")")
end

"""
    controler_Pdelta(corpus, info; signalees = 0) -> RapportProtocole

Contrôle du protocole Pδ (protocole 11.1) sur une structuration effective.
"""
function controler_Pdelta(corpus::Chaine.CorpusDonnees, info::Chaine.Information;
                          signalees::Int = 0)
    pre = constate_attestation(corpus) && constate_question(corpus)
    # invariant : aucune donnée écartée sans signalement
    nb_ecartees = length(corpus.donnees) - length(info.contenu)
    inv = nb_ecartees <= signalees
    post = !isempty(info.schema)
    return RapportProtocole(:δ, pre, inv, post)
end

"""
    controler_Piota(info, T) -> RapportProtocole

Contrôle du protocole Pι (protocole 11.2) sur une modélisation effective.
"""
function controler_Piota(info::Chaine.Information, T::Chaine.Connaissance)
    pre = !isempty(info.schema) && constate_langage(T)
    inv = !isempty(T.base)                 # les hypothèses demeurent consignées
    post = !isempty(T.langue)              # la théorie est munie de sa justification
    return RapportProtocole(:ι, pre, inv, post)
end

"""
    controler_Pkappa(T, r; epreuves_passees = true) -> RapportProtocole

Contrôle du protocole Pκ (protocole 11.3) sur une mise en renseignement effective.
"""
function controler_Pkappa(T::Chaine.Connaissance, r::Chaine.Renseignement;
                         epreuves_passees::Bool = true)
    pre = !isempty(r.action) && r.valeur !== nothing && constate_langage(T)
    inv = epreuves_passees                  # les épreuves passent avant la production
    post = constate_evaluation_avant_action(r)
    return RapportProtocole(:κ, pre, inv, post)
end
