# ============================================================================
#  Les quatre mouvements du dispositif unifié  (définition 13.1, section 13.2)
# ----------------------------------------------------------------------------
#  Le dispositif unifié de résolution est la procédure générale par laquelle la
#  Kamitique traite toute catégorie de problèmes computationnels. Il est
#  constitué de quatre mouvements, toujours les mêmes :
#    1. la problématisation  — question, porteur, état, gouverne, données attestées
#    2. la géométrisation    — la triple substitution
#    3. le calcul non-binaire — déroulé de δ, ι, κ sous les trois gouvernes
#    4. la pesée et le rendu  — balance, non-compensation, dernière pesée humaine
# ============================================================================

"""
    Mouvement

Un des quatre mouvements du dispositif unifié (définition 13.1) : son rang, son nom
et sa définition.
"""
struct Mouvement
    rang       :: Int
    nom        :: Symbol
    definition :: String
end

function Base.show(io::IO, m::Mouvement)
    print(io, "Mouvement(", m.rang, ", ", m.nom, ")")
end

"""Les quatre mouvements, toujours les mêmes (définition 13.1)."""
const MOUVEMENTS = Mouvement[
    Mouvement(1, :problematisation,
              "formuler le problème dans le vocabulaire du socle — question, porteur, état, gouverne — avec la question consignée et les données attestées"),
    Mouvement(2, :geometrisation,
              "substituer au support un porteur de figures situées, à la valuation l'ordre de pesée M, à la dynamique la trajectoire encadrée — la triple substitution"),
    Mouvement(3, :calcul_non_binaire,
              "dérouler les opérateurs δ, ι, κ sur les états du porteur, sous les trois gouvernes et sous conservation de l'harmonie"),
    Mouvement(4, :pesee_et_rendu,
              "trancher la question par la théorie de la décision et restituer le résultat avec son registre"),
]

mouvement(nom::Symbol) = MOUVEMENTS[findfirst(m -> m.nom == nom, MOUVEMENTS)]

"""
    TripleSubstitution

La **triple substitution** du deuxième mouvement (théorème 8.5) :

- `support`   — les unités de la catégorie devenues des sites situés (un `Porteur`) ;
- `valuation` — les valuations discrètes devenues des pesées dans `M` ;
- `dynamique` — les transformations devenues des trajectoires encadrées.
"""
struct TripleSubstitution
    support   :: Porteur
    valuation :: String
    dynamique :: String
end

"""
    RapportMouvement

Le résultat d'un mouvement : sa conformité, le produit éventuel et le motif.
"""
struct RapportMouvement
    nom      :: Symbol
    conforme :: Bool
    motif    :: String
    produit  :: Any
end

function Base.show(io::IO, r::RapportMouvement)
    print(io, "RapportMouvement(", r.nom, ", ",
          r.conforme ? "conforme" : "non conforme", ")")
end
