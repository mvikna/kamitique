# ============================================================================
#  L'espace des phases global  (ℋ_Noun, M₄, {ℳ_k}²²)
# ----------------------------------------------------------------------------
#  La synthèse axiomatique de la CQG (chap. 1 §6) définit l'espace des phases
#  global comme un triplet : le substrat hilbertien ℋ_Noun qui porte les
#  potentialités, la variété évolutive M₄ qui porte les manifestations, et
#  l'algèbre {ℳ_k}²² des vingt-deux opérateurs de structuration — les Métous —
#  établie à l'anatomie universelle (chap. 5).
#
#  Y sont consignés :
#    • les **neuf constituants** universels de toute entité (CQG éq. 17) ;
#    • les **neuf degrés de liberté topologiques** — l'Ennéade (classes de
#      Stiefel–Whitney, de Chern et de Pontryagin) ;
#    • l'**algèbre de Lie** des vingt-deux Métous : [ℳ_j, ℳ_k] = i f_jkl ℳ_l
#      (CQG éq. 18), avec ses contrats d'antisymétrie et d'identité de Jacobi.
# ============================================================================

# ----------------------------------------------------------------------------
#  Les neuf constituants universels de toute entité (CQG éq. 17)
# ----------------------------------------------------------------------------

"""L'ordre canonique des neuf constituants (CQG, éq. 17)."""
const ORDRE_CONSTITUANTS =
    [:Khat, :Khaibit, :Ren, :Ba, :Ka, :Ib, :Sekhem, :Sahu, :Akh]

"""Définition formalisée et corrélat physique de chaque constituant (CQG tab. 1)."""
const CONSTITUANTS = Dict{Symbol,String}(
    :Khat    => "Substrat matériel dense stabilisé par la géométrie fractale ; champ de matière condensée.",
    :Khaibit => "Champ de dissipation thermique et électromagnétique émis dans l'éther ; rayonnement, bilan entropique.",
    :Ren     => "Signature informationnelle, identifiant topologique univoque inscrit dans la mémoire morphique.",
    :Ba      => "Âme mobile, vecteur de non-localité et de transport d'information ; amplitudes d'intrication.",
    :Ka      => "Moteur quantique, tenseur de contrainte énergétique interne anti-entropique.",
    :Ib      => "Attracteur informationnel décisionnel soumis à la norme de la Maât ; bassin d'attraction.",
    :Sekhem  => "Puissance agissante, potentiel cinétique brut du système ; capacité de modification du champ.",
    :Sahu    => "Corps spirituel stable et solitonique atteint par maturation géométrique.",
    :Akh     => "Esprit lumineux unifié réintégré dans le Noun et la mémoire morphique universelle.",
)

"""Les neuf constituants, dans l'ordre canonique (CQG, éq. 17)."""
constituants() = copy(ORDRE_CONSTITUANTS)

"""Rang (1 … 9) d'un constituant dans l'ordre canonique ; `nothing` si inconnu."""
ordre_constituant(nom::Symbol) = findfirst(==(nom), ORDRE_CONSTITUANTS)

"""
    Entite(valeurs)

Une entité manifeste — le neuf-uplet `(Khat, Khaibit, Ren, Ba, Ka, Ib, Sekhem,
Sahu, Akh)` de la CQG (éq. 17). Toute entité, de la sous-particule à l'égrégore,
est un tel neuf-uplet ; seule sa configuration numérique diffère.
"""
struct Entite
    valeurs :: Vector{Float64}

    function Entite(v::AbstractVector{<:Real})
        length(v) == 9 ||
            throw(ArgumentError("une entité manifeste porte neuf constituants (CQG éq. 17)"))
        new(Float64[v...])
    end
end

"""Valeur d'un constituant d'une entité, désigné par son nom traditionnel."""
function constituant(e::Entite, nom::Symbol)
    i = ordre_constituant(nom)
    i === nothing && throw(ArgumentError("constituant inconnu : $nom"))
    return e.valeurs[i]
end

# ----------------------------------------------------------------------------
#  Les neuf degrés de liberté topologiques — l'Ennéade (A2)
# ----------------------------------------------------------------------------

"""Les trois familles de classes caractéristiques : l'Ennéade (CQG §1.3)."""
const FAMILLES_INVARIANTS = (:stiefel_whitney, :chern, :pontryagin)

"""
Nombre de degrés de liberté topologiques fixé par l'Axiome 2 : **neuf**
(`dim DOF_top = 9`). Ce sont les classes de Stiefel–Whitney, de Chern et de
Pontryagin qui déterminent complètement la topologie de la variété.
"""
const DOF_TOPOLOGIQUES = 9

"""Contrôle qu'une configuration d'invariants porte bien les neuf degrés de l'Ennéade."""
enneade_valide(v::AbstractVector) = length(v) == DOF_TOPOLOGIQUES

# ----------------------------------------------------------------------------
#  Les vingt-deux Métous — opérateurs non-commutatifs de la réalité (CQG §5.4)
# ----------------------------------------------------------------------------

"""Nombre de Métous — les canaux de circulation de toute entité : **vingt-deux**."""
const NB_METOUS = 22

"""Familles de Métous (CQG §17.2) : 4 céphaliques, 2 supérieurs, 10 du tronc, 6 inférieurs."""
const FAMILLES_METOUS = Dict{Symbol,UnitRange{Int}}(
    :cephaliques         => 1:4,
    :membres_superieurs  => 5:6,
    :tronc               => 7:16,
    :membres_inferieurs  => 17:22,
)

"""Les vingt-deux Métous, dans l'ordre des canaux `ℳ₁ … ℳ₂₂`."""
metous() = collect(1:NB_METOUS)

"""
    famille_metou(k) -> Symbol

La famille anatomique du `k`-ième Métou (céphaliques, membres supérieurs, tronc,
membres inférieurs) — partition exacte de `1:22` en `4 + 2 + 10 + 6`.
"""
function famille_metou(k::Integer)
    1 <= k <= NB_METOUS || throw(ArgumentError("un Métou est un canal de 1 à 22"))
    for (nom, plage) in FAMILLES_METOUS
        k in plage && return nom
    end
    return :inconnue
end

"""
    AlgebreMetous(f)

L'algèbre de Lie engendrée par les vingt-deux Métous : `[ℳ_j, ℳ_k] = i f_jkl ℳ_l`
(CQG, éq. 18). `f` est le tenseur `22 × 22 × 22` des constantes de structure ; le
contrat d'antisymétrie `f_jkl = −f_kjl` et l'identité de Jacobi sont **vérifiables**
([`verifie_antisymetrie_metous`](@ref), [`verifie_jacobi_metous`](@ref)). La
non-commutativité est l'essence de l'algèbre : l'ordre d'activation des canaux
constitue la configuration.
"""
struct AlgebreMetous
    f :: Array{Float64,3}

    function AlgebreMetous(f::AbstractArray{<:Real,3})
        size(f) == (NB_METOUS, NB_METOUS, NB_METOUS) ||
            throw(ArgumentError("les constantes de structure portent 22×22×22 entrées (éq. 18)"))
        new(Float64.(f))
    end
end

"""
    verifie_antisymetrie_metous(alg) -> Bool

Le contrat d'antisymétrie `f_jkl = −f_kjl` (donc `f_jjl = 0`) sur toute l'algèbre.
"""
function verifie_antisymetrie_metous(alg::AlgebreMetous; tol::Real = 1e-12)
    f = alg.f
    for j in 1:NB_METOUS, k in 1:NB_METOUS, l in 1:NB_METOUS
        abs(f[j, k, l] + f[k, j, l]) <= tol || return false
    end
    return true
end

"""
    verifie_jacobi_metous(alg) -> Bool

L'identité de Jacobi de l'algèbre de Lie `[ℳ_j, ℳ_k] = i f_jkl ℳ_l` (éq. 18) :
`Σ_l ( f_jkl·f_lmn + f_kml·f_ljn + f_mjl·f_lkn ) = 0` — le premier indice de la
première paire de chaque terme tourne cycliquement `(jk) → (km) → (mj)`, et le
dernier indice porte celui laissé de côté à l'itération précédente.
"""
function verifie_jacobi_metous(alg::AlgebreMetous; tol::Real = 1e-10)
    f = alg.f
    for j in 1:NB_METOUS, k in 1:NB_METOUS, m in 1:NB_METOUS, n in 1:NB_METOUS
        s = 0.0
        for l in 1:NB_METOUS
            s += f[j, k, l] * f[l, m, n] + f[k, m, l] * f[l, j, n] + f[m, j, l] * f[l, k, n]
        end
        abs(s) <= tol || return false
    end
    return true
end

# ----------------------------------------------------------------------------
#  L'espace des phases global — synthèse axiomatique (CQG §1.6)
# ----------------------------------------------------------------------------

"""
    EspacePhases(substrat, variete, metous)

Le triplet `(ℋ_Noun, M₄, {ℳ_k}²²)` de la synthèse axiomatique (CQG §1.6) : le
substrat hilbertien porte les potentialités, la variété évolutive porte les
manifestations, et l'algèbre des Métous porte les opérations de structuration.
"""
struct EspacePhases
    substrat :: Symbol
    variete  :: Symbol
    metous   :: AlgebreMetous
end

"""
    espace_phases(alg) -> EspacePhases

L'espace des phases global standard : `(ℋ_Noun, M₄, alg)`.
"""
espace_phases(alg::AlgebreMetous) = EspacePhases(:Noun, :M4, alg)
