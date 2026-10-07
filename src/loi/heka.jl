# ============================================================================
#  L'Énergie du Noun — Heka (CQG chap. 3)
# ----------------------------------------------------------------------------
#  « Toute manifestation est un flux d'énergie du substrat, et toute entité
#  manifestée est un régime de ce flux. Le nom traditionnel de ce flux est Heka »
#  (CQG §3.1). Heka est le **générateur** d'énergie du Noun — non une figure à
#  interpréter, mais l'opérateur lui-même :
#
#    • le générateur  (éq. 7)  :  Ĥ_Noun Ψ = iℏ ∂Ψ/∂s ;
#    • l'énergie      (éq. 8)  :  E[Ψ] = ⟨Ψ|Ĥ_Noun|Ψ⟩ ;
#    • la décomposition (éq. 9):  E = E_éther + E_jauge + E_morph ;
#    • la conservation (éq. 10):  dE/ds = 0 ⟹ ∇_μ J^μ = 0.
#
#  L'énergie est une ; ses circulations sont trois. La conservation découle de
#  l'axiomatique sans hypothèse supplémentaire : l'action invariante par
#  translation du paramètre d'évolution `s` fournit, par le théorème de Noether,
#  l'identité de conservation (10). La création est une mise en circulation, non
#  une dépense.
#
#  Source : CQG §3.1–3.2 (éq. 7, 8, 9, 10).
# ============================================================================

"""
    Heka(etat, hamiltonien)

Le générateur d'énergie du Noun (CQG éq. 7–8). `etat` est l'état `Ψ` du substrat
dans `ℋ_Noun` ; `hamiltonien` est l'opérateur auto-adjoint `Ĥ_Noun` tel que
`Ĥ_Noun Ψ = iℏ ∂Ψ/∂s`. L'énergie est la valeur attendue `⟨Ψ|Ĥ_Noun|Ψ⟩`.
"""
struct Heka
    etat        :: Vector{ComplexF64}
    hamiltonien :: Matrix{ComplexF64}

    function Heka(etat::AbstractVector{<:Number}, hamiltonien::AbstractMatrix{<:Number})
        n = length(etat)
        size(hamiltonien) == (n, n) ||
            throw(ArgumentError("Ĥ_Noun agit sur ℋ_Noun : matrice n×n attendue"))
        return new(ComplexF64.(etat), ComplexF64.(hamiltonien))
    end
end

"""
    energie_noun(h) -> Float64

L'énergie du Noun — la valeur attendue du générateur de Kheper dans l'état
actualisé (CQG éq. 8) : `E[Ψ] = ⟨Ψ|Ĥ_Noun|Ψ⟩`.
"""
energie_noun(h::Heka) = real(dot(h.etat, h.hamiltonien * h.etat))

"""
    SECTEURS_ENERGIE

Les trois secteurs conjoints de l'énergie (CQG éq. 9) : l'élasticité de l'éther,
l'antagonisme de jauge, la commande morphique.
"""
const SECTEURS_ENERGIE = (:ether, :jauge, :morph)

"""
    decomposition_energie(E_ether, E_jauge, E_morph) -> NamedTuple

La décomposition de l'énergie en ses trois secteurs conjoints (CQG éq. 9) :
`E = E_éther + E_jauge + E_morph`. Rend les trois composantes et leur somme
`total`.
"""
function decomposition_energie(E_ether::Real, E_jauge::Real, E_morph::Real)
    return (ether = float(E_ether), jauge = float(E_jauge), morph = float(E_morph),
            total = float(E_ether + E_jauge + E_morph))
end

"""
    verifie_conservation_energie(h, s_grid; tol = 1e-8) -> Bool

Vérifie la conservation de l'énergie (CQG éq. 10). L'évolution gouvernée par le
générateur `Ĥ_Noun Ψ = iℏ ∂Ψ/∂s` laisse `E[Ψ]` invariante ; elle est intégrée ici
par un pas de Crank–Nicolson, unitaire pour un `Ĥ_Noun` auto-adjoint. `dE/ds = 0`
est contrôlé le long de la grille d'instants `s_grid`.
"""
function verifie_conservation_energie(h::Heka, s_grid::AbstractVector{<:Real};
                                      tol::Real = 1e-8)
    length(s_grid) >= 2 || throw(ArgumentError("au moins deux instants requis"))
    H = h.hamiltonien
    n = size(H, 1)
    identite = Matrix{ComplexF64}(I, n, n)
    Ψ = copy(h.etat)
    E0 = real(dot(Ψ, H * Ψ))
    for i in 2:length(s_grid)
        ds = float(s_grid[i] - s_grid[i-1])
        Ψ = (identite + im * ds / 2 * H) \ ((identite - im * ds / 2 * H) * Ψ)
        E = real(dot(Ψ, H * Ψ))
        abs(E - E0) <= tol * max(1.0, abs(E0)) || return false
    end
    return true
end

"""
    HEKA

La doctrine énergétique du Noun (CQG §3.1), consignée dans sa forme exacte.
"""
const HEKA =
    "E[Ψ] = ⟨Ψ|Ĥ_Noun|Ψ⟩ ;  E = E_éther + E_jauge + E_morph ;  dE/ds = 0 ⟹ ∇_μ J^μ = 0"
