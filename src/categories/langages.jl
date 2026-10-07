# ============================================================================
#  Langages de programmation kamitiques  (chapitre 16)
# ----------------------------------------------------------------------------
#  « formes composées, types en degrés, évaluation consignée ». Un programme est
#  une figure ; sa réécriture est une composition. La compilation compose des
#  formes pesées et **retarde** la coupure M → {0,1} jusqu'au dernier moment.
# ============================================================================

"""
    TypeDegres

Un **type en degrés** (chapitre 16) : un nom et un vecteur de degrés dans l'ordre de
pesée `M`. Un type n'est pas une étiquette binaire : c'est une position graduée.
"""
struct TypeDegres
    nom    :: Symbol
    degres :: Vector{Float64}

    function TypeDegres(nom::Symbol, degres::AbstractVector{<:Real})
        ds = Float64[valider_degre(d; nom = "degré de type") for d in degres]
        new(nom, ds)
    end
end

Base.length(t::TypeDegres) = length(t.degres)

"""
    compatibilite_types(a, b) -> Float64

Degré de compatibilité de deux types en degrés de même largeur :
`1 − écart moyen`. Deux types de largeurs différentes sont incompatibles (`0.0`).
"""
function compatibilite_types(a::TypeDegres, b::TypeDegres)
    length(a.degres) == length(b.degres) || return 0.0
    isempty(a.degres) && return 1.0
    return clamp(1.0 - sum(abs.(a.degres .- b.degres)) / length(a.degres), 0.0, 1.0)
end

"""
    ResultatCompilation

Le résultat d'une compilation par composition pesée : la forme compilée (en degrés),
le fait que la coupure `M → {0,1}` ait été différée, et le registre.
"""
struct ResultatCompilation
    forme            :: Vector{Float64}
    coupure_differee :: Bool
    registre         :: Vector{String}
end

"""
    compilation_par_composition(instructions) -> ResultatCompilation

**Compilation par composition pesée** (méthode 16.1). Compose les formes des
instructions successives par moyenne pondérée, **sans trancher** : la coupure
`M → {0,1}` est **différée** tant que la forme porte des degrés non dégénérés. Le
registre dit si une coupure aurait été nécessaire — et qu'elle a été remise à plus tard.
"""
function compilation_par_composition(instructions::AbstractVector{TypeDegres})
    isempty(instructions) && throw(ArgumentError("un programme porte au moins une instruction"))
    forme = copy(instructions[1].degres)
    registre = String["compilation par composition pesée de $(length(instructions)) instruction(s)"]
    for k in 2:length(instructions)
        ins = instructions[k].degres
        length(ins) == length(forme) ||
            throw(ArgumentError("formes de largeur incompatible : $(length(forme)) vs $(length(ins))"))
        forme = (forme .+ ins) ./ 2      # composition pesée : moyenne, sans coupure
    end
    differee = any(d -> 0.0 < d < 1.0, forme)
    push!(registre, differee ?
          "coupure M→{0,1} différée : la forme reste portée en degrés" :
          "forme déjà tranchée, aucune coupure nécessaire")
    return ResultatCompilation(forme, differee, registre)
end

"""
    ResultatEvaluation

Le résultat d'une évaluation consignée : la valeur finale, la suite des valeurs
intermédiaires et le registre.
"""
struct ResultatEvaluation
    valeur   :: Float64
    etapes   :: Vector{Float64}
    registre :: Vector{String}
end

"""
    evaluation_consignee(instructions, entree) -> ResultatEvaluation

**Évaluation consignée** (méthode 16.2). Évalue le programme sur une entrée en
appliquant les formes degré par degré et en **consignant chaque étape**. La valeur
rendue est la moyenne de la forme finale — un degré, non un drapeau.
"""
function evaluation_consignee(instructions::AbstractVector{TypeDegres},
                              entree::AbstractVector{<:Real})
    isempty(instructions) && throw(ArgumentError("un programme porte au moins une instruction"))
    n = length(instructions[1].degres)
    length(entree) == n ||
        throw(ArgumentError("largeur d'entrée incompatible : $(length(entree)) vs $n"))
    courant = clamp.(float.(collect(entree)), 0.0, 1.0)
    etapes = Float64[sum(courant) / n]
    registre = String["évaluation consignée"]
    for (k, ins) in enumerate(instructions)
        length(ins.degres) == n ||
            throw(ArgumentError("largeur d'instruction incompatible"))
        courant = clamp.(courant .* ins.degres, 0.0, 1.0)
        push!(etapes, sum(courant) / n)
        push!(registre, "instruction $k ($(ins.nom)) → $(round(etapes[end]; digits = 4))")
    end
    return ResultatEvaluation(etapes[end], etapes, registre)
end
