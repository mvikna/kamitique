# ============================================================================
#  Les sept dimensions de la chaîne épistémologique  (définitions 9.1 à 9.7)
# ----------------------------------------------------------------------------
#  Quatre étapes de production : donnée, information, connaissance, renseignement.
#  Trois gouvernes : éthique, frugalité, explicabilité — qui ne sont pas une
#  phase mais portent chaque étape (proposition 9.1).
# ============================================================================

# ----------------------------------------------------------------------------
#  Étape 1 — la donnée
# ----------------------------------------------------------------------------

"""
    Metadonnee

La métadonnée d'attestation d'une donnée (définition 9.1) : source, mode
d'acquisition, horodatage — et, lorsque la donnée concerne des personnes ou des
communautés, la mention du consentement.
"""
struct Metadonnee
    source       :: String
    mode         :: String
    horodatage   :: String
    consentement :: Union{Bool,Nothing}
end

Metadonnee(source::AbstractString, mode::AbstractString, horodatage::AbstractString) =
    Metadonnee(String(source), String(mode), String(horodatage), nothing)

"""
    Donnee(signe, meta)

La **donnée** (définition 9.1) : un fait porté par un signe et attesté par son origine.
La métadonnée distingue la donnée d'un simple symbole : elle garantit qu'il existe un
lieu, un instant et un procédé dont ce signe est la trace.

**Règle 11.1** : aucune donnée non attestée n'entre dans la chaîne.
"""
struct Donnee
    signe :: String
    meta  :: Metadonnee
end

"""Une donnée est attestée si sa métadonnée porte source, mode et horodatage."""
est_attestee(d::Donnee) =
    !isempty(d.meta.source) && !isempty(d.meta.mode) && !isempty(d.meta.horodatage)

"""Consentement explicite requis pour toute donnée concernant des personnes."""
consentement_recueilli(d::Donnee) = d.meta.consentement === true

# ----------------------------------------------------------------------------
#  Étape 2 — l'information
# ----------------------------------------------------------------------------

"""
    Information(schema, contenu, variables, entropie_q, incertitude)

L'**information** (définition 9.2) : un ensemble de données organisé selon un schéma
explicite et évalué comme **réduction d'incertitude** relativement à une question :

    Iq(D) = H(q) − H(q | D).

L'information n'est pas un contenu flottant : c'est une relation entre des données et
une question.
"""
struct Information
    schema      :: String
    contenu     :: Vector{Donnee}
    variables   :: Vector{Symbol}
    entropie_q  :: Float64
    incertitude :: Float64      # Iq(D) ∈ [0, 1]
end

"""Réduction d'incertitude portée par l'information (équation 9.1)."""
reduction_incertitude(i::Information) = i.incertitude

# ----------------------------------------------------------------------------
#  Étape 3 — la connaissance
# ----------------------------------------------------------------------------

"""
    Connaissance(langue, base, inference)

La **connaissance** (définition 9.3) : une théorie `T = (L, KB, ⊢)` où `L` est un
langage, `KB` une base de propositions admises, `inference` la relation d'inférence
(`:deductive`, `:inductive` ou `:expertale`).
"""
struct Connaissance
    langue    :: String
    base      :: Vector{String}
    inference :: Symbol

    function Connaissance(langue::AbstractString, base::AbstractVector{<:AbstractString},
                          inference::Symbol)
        inference in (:deductive, :inductive, :expertale) ||
            throw(ArgumentError("l'inférence est déductive, inductive ou expertale"))
        new(String(langue), String[base...], inference)
    end
end

"""Une proposition est inférable si elle appartient à la base admise."""
infere(T::Connaissance, p::AbstractString) = p in T.base

# ----------------------------------------------------------------------------
#  Étape 4 — le renseignement
# ----------------------------------------------------------------------------

"""
    Renseignement(theorie, action, valeur, registre)

Le **renseignement** (définition 9.4) : un triplet `r = (T, a, v)` — une connaissance
rendue applicable à une action `a` selon une valeur `v`. Le renseignement engage, car
il oriente une action qui a des conséquences.

**Règle 11.4** : aucune constitution du renseignement sans action et échelle de valeur
explicitées au préalable.
"""
struct Renseignement
    theorie  :: Connaissance
    action   :: String
    valeur   :: Function
    registre :: Any
end

"""Évalue l'issue d'une action selon l'échelle de valeur du renseignement."""
evaluer(r::Renseignement, issue) = float(r.valeur(issue))

# ----------------------------------------------------------------------------
#  Les trois gouvernes
# ----------------------------------------------------------------------------

"""
    Justification(texte, fidele, intelligible)

L'**explicabilité** `X(m) ∈ J` (définition 9.7) : un énoncé lisible qui rend compte du
modèle produit et des raisons pour lesquelles il le produit. `X` doit satisfaire la
**fidélité** (la justification reflète le fonctionnement réel) et l'**intelligibilité**
(elle est compréhensible par son destinataire).
"""
struct Justification
    texte        :: String
    fidele       :: Bool
    intelligible :: Bool
end

justification_valide(j::Justification) = j.fidele && j.intelligible

"""
    Ressources(energie, calcul, donnees)

Les moyens mobilisés par un processus : énergie consommée `Re`, ressources de calcul
`Rc`, données mobilisées `Rd` (équation 9.2).
"""
struct Ressources
    energie :: Float64
    calcul  :: Float64
    donnees :: Float64
end

"""
    Frugalite(α, β, γ)

La **frugalité** (définition 9.6) : la fonctionnelle

    F(π) = α·Re(π) + β·Rc(π) + γ·Rd(π),

avec `α, β, γ ≥ 0` reflétant les priorités du contexte. À efficacité égale, le
processus préféré est celui dont `F` est minimal (axiome 9.4).
"""
struct Frugalite
    α :: Float64
    β :: Float64
    γ :: Float64

    function Frugalite(α::Real = 1.0, β::Real = 1.0, γ::Real = 1.0)
        (α < 0 || β < 0 || γ < 0) && throw(ArgumentError("les poids de frugalité sont positifs ou nuls"))
        new(float(α), float(β), float(γ))
    end
end

"""Évalue la fonctionnelle de frugalité sur des ressources mobilisées."""
(f::Frugalite)(r::Ressources) = f.α * r.energie + f.β * r.calcul + f.γ * r.donnees

"""
    EpreuveGouvernanceEthique

Le prédicat éthique `E` (définition 9.5) : conjonction des cinq contraintes
constitutives — consentement, dignité, équité, non-malfaisance, souveraineté des
communautés sur leurs données et leurs savoirs.
"""
struct EpreuveGouvernanceEthique
    contraintes :: Vector{Any}   # ContrainteEthique (Pesee) — typé Any pour éviter la dépendance circulaire
end

EpreuveGouvernanceEthique() = EpreuveGouvernanceEthique(Any[])
