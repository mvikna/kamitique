# ============================================================================
#  Bases de données kamitiques  (chapitre 21)
# ----------------------------------------------------------------------------
#  « recherche par relaxation, jointure par composition ». La recherche rend un
#  degré avec sa figure, non un drapeau avec une adresse ; la jointure compose
#  les figures situées selon les liens attestés du porteur.
# ============================================================================

"""
    ResultatRecherche

Le résultat d'une recherche par relaxation : la figure retenue (ou `nothing`), le
degré mesuré, le seuil effectivement atteint, et le registre de la relaxation.
"""
struct ResultatRecherche
    figure   :: Union{Figure,Nothing}
    degre    :: Float64
    seuil    :: Float64
    registre :: Vector{String}
end

trouve(r::ResultatRecherche) = r.figure !== nothing

"""
    recherche_par_relaxation(Ψ, p; seuils = [1.0, 0.75, 0.5, 0.25, 0.0])
        -> ResultatRecherche

**Recherche par relaxation** (chapitre 21). Cherche la figure du support qui
satisfait la proposition `p`, en descendant progressivement l'exigence `seuils`
jusqu'au premier degré `ν(f, p)` qui l'atteint. La recherche ne cache pas sa
relaxation : elle **rend le degré atteint et le seuil** qui l'a emporté.
"""
function recherche_par_relaxation(Ψ::Etat, p::Proposition;
                                  seuils::AbstractVector{<:Real} =
                                      [1.0, 0.75, 0.5, 0.25, 0.0])
    for s in seuils
        for f in Ψ.figures
            d = valuation(Etat([f], [1.0]), p)
            if d >= s
                reg = String["relaxation jusqu'au seuil $s",
                             "degré mesuré ν(f, $(p.nom)) = $d"]
                return ResultatRecherche(f, d, float(s), reg)
            end
        end
    end
    return ResultatRecherche(nothing, 0.0, 0.0,
                             String["aucune figure n'atteint le seuil minimal"])
end

"""
    ResultatJointure

Le résultat d'une jointure : la figure composée, les sites partagés, et le registre.
"""
struct ResultatJointure
    composee :: Figure
    communes :: Vector{Symbol}
    registre :: Vector{String}
end

"""
    jointure_par_composition(G, a, b) -> ResultatJointure

**Jointure par composition** (chapitre 21). Joint deux figures situées en les
composant par `⊙` : la figure jointe porte, en plus de leur réunion, les liens que
le porteur `G` atteste entre elles. Les sites partagés sont consignés.
"""
function jointure_par_composition(G::Porteur, a::Figure, b::Figure)
    communes = intersect(a.sites, b.sites)
    composee = ⊙(G, a, b)
    reg = String["jointure de $(length(a.sites)) et $(length(b.sites)) sites",
                 "sites partagés : " * (isempty(communes) ? "∅" : join(string.(communes), ", ")),
                 "figure jointe : $(length(composee.sites)) sites, $(length(composee.liens)) liens"]
    return ResultatJointure(composee, communes, reg)
end
