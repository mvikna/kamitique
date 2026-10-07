# ============================================================================
#  L'ordre de pesée M  (définition 5.5)
# ----------------------------------------------------------------------------
#  M est un ordre dense, à bornes 0 et 1, dans lequel se mesurent les degrés
#  de présence et les valuations. Le deux-valeurs {0, 1} en est le cas dégénéré.
# ============================================================================

"""
    OrdrePesee(pas = 0.0)

L'ordre de pesée `M` défini par la Kamitique : un ordre dense à bornes `0` et `1`.

- `pas == 0.0` : ordre continu (dense au sens strict).
- `pas > 0.0` : discrétisation de granularité `pas` (cas d'usage numérique).

Le sous-ordre `{0, 1}` est obtenu par [`deux_valeurs`](@ref) : c'est le cas dégénéré
de la pesée, celui où l'on ne retient que l'absence totale et la présence totale.
"""
struct OrdrePesee
    pas :: Float64

    function OrdrePesee(pas::Real = 0.0)
        pas < 0 && throw(ArgumentError("le pas de l'ordre de pesée doit être positif ou nul"))
        new(float(pas))
    end
end

"""Instance canonique : l'ordre dense continu `M`."""
const M = OrdrePesee(0.0)

"""Le sous-ordre dégénéré `{0, 1}` (bornes de `M`)."""
const DEUX_VALEURS = OrdrePesee(1.0)

bornes(::OrdrePesee) = (0.0, 1.0)
est_dense(o::OrdrePesee) = o.pas == 0.0

"""
    appartient(o::OrdrePesee, x)

Indique si `x` appartient à l'ordre `o` (donc à `[0, 1]`).
"""
appartient(o::OrdrePesee, x::Real) = 0.0 <= x <= 1.0

"""
    valider_degre(x; nom = "degré")

Contrôle qu'une valeur appartient bien à l'ordre `M` et la retourne comme `Float64`.
"""
function valider_degre(x::Real; nom::AbstractString = "degré")
    if !(0.0 <= x <= 1.0)
        throw(ArgumentError("$nom hors de l'ordre M : $x ∉ [0, 1]"))
    end
    return clamp(float(x), 0.0, 1.0)
end

"""
    couper(x, ordre::OrdrePesee)

Applique la coupure `M → {0, 1}` en usage dégénéré (définition 5.5) :
un degré est projeté sur la borne la plus proche.

Cette opération est une **décision**, non une lecture (axiome A-K3) : elle doit
être consignée par l'appelant lorsqu'elle engage un résultat.
"""
function couper(x::Real, o::OrdrePesee = DEUX_VALEURS)
    valider_degre(x)
    o.pas == 0.0 && return float(x)          # ordre continu : pas de coupure
    return x < 0.5 ? 0.0 : 1.0
end
