# ============================================================================
#  Réseaux kamitiques  (chapitre 23)
# ----------------------------------------------------------------------------
#  « routage par harmonie, résilience par pesée locale ». Le routage ne compte pas
#  les sauts : il retient le chemin dont l'harmonie cumulée est la plus haute.
# ============================================================================

"""
    ResultatRoutage

Le résultat d'un routage : le chemin retenu, son harmonie cumulée, et le registre.
"""
struct ResultatRoutage
    chemin   :: Vector{Symbol}
    harmonie :: Float64
    registre :: Vector{String}
end

trouve(r::ResultatRoutage) = !isempty(r.chemin)

"""
    routage_par_harmonie(G, depart, arrivee, h; max_profondeur = 32) -> ResultatRoutage

**Routage par harmonie** (chapitre 23). Retient, parmi les chemins simples du
porteur `G` allant de `depart` à `arrivee`, celui dont l'**harmonie cumulée** — le
produit des compatibilités `µ` des pas successifs — est maximale. Le routage
conserve une harmonie, non un compteur de sauts.
"""
function routage_par_harmonie(G::Porteur, depart::Symbol, arrivee::Symbol, h::Harmonie;
                              max_profondeur::Integer = 32)
    haskey(G, depart)  || throw(KeyError("site de départ non attesté : $depart"))
    haskey(G, arrivee) || throw(KeyError("site d'arrivée non attesté : $arrivee"))
    meilleur = Symbol[]
    meilleure_h = -1.0
    explorer(chemin::Vector{Symbol}, hcum::Float64) = begin
        courant = chemin[end]
        if courant == arrivee
            if hcum > meilleure_h
                meilleure_h = hcum
                meilleur = copy(chemin)
            end
            return
        end
        length(chemin) >= max_profondeur && return
        for v in voisins(G, courant)
            haskey(G, v) || continue
            v in chemin && continue
            c = clamp(float(h.compatibilite(Figure([courant]), Figure([v]))), 0.0, 1.0)
            explorer(vcat(chemin, v), hcum * c)
        end
    end
    explorer(Symbol[depart], 1.0)
    reg = isempty(meilleur) ?
        String["aucun chemin de $depart à $arrivee"] :
        String["chemin retenu : " * join(string.(meilleur), " → "),
               "harmonie cumulée : $(round(meilleure_h; digits = 4))"]
    return ResultatRoutage(meilleur, meilleure_h, reg)
end
