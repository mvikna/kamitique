# ============================================================================
#  Savoir : la géomancie  (sikidy malgache, ifa yoruba, tirage par cauris)
# ----------------------------------------------------------------------------
#  Logique de calcul de la géomancie africaine. La figure géomantique est un mot
#  de **quatre lignes binaires** (trait simple / trait double) : il y en a donc
#  exactement 2⁴ = 16. Toute l'algèbre est une algèbre de parité :
#    • l'**addition** de deux figures est le OU-exclusif ligne à ligne ;
#    • l'**inversion** échange traits simples et doubles ;
#    • la **réversion** renverse l'ordre des lignes (haut ↔ bas).
#  De quatre figures « mères » se déduisent, par transposition puis addition, les
#  filles, nièces, témoins et le **juge** — la figure qui répond. C'est le bouclier
#  géomantique, identique dans son principe au sikidy malgache.
#
#  Convention (déclarée) : bit = 1 → trait simple/actif, bit = 0 → trait double/
#  passif ; lignes de haut en bas = Feu, Air, Eau, Terre. La table des noms suit
#  une tradition explicite unique ; elle est **déclarative** et n'affecte pas
#  l'algèbre de parité, qui est l'objet propre du calcul.
# ============================================================================

const MASQUE_GEOMANCIE = 0b1111

"""Nombre de lignes d'une figure géomantique."""
const LIGNES_GEOMANCIE = 4

"""Les 16 figures géomantiques — noms traditionnels, table déclarative (code → nom)."""
const GEOMANCIE_NOMS = Dict{Int,String}(
    0  => "Populus",        1  => "Tristitia",      2  => "Albus",
    3  => "Fortuna Major",  4  => "Rubeus",         5  => "Acquisitio",
    6  => "Conjunctio",     7  => "Caput Draconis", 8  => "Laetitia",
    9  => "Carcer",         10 => "Amissio",        11 => "Puella",
    12 => "Fortuna Minor",  13 => "Puer",           14 => "Cauda Draconis",
    15 => "Via",
)

"""Nom traditionnel d'une figure géomantique (table déclarative)."""
geomancie_nom(code::Integer) = get(GEOMANCIE_NOMS, Int(code), "Figure $(Int(code))")

"""Contrôle qu'un code désigne bien une figure (0 ≤ code ≤ 15)."""
function _valider_figure(code::Integer)
    0 <= code <= MASQUE_GEOMANCIE ||
        throw(ArgumentError("une figure géomantique est un mot de 4 bits (0:15), reçu $code"))
    return Int(code)
end

"""Lignes `(bas ← haut)` d'une figure : le vecteur des 4 bits, ligne 1 en tête."""
geomancie_bits(code::Integer) =
    [Int((code >> (LIGNES_GEOMANCIE - r)) & 1) for r in 1:LIGNES_GEOMANCIE]

"""Code d'une figure à partir de ses quatre lignes (haut → bas)."""
function geomancie_code(lignes::AbstractVector{<:Integer})
    length(lignes) == LIGNES_GEOMANCIE ||
        throw(ArgumentError("une figure porte exactement 4 lignes"))
    code = 0
    for b in lignes
        b in (0, 1) || throw(ArgumentError("chaque ligne vaut 0 (double) ou 1 (simple)"))
        code = (code << 1) | Int(b)
    end
    return code
end

"""
    geomancie_addition(a, b) -> Int

**Addition** géomantique : OU-exclusif ligne à ligne (parité). Elle est
commutative, associative, d'élément neutre `Populus` (0) et involutive
(`a ⊕ a = Populus`).
"""
geomancie_addition(a::Integer, b::Integer) = xor(_valider_figure(a), _valider_figure(b))

"""
    geomancie_inversion(code) -> Int

**Inversion** : échange chaque trait simple en double et réciproquement (complément
à 4 bits). Autoinverse.
"""
geomancie_inversion(code::Integer) = xor(_valider_figure(code), MASQUE_GEOMANCIE)

"""
    geomancie_reversion(code) -> Int

**Réversion** : renverse l'ordre des quatre lignes (haut ↔ bas).
"""
function geomancie_reversion(code::Integer)
    c = _valider_figure(code)
    return ((c & 1) << 3) | ((c & 2) << 1) | ((c & 4) >> 1) | ((c & 8) >> 3)
end

"""Nombre de traits simples (lignes actives) d'une figure."""
geomancie_actifs(code::Integer) = count_ones(_valider_figure(code))

# ----------------------------------------------------------------------------
#  Bouclier géomantique  (mères → filles → nièces → témoins → juge)
# ----------------------------------------------------------------------------

"""
    geomancie_filles(meres) -> Vector{Int}

Les quatre **filles** d'un jeu de quatre mères, obtenues par **transposition** :
la j-ième fille rassemble les j-ièmes lignes des quatre mères, dans l'ordre.
"""
function geomancie_filles(meres::AbstractVector{<:Integer})
    length(meres) == 4 || throw(ArgumentError("quatre mères attendues"))
    filles = Int[]
    for j in 1:LIGNES_GEOMANCIE
        lignes = [Int((meres[i] >> (LIGNES_GEOMANCIE - j)) & 1) for i in 1:4]
        push!(filles, geomancie_code(lignes))
    end
    return filles
end

"""
    geomancie_bouclier(meres) -> NamedTuple

Construit le **bouclier** complet à partir des quatre mères :

- 4 mères ;
- 4 filles (transposition des mères) ;
- 4 nièces : `m₁⊕m₂`, `m₃⊕m₄`, `f₁⊕f₂`, `f₃⊕f₄` ;
- 2 témoins : `n₁⊕n₂` (témoin droit), `n₃⊕n₄` (témoin gauche) ;
- le **juge** : `témoin droit ⊕ témoin gauche`.

Le juge est la figure qui répond à la question posée.
"""
function geomancie_bouclier(meres::AbstractVector{<:Integer})
    length(meres) == 4 || throw(ArgumentError("quatre mères attendues"))
    m = _valider_figure.(meres)
    filles = geomancie_filles(m)
    nieces = [xor(m[1], m[2]), xor(m[3], m[4]), xor(filles[1], filles[2]), xor(filles[3], filles[4])]
    temoins = [xor(nieces[1], nieces[2]), xor(nieces[3], nieces[4])]
    juge = xor(temoins[1], temoins[2])
    return (meres = m, filles = filles, nieces = nieces, temoins = temoins, juge = juge)
end

# ----------------------------------------------------------------------------
#  Sikidy malgache
# ----------------------------------------------------------------------------

"""
    sikidy_reny(rng; cauris = 16) -> Vector{Int}

Les quatre **reny** (mères) du sikidy, tirées par parité de quatre poignées de
graines. Chaque poignée donne une figure de 4 lignes (tirage impair → trait simple).
"""
function sikidy_reny(rng; cauris::Integer = 16)
    cauris >= 1 || throw(ArgumentError("au moins un cauris par tirage"))
    noms = (reny = [cauris_figure(rng; cauris = cauris) for _ in 1:4],)
    return noms.reny
end

"""Les **zanaka** (filles) du sikidy, transposition des quatre reny (mères)."""
sikidy_zanaka(reny::AbstractVector{<:Integer}) = geomancie_filles(reny)

"""
    sikidy_tableau(rng; cauris = 16) -> NamedTuple

Tableau sikidy : quatre reny tirées, leurs zanaka, et le bouclier de parité
(nièces, témoins, juge). Le sikidy est, dans son principe, le même calcul que le
bouclier géomantique — la « science du sable » (khatt al-raml) dont Madagascar est
une branche.
"""
function sikidy_tableau(rng; cauris::Integer = 16)
    reny = sikidy_reny(rng; cauris = cauris)
    return merge(geomancie_bouclier(reny), (reny = reny, zanaka = geomancie_filles(reny)))
end

# ----------------------------------------------------------------------------
#  Ifa yoruba
# ----------------------------------------------------------------------------

"""
    ifa_figures() -> UnitRange{Int}

Les seize **Odu** d'une jambe de l'ifa yoruba, comme mots de quatre bits. Une
consultation complète croise deux de ces figures (une par jambe), soit
{@ref `ifa_odu`}` 16 × 16 = 256 combinaisons.
"""
ifa_figures() = 0:MASQUE_GEOMANCIE

"""Nombre total d'Odu d'ifa : 16 × 16 = 256."""
ifa_odu_total() = 16 * 16

"""
    ifa_odu(premier, second) -> NamedTuple

Un Odu d'ifa : la paire ordonnée de deux figures de quatre bits (les deux jambes
de la divination). `premier` est la figure de droite, `second` celle de gauche.
"""
function ifa_odu(premier::Integer, second::Integer)
    a = _valider_figure(premier)
    b = _valider_figure(second)
    return (premier = a, second = b, indice = a * 16 + b,
            nom_premier = geomancie_nom(a), nom_second = geomancie_nom(b))
end

# ----------------------------------------------------------------------------
#  Tirage par cauris
# ----------------------------------------------------------------------------

"""
    cauris_figure(rng; cauris = 16) -> Int

Tire une figure géomantique par parité : quatre poignées de cauris, un trait
simple pour une poignée impaire. Le générateur `rng` rend le tirage reproductible.
"""
function cauris_figure(rng; cauris::Integer = 16)
    cauris >= 1 || throw(ArgumentError("au moins un cauris par tirage"))
    lignes = Int[]
    for _ in 1:LIGNES_GEOMANCIE
        push!(lignes, isodd(rand(rng, 0:cauris)) ? 1 : 0)
    end
    return geomancie_code(lignes)
end

"""
    cauris_oracle(rng; cauris = 16) -> NamedTuple

Tirage par cauris d'une figure : le code, ses lignes et son nom déclaré.
"""
function cauris_oracle(rng; cauris::Integer = 16)
    code = cauris_figure(rng; cauris = cauris)
    return (code = code, bits = geomancie_bits(code), nom = geomancie_nom(code))
end

# ----------------------------------------------------------------------------
#  Enregistrement au registre
# ----------------------------------------------------------------------------

enregistrer_savoir!(Savoir(:geomancie;
    nom = "Géomancie (sikidy / ifa / cauris)",
    domaine = :geomancie,
    resume = "Algèbre de parité des 16 figures : addition, inversion, réversion, bouclier, sikidy, ifa.",
    entrees = [:geomancie_addition, :geomancie_inversion, :geomancie_reversion,
               :geomancie_filles, :geomancie_bouclier, :sikidy_reny, :sikidy_tableau,
               :ifa_figures, :ifa_odu, :cauris_oracle]))
