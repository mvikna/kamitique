# ============================================================================
#  Savoir : les motifs et leurs symétries  (adinkra, frises, sona)
# ----------------------------------------------------------------------------
#  Logique de calcul des motifs africains à partir de leur **groupe de
#  symétrie** — le point de vue de la théorie des groupes, qui est le langage
#  dans lequel ces motifs ont été formalisés (Gerdes, Eglash, Chemillier).
#    • un motif carré (p. ex. un symbole adinkra) a un stabilisateur dans le
#      groupe diédral D4 (8 opérations) ;
#    • un motif en bande (p. ex. une frise tissée) relève de l'un des 7 groupes
#      de frise ;
#    • une figure sona (tracé tchokwe) est **monolinéaire** : elle se parcourt
#      d'un seul trait fermé. Le module vérifie cette propriété et reconstruit
#      le parcours.
#  Les tables culturelles (noms adinkra, groupes) sont **déclaratives** ; le
#  calcul — rotation, réflexion, connexité, circuit — est l'objet propre du
#  savoir et ne dépend pas des tables.
# ============================================================================

# ----------------------------------------------------------------------------
#  Symétries d'un motif carré  (groupe diédral D4)
# ----------------------------------------------------------------------------

"""Les huit opérations du groupe diédral `D4` d'un carré (convention déclarée)."""
const OPERATIONS_D4 = (:identite, :rotation90, :rotation180, :rotation270,
                       :miroir_vertical, :miroir_horizontal,
                       :miroir_diagonal, :miroir_antidiagonal)

"""
    transformer_d4(motif, op) -> Matrix

Applique l'opération `op ∈ OPERATIONS_D4` à un motif carré. Les rotations sont
comptées positivement (sens inverse des aiguilles d'une montre) ; `miroir_vertical`
renverse les colonnes, `miroir_horizontal` les lignes, `miroir_diagonal` prend la
transposée, `miroir_antidiagonal` la transposée de la rotation d'un demi-tour.
"""
function transformer_d4(motif::AbstractMatrix, op::Symbol)
    f, c = size(motif)
    f == c || throw(ArgumentError("le groupe D4 exige un motif carré, reçu $f×$c"))
    op === :identite          && return permutedims(motif)
    op === :rotation90        && return reverse(permutedims(motif), dims = 1)
    op === :rotation180       && return reverse(reverse(motif, dims = 1), dims = 2)
    op === :rotation270       && return reverse(permutedims(motif), dims = 2)
    op === :miroir_vertical   && return reverse(motif, dims = 2)
    op === :miroir_horizontal && return reverse(motif, dims = 1)
    op === :miroir_diagonal   && return permutedims(motif)
    op === :miroir_antidiagonal &&
        return reverse(reverse(permutedims(motif), dims = 1), dims = 2)
    throw(ArgumentError("opération D4 inconnue : $op"))
end

"""
    symetries_d4(motif) -> Vector{Symbol}

Opérations de `D4` qui laissent le motif **invariant** : elles forment le
stabilisateur (sous-groupe) du motif.
"""
symetries_d4(motif::AbstractMatrix) =
    Symbol[op for op in OPERATIONS_D4 if transformer_d4(motif, op) == motif]

"""
    groupe_symetrie(motif) -> NamedTuple

Groupe de symétrie d'un motif carré : la liste des opérations invariantes, son
ordre et son nom (`:trivial`, `:cyclique2`, `:reflexion`, `:cyclique4`, `:klein`,
`:diedral4`). Le nom est déduit de l'ordre et de la présence des générateurs — il
n'est pas lu dans une table.
"""
function groupe_symetrie(motif::AbstractMatrix)
    ops = symetries_d4(motif)
    n = length(ops)
    nom = if n == 1
        :trivial
    elseif n == 2
        :rotation180 in ops ? :cyclique2 : :reflexion
    elseif n == 4
        :rotation90 in ops ? :cyclique4 : :klein
    elseif n == 8
        :diedral4
    else
        :inconnu
    end
    return (operations = ops, ordre = n, nom = nom)
end

# ----------------------------------------------------------------------------
#  Symétries d'un motif en bande  (7 groupes de frise)
# ----------------------------------------------------------------------------

"""Les sept groupes de frise, indexés par leur notation cristallographique."""
const GROUPES_FRISE = Dict{Symbol,String}(
    :p111 => "Translation seule (frise banale).",
    :p1a1 => "Translation + réflexion glissée (pas).",
    :p1m1 => "Translation + réflexion verticale (miroirs perpendiculaires au déplacement).",
    :p11m => "Translation + réflexion horizontale (miroir le long du déplacement).",
    :p112 => "Translation + rotation d'un demi-tour.",
    :p2mg => "Réflexion verticale + réflexion glissée + demi-tour (sans miroir horizontal).",
    :p2mm => "Groupe maximal : réflexions verticale et horizontale + glissement + demi-tour.",
)

"""Les dix-sept groupes cristallographiques plans (papier peint), pour mémoire."""
const GROUPES_PAPIER = (:p1, :p2, :pm, :pg, :cm, :pmm, :pmg, :pgg, :cmm,
                        :p4, :p4m, :p4g, :p3, :p3m1, :p31m, :p6, :p6m)

"""
    symetries_bande(motif) -> Vector{Symbol}

Opérations de symétrie présentes dans un motif en bande de largeur `w` supposée
égale à sa période horizontale. Sont testées : translation (par hypothèse),
réflexion verticale (colonnes), réflexion horizontale (lignes), rotation d'un
demi-tour, et réflexion glissée (miroir horizontal suivi d'un demi-décalage,
exigé par la parité de la largeur).
"""
function symetries_bande(motif::AbstractMatrix)
    w = size(motif, 2)
    ops = Symbol[:translation]
    reverse(motif, dims = 2) == motif && push!(ops, :reflexion_verticale)
    reverse(motif, dims = 1) == motif && push!(ops, :reflexion_horizontale)
    reverse(reverse(motif, dims = 1), dims = 2) == motif && push!(ops, :rotation_180)
    if iseven(w)
        circshift(reverse(motif, dims = 1), (0, w ÷ 2)) == motif &&
            push!(ops, :reflexion_glissee)
    end
    return ops
end

"""
    groupe_frise(motif) -> NamedTuple

Classification d'un motif en bande dans l'un des sept groupes de frise, d'après
la hiérarchie des sous-groupes : le nom et la liste des opérations sont déduits
des symétries effectivement présentes (aucune table à consulter pour décider).
"""
function groupe_frise(motif::AbstractMatrix)
    ops = symetries_bande(motif)
    rv = :reflexion_verticale in ops
    rh = :reflexion_horizontale in ops
    r2 = :rotation_180 in ops
    gl = :reflexion_glissee in ops
    nom = rv && rh ? :p2mm :
          rv && r2 ? :p2mg :
          rv       ? :p1m1 :
          rh       ? :p11m :
          r2       ? :p112 :
          gl       ? :p1a1 : :p111
    return (nom = nom, operations = ops, description = GROUPES_FRISE[nom])
end

# ----------------------------------------------------------------------------
#  Symboles adinkra  (table déclarative — Akan, Ghana)
# ----------------------------------------------------------------------------

"""Symboles adinkra attestés et leur sens (table déclarative)."""
const ADINKRA = Dict{Symbol,String}(
    :gye_nyame        => "« Excepté Dieu » — la suprématie de Dieu.",
    :sankofa          => "« Retourne le chercher » — apprendre du passé.",
    :adinkrahene      => "Chef des symboles adinkra — grandeur, leadership.",
    :dwennimmen       => "Cornes de bélier — humilité et force.",
    :nkyinkyim        => "Le zigzag — initiative, adaptabilité.",
    :eban             => "La clôture — sûreté, sécurité.",
    :akoma            => "Le cœur — patience et tolérance.",
    :funtunfunefu     => "Crocodiles siamois — unité dans la diversité.",
)

"""Table adinkra (symbole → sens), table déclarative du savoir `:motifs`."""
adinkra() = ADINKRA

# ----------------------------------------------------------------------------
#  Sona  (tracés tchokwe — propriété de monolinéarité ; Gerdes)
# ----------------------------------------------------------------------------

"""La grille de points du tracé sona : `p × q` points, coordonnées entières."""
sona_grille(p::Integer, q::Integer) =
    [(i, j) for i in 1:p, j in 1:q]

# Graphe d'adjacence d'un tracé donné sous forme de liste d'arêtes.
function _adjacence_sona(aretes)
    adj = Dict{NTuple{2,Int},Vector{NTuple{2,Int}}}()
    for (u, v) in aretes
        push!(get!(adj, NTuple{2,Int}(u), NTuple{2,Int}[]), NTuple{2,Int}(v))
        push!(get!(adj, NTuple{2,Int}(v), NTuple{2,Int}[]), NTuple{2,Int}(u))
    end
    return adj
end

"""
    sona_lignes(aretes) -> Int

Nombre de lignes fermées du tracé `aretes` (liste de couples de sommets). Un
tracé n'est un sona que si chaque sommet est de degré pair (chaque passage est
un aller-retour). Lève une erreur sinon.
"""
function sona_lignes(aretes)
    adj = _adjacence_sona(aretes)
    for (v, ns) in adj
        iseven(length(ns)) ||
            throw(ArgumentError("sommet $v de degré impair : le tracé n'est pas une ligne fermée"))
    end
    vus = Set{NTuple{2,Int}}()
    lignes = 0
    for s in keys(adj)
        s in vus && continue
        lignes += 1
        pile = NTuple{2,Int}[s]
        while !isempty(pile)
            x = pop!(pile)
            x in vus && continue
            push!(vus, x)
            for y in adj[x]
                y in vus || push!(pile, y)
            end
        end
    end
    return lignes
end

"""Indique si le tracé est **monolinéaire** : un seul trait fermé (définition du sona)."""
sona_monolineaire(aretes) = sona_lignes(aretes) == 1

"""
    sona_circuit(aretes) -> Vector{NTuple{2,Int}}

Reconstruit l'ordre de parcours d'un sona monolinéaire (algorithme de
Hierholzer sur le multigraphe d'arêtes). Le premier sommet est répété en fin
pour marquer la fermeture.
"""
function sona_circuit(aretes)
    aretes = collect(aretes)
    isempty(aretes) && throw(ArgumentError("tracé vide"))
    sona_monolineaire(aretes) ||
        throw(ArgumentError("le tracé doit être monolinéaire (un seul trait fermé)"))
    # Adjacence par indices d'arête : préserve les arêtes multiples.
    boucles = Dict{NTuple{2,Int},Vector{Int}}()
    for (k, (u, v)) in enumerate(aretes)
        push!(get!(boucles, NTuple{2,Int}(u), Int[]), k)
        push!(get!(boucles, NTuple{2,Int}(v), Int[]), k)
    end
    depart = NTuple{2,Int}(aretes[1][1])
    utilise = falses(length(aretes))
    chemin = NTuple{2,Int}[]
    pile = Tuple{NTuple{2,Int},Int}[]
    courant = depart
    while true
        libre = 0
        for k in boucles[courant]
            if !utilise[k]
                libre = k
                break
            end
        end
        if libre != 0
            utilise[libre] = true
            u, v = NTuple{2,Int}(aretes[libre][1]), NTuple{2,Int}(aretes[libre][2])
            suivant = u == courant ? v : u
            push!(pile, (courant, libre))
            courant = suivant
        elseif !isempty(pile)
            push!(chemin, courant)
            courant, _ = pop!(pile)
        else
            break
        end
    end
    push!(chemin, depart)
    return chemin
end

# ----------------------------------------------------------------------------
#  Enregistrement au registre
# ----------------------------------------------------------------------------

enregistrer_savoir!(Savoir(:motifs;
    nom = "Motifs et symétries (adinkra, frises, sona)",
    domaine = :motifs,
    resume = "Groupe D4 des motifs carrés, 7 groupes de frise, symboles adinkra, monolinéarité des sona.",
    entrees = [:OPERATIONS_D4, :transformer_d4, :symetries_d4, :groupe_symetrie,
               :GROUPES_FRISE, :GROUPES_PAPIER, :symetries_bande, :groupe_frise,
               :ADINKRA, :adinkra, :sona_grille, :sona_lignes, :sona_monolineaire,
               :sona_circuit]))
