# ============================================================================
#  Architectures des ordinateurs kamitiques  (chapitre 14)
# ----------------------------------------------------------------------------
#  « réseau d'ateliers pesés, placement par pesée harmonique ». La localité du
#  cache est une pesée : rapprocher ce qui s'harmonise. Le flot suit la
#  composition des sites et paie sa communication avant de l'engager.
# ============================================================================

"""
    ResultatPlacement

Le résultat d'un placement par pesée : l'atelier affecté à chaque figure du
support, l'harmonie locale moyenne et le registre du placement.
"""
struct ResultatPlacement
    affectation     :: Vector{Int}
    harmonie_locale :: Float64
    registre        :: Vector{String}
end

Base.length(r::ResultatPlacement) = length(r.affectation)

"""
    placement_par_pesee(Ψ, h; ateliers = 2) -> ResultatPlacement

**Placement par pesée harmonique** (méthode 14.1). Répartit les figures du support
de `Ψ` entre `ateliers` unités de calcul en rapprochant celles dont la compatibilité
`µ` est la plus haute : la localité est une **cache pesée**, non un indice d'adresse.
Chaque figure est affectée à l'atelier où la compatibilité cumulée avec les figures
déjà placées est maximale. L'harmonie locale moyenne mesure la cohérence intra-atelier.
"""
function placement_par_pesee(Ψ::Etat, h::Harmonie; ateliers::Integer = 2)
    ateliers >= 1 || throw(ArgumentError("le réseau porte au moins un atelier"))
    n = length(Ψ.figures)
    affectation = zeros(Int, n)
    registre = String["placement par pesée harmonique : $n figure(s), $ateliers atelier(s)"]
    for i in 1:n
        if i == 1
            affectation[i] = 1
            push!(registre, "figure 1 → atelier 1 (ouverture)")
            continue
        end
        meilleur_atelier = 1
        meilleure_coh = -1.0
        for a in 1:ateliers
            coh = 0.0
            for j in 1:(i - 1)
                affectation[j] == a || continue
                coh += clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
            end
            if coh > meilleure_coh
                meilleure_coh = coh
                meilleur_atelier = a
            end
        end
        affectation[i] = meilleur_atelier
        push!(registre, "figure $i → atelier $meilleur_atelier " *
                        "(cohérence $(round(meilleure_coh; digits = 3)))")
    end
    # harmonie locale moyenne : compatibilité moyenne des paires d'un même atelier
    s = 0.0
    paires = 0
    for a in 1:ateliers
        idx = findall(==(a), affectation)
        for x in 1:length(idx), y in (x + 1):length(idx)
            s += clamp(float(h.compatibilite(Ψ.figures[idx[x]], Ψ.figures[idx[y]])), 0.0, 1.0)
            paires += 1
        end
    end
    hl = paires == 0 ? 1.0 : s / paires
    return ResultatPlacement(affectation, hl, registre)
end

"""
    ResultatFlot

Le résultat d'un flot par composition : le chemin retenu, son débit (le maillon le
plus faible) et le registre.
"""
struct ResultatFlot
    chemin   :: Vector{Symbol}
    debit    :: Float64
    registre :: Vector{String}
end

trouve(r::ResultatFlot) = !isempty(r.chemin)

"""
    flot_par_composition(G, source, puits, h; max_profondeur = 32) -> ResultatFlot

**Flot par composition consignée** (méthode 14.2). Achemine la présence de `source`
vers `puits` par un chemin de sites composés. Le débit d'un chemin est fixé par son
**maillon le plus faible** — la plus basse compatibilité `µ` de ses pas : la
communication se paie avant de s'engager, non après. On retient le chemin de débit
maximal.
"""
function flot_par_composition(G::Porteur, source::Symbol, puits::Symbol, h::Harmonie;
                              max_profondeur::Integer = 32)
    haskey(G, source) || throw(KeyError("site source non attesté : $source"))
    haskey(G, puits)  || throw(KeyError("site puits non attesté : $puits"))
    meilleur = Symbol[]
    meilleur_debit = -1.0
    explorer(chemin::Vector{Symbol}, debit::Float64) = begin
        courant = chemin[end]
        if courant == puits
            if debit > meilleur_debit
                meilleur_debit = debit
                meilleur = copy(chemin)
            end
            return
        end
        length(chemin) >= max_profondeur && return
        for v in voisins(G, courant)
            haskey(G, v) || continue
            v in chemin && continue
            c = clamp(float(h.compatibilite(Figure([courant]), Figure([v]))), 0.0, 1.0)
            explorer(vcat(chemin, v), min(debit, c))
        end
    end
    explorer(Symbol[source], 1.0)
    reg = isempty(meilleur) ?
        String["aucun chemin de $source à $puits"] :
        String["chemin : " * join(string.(meilleur), " → "),
               "débit (maillon le plus faible) : $(round(meilleur_debit; digits = 4))"]
    return ResultatFlot(meilleur, meilleur_debit, reg)
end
