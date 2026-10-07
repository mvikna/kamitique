# ============================================================================
#  Savoir : les numérations africaines
# ----------------------------------------------------------------------------
#  Logique de calcul des systèmes de numération attestés : égyptien
#  hiéroglyphique (décimal additif), guèze (décimal à symboles propres), yoruba
#  (vigésimal soustractif), et comptage par cauris. Chaque résultat est un objet
#  auto-descriptif ; les tables de mots sont **déclaratives** (données culturelles)
#  et indépendantes de l'arithmétique, qui est l'objet propre du calcul.
# ============================================================================

"""Systèmes de numération africains attestés, avec leur principe de calcul."""
const SYSTEMES_NUMERATION = Dict{Symbol,String}(
    :egyptien => "Hiéroglyphes égyptiens — décimal additif (puissances de 10 répétées).",
    :geez     => "Numération guèze/éthiopienne — décimale à symboles propres (1–9, dizaines, 100, 10 000).",
    :yoruba   => "Numération yoruba — vigésimale, avec soustraction dans chaque score (20k ± r).",
    :igbo     => "Numération igbo — vigésimale à soustraction (même squelette que le yoruba).",
    :cauris   => "Comptage par cauris — groupements par 5 et par 20.",
    :positionnel => "Numération positionnelle générique de base b.",
)

# ----------------------------------------------------------------------------
#  Numération positionnelle générique
# ----------------------------------------------------------------------------

"""
    numerer_base(n, base = 10) -> Vector{Int}

Décomposition positionnelle de `n` en base `base`. Le vecteur est rendu **poids
faible en tête** : `numerer_base(13, 10) == [3, 1]`, `numerer_base(13, 2) == [1,0,1,1]`.
"""
function numerer_base(n::Integer; base::Integer = 10)
    2 <= base <= 60 || throw(ArgumentError("base ∈ [2, 60], reçu $base"))
    n >= 0 || throw(ArgumentError("la numération porte sur les entiers naturels"))
    m = n
    chiffres = Int[]
    if m == 0
        push!(chiffres, 0)
    else
        while m > 0
            push!(chiffres, m % base)
            m ÷= base
        end
    end
    return chiffres
end

const _CHARS = collect("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

"""Écriture de `n` en base `base` (chiffres `0-9` puis lettres), poids fort en tête."""
function numerer_chaine(n::Integer; base::Integer = 10)
    chiffres = reverse(numerer_base(n; base = base))
    return join(_CHARS[c + 1] for c in chiffres)
end

# ----------------------------------------------------------------------------
#  Numération égyptienne (hiéroglyphique, décimale additive)
# ----------------------------------------------------------------------------

"""Hiéroglyphes égyptiens des puissances de 10 (table déclarative)."""
const HIEROGLYPHES_EGYPTIENS = Dict{Int,String}(
    1 => "bâton (|)", 10 => "anse (∩)", 100 => "corde enroulée", 1000 => "lotus",
    10_000 => "doigt", 100_000 => "têtard", 1_000_000 => "homme assis (Heh)",
)

"""
    numerer_egyptien(n) -> Vector{Tuple{Int,Int}}

Décomposition égyptienne additive de `n` : liste de couples `(puissance, nombre)`
telle que `n = Σ nombre · puissance`, puissances décroissantes. Le système est
décimal additif — un même signe se répète autant que de fois nécessaires.
"""
function numerer_egyptien(n::Integer)
    n >= 0 || throw(ArgumentError("la numération porte sur les entiers naturels"))
    parts = Tuple{Int,Int}[]
    p = 1
    while p * 10 <= n
        p *= 10
    end
    reste = n
    while p >= 1
        q = reste ÷ p
        q > 0 && push!(parts, (p, q))
        reste -= q * p
        p ÷= 10
    end
    return parts
end

# ----------------------------------------------------------------------------
#  Fractions égyptiennes  (algorithme glouton de Fibonacci–Sylvester)
# ----------------------------------------------------------------------------

"""
    fraction_egyptienne(a, b) -> Vector{Int}

Développe la fraction propre `a/b` (`0 < a < b`) en somme de fractions unitaires
distinctes : le dénominateur de chaque terme est retourné dans l'ordre. C'est
l'algorithme glouton (Sylvester, 1880) : à chaque pas, on retranche la plus
grande fraction unitaire ne dépassant pas le reste.

Le développement **termine toujours** et ses dénominateurs sont strictement
croissants (propriété classique de la méthode gloutonne).
"""
function fraction_egyptienne(a::Integer, b::Integer)
    (a > 0 && b > 0) || throw(ArgumentError("a et b strictement positifs"))
    a < b || throw(ArgumentError("fraction propre attendue : a < b"))
    denoms = Int[]
    p, q = Int(a), Int(b)
    while p > 0
        u = cld(q, p)                      # plus petit dénominateur 1/u ≤ p/q
        push!(denoms, u)
        p, q = p * u - q, q * u            # p/q − 1/u
        g = gcd(p, q)
        g > 0 && (p ÷= g; q ÷= g)
    end
    return denoms
end

"""Somme `Σ 1/d` sur les dénominateurs `d` — sert de contrôle de fidélité."""
somme_unitaire(denoms::AbstractVector{<:Integer}) = sum(1 // d for d in denoms; init = 0 // 1)

# ----------------------------------------------------------------------------
#  Œil d'Horus  (fractions binaires 1/2 … 1/64, reste en « ro » = 1/320)
# ----------------------------------------------------------------------------

const PARTS_OEIL_HORUS = [1 // 2, 1 // 4, 1 // 8, 1 // 16, 1 // 32, 1 // 64]
const VALEUR_RO = 1 // 320

"""
    oeil_horus(a, b) -> NamedTuple

Décompose `a/b` selon l'œil d'Horus (fraction binaire : `1/2, 1/4, …, 1/64`).
Retourne les parts retenues, le nombre de « ro » (`1/320`) du reste, et le reste
résiduel exact (fraction) — rendu **honnêtement** même s'il n'est pas exprimable
par les parts canoniques.
"""
function oeil_horus(a::Integer, b::Integer)
    (a >= 0 && b > 0) || throw(ArgumentError("fraction positive attendue"))
    reste = a // b
    parts = Rational{Int}[]
    for p in PARTS_OEIL_HORUS
        if reste >= p
            push!(parts, p)
            reste -= p
        end
    end
    ro = Int(fld(reste * 320, 1))
    residu = reste - ro * VALEUR_RO
    return (parts = parts, ro = ro, residu = residu, exact = iszero(residu))
end

# ----------------------------------------------------------------------------
#  Numération vigésimale soustractive  (yoruba, igbo)
# ----------------------------------------------------------------------------

"""Mots yoruba des unités 1–10 (table déclarative, indépendante du calcul)."""
const MOTS_YORUBA_UNITES = ["", "ọ̀kan", "èjì", "ẹ̀ta", "ẹ̀rin", "àrún",
                            "ẹ̀fà", "èje", "ẹ̀jọ", "ẹ̀sán", "ẹ̀wá"]

"""
    numerer_vigesimal(n) -> NamedTuple

Décomposition d'un entier selon le squelette **vigésimal soustractif** des
numérations yoruba/igbo. Pour `n = 10q + d` :

- `d ∈ {0,1,2,3,4}` : `n = 10q + d` (addition) ;
- `d ∈ {5,6,7,8,9}` : `n = 10(q+1) − (10 − d)` (soustraction au multiple supérieur),
  ce qui reproduit la construction « 20−5 = 15 », « 30−5 = 25 », « 50−5 = 45 ».

Retourne l'entier, la base du calcul (`base`), le sens (`:plus`, `:moins` ou
`:exact`) et l'écart `|n − base|`.
"""
function numerer_vigesimal(n::Integer)
    n >= 0 || throw(ArgumentError("la numération porte sur les entiers naturels"))
    n == 0 && return (n = 0, base = 0, sens = :exact, ecart = 0, dizaines = 0)
    q, d = divrem(n, 10)
    if d == 0
        return (n = n, base = n, sens = :exact, ecart = 0, dizaines = q)
    elseif d <= 4
        base = 10q
        return (n = n, base = base, sens = :plus, ecart = d, dizaines = q)
    else
        base = 10 * (q + 1)
        return (n = n, base = base, sens = :moins, ecart = 10 - d, dizaines = q + 1)
    end
end

"""
    numerer_yoruba(n) -> NamedTuple

Numération yoruba : reprend le squelette vigésimal `numerer_vigesimal` et ajoute
le mot de l'unité (table déclarative) lorsque `n ≤ 10`.
"""
function numerer_yoruba(n::Integer)
    s = numerer_vigesimal(n)
    mot = 1 <= n <= 10 ? MOTS_YORUBA_UNITES[n + 1] : nothing
    return merge(s, (mot = mot,))
end

# ----------------------------------------------------------------------------
#  Numération guèze / éthiopienne
# ----------------------------------------------------------------------------

"""Symboles guèze : unités 1–9 et dizaines 10–90, puis 100 et 10 000."""
const SYMBOLES_GEEZ = Dict{Int,String}(
    1 => "፩", 2 => "፪", 3 => "፫", 4 => "፬", 5 => "፭", 6 => "፮", 7 => "፯", 8 => "፰", 9 => "፱",
    10 => "፲", 20 => "፳", 30 => "፴", 40 => "፵", 50 => "፶", 60 => "፷", 70 => "፸", 80 => "፹", 90 => "፺",
    100 => "፻", 10_000 => "፼",
)

# Rend en symboles guèze un entier `1 ≤ m ≤ 99` (dizaines puis unités).
function _geez_sous_100(m::Integer)
    t, u = divrem(m, 10)
    s = t > 0 ? SYMBOLES_GEEZ[t * 10] : ""
    s *= u > 0 ? SYMBOLES_GEEZ[u] : ""
    return s
end

"""
    numerer_geez(n) -> Vector{Tuple{Int,String}}

Écriture guèze additive de `n` : liste de couples `(valeur, symbole)`, valeurs
décroissantes. Le système est décimal ; `100` et `10 000` ont des signes propres,
et les milliers s'écrivent comme des dizaines de centaines (1 000 = `10 × 100`,
soit `፲፻`), selon l'usage éthiopien. Le domaine couvert va jusqu'à 10⁶ − 1.
"""
function numerer_geez(n::Integer)
    n >= 0 || throw(ArgumentError("la numération porte sur les entiers naturels"))
    n == 0 && return Tuple{Int,String}[]
    parts = Tuple{Int,String}[]
    reste = n
    if reste >= 10_000
        q = reste ÷ 10_000
        q <= 99 || throw(ArgumentError("numération guèze : domaine limité à 10⁶ − 1"))
        tete = q == 1 ? "" : _geez_sous_100(q)
        push!(parts, (q * 10_000, tete * SYMBOLES_GEEZ[10_000]))
        reste %= 10_000
    end
    if reste >= 100
        q = reste ÷ 100
        tete = q == 1 ? "" : _geez_sous_100(q)
        push!(parts, (q * 100, tete * SYMBOLES_GEEZ[100]))
        reste %= 100
    end
    reste > 0 && push!(parts, (reste, _geez_sous_100(reste)))
    return parts
end

# ----------------------------------------------------------------------------
#  Comptage par cauris
# ----------------------------------------------------------------------------

"""
    numerer_cauris(n) -> NamedTuple

Comptage par cauris : groupements par 20 (chaînes), puis par 5, puis unités.
Retourne les nombres de paquets de 20, de paquets de 5 et d'unités libres.
"""
function numerer_cauris(n::Integer)
    n >= 0 || throw(ArgumentError("la numération porte sur les entiers naturels"))
    paquets20, r = divrem(n, 20)
    paquets5, unites = divrem(r, 5)
    return (n = n, paquets20 = paquets20, paquets5 = paquets5, unites = unites)
end

# ----------------------------------------------------------------------------
#  Enregistrement au registre
# ----------------------------------------------------------------------------

enregistrer_savoir!(Savoir(:numeration;
    nom = "Numérations africaines",
    domaine = :numerations,
    resume = "Hiéroglyphes égyptiens, fractions (Œil d'Horus, glouton), yoruba vigésimal, guèze, cauris.",
    entrees = [:numerer_base, :numerer_egyptien, :fraction_egyptienne, :oeil_horus,
               :numerer_vigesimal, :numerer_yoruba, :numerer_geez, :numerer_cauris]))
