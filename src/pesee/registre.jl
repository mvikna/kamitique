# ============================================================================
#  Registre de pesée  (section 8.9)
# ----------------------------------------------------------------------------
#  Une pesée qui ne laisse pas de trace n'est pas une pesée kamitique.
#  Le registre comprend quatre mentions : la question, les degrés mesurés, la
#  comparaison harmonique, les figures écartées. Il remplit trois offices :
#  explication, contestation, mémoire.
# ============================================================================

"""
    RegistrePesee

Le **registre de pesée** (clause (iv) du principe 8.1, section 8.9). Il consigne :

1. `question`      — la question posée ;
2. `degres`        — les degrés `ν(Ψ, pi)` mesurés dans `M` ;
3. `comparaison`   — la comparaison harmonique des candidates ;
4. `ecartees`      — les figures écartées, avec leurs motifs.
"""
struct RegistrePesee
    question         :: Symbol
    propositions     :: Vector{String}
    degres           :: Vector{Float64}
    comparaison      :: Vector{Float64}
    candidates       :: Vector{String}
    retenue          :: Union{String,Nothing}
    ecartees         :: Vector{String}
    motifs           :: Vector{String}
    decision_humaine :: Bool
end

function Base.show(io::IO, r::RegistrePesee)
    print(io, "RegistrePesee(", r.question, ", retenue=", r.retenue,
          ", écartées=", length(r.ecartees),
          r.decision_humaine ? ", dernière pesée humaine" : "", ")")
end

"""
    ResultatPesee

Le produit d'une pesée (principe 8.1) : un **état résolu** accompagné de son
**registre de pesée**.
"""
struct ResultatPesee
    etat     :: Etat
    registre :: RegistrePesee
end

est_resolue(r::ResultatPesee) = est_resolu(r.etat)
figure_retenue(r::ResultatPesee) = r.registre.retenue
