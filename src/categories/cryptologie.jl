# ============================================================================
#  Cryptologie kamitique  (chapitre 24)
# ----------------------------------------------------------------------------
#  « hachage par pesée, chiffrement par redistribution ». L'empreinte est un
#  vecteur de degrés mesurés (une position, non un bit) ; le chiffrement engage
#  la redistribution des présences, et sa difficulté tient à l'irréversibilité de
#  la pesée, non à la factorisation.
# ============================================================================

"""
    Empreinte

L'**empreinte par pesée** d'une figure : le vecteur de degrés `ν(f, p)` mesurés sur
un faisceau de propositions (les « regards »). C'est une position dans un ordre, non
une chaîne de bits.
"""
struct Empreinte
    degres :: Vector{Float64}
end

Base.length(e::Empreinte) = length(e.degres)
Base.:(==)(a::Empreinte, b::Empreinte) = a.degres == b.degres
Base.hash(e::Empreinte, h::UInt) = hash(e.degres, h)

"""
    hachage_par_pesee(f, regards) -> Empreinte

**Hachage par pesée** (chapitre 24). Produit l'empreinte de la figure `f` en la
mesurant sur le faisceau de `regards` : `ν(f, p)` pour chaque proposition `p`. Deux
figures de même empreinte occupent la même position au regard de ces propositions.
"""
function hachage_par_pesee(f::Figure, regards::AbstractVector{Proposition})
    Ψf = Etat([f], [1.0])
    return Empreinte([valuation(Ψf, p) for p in regards])
end

"""
    hachage_par_pesee(Ψ, regards) -> Empreinte

Empreinte d'un état : ses degrés `ν(Ψ, p)` sur les `regards`.
"""
hachage_par_pesee(Ψ::Etat, regards::AbstractVector{Proposition}) =
    Empreinte([valuation(Ψ, p) for p in regards])

"""
    chiffrement_par_redistribution(Ψ, cle) -> Etat

**Chiffrement par redistribution** (chapitre 24). Applique au clair `Ψ` la loi de
redistribution avec les facteurs de la clé : la présence est repondérée de façon
multiplicative, puis renormalisée — rien ne s'ajoute, tout se réorganise (axiome
A-K2). Le message chiffré conserve la totalité de la présence.
"""
chiffrement_par_redistribution(Ψ::Etat, cle::AbstractVector{<:Real}) =
    redistribuer(Ψ, cle)

"""
    dechiffrement_par_redistribution(Ψc, cle) -> Etat

Récupère le clair en redistribuant par l'inverse de la clé. La redistribution étant
une renormalisation, le clair est retrouvé à un facteur d'échelle près.
"""
dechiffrement_par_redistribution(Ψc::Etat, cle::AbstractVector{<:Real}) =
    redistribuer(Ψc, 1.0 ./ float.(cle))
