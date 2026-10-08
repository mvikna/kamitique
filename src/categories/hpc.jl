# ============================================================================
#  Calcul haute performance kamitique  (chapitre 19)
# ----------------------------------------------------------------------------
#  « grille de pesée, exécution par harmonie ». Répartir le travail selon les
#  harmonies plutôt que les adresses, et ne redistribuer la charge que lorsque le
#  **gain net dépasse le coût de trajet** — la communication pesée avant payée.
# ============================================================================

"""
    ResultatGrille

Le résultat d'une exécution par harmonie : l'affectation de chaque figure du support
à un worker, l'harmonie totale intra-worker et le registre.
"""
struct ResultatGrille
    affectation :: Vector{Int}
    harmonie    :: Float64
    registre    :: Vector{String}
end

Base.length(r::ResultatGrille) = length(r.affectation)

"""
    execution_par_harmonie(Ψ, h; workers = 2) -> ResultatGrille

**Exécution par harmonie** (méthode 19.1). Dispose les figures du support de `Ψ` sur
`workers` travailleurs d'une grille de pesée, en regroupant celles dont la
compatibilité `µ` est haute : le placement minimise les communications par construction.
L'harmonie totale rendue est la somme des compatibilités intra-worker.

La répartition est **équilibrée** : chaque worker reçoit au plus `⌈n / workers⌉`
figures (charge d'un worker). Parmi les workers **non saturés**, chaque figure rejoint
celui où la compatibilité cumulée avec les figures déjà placées est maximale (à égalité,
le plus petit indice) ; un worker saturé est écarté de la pesée. La capacité garantit
que tous les workers sont peuplés dès que `workers ≤ n`.
"""
function execution_par_harmonie(Ψ::Etat, h::Harmonie; workers::Integer = 2)
    workers >= 1 || throw(ArgumentError("la grille porte au moins un worker"))
    n = length(Ψ.figures)
    capacite = cld(n, workers)                   # charge maximale par worker (équilibre)
    charge = zeros(Int, workers)
    affectation = zeros(Int, n)
    registre = String["exécution par harmonie : $n figure(s), $workers worker(s), " *
                      "capacité $capacite par worker"]
    for i in 1:n
        meilleur = 0
        meilleure_coh = -1.0
        for w in 1:workers
            charge[w] >= capacite && continue     # worker saturé : hors de la pesée
            coh = 0.0
            for j in 1:(i - 1)
                affectation[j] == w || continue
                coh += clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
            end
            if coh > meilleure_coh
                meilleure_coh = coh
                meilleur = w
            end
        end
        affectation[i] = meilleur
        charge[meilleur] += 1
        push!(registre, "figure $i → worker $meilleur (cohérence $(round(meilleure_coh; digits = 3)))")
    end
    total = 0.0
    for w in 1:workers
        idx = findall(==(w), affectation)
        for x in 1:length(idx), y in (x + 1):length(idx)
            total += clamp(float(h.compatibilite(Ψ.figures[idx[x]], Ψ.figures[idx[y]])), 0.0, 1.0)
        end
    end
    push!(registre, "harmonie totale intra-worker : $(round(total; digits = 4))")
    return ResultatGrille(affectation, total, registre)
end

"""
    ResultatReponderationCharge

Le résultat d'une repondération sous charge : les voies retenues, le gain net total,
le fait qu'au moins une voie ait été repondérée, et le registre.
"""
struct ResultatReponderationCharge
    retenues :: Vector{Int}
    gain_net :: Float64
    repondere :: Bool
    registre :: Vector{String}
end

"""
    reponderation_sous_charge(gains, couts; tolerance = 0.0) -> ResultatReponderationCharge

**Repondération sous charge** (méthode 19.2). Pour chaque voie de redistribution, on
compare le **gain** attendu au **coût de trajet** ; la voie n'est retenue que si le
gain net dépasse `tolerance`. La communication est ainsi pesée **avant** d'être payée,
et les voies non rentables sont écartées en le consignant.
"""
function reponderation_sous_charge(gains::AbstractVector{<:Real},
                                   couts::AbstractVector{<:Real};
                                   tolerance::Real = 0.0)
    length(gains) == length(couts) ||
        throw(ArgumentError("un gain et un coût par voie"))
    isempty(gains) && throw(ArgumentError("aucune voie à peser"))
    retenues = Int[]
    net = 0.0
    registre = String["repondération sous charge : $(length(gains)) voie(s)"]
    sizehint!(retenues, length(gains))
    sizehint!(registre, length(gains) + 1)     # une entrée par voie, + en-tête
    for k in eachindex(gains)
        g = float(gains[k]) - float(couts[k])          # gain net = gain − coût de trajet
        if g > tolerance
            push!(retenues, k)
            net += g
            push!(registre, "voie $k retenue (gain net $(round(g; digits = 4)))")
        else
            push!(registre, "voie $k écartée (gain net $(round(g; digits = 4)) ≤ $(round(float(tolerance); digits = 4)))")
        end
    end
    return ResultatReponderationCharge(retenues, net, !isempty(retenues), registre)
end
