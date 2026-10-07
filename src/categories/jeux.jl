# ============================================================================
#  Théorie des jeux kamitique  (chapitre 27)
# ----------------------------------------------------------------------------
#  « pesée mutuelle, équilibre de Maât ». Chaque joueur repondère sa stratégie au
#  regard des autres jusqu'à ce que plus personne n'ait intérêt à changer : c'est
#  l'équilibre de Maât. La conception vise l'attracteur harmonique, non le gain brut.
# ============================================================================

"""
    ResultatEquilibre

Le résultat d'une pesée mutuelle : le profil de stratégies atteint, l'harmonie de Maât
(la satisfaction la plus faible) et le registre.
"""
struct ResultatEquilibre
    profil   :: Vector{Int}
    harmonie :: Float64
    registre :: Vector{String}
end

"""
    pesee_mutuelle(gains; max_iter = 64) -> ResultatEquilibre

**Résolution par pesée mutuelle** (méthode 27.1). `gains[i, s]` est le gain du joueur
`i` s'il joue la stratégie `s`. Chaque joueur, à tour de rôle, repondère sa stratégie
vers sa meilleure réponse au profil courant ; on itère jusqu'à stabilité. L'**équilibre
de Maât** est le profil stable ; son harmonie est la satisfaction la plus faible (règle
de non-compensation entre joueurs).
"""
function pesee_mutuelle(gains::AbstractMatrix{<:Real}; max_iter::Integer = 64)
    n, s = size(gains)
    n == 0 && throw(ArgumentError("aucun joueur"))
    s == 0 && throw(ArgumentError("aucune stratégie"))
    profil = ones(Int, n)
    registre = String["pesée mutuelle : $n joueur(s), $s stratégie(s)"]
    stable = false
    iterations = 0
    while iterations < max_iter && !stable
        stable = true
        for i in 1:n
            meilleure = argmax(view(gains, i, :))
            if profil[i] != meilleure
                profil[i] = meilleure
                stable = false
            end
        end
        iterations += 1
    end
    mu = minimum(clamp(float(gains[i, profil[i]]), 0.0, 1.0) for i in 1:n)
    push!(registre, stable ? "équilibre de Maât atteint en $iterations itération(s)" :
                             "aucun équilibre stable en $max_iter itération(s)")
    push!(registre, "profil : " * join(profil, ", ") * ", harmonie (min) : $(round(mu; digits = 4))")
    return ResultatEquilibre(profil, mu, registre)
end

"""
    ResultatConception

Le résultat d'une conception par attracteur : le profil visé et le registre.
"""
struct ResultatConception
    profil   :: Vector{Int}
    registre :: Vector{String}
end

"""
    conception_par_attracteur(gains) -> ResultatConception

**Conception par attracteur harmonique** (méthode 27.2). On ne maximise pas le gain
total, on **choisit l'attracteur** : le profil qui rend maximale la satisfaction la plus
faible. Conçu ainsi, le jeu attire les joueurs vers un équilibre équitable.
"""
function conception_par_attracteur(gains::AbstractMatrix{<:Real})
    n, s = size(gains)
    n == 0 && throw(ArgumentError("aucun joueur"))
    s == 0 && throw(ArgumentError("aucune stratégie"))
    meilleur = ones(Int, n)
    meilleure = -Inf
    for combo in Iterators.product((1:s for _ in 1:n)...)
        m = minimum(float(gains[i, combo[i]]) for i in 1:n)
        if m > meilleure
            meilleure = m
            meilleur = collect(combo)
        end
    end
    registre = String["conception par attracteur harmonique",
                      "satisfaction minimale garantie : $(round(meilleure; digits = 4))",
                      "profil visé : " * join(meilleur, ", ")]
    return ResultatConception(meilleur, registre)
end
