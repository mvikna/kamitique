# ============================================================================
#  Ingénierie des connaissances kamitique  (chapitre 28)
# ----------------------------------------------------------------------------
#  « acquisition par pesée, raisonnement par composition ». Une figure de savoir est
#  attestée, située et gouvernée — ces trois traits sont insécables. L'acquisition
#  suit ses cinq pas ; le raisonnement compose les prémisses retenues.
# ============================================================================

"""
    ResultatAcquisition

Le résultat d'une acquisition kamitique : la figure de savoir, le caractère attesté,
les cinq pas franchis et le registre.
"""
struct ResultatAcquisition
    figure   :: Figure
    attestee :: Bool
    etapes   :: Vector{String}
    registre :: Vector{String}
end

"""Les cinq pas de l'acquisition kamitique (méthode 28.1)."""
const ETAPES_ACQUISITION = ["problématiser", "recueillir", "formaliser",
                            "valider à deux balances", "restituer"]

"""
    acquisition_par_pesee(G, savoirs, h; contraintes, seuil_harmonie = 0.0)
        -> ResultatAcquisition

**Acquisition kamitique par pesée** (méthode 28.1). Les cinq pas : *problématiser*
(question consignée), *recueillir* (n'admettre que des savoirs situés dans `G`),
*formaliser* (composer la figure de savoir par ⊙), *valider à deux balances* (balance
éthique εE puis balance de pesée `µ`), *restituer*. Un savoir n'est attesté que s'il
passe les deux balances.
"""
function acquisition_par_pesee(G::Porteur, savoirs::AbstractVector{Figure}, h::Harmonie;
                               contraintes = contraintes_ethiques_canoniques(),
                               seuil_harmonie::Real = 0.0)
    isempty(savoirs) && throw(ArgumentError("aucun savoir à recueillir"))
    registre = String["acquisition kamitique par pesée"]
    # — recueillir : n'admettre que des figures situées
    situes = Figure[f for f in savoirs if verifier_appartenance(G, f)]
    if length(situes) != length(savoirs)
        push!(registre, "$(length(savoirs) - length(situes)) savoir(s) non situé(s) écarté(s)")
    end
    isempty(situes) && throw(ArgumentError("aucun savoir situé dans le porteur"))
    # — formaliser : composer la figure de savoir (accumulation en place)
    figure = length(situes) == 1 ? situes[1] : composer_cumule(situes; G = G)
    push!(registre, "figure de savoir : $(length(figure.sites)) site(s) composé(s)")
    # — valider à deux balances : éthique (εE) puis pesée (µ)
    ok_ethique, violees = admissibilite(figure, contraintes)
    mu = float(h(Etat([figure], [1.0])))
    push!(registre, ok_ethique ? "balance éthique : admise" :
                                  "balance éthique : violée (" * join(string.(violees), ", ") * ")")
    push!(registre, "balance de pesée : µ = $(round(mu; digits = 4))")
    attestee = ok_ethique && mu >= seuil_harmonie - 1e-9
    # — restituer
    push!(registre, attestee ? "savoir attesté et restitué" : "savoir non attesté : rejeté")
    return ResultatAcquisition(figure, attestee, copy(ETAPES_ACQUISITION), registre)
end

"""
    ResultatRaisonnement

Le résultat d'un raisonnement par composition : la conclusion, les prémisses retenues
et écartées, et le registre.
"""
struct ResultatRaisonnement
    conclusion :: Figure
    retenues   :: Vector{Int}
    ecartees   :: Vector{Int}
    registre   :: Vector{String}
end

"""
    raisonnement_par_composition(premisses, regle; G = nothing) -> ResultatRaisonnement

**Raisonnement par composition** (méthode 28.2). Ne retient que les prémisses qui
satisfont `regle`, puis **compose** ces prémisses par `⊙` (enrichi des liens attestés
si `G` est fourni). Les prémisses écartées sont consignées : aucune n'est tue.
"""
function raisonnement_par_composition(premisses::AbstractVector{Figure}, regle::Function;
                                      G::Union{Porteur,Nothing} = nothing)
    isempty(premisses) && throw(ArgumentError("aucune prémisse"))
    retenues = Int[]
    ecartees = Int[]
    for (k, f) in enumerate(premisses)
        if regle(f)
            push!(retenues, k)
        else
            push!(ecartees, k)
        end
    end
    isempty(retenues) && throw(ArgumentError("aucune prémisse ne satisfait la règle"))
    retenues_figs = premisses[retenues]
    conclusion = length(retenues_figs) == 1 ? retenues_figs[1] :
                 (G === nothing ? composer_cumule(retenues_figs) :
                                  composer_cumule(retenues_figs; G = G))
    registre = String["raisonnement par composition de $(length(premisses)) prémisse(s)",
                      "retenues : " * join(retenues, ", "),
                      "écartées : " * (isempty(ecartees) ? "∅" : join(ecartees, ", ")),
                      "conclusion : $(length(conclusion.sites)) site(s)"]
    return ResultatRaisonnement(conclusion, retenues, ecartees, registre)
end
