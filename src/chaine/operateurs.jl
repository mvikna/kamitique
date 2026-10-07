# ============================================================================
#  Opérateurs de la chaîne  (définitions 10.2 à 10.4)
# ----------------------------------------------------------------------------
#  Identité structurelle (chapitre 12) : les opérateurs δ, ι, κ de la chaîne
#  sont LES MÊMES que ceux de la dynamique du socle. On étend donc les fonctions
#  génériques δ, ι, κ définies par Socle, au lieu de redéfinir des symboles.
#    δ : P(D) → I     structuration
#    ι : I → C        modélisation
#    κ : C×A×V → R    mise en renseignement
# ============================================================================

"""
    CorpusDonnees(donnees, question, schema = "")

Un ensemble de données attestées relatives à une question consignée. C'est l'entrée
de la chaîne (règle 11.1 et règle 11.2).
"""
struct CorpusDonnees
    donnees  :: Vector{Donnee}
    question :: Symbol
    schema   :: String
end

CorpusDonnees(donnees::AbstractVector{Donnee}, question::Symbol) =
    CorpusDonnees(collect(donnees), question, "")

"""Données du corpus dont la métadonnée d'attestation est complète."""
donnees_attestees(c::CorpusDonnees) = Donnee[d for d in c.donnees if est_attestee(d)]

"""
    δ(c::CorpusDonnees; variables = Symbol[], entropie_q = 1.0, entropie_conditionnelle = 0.0)
        -> Information

**Opérateur de structuration** (définitions 7.1 et 10.2). À un ensemble de données
brutes, `δ` associe une information structurée : il choisit un schéma, range les
données selon ce schéma, écarte ou signale les données non conformes, et produit
l'évaluation d'incertitude `Iq(D) = H(q) − H(q | D)`.

Conditions préalables (protocole Pδ) : données attestées (règle 11.1), question
consignée (règle 11.2). Aucune donnée n'est écartée sans signalement.
"""
function δ(c::CorpusDonnees; variables::AbstractVector{Symbol} = Symbol[],
           entropie_q::Real = 1.0, entropie_conditionnelle::Real = 0.0)
    attestees = donnees_attestees(c)
    # les données non attestées sont signalées, jamais tues
    signalees = length(attestees) - length(c.donnees)
    schema = isempty(c.schema) ? "schéma explicite de structuration" : c.schema
    iq = clamp(float(entropie_q) - float(entropie_conditionnelle), 0.0, 1.0)
    info = Information(schema, attestees, collect(variables), float(entropie_q), iq)
    return info
end

"""Structuration avec question explicite (la question est obligatoire)."""
function δ(c::CorpusDonnees, q::Question; kwargs...)
    info = δ(c; kwargs...)
    return info
end

"""
    ι(i::Information, langue; inference = :inductive, base = String[]) -> Connaissance

**Opérateur de modélisation** (définitions 7.2 et 10.3). À une information structurée,
`ι` associe une connaissance : il choisit un langage `L`, y construit une base `KB` qui
généralise l'information, et dote le couple d'une relation d'inférence `⊢`.

Règle 11.3 : le choix du langage est documenté **avant** toute inférence.
"""
function ι(i::Information, langue::AbstractString;
           inference::Symbol = :inductive, base::AbstractVector{<:AbstractString} = String[])
    kb = String[base...]
    if isempty(kb)
        for d in i.contenu
            push!(kb, d.signe)
        end
    end
    return Connaissance(langue, kb, inference)
end

"""
    ι(i::Information, langue, inference; base = String[]) -> Connaissance
"""
ι(i::Information, langue::AbstractString, inference::Symbol; kwargs...) =
    ι(i, langue; inference = inference, kwargs...)

"""
    κ(T::Connaissance, action, valeur; registre = nothing) -> Renseignement

**Opérateur de mise en renseignement** (définitions 7.3 et 10.4). À une connaissance,
une action et une échelle de valeur, `κ` associe le renseignement `r = (T, a, v)` :
la connaissance rendue applicable selon la valeur.

Règle 11.4 : aucun renseignement sans explicitation préalable de `a` et de `v`.
"""
function κ(T::Connaissance, action::AbstractString, valeur::Function; registre = nothing)
    return Renseignement(T, String(action), valeur, registre)
end

"""
    rho(c, schema, langue, action, valeur; ...) -> Renseignement

La **chaîne de production du noyau** (théorème 10.1) :

    ρ = κ ∘ (ι × id) ∘ (δ × id),

c'est-à-dire `r = κ(ι(δ(D̂)), a, v)`.
"""
function rho(c::CorpusDonnees, langue::AbstractString, action::AbstractString,
             valeur::Function;
             inferenced::Union{Symbol,Nothing} = nothing,
             inference::Symbol = :inductive,
             variables::AbstractVector{Symbol} = Symbol[],
             entropie_q::Real = 1.0, entropie_conditionnelle::Real = 0.0,
             base::AbstractVector{<:AbstractString} = String[])
    inf = δ(c; variables = variables, entropie_q = entropie_q,
            entropie_conditionnelle = entropie_conditionnelle)
    T = ι(inf, langue; inference = inference, base = base)
    return κ(T, action, valeur)
end
