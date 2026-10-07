# ============================================================================
#  La Spirale d'or — Axiome 3 de la CQG (Invariance fractale)
# ----------------------------------------------------------------------------
#  A3 : « la métrique globale g_μν et les échelles de jauge obéissent à une
#  auto-similarité conforme gouvernée par le nombre d'or φ = (1+√5)/2, éliminant
#  les divergences ultraviolettes par une coupure topologique naturelle définie
#  par r(θ) = r₀ e^{bθ} » (CQG §1.4, éq. 2).
#
#  Trois données y sont consignées :
#    • le nombre d'or φ et sa propriété définissante φ² = φ + 1 (soit φ − 1 = 1/φ ;
#      la formule (2) de la CQG l'imprime sous la forme fautive φ/(φ−1) = φ) ;
#    • le pas angulaire b = ln φ / (π/2) : un quart de tour multiplie le rayon par
#      φ — la spirale d'or est l'unique courbe logarithmique possédant cette
#      propriété ;
#    • la coupure conforme R₀ ≠ 0 : au-delà d'un certain régime de contraction,
#      l'échelle se replie sur elle-même ; l'infini n'est jamais atteint.
#
#  Source : CQG §1.4 (éq. 2), §3.2 (rₙ = R₀ φⁿ), §4.4 (Ĝ_Kh : e^{2bθ} g_μν).
# ============================================================================

"""
    NOMBRE_OR

Le nombre d'or `φ = (1 + √5)/2` (CQG §1.4, éq. 2). C'est l'unique racine positive
de `φ² = φ + 1` (équivalente à `φ − 1 = 1/φ`). La formule (2) de la CQG l'imprime
sous la forme fautive `φ/(φ−1) = φ`, qui vaut en réalité `φ²`.
"""
const NOMBRE_OR = (1 + sqrt(5)) / 2

"""
    B_SPIRALE

Le pas angulaire de la spirale d'or : `b = ln φ / (π/2)` (CQG éq. 2). Un quart de
tour (`θ → θ + π/2`) multiplie alors le rayon par `e^{b·π/2} = φ`, faisant de la
spirale d'or la courbe de l'auto-similarité conforme.
"""
const B_SPIRALE = log(NOMBRE_OR) / (π / 2)

"""
    COUPURE_R0

L'échelle conforme fondamentale `R₀ ≠ 0` (CQG §1.4) : la coupure topologique
naturelle qui remplace le continuum indéfiniment divisible par une hiérarchie
fractale ordonnée. **Convention consignée** : exprimée en unités fondamentales,
elle vaut `1.0` ; toute la physique réside dans les *rapports* `rₙ = R₀ φⁿ`
(CQG §3.2), et non dans la valeur absolue de l'unité.
"""
const COUPURE_R0 = 1.0

"""
    coupure_r0(r0 = COUPURE_R0) -> Float64

L'échelle conforme fondamentale de la coupure. La CQG impose `R₀ ≠ 0` : le
continuum ne se replie jamais sur un point.
"""
function coupure_r0(r0::Real = COUPURE_R0)
    r0 == 0 && throw(ArgumentError("la coupure conforme R₀ est non nulle (A3)"))
    return float(r0)
end

"""
    spirale_rayon(θ; r0 = COUPURE_R0) -> Float64

Le rayon de la spirale d'or au paramètre angulaire `θ` : `r(θ) = r₀ e^{bθ}`
(CQG, éq. 2).
"""
spirale_rayon(θ::Real; r0::Real = COUPURE_R0) = coupure_r0(r0) * exp(B_SPIRALE * θ)

"""
    facteur_quart_tour() -> Float64

Le facteur d'auto-similarité par quart de tour : **exactement** le nombre d'or `φ`.
C'est la propriété qui caractérise la spirale d'or parmi toutes les courbes
logarithmiques (CQG §1.4).
"""
facteur_quart_tour() = NOMBRE_OR

"""
    echelle_conforme(n; r0 = COUPURE_R0) -> Float64

La `n`-ième échelle de la stratification conforme : `rₙ = R₀ φⁿ` (CQG §3.2). La
descente conforme distribue les quanta d'énergie en suivant cette même loi
d'échelle, par quarts de tour.
"""
echelle_conforme(n::Integer; r0::Real = COUPURE_R0) = coupure_r0(r0) * NOMBRE_OR^n

"""
    facteur_conforme(θ) -> Float64

Le facteur conforme de la métrique sous le modelage de Khnoum : `e^{2bθ}`
(CQG §4.4, éq. 16). Un quart de tour multiplie les longueurs par `φ` et la
métrique par `φ²`.
"""
facteur_conforme(θ::Real) = exp(2 * B_SPIRALE * θ)

"""
    verifie_nombre_or(; tol = 1e-12) -> Bool

Vérifie la propriété définissante du nombre d'or : `φ² = φ + 1`, équivalente à
`φ − 1 = 1/φ`. C'est cette identité qui fait de `φ` la constante d'auto-similarité
de la spirale d'or (CQG éq. 2).
"""
function verifie_nombre_or(; tol::Real = 1e-12)
    φ = NOMBRE_OR
    return abs(φ^2 - φ - 1) <= tol && abs((φ - 1) - 1 / φ) <= tol
end

"""
    verifie_autosimilarite(; θ = 0.0, r0 = COUPURE_R0, tol = 1e-12) -> Bool

Vérifie l'auto-similarité conforme de l'Axiome 3 : un quart de tour multiplie le
rayon par `φ` et la métrique par `φ²`, soit `r(θ+π/2) = φ·r(θ)` et
`facteur_conforme(θ+π/2) = φ²·facteur_conforme(θ)`.
"""
function verifie_autosimilarite(; θ::Real = 0.0, r0::Real = COUPURE_R0, tol::Real = 1e-12)
    écart_rayon = abs(spirale_rayon(θ + π / 2; r0 = r0) - NOMBRE_OR * spirale_rayon(θ; r0 = r0))
    f_plus = facteur_conforme(θ + π / 2)
    écart_conforme = abs(f_plus - NOMBRE_OR^2 * facteur_conforme(θ)) / abs(f_plus)
    return écart_rayon <= tol * max(1.0, abs(coupure_r0(r0))) && écart_conforme <= tol
end
