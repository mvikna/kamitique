# ============================================================================
#  La Loi Universelle — le lagrangien unifié à trois secteurs (CQG chap. 2)
# ----------------------------------------------------------------------------
#  Le second chapitre de la CQG établit la loi qui gouverne l'univers manifesté
#  sous la forme d'un unique lagrangien sur M₄ (éq. 6) :
#
#    ℒ_CQG = √−g [ (R − 2Λ)/(2κ) − ¼ F^a_μν F^{aμν} + ℒ_morph ]
#
#  Trois secteurs s'y lisent, homologues des trois régimes du flux de Heka :
#    • l'élasticité de l'éther — le terme de courbure (R − 2Λ)/(2κ) : la variété
#      paie un prix en action pour toute courbure qu'elle supporte ;
#    • l'antagonisme Horus–Seth — le terme cinétique de jauge −¼ F² (éq. 4–5) :
#      par sa non-linéarité, il condense l'énergie en structures massives ;
#    • la commande morphique — le terme ℒ_morph : nul ordre, nulle mémoire ne
#      sont gratuits ; l'information participe du même principe variationnel.
#
#  Source : CQG §2.1 (éther), §2.2 (tenseur de jauge, éq. 4–5), §2.3 (éq. 6).
# ============================================================================

"""
    SecteurEther(R, Λ, κ)

Le secteur d'élasticité de l'éther : le terme de courbure `(R − 2Λ)/(2κ)` de la
Loi Universelle (CQG éq. 6). `R` est la courbure scalaire de la métrique d'éther,
`Λ` la constante cosmologique — tension d'équilibre de l'attracteur de la Maât —
et `κ` le couplage gravitationnel.
"""
struct SecteurEther
    R :: Float64
    Λ :: Float64
    κ :: Float64
end

SecteurEther(R::Real, Λ::Real, κ::Real) = SecteurEther(Float64(R), Float64(Λ), Float64(κ))

"""
    SecteurJauge(F2)

Le secteur d'antagonisme Horus–Seth : le terme cinétique de jauge `−¼ F^a_μν
F^{aμν}` (CQG éq. 6), porté par le tenseur de champ non-abélien `F_μν` (éq. 5).
`F2` est le scalaire de jauge `F^a_μν F^{aμν}`.
"""
struct SecteurJauge
    F2 :: Float64
end

SecteurJauge(F2::Real) = SecteurJauge(Float64(F2))

"""
    SecteurMorphique(L)

Le secteur de la commande morphique : le terme `ℒ_morph` qui couple les structures
informationnelles (mémoire universelle, signatures du Ren, flux d'intrication du
Ba) à la géométrie (CQG éq. 6).
"""
struct SecteurMorphique
    L :: Float64
end

SecteurMorphique(L::Real) = SecteurMorphique(Float64(L))

"""
    densite_ether(s) -> Float64

La densité lagrangienne du secteur d'éther : `(R − 2Λ)/(2κ)` (CQG éq. 6).
"""
function densite_ether(s::SecteurEther)
    s.κ == 0 && throw(ArgumentError("le couplage gravitationnel κ est non nul"))
    return (s.R - 2s.Λ) / (2s.κ)
end

"""
    densite_jauge(s) -> Float64

La densité lagrangienne du secteur de jauge : `−¼ F²` (CQG éq. 6).
"""
densite_jauge(s::SecteurJauge) = -s.F2 / 4

"""
    densite_morphique(s) -> Float64

La densité lagrangienne du secteur morphique : `ℒ_morph` (CQG éq. 6).
"""
densite_morphique(s::SecteurMorphique) = s.L

"""
    tenseur_jauge(Aμ, Aν, ∂μAν, ∂νAμ; g = 1.0) -> Matrix

Le tenseur de champ de jauge non-abélien (CQG éq. 4–5) :

    F_μν = ∂_μ A_ν − ∂_ν A_μ + g [A_μ, A_ν].

Le champ de connexion `A_μ` est à valeurs dans l'algèbre de Lie du groupe de
structure. La partie linéaire `∂_μ A_ν − ∂_ν A_μ` est la force de rappel
structurante — **Horus** ; le commutateur `g[A_μ, A_ν]`, absent des théories
abéliennes, est le siège de la non-linéarité — **Seth**, dispersion et contrainte
non-linéaire. Les deux pôles sont inséparables : leur équilibre est la condition
d'existence d'un cosmos.
"""
function tenseur_jauge(Aμ::AbstractMatrix, Aν::AbstractMatrix,
                       ∂μAν::AbstractMatrix, ∂νAμ::AbstractMatrix; g::Real = 1.0)
    return ∂μAν - ∂νAμ + g * (Aμ * Aν - Aν * Aμ)
end

"""
    LagrangienUnifie(ether, jauge, morph, racine_g)

Le lagrangien unifié de la Loi Universelle (CQG éq. 6) : les trois secteurs
conjoints et le facteur de volume `√−g` de la variété.
"""
struct LagrangienUnifie
    ether    :: SecteurEther
    jauge    :: SecteurJauge
    morph    :: SecteurMorphique
    racine_g :: Float64
end

LagrangienUnifie(ether::SecteurEther, jauge::SecteurJauge, morph::SecteurMorphique,
                 racine_g::Real) =
    LagrangienUnifie(ether, jauge, morph, Float64(racine_g))

"""
    densite_lagrangien(L) -> Float64

La densité lagrangienne unifiée (CQG éq. 6) :
`ℒ_CQG = √−g [ (R−2Λ)/(2κ) − ¼F² + ℒ_morph ]`.
"""
function densite_lagrangien(L::LagrangienUnifie)
    return L.racine_g * (densite_ether(L.ether) +
                         densite_jauge(L.jauge) +
                         densite_morphique(L.morph))
end

"""
    secteurs(L) -> (SecteurEther, SecteurJauge, SecteurMorphique)

Les trois secteurs conjoints de la Loi Universelle : l'élasticité de l'éther,
l'antagonisme Horus–Seth, la commande morphique.
"""
secteurs(L::LagrangienUnifie) = (L.ether, L.jauge, L.morph)

"""
    LOI_UNIVERSELLE

La Loi Universelle de la CQG (éq. 6), consignée dans sa forme exacte.
"""
const LOI_UNIVERSELLE =
    "ℒ_CQG = √−g [ (R − 2Λ)/(2κ) − ¼ F^a_μν F^{aμν} + ℒ_morph ]"
