# ============================================================================
#  La balance de Maât  (principe 8.1, proposition 8.7, proposition 8.8)
# ----------------------------------------------------------------------------
#  Peser un état Ψ sur une question q, c'est :
#    (i)   expliciter les propositions qui portent q ;
#    (ii)  mesurer les degrés ν(Ψ, pi) dans M ;
#    (iii) comparer les candidates au regard de l'harmonie µ (position, non verdict) ;
#    (iv)  résoudre par sélection, en consignant la question, les degrés, les écartées.
#  L'épreuve éthique passe d'abord et son rejet est définitif (non-compensation).
# ============================================================================

"""Nom lisible d'une figure : ses sites joints par '·'."""
nom_figure(f::Figure) = isempty(f.sites) ? "∅" : join(string.(f.sites), "·")

"""
    balance(Ψ, q, h; λ = 0.5, contraintes = ContrainteEthique[],
            decision_engageante = false) -> ResultatPesee

La **balance de Maât** (principe 8.1). Applique les quatre clauses de la pesée et
retourne un état résolu muni de son registre.

- `q` : la question portée par ses propositions (clause i) ;
- `h` : la mesure d'harmonie (clause iii) ;
- `contraintes` : les contraintes éthiques ; les figures qui en violent une sont
  écartées **avant** toute comparaison (non-compensation, proposition 8.7) ;
- `decision_engageante` : si `true`, la pesée finale est marquée comme **humaine**
  (proposition 8.8) — la machine prépare, l'humain tranche.
"""
function balance(Ψ::Etat, q::Question, h::Harmonie;
                 λ::Real = 0.5,
                 contraintes::AbstractVector{ContrainteEthique} = ContrainteEthique[],
                 decision_engageante::Bool = false)

    # ---- clause (i) : la question est explicite -----------------------------
    isempty(q.propositions) &&
        throw(ArgumentError("une pesée sans question consignée est le geste du dispendieux"))

    # ---- non-compensation : l'épreuve éthique d'abord, définitive -----------
    admissibles = Int[]
    ecartees = String[]
    motifs = String[]
    for i in eachindex(Ψ.figures)
        ok, violees = admissibilite(Ψ.figures[i], contraintes)
        if ok
            push!(admissibles, i)
        else
            push!(ecartees, nom_figure(Ψ.figures[i]))
            push!(motifs, "violation éthique : " * join(string.(violees), ", "))
        end
    end
    isempty(admissibles) &&
        throw(ArgumentError("aucune figure admissible : l'épreuve éthique εE rejette toutes les candidates"))

    # ---- clause (ii) : mesure des degrés dans M -----------------------------
    degres = [valuation(Ψ, p) for p in q.propositions]

    # ---- clause (iii) : comparaison harmonique des seules admissibles -------
    Ψadm = Etat(Ψ.figures[admissibles], Ψ.poids[admissibles])
    scores = scores_pesee(Ψadm, q, h; λ = λ)
    gagnant_local = argmax(scores.scores)
    gagnant = admissibles[gagnant_local]

    for (k, i) in enumerate(admissibles)
        if k != gagnant_local
            push!(ecartees, nom_figure(Ψ.figures[i]))
            push!(motifs, "non retenue : score harmonique inférieur")
        end
    end

    # ---- clause (iv) : résolution et registre ------------------------------
    Ψr = resolve(Ψ, gagnant)
    reg = RegistrePesee(
        q.nom,
        [p.nom for p in q.propositions],
        degres,
        scores.scores,
        [nom_figure(Ψ.figures[i]) for i in admissibles],
        nom_figure(Ψ.figures[gagnant]),
        ecartees,
        motifs,
        decision_engageante,
    )
    return ResultatPesee(Ψr, reg)
end

"""
    derniere_pesee_humaine(r::ResultatPesee) -> Bool

**Proposition 8.8 — Dernière pesée humaine.** Indique si la pesée finale engage des
personnes ou des communautés, auquel cas elle demeure une responsabilité humaine et
ne peut être déléguée à une procédure.
"""
derniere_pesee_humaine(r::ResultatPesee) = r.registre.decision_humaine

"""
    produit_de_la_pesee(r::ResultatPesee)

Le produit de la pesée : un état résolu accompagné de son registre.
"""
produit_de_la_pesee(r::ResultatPesee) = (r.etat, r.registre)
