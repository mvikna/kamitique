# ============================================================================
#  Calcul scientifique kamitique  (chapitre 18)
# ----------------------------------------------------------------------------
#  « éventail de discrétisation, résolution par descente de raffinement ». On
#  raffine **là où le désaccord pèse**, et l'on harmonise jusqu'à convergence
#  sous gouverne : multigrille et descente ne sont qu'une seule pesée gouvernée.
# ============================================================================

"""
    ResultatDescenteScientifique

Le résultat d'une descente de raffinement : le nombre de subdivisions par cellule,
le résidu maximal atteint, le nombre d'itérations et le registre.
"""
struct ResultatDescenteScientifique
    subdivisions :: Vector{Int}
    residu       :: Float64
    iterations   :: Int
    registre     :: Vector{String}
end

"""
    resolution_par_descente(residus; seuil = 1e-6, max_iter = 64)
        -> ResultatDescenteScientifique

**Résolution par descente de raffinement** (méthode 18.1). À partir de l'éventail des
résidus par cellule, raffine itérativement **la cellule dont le résidu est le plus
élevé** — on raffine là où le désaccord pèse, non uniformément. La descente s'arrête
lorsque le résidu maximal passe sous `seuil` ou après `max_iter` itérations.
"""
function resolution_par_descente(residus::AbstractVector{<:Real};
                                 seuil::Real = 1e-6, max_iter::Integer = 64)
    isempty(residus) && throw(ArgumentError("l'éventail porte au moins une cellule"))
    r = Float64[abs(float(x)) for x in residus]
    subdivisions = ones(Int, length(r))
    iterations = 0
    registre = String["éventail de discrétisation : $(length(r)) cellule(s)"]
    while maximum(r) > seuil && iterations < max_iter
        i = argmax(r)
        r[i] = r[i] / 2                 # raffiner la cellule la plus en désaccord
        subdivisions[i] += 1
        iterations += 1
    end
    push!(registre, "descente de raffinement : $iterations itération(s)")
    push!(registre, "résidu maximal : $(round(maximum(r); sigdigits = 4))")
    return ResultatDescenteScientifique(subdivisions, maximum(r), iterations, registre)
end

"""
    ResultatHarmonisation

Le résultat d'une convergence par harmonisation : l'harmonie avant et après, la
convergence constatée et le registre.
"""
struct ResultatHarmonisation
    harmonie_avant :: Float64
    harmonie_apres :: Float64
    converge       :: Bool
    registre       :: Vector{String}
end

"""
    convergence_par_harmonisation(Ψ, h; tolerance = 1e-3, max_iter = 64)
        -> ResultatHarmonisation

**Convergence par harmonisation gouvernée** (méthode 18.2). Repondère itérativement la
présence vers les figures les plus cohérentes (montée de gradient sur `µ`), jusqu'à ce
que l'harmonie ne progresse plus de plus de `tolerance`. La gouverne est respectée :
`µ` ne décroît pas.
"""
function convergence_par_harmonisation(Ψ::Etat, h::Harmonie;
                                       tolerance::Real = 1e-3, max_iter::Integer = 64)
    courant = Ψ
    h0 = float(h(courant))
    iterations = 0
    converge = false
    registre = String["harmonisation gouvernée"]
    while iterations < max_iter
        n = length(courant.figures)
        coh = zeros(n)
        for i in 1:n
            c = 0.0
            for j in 1:n
                courant.poids[j] == 0 && continue
                c += courant.poids[j] *
                     clamp(float(h.compatibilite(courant.figures[i], courant.figures[j])),
                           0.0, 1.0)
            end
            coh[i] = c
        end
        hprev = float(h(courant))
        courant = redistribuer(courant, 1.0 .+ 0.5 .* coh)
        hnew = float(h(courant))
        iterations += 1
        if abs(hnew - hprev) < tolerance
            converge = true
            break
        end
    end
    h1 = float(h(courant))
    push!(registre, "itérations : $iterations, µ : $(round(h0; digits = 4)) → $(round(h1; digits = 4))")
    push!(registre, converge ? "convergence atteinte" : "limite d'itérations atteinte")
    return ResultatHarmonisation(h0, h1, converge, registre)
end
