# ============================================================================
#  Big data kamitique  (chapitre 22)
# ----------------------------------------------------------------------------
#  « partitionnement géométrique, agrégation harmonique ». On ne coupe jamais une
#  figure : les figures qui partagent des sites sont closes sous ⊙ avant d'être
#  réparties. La densité de stockage est géométrique (bᵈ sites), non additive.
# ============================================================================

"""
    ResultatPartition

Le résultat d'un partitionnement géométrique : les partitions (chacune étant la
composition de ses figures) et le registre.
"""
struct ResultatPartition
    partitions :: Vector{Figure}
    registre   :: Vector{String}
end

Base.length(r::ResultatPartition) = length(r.partitions)

"""Indique si deux figures partagent au moins un site, sans rien allouer : le test
d'appartenance est mené sur le plus court des deux vecteurs de sites."""
function _partagent_un_site(a::Figure, b::Figure)
    sa, sb = a.sites, b.sites
    return length(sa) < length(sb) ? any(s -> s in sb, sa) : any(s -> s in sa, sb)
end

"""Composantes connexes d'un ensemble de figures : figures closes sous ⊙. Ne coupe
jamais une figure — deux figures qui partagent un site appartiennent à la même
composante."""
function _composantes_figures(figures::AbstractVector{Figure})
    n = length(figures)
    parent = collect(1:n)
    racine(x) = parent[x] == x ? x : (parent[x] = racine(parent[x]))
    unir!(a, b) = begin
        ra, rb = racine(a), racine(b)
        ra != rb && (parent[rb] = ra)
    end
    for i in 1:n, j in (i + 1):n
        _partagent_un_site(figures[i], figures[j]) && unir!(i, j)
    end
    groupes = Dict{Int,Figure}()
    for i in 1:n
        r = racine(i)
        groupes[r] = haskey(groupes, r) ? (groupes[r] ⊙ figures[i]) : figures[i]
    end
    return Figure[groupes[r] for r in sort!(collect(keys(groupes)))]
end

"""
    partitionnement_geometrique(figures, h; parts = 2) -> ResultatPartition

**Partitionnement géométrique massif** (méthode 22.1). Les figures sont d'abord
**closes sous ⊙** : les figures qui partagent un site ne sont jamais séparées, elles
sont fusionnées en une composante insécable. Chaque composante est ensuite affectée à
la partition dont l'harmonie cumulée est la plus haute. On ne coupe jamais une figure.
"""
function partitionnement_geometrique(figures::AbstractVector{Figure}, h::Harmonie;
                                     parts::Integer = 2)
    isempty(figures) && throw(ArgumentError("aucune figure à partitionner"))
    parts >= 1 || throw(ArgumentError("au moins une partition"))
    comps = _composantes_figures(figures)
    parts_vec = Figure[figure_vide() for _ in 1:parts]
    registre = String["partitionnement géométrique : $(length(figures)) figure(s) → " *
                      "$(length(comps)) composante(s) close(s) sous ⊙, $parts partition(s)"]
    for (k, c) in enumerate(comps)
        meilleur = 1
        meilleure_coh = -1.0
        for p in 1:parts
            coh = isempty(parts_vec[p]) ? 0.0 :
                  clamp(float(h.compatibilite(c, parts_vec[p])), 0.0, 1.0)
            if coh > meilleure_coh
                meilleure_coh = coh
                meilleur = p
            end
        end
        parts_vec[meilleur] = parts_vec[meilleur] ⊙ c
        push!(registre, "composante $k ($(length(c.sites)) site(s)) → partition $meilleur")
    end
    return ResultatPartition(parts_vec, registre)
end

"""
    ResultatAgregation

Le résultat d'une agrégation harmonique : la figure agrégée, l'harmonie d'agrégat et
le registre.
"""
struct ResultatAgregation
    agregee  :: Figure
    harmonie :: Float64
    registre :: Vector{String}
end

"""
    agregation_harmonique(partitions, h) -> ResultatAgregation

**Agrégation harmonique distribuée** (méthode 22.2). Compose les partitions par `⊙`
pour en rendre la figure agrégée, et mesure l'**harmonie d'agrégat** — la compatibilité
moyenne des paires de partitions. L'agrégat ne perd aucun site : il recompose.
"""
function agregation_harmonique(partitions::AbstractVector{Figure}, h::Harmonie)
    isempty(partitions) && throw(ArgumentError("aucune partition à agréger"))
    agregee = partitions[1]
    for k in 2:length(partitions)
        agregee = agregee ⊙ partitions[k]
    end
    s = 0.0
    paires = 0
    for i in 1:length(partitions), j in (i + 1):length(partitions)
        s += clamp(float(h.compatibilite(partitions[i], partitions[j])), 0.0, 1.0)
        paires += 1
    end
    mu = paires == 0 ? 1.0 : s / paires
    registre = String["agrégation harmonique de $(length(partitions)) partition(s)",
                      "figure agrégée : $(length(agregee.sites)) site(s)",
                      "harmonie d'agrégat : $(round(mu; digits = 4))"]
    return ResultatAgregation(agregee, mu, registre)
end
