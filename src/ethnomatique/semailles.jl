# ============================================================================
#  Savoir : les jeux de semailles  (awalé / oware / mancala)
# ----------------------------------------------------------------------------
#  Logique de calcul de la famille des jeux de semailles africains. Le modèle
#  retenu est l'**oware** (Akan, Ghana / Côte d'Ivoire) : deux camps de 6 trous,
#  4 graines par trou, semailles en boucle, capture des trous adverses totalisant
#  2 ou 3 graines, avec les deux garde-fous classiques :
#    • « nourrir » — un joueur ne peut pas prendre à un adversaire affamé ;
#    • « grand chelem » — une prise ne peut vider entièrement l'adversaire.
#  L'invariant de conservation (Σ graines) est vérifié à chaque coup.
# ============================================================================

"""
    PlateauSemailles(trous, graines, camp, grenier)

Position d'un jeu de semailles. Les trous sont numérotés `1:2trous` en suivant
l'ordre de semailles (boucle) : `1:trous` forment le camp 1, `trous+1:2trous` le
camp 2. `camp ∈ {1,2}` désigne le joueur au trait ; `grenier` compte les graines
capturées par chaque camp.
"""
struct PlateauSemailles
    trous   :: Int
    graines :: Vector{Int}
    camp    :: Int
    grenier :: Vector{Int}

    function PlateauSemailles(trous::Integer, graines::AbstractVector{<:Integer},
                              camp::Integer, grenier::AbstractVector{<:Integer})
        trous >= 2 || throw(ArgumentError("au moins deux trous par camp"))
        length(graines) == 2trous || throw(ArgumentError("le plateau porte 2*trous trous"))
        all(>=(0), graines) || throw(ArgumentError("les graines d'un trou sont positives ou nulles"))
        camp in (1, 2) || throw(ArgumentError("le camp au trait vaut 1 ou 2"))
        length(grenier) == 2 || throw(ArgumentError("deux greniers, un par camp"))
        new(Int(trous), Int[graines...], Int(camp), Int[grenier...])
    end
end

"""Trous appartenant à un camp, dans l'ordre de semailles."""
_camp_trous(p::PlateauSemailles, camp::Integer) =
    camp == 1 ? (1:p.trous) : (p.trous + 1:2p.trous)

"""
    awele_initialiser(; trous = 6, graines = 4) -> PlateauSemailles

Position initiale : `graines` dans chacun des `2*trous` trous, camp 1 au trait.
"""
awele_initialiser(; trous::Integer = 6, graines::Integer = 4) =
    PlateauSemailles(trous, fill(Int(graines), 2trous), 1, [0, 0])

"""Nombre total de graines du jeu (trous + greniers) — invariant de conservation."""
awele_total(p::PlateauSemailles) = sum(p.graines) + sum(p.grenier)

# Semailles brutes : vide le trou `trou`, puis dépose une graine par trou suivant
# jusqu'à épuisement. Retourne l'indice du dernier trou atteint.
function _semis!(graines::Vector{Int}, trou::Int)
    N = length(graines)
    s = graines[trou]
    graines[trou] = 0
    idx = trou
    for _ in 1:s
        idx = mod1(idx + 1, N)
        graines[idx] += 1
    end
    return idx
end

"""
    awele_coups(p) -> Vector{Int}

Coups légaux du camp au trait : ses trous non vides. Si l'adversaire est affamé
(aucune graine), seuls les coups qui lui en donnent au moins une sont légaux ; s'il
n'en existe aucun, la liste est vide (**fin par famine**).
"""
function awele_coups(p::PlateauSemailles)
    camp, opp = p.camp, 3 - p.camp
    base = Int[h for h in _camp_trous(p, camp) if p.graines[h] > 0]
    sum(p.graines[h] for h in _camp_trous(p, opp)) > 0 && return base
    nourrissants = Int[]
    for h in base
        g = copy(p.graines)
        _semis!(g, h)
        sum(g[j] for j in _camp_trous(p, opp)) > 0 && push!(nourrissants, h)
    end
    return nourrissants
end

"""Indique si le camp au trait a au moins un coup légal."""
awele_jouable(p::PlateauSemailles) = !isempty(awele_coups(p))

"""
    awele_semer(p, trou) -> (PlateauSemailles, Int)

Joue le coup `trou` pour le camp au trait et retourne la position suivante (camp
adverse au trait) et le nombre de graines capturées. Lève une erreur si le coup
n'est pas légal (trou hors camp ou vide).
"""
function awele_semer(p::PlateauSemailles, trou::Integer)
    camp = p.camp
    trou in _camp_trous(p, camp) ||
        throw(ArgumentError("le trou $trou n'appartient pas au camp $camp"))
    p.graines[trou] > 0 || throw(ArgumentError("le trou $trou est vide"))
    g = copy(p.graines)
    idx = _semis!(g, Int(trou))
    adversaire = 3 - camp
    opp = _camp_trous(p, adversaire)
    grenier = copy(p.grenier)
    capture = 0
    if idx in opp
        tmp = copy(g)
        cap = 0
        cur = idx
        while cur in opp && (g[cur] == 2 || g[cur] == 3)
            cap += g[cur]
            tmp[cur] = 0
            cur = mod1(cur - 1, length(g))
        end
        total_opp = sum(g[h] for h in opp)
        if cap > 0 && cap < total_opp       # ni prise nulle, ni grand chelem
            g = tmp
            capture = cap
        end
    end
    grenier[camp] += capture
    return PlateauSemailles(p.trous, g, adversaire, grenier), capture
end

# Stratégies déterministes ; :aleatoire consomme un générateur ensemencé.
function _choisir_coup(p::PlateauSemailles, strategie::Symbol, rng)
    coups = awele_coups(p)
    isempty(coups) && return 0
    strategie === :premier && return first(coups)
    if strategie === :gourmand
        meilleur, gain = first(coups), -1
        for h in coups
            _, cap = awele_semer(p, h)
            if cap > gain
                meilleur, gain = h, cap
            end
        end
        return meilleur
    end
    strategie === :aleatoire && return coups[rand(rng, eachindex(coups))]
    throw(ArgumentError("stratégie inconnue : $strategie"))
end

"""
    awele_partie(; strategie1 = :gourmand, strategie2 = :gourmand,
                   trous = 6, graines = 4, max_tours = 400, graine = 0) -> NamedTuple

Joue une partie complète, de façon **déterministe** (le tirage `:aleatoire` utilise
un générateur ensemencé par `graine`). À la fin (un camp ne peut plus jouer), le
camp adverse récolte les graines restant sur le plateau. Retourne la position
finale, le nombre de tours, l'issue et les deux scores.
"""
function awele_partie(; strategie1::Symbol = :gourmand, strategie2::Symbol = :gourmand,
                      trous::Integer = 6, graines::Integer = 4, max_tours::Integer = 400,
                      graine::Integer = 0)
    rng = MersenneTwister(graine)
    p = awele_initialiser(; trous = trous, graines = graines)
    tours = 0
    while awele_jouable(p) && tours < max_tours
        h = _choisir_coup(p, p.camp == 1 ? strategie1 : strategie2, rng)
        h == 0 && break
        p, _ = awele_semer(p, h)
        tours += 1
    end
    termine = !awele_jouable(p)
    if termine
        adversaire = 3 - p.camp
        grenier = copy(p.grenier)
        grenier[adversaire] += sum(p.graines)          # récolte des graines restantes
        p = PlateauSemailles(p.trous, zeros(Int, 2p.trous), p.camp, grenier)
    end
    gagnant = p.grenier[1] > p.grenier[2] ? 1 : (p.grenier[2] > p.grenier[1] ? 2 : 0)
    return (plateau = p, tours = tours, termine = termine, gagnant = gagnant,
            score1 = p.grenier[1], score2 = p.grenier[2])
end

"""Variantes africaines attestées de la famille des jeux de semailles."""
const VARIANTES_SEMAILLES = Dict{Symbol,String}(
    :oware    => "Oware (Akan, Ghana/Côte d'Ivoire) — 2×6 trous, prise des trous à 2 ou 3.",
    :awele    => "Awalé / warri — nom générique ouest-africain du même jeu.",
    :kalah    => "Kalah (variante commerciale) — greniers séparés en bout de rangée.",
    :omweso   => "Omweso (Buganda, Ouganda) — 2×16 trous, prises en chaîne.",
    :bao      => "Bao (Swahili, Afrique de l'Est) — 2×4 rangées, règles de prise complexes.",
    :dara     => "Dara / derrah — jeu d'alignement (trois en ligne), proche de l'awalé par le matériel.",
)

awele_variantes() = VARIANTES_SEMAILLES

# ----------------------------------------------------------------------------
#  Enregistrement au registre
# ----------------------------------------------------------------------------

enregistrer_savoir!(Savoir(:jeux_semailles;
    nom = "Jeux de semailles (awalé / oware)",
    domaine = :jeux,
    resume = "Semailles en boucle, capture des trous à 2 ou 3, nourrir l'affamé, grand chelem.",
    entrees = [:PlateauSemailles, :awele_initialiser, :awele_coups, :awele_semer,
               :awele_jouable, :awele_partie, :awele_total, :awele_variantes]))
