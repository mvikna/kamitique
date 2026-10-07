# ============================================================================
#  Systèmes d'exploitation kamitiques  (chapitre 15)
# ----------------------------------------------------------------------------
#  « règne pesé, ordonnancement par pesée de besoin ». Le tourniquet est une pesée
#  équirépartie : ce qui a été écarté est repondéré par son ancienneté. La mémoire
#  est allouée selon la situation — la proximité dans le porteur.
# ============================================================================

"""
    ResultatOrdonnancement

Le résultat d'un ordonnancement par pesée de besoin : l'ordre de service, les degrés
de besoin effectifs et le registre.
"""
struct ResultatOrdonnancement
    ordre    :: Vector{Int}
    degres   :: Vector{Float64}
    registre :: Vector{String}
end

Base.length(r::ResultatOrdonnancement) = length(r.ordre)

"""
    ordonnancement_par_pesee(besoins, anciennete; seuil = 0.5) -> ResultatOrdonnancement

**Ordonnancement par pesée de besoin** (méthode 15.1). Chaque tâche porte un besoin ;
les tâches dont le besoin normalisé tombe sous `seuil` — les **écartées** — sont
**repondérées** par leur ancienneté (le tourniquet est une pesée équirépartie), afin
qu'aucune ne soit affamée. L'ordre de service est celui des degrés décroissants.
"""
function ordonnancement_par_pesee(besoins::AbstractVector{<:Real},
                                  anciennete::AbstractVector{<:Real};
                                  seuil::Real = 0.5)
    length(besoins) == length(anciennete) ||
        throw(ArgumentError("un besoin et une ancienneté par tâche"))
    isempty(besoins) && throw(ArgumentError("aucune tâche à ordonnancer"))
    sb = sum(float.(besoins))
    sb > 0 || throw(ArgumentError("la somme des besoins doit être positive"))
    sa = sum(float.(anciennete))
    n = length(besoins)
    degres = zeros(n)
    ecartees = Int[]
    for k in 1:n
        d = float(besoins[k]) / sb
        if d < seuil
            push!(ecartees, k)
            if sa > 0
                d += float(anciennete[k]) / sa      # repondération de l'écartée
            end
        end
        degres[k] = d
    end
    dmax = maximum(degres)
    dmax > 0 && (degres = degres ./ dmax)           # ramener dans l'ordre M
    ordre = sortperm(degres; rev = true)
    registre = String["ordonnancement par pesée de besoin (seuil $seuil)",
                      "tâches : $n, écartées repondérées par ancienneté : " *
                      (isempty(ecartees) ? "∅" : join(ecartees, ", ")),
                      "ordre : " * join(ordre, " → ")]
    return ResultatOrdonnancement(ordre, degres, registre)
end

"""
    ResultatAllocation

Le résultat d'une allocation de mémoire située : la mémoire affectée à chaque demande,
les distances mesurées et le registre.
"""
struct ResultatAllocation
    affectation :: Vector{Symbol}
    distances   :: Vector{Int}
    registre    :: Vector{String}
end

"""Distances de voisinage depuis un site source (parcours en largeur)."""
function _distances_site(G::Porteur, source::Symbol)
    haskey(G, source) || throw(KeyError("site non attesté : $source"))
    dist = Dict{Symbol,Int}(source => 0)
    file = Symbol[source]
    while !isempty(file)
        u = popfirst!(file)
        for v in voisins(G, u)
            haskey(G, v) || continue
            if !haskey(dist, v)
                dist[v] = dist[u] + 1
                push!(file, v)
            end
        end
    end
    return dist
end

"""
    allocation_memoire_situee(G, demandes, memoires) -> ResultatAllocation

**Allocation de mémoire située** (méthode 15.2). Chaque demande est affectée à la
mémoire la plus **proche** dans le porteur `G` — la proximité remplace l'adresse. La
distance est mesurée par le voisinage attesté ; les mémoires inaccessibles sont
écartées en le signalant.
"""
function allocation_memoire_situee(G::Porteur, demandes::AbstractVector{Symbol},
                                   memoires::AbstractVector{Symbol})
    isempty(demandes) && throw(ArgumentError("aucune demande de mémoire"))
    isempty(memoires) && throw(ArgumentError("aucune mémoire attestée"))
    for m in memoires
        haskey(G, m) || throw(KeyError("mémoire non attestée : $m"))
    end
    affectation = Symbol[]
    distances = Int[]
    registre = String["allocation de mémoire située : $(length(demandes)) demande(s)"]
    for d in demandes
        dist = _distances_site(G, d)
        meilleure = Symbol()
        meilleure_dist = typemax(Int)
        for m in memoires
            dm = get(dist, m, typemax(Int))
            if dm < meilleure_dist
                meilleure_dist = dm
                meilleure = m
            end
        end
        if meilleure_dist == typemax(Int)
            push!(registre, "demande $d : aucune mémoire accessible, écartée")
            continue
        end
        push!(affectation, meilleure)
        push!(distances, meilleure_dist)
        push!(registre, "demande $d → mémoire $meilleure (distance $meilleure_dist)")
    end
    return ResultatAllocation(affectation, distances, registre)
end
