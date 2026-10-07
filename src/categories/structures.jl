# ============================================================================
#  Structures de données kamitiques  (chapitre 17)
# ----------------------------------------------------------------------------
#  « quatre structures natives, parcours réglé, tri par pesée harmonique ».
#  Le tri rend un ordre de degrés, non un drapeau ; le parcours est réglé et
#  consigné.
# ============================================================================

"""
    ResultatTri

Le résultat d'un tri par pesée : les figures rangées par degré décroissant, leurs
degrés, et le registre du tri.
"""
struct ResultatTri
    figures  :: Vector{Figure}
    degres   :: Vector{Float64}
    registre :: Vector{String}
end

Base.length(r::ResultatTri) = length(r.figures)

"""
    tri_par_pesee(Ψ, q, h; λ = 0.5) -> ResultatTri

**Tri par pesée harmonique** (chapitre 17). Range les figures du support de `Ψ` par
score de pesée décroissant sur la question `q` : le tri rend un **ordre de degrés**,
et son registre, plutôt qu'un drapeau et une adresse.

    score = (1 − λ) · ν_moyen + λ · cohérence.
"""
function tri_par_pesee(Ψ::Etat, q::Question, h::Harmonie; λ::Real = 0.5)
    sc = scores_pesee(Ψ, q, h; λ = λ)
    ordre = sortperm(sc.scores; rev = true)
    figures = Ψ.figures[ordre]
    degres = sc.scores[ordre]
    registre = String["tri par pesée harmonique sur la question $(q.nom)",
                       "λ = $λ",
                       "degrés : " * join(round.(degres; digits = 3), ", ")]
    return ResultatTri(figures, degres, registre)
end

"""
    ResultatParcours

Le résultat d'un parcours réglé : la figure parcourue (le chemin) et le journal des
pas.
"""
struct ResultatParcours
    chemin  :: Figure
    journal :: Vector{String}
end

"""
    parcours_regle(G, depart; regle = _ -> true, max_pas = typemax(Int)) -> ResultatParcours

**Parcours réglé** (chapitre 17). Parcourt le porteur `G` depuis le site `depart`
en ne franchissant un voisin que si `regle(site)` est vérifiée, et consigne chaque
pas. Le parcours s'arrête sur un cul-de-sac ou une répétition.
"""
function parcours_regle(G::Porteur, depart::Symbol;
                        regle::Function = _ -> true, max_pas::Integer = typemax(Int))
    haskey(G, depart) || throw(KeyError("site de départ non attesté : $depart"))
    visite = Symbol[]
    journal = String[]
    courant = depart
    while courant !== nothing && !(courant in visite) && length(visite) < max_pas
        push!(visite, courant)
        push!(journal, "visite $courant (lieu=$(site(G, courant).lieu))")
        suivant = nothing
        for v in voisins(G, courant)
            haskey(G, v) || continue
            v in visite && continue
            if regle(site(G, v))
                suivant = v
                break
            end
        end
        courant = suivant
    end
    return ResultatParcours(Figure(visite), journal)
end
