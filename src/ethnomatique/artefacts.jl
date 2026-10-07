# ============================================================================
#  Savoir : les artefacts à encoches  (Ishango, Lebombo, systèmes de talles)
# ----------------------------------------------------------------------------
#  Logique de calcul des plus anciens artefacts numériques africains : les os
#  à encoches. L'objet propre du calcul est le **groupement des encoches** —
#  c'est-à-dire la reconnaissance d'une structure (sommes remarquables, multiples
#  d'un module, suite de nombres premiers, cycles) dans une suite de comptes.
#  Les lectures proposées par les auteurs (calendrier, comptage en base, suites
#  arithmétiques) sont **déclarées** comme telles : le module calcule, il ne
#  tranche pas à la place des spécialistes (G5).
# ============================================================================

# ----------------------------------------------------------------------------
#  Os d'Ishango  (~20 000 ans ; trois colonnes d'encoches G/M/D)
# ----------------------------------------------------------------------------

"""
    OS_ISHANGO

Relevé des trois colonnes d'encoches de l'os d'Ishango (colonne gauche `G`,
milieu `M`, droite `D`), tel qu'établi par la littérature (Marshack ; Pletser &
Huylebrouck). Chaque colonne est la suite des comptes d'encoches par groupe.
"""
const OS_ISHANGO = (
    G = [11, 13, 17, 19],
    M = [3, 6, 4, 8, 10, 5, 5, 7],
    D = [11, 21, 19, 9],
)

"""Somme des encoches d'une colonne de l'os d'Ishango (`:G`, `:M` ou `:D`)."""
function ishango_somme(colonne::Symbol)
    haskey(OS_ISHANGO, colonne) ||
        throw(ArgumentError("colonne inconnue : $colonne (attendu :G, :M ou :D)"))
    return sum(getfield(OS_ISHANGO, colonne))
end

"""
    ishango_analyse() -> NamedTuple

Analyse arithmétique des trois colonnes : somme, écriture en multiple du module
`12` (l'hypothèse « calendaire » veut que les sommes soient des multiples de 12),
et, le cas échéant, la lecture en nombres premiers. Aucune conclusion culturelle
n'est tirée ici : seules les régularités arithmétiques sont établies.
"""
function ishango_analyse(; modulo::Integer = 12)
    colonnes = (:G, :M, :D)
    sommes = Dict(c => ishango_somme(c) for c in colonnes)
    multiples = Dict(c => (sommes[c] % modulo == 0 ? sommes[c] ÷ modulo : nothing)
                          for c in colonnes)
    premiers = Dict(c => all(_est_premier, getfield(OS_ISHANGO, c)) for c in colonnes)
    return (sommes = sommes, modulo = modulo, multiples = multiples,
            colonnes_premieres = premiers)
end

_est_premier(n::Integer) = n > 1 && all(n % d != 0 for d in 2:isqrt(n))

# ----------------------------------------------------------------------------
#  Os de Lebombo  (~44 000 ans ; encoches possiblement lunaires)
# ----------------------------------------------------------------------------

"""Nombre d'encoches relevées sur l'os de Lebombo (Eswatini)."""
const LEBOMBO_ENCOCHES = 29

"""Durée moyenne de la lunaison (jour synodique), en jours — repère de comparaison."""
lunaison_jours() = 29.530588853

"""
    lebombo_lunaison() -> NamedTuple

Compare le nombre d'encoches de l'os de Lebombo à la lunaison. L'écart est rendu
honnêtement ; l'interprétation « calendrier lunaire » reste une hypothèse des
auteurs, non un résultat du calcul.
"""
function lebombo_lunaison()
    ecart = abs(LEBOMBO_ENCOCHES - lunaison_jours())
    return (encoches = LEBOMBO_ENCOCHES, lunaison = lunaison_jours(),
            ecart_jours = ecart, proche_lunaison = ecart < 1.0)
end

# ----------------------------------------------------------------------------
#  Systèmes de talles (encoches groupées)
# ----------------------------------------------------------------------------

"""Systèmes de talles attestés, par module de groupement (table déclarative)."""
const SYSTEMES_ENCOCHES = Dict{Int,String}(
    5  => "Groupement par 5 (talles en faisceaux ; base du comptage digital et des cauris).",
    10 => "Groupement par 10 (décimal).",
    20 => "Groupement par 20 (vigésimal ; cauris, yoruba, igbo).",
)

"""
    compter_encoches(n, modulo = 5) -> NamedTuple

Groupement de `n` encoches en paquets de `modulo` (talles) plus un reste. Rend le
nombre de paquets complets et les encoches libres — la lecture qu'un compteur
ferait d'une suite de marques.
"""
function compter_encoches(n::Integer; modulo::Integer = 5)
    n >= 0 || throw(ArgumentError("le comptage porte sur les entiers naturels"))
    modulo >= 2 || throw(ArgumentError("le module de groupement vaut au moins 2"))
    paquets, libres = divrem(n, modulo)
    return (n = n, modulo = modulo, paquets = paquets, libres = libres)
end

# ----------------------------------------------------------------------------
#  Enregistrement au registre
# ----------------------------------------------------------------------------

enregistrer_savoir!(Savoir(:artefacts;
    nom = "Artefacts à encoches (Ishango, Lebombo)",
    domaine = :artefacts,
    resume = "Analyse des colonnes d'encoches (sommes, module 12, nombres premiers), lunaison, talles.",
    entrees = [:OS_ISHANGO, :ishango_somme, :ishango_analyse,
               :LEBOMBO_ENCOCHES, :lunaison_jours, :lebombo_lunaison,
               :SYSTEMES_ENCOCHES, :compter_encoches]))
