# ============================================================================
#  La carte des catégories  (tableau 13.1)
# ----------------------------------------------------------------------------
#  Le registre des catégories de problèmes computationnels que le dispositif
#  unifié traite, et des méthodes kamitiques correspondantes. Ce registre est un
#  état des lieux, ouvert par construction.
# ============================================================================

"""
    Categorie

Une ligne de la **carte des catégories** (tableau 13.1) : la catégorie, les
problèmes traités, les méthodes kamitiques et le chapitre qui les formalise.
"""
struct Categorie
    nom       :: String
    problemes :: Vector{String}
    methodes  :: Vector{String}
    chapitre  :: Int
end

function Base.show(io::IO, c::Categorie)
    print(io, "Categorie(", c.nom, ", chapitre ", c.chapitre, ")")
end

"""La carte des catégories de problèmes computationnels (tableau 13.1)."""
const CARTE_CATEGORIES = Categorie[
    Categorie("Architectures des ordinateurs",
              ["placement", "pipelines", "hiérarchie mémoire"],
              ["réseau d'ateliers pesés", "placement par pesée harmonique"], 14),
    Categorie("Systèmes d'exploitation",
              ["ordonnancement", "allocation", "synchronisation"],
              ["règne pesé", "ordonnancement par pesée de besoin"], 15),
    Categorie("Langages de programmation",
              ["syntaxe", "typage", "sémantique opératoire"],
              ["formes composées", "types en degrés", "évaluation consignée"], 16),
    Categorie("Structures de données",
              ["modélisation", "indexation", "requête", "jointure"],
              ["quatre structures natives", "parcours réglé", "tri par pesée harmonique"], 17),
    Categorie("Calcul scientifique",
              ["discrétisation", "solveurs", "estimation d'erreur"],
              ["éventail de discrétisation", "résolution par descente de raffinement"], 18),
    Categorie("Calcul haute performance",
              ["partitionnement", "communications", "équilibrage"],
              ["grille de pesée", "exécution par harmonie"], 19),
    Categorie("Informatique quantique",
              ["superposition", "intrication", "mesure", "correction"],
              ["pesée quantique", "correction par harmonisation"], 20),
    Categorie("Bases de données",
              ["requêtes", "jointures", "transactions"],
              ["recherche par relaxation", "jointure par composition"], 21),
    Categorie("Big data",
              ["partitionnement", "agrégation", "distribution"],
              ["partitionnement géométrique", "agrégation harmonique"], 22),
    Categorie("Réseaux",
              ["routage", "équilibrage", "résilience"],
              ["routage par harmonie", "résilience par pesée locale"], 23),
    Categorie("Cryptologie",
              ["hachage", "chiffrement", "authentification"],
              ["hachage par pesée", "chiffrement par redistribution"], 24),
    Categorie("Optimisation et recherche opérationnelle",
              ["programmes linéaires", "combinatoire", "voisinages"],
              ["harmonisation", "élagage par pesée des voies"], 25),
    Categorie("Aide multicritère à la décision",
              ["classement", "pondération", "sensibilité"],
              ["pesée des regards", "non-compensation native"], 26),
    Categorie("Théorie des jeux",
              ["équilibres", "coopération", "mécanismes"],
              ["pesée mutuelle", "équilibre de Maât"], 27),
    Categorie("Ingénierie des connaissances",
              ["acquisition", "organisation", "inférence"],
              ["acquisition par pesée", "raisonnement par composition"], 28),
    Categorie("Recherche heuristique et systèmes experts",
              ["exploration", "planification", "inférence"],
              ["pesée de promesse", "inférence gouvernée"], 29),
    Categorie("Apprentissage automatique",
              ["supervisé", "non supervisé", "renforcement"],
              ["repondération sous encadrement"], 30),
]

"""Retourne la catégorie portant le nom donné (recherche par sous-chaîne insensible à la casse)."""
function categorie(nom::AbstractString)
    cible = lowercase(nom)
    for c in CARTE_CATEGORIES
        occursin(cible, lowercase(c.nom)) && return c
    end
    throw(ArgumentError("catégorie inconnue : $nom"))
end
