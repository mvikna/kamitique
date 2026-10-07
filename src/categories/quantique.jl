# ============================================================================
#  Informatique quantique kamitique  (chapitre 20)
# ----------------------------------------------------------------------------
#  « pesée quantique, correction par harmonisation ». La superposition est native ;
#  la mesure est une **pesée**, non une coupure. La décohérence est une perte
#  d'harmonie localisée, que l'on corrige en repondérant la branche fautive.
# ============================================================================

"""
    ResultatMesureQuantique

Le résultat d'un calcul par superposition pesée : la branche retenue (ou `nothing`),
son degré et le registre.
"""
struct ResultatMesureQuantique
    figure   :: Union{Figure,Nothing}
    degre    :: Float64
    registre :: Vector{String}
end

"""
    calcul_par_superposition(Ψ, q, h; λ = 0.5) -> ResultatMesureQuantique

**Calcul par superposition pesée** (méthode 20.1). L'état `Ψ` est une superposition de
branches ; on ne coupe pas la superposition, on la **pèse** : les branches sont
comparées par le score de pesée sur la question `q`, et la présence est mesurée. La
mesure rend un degré avec sa branche, non un bit avec une adresse.
"""
function calcul_par_superposition(Ψ::Etat, q::Question, h::Harmonie; λ::Real = 0.5)
    sc = scores_pesee(Ψ, q, h; λ = λ)
    i = argmax(sc.scores)
    registre = String["superposition native : $(length(Ψ.figures)) branche(s)",
                      "la mesure est une pesée, non une coupure",
                      "branche retenue : $i (degré $(round(sc.scores[i]; digits = 4)))"]
    return ResultatMesureQuantique(Ψ.figures[i], sc.scores[i], registre)
end

"""
    ResultatCorrection

Le résultat d'une correction par harmonisation : l'état corrigé, l'harmonie avant et
après, et le registre.
"""
struct ResultatCorrection
    corrigee       :: Etat
    harmonie_avant :: Float64
    harmonie_apres :: Float64
    registre       :: Vector{String}
end

"""
    correction_par_harmonisation(Ψ, h) -> ResultatCorrection

**Correction par harmonisation** (méthode 20.2). La décohérence est une **perte
d'harmonie localisée** : on identifie la branche la moins cohérente avec le reste de
la présence, puis on repondère sa présence à la baisse et l'on renormalise. La
correction est gouvernée — elle n'est admise que si `µ` ne décroît pas.
"""
function correction_par_harmonisation(Ψ::Etat, h::Harmonie)
    n = length(Ψ.figures)
    h0 = float(h(Ψ))
    if n == 1
        return ResultatCorrection(Ψ, h0, h0, String["une seule branche : aucune décohérence localisée"])
    end
    coh = zeros(n)
    for i in 1:n
        c = 0.0
        for j in 1:n
            Ψ.poids[j] == 0 && continue
            c += Ψ.poids[j] * clamp(float(h.compatibilite(Ψ.figures[i], Ψ.figures[j])), 0.0, 1.0)
        end
        coh[i] = c
    end
    i_decoh = argmin(coh)
    facteurs = ones(n)
    facteurs[i_decoh] = 0.5
    corrigee = redistribuer(Ψ, facteurs)
    h1 = float(h(corrigee))
    registre = String["décohérence localisée sur la branche $i_decoh (cohérence $(round(coh[i_decoh]; digits = 4)))",
                      "µ : $(round(h0; digits = 4)) → $(round(h1; digits = 4))",
                      h1 >= h0 - 1e-9 ? "correction admise (µ non décroissante)" :
                                        "correction refusée (µ décroissante)"]
    return ResultatCorrection(corrigee, h0, h1, registre)
end
