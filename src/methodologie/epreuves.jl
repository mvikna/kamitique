# ============================================================================
#  Les épreuves de gouvernance  (définition 11.3, proposition 11.3)
# ----------------------------------------------------------------------------
#  Une épreuve de gouvernance est une procédure de décision appliquée à un
#  opérateur ou à son produit, qui conclut à la conformité ou au rejet au regard
#  d'une gouverne. Trois épreuves convertissent les trois gouvernes en procédures :
#    εE — éthique       (conjonction des cinq contraintes ; la pesée)
#    εF — frugalité     (fonctionnelle minimale à efficacité égale)
#    εX — explicabilité (justification fidèle et intelligible)
#  Ordre non compensable : εE d'abord (rejet définitif), εF ensuite (parmi les
#  seuls admissibles), εX enfin.
# ============================================================================

"""
    Epreuve

Une **épreuve de gouvernance** (définition 11.3) : son code, la gouverne qu'elle
opérationalise, et le point de contrôle où sa satisfaction se constate.
"""
struct Epreuve
    code           :: Symbol
    gouverne       :: Symbol
    definition     :: String
    point_controle :: String
end

"""Les trois épreuves de gouvernance du cadre."""
const EPREUVES = Epreuve[
    Epreuve(:εE, :ethique,
            "applique la conjonction des cinq contraintes de la définition 9.5 et de leur traduction opératoire — la pesée",
            "porte éthique avant toute dépense"),
    Epreuve(:εF, :frugalite,
            "compare les fonctionnelles (9.2) des processus éthiquement admissibles et d'efficacité égale, et retient le minimal",
            "comparaison des fonctionnelles de ressources"),
    Epreuve(:εX, :explicabilite,
            "vérifie que la justification produite satisfait la fidélité et l'intelligibilité de la définition 9.7, ajustées à son public",
            "revue de la justification fidèle et intelligible"),
]

"""
    ordre_epreuves() -> Vector{Symbol}

L'ordre de passage des épreuves (proposition 11.3) : `[:εE, :εF, :εX]`. Cet ordre
reproduit la structure de la gouvernance et n'est pas compensable.
"""
ordre_epreuves() = Symbol[:εE, :εF, :εX]

"""
    IssueEpreuve

Le résultat d'une épreuve : sa conformité, le motif, la valeur mesurée éventuelle
(par exemple la fonctionnelle `F` retenue) et l'indice éventuel du retenu.
"""
struct IssueEpreuve
    epreuve  :: Symbol
    conforme :: Bool
    motif    :: String
    valeur   :: Union{Float64,Nothing}
    retenu   :: Union{Int,Nothing}
end

IssueEpreuve(epreuve::Symbol, conforme::Bool, motif::AbstractString) =
    IssueEpreuve(epreuve, conforme, String(motif), nothing, nothing)

function Base.show(io::IO, i::IssueEpreuve)
    print(io, "IssueEpreuve(", i.epreuve, ", ",
          i.conforme ? "conforme" : "rejet", " : ", i.motif, ")")
end

# ----------------------------------------------------------------------------
#  εE — épreuve éthique
# ----------------------------------------------------------------------------

"""
    epreuve_ethique(f, contraintes) -> IssueEpreuve

**Épreuve éthique εE.** Applique la conjonction des contraintes éthiques à une
figure. Son rejet est **définitif** : aucune performance ne rachète une violation
(axiome de prééminence éthique 9.3, non-compensation proposition 8.7).
"""
function epreuve_ethique(f::Figure,
                         contraintes::AbstractVector{Pesee.ContrainteEthique} =
                             Pesee.contraintes_ethiques_canoniques())
    ok, violees = Pesee.admissibilite(f, contraintes)
    motif = ok ? "conjonction des contraintes satisfaite" :
                 "violation : " * join(string.(violees), ", ")
    return IssueEpreuve(:εE, ok, motif)
end

# ----------------------------------------------------------------------------
#  εF — épreuve de frugalité
# ----------------------------------------------------------------------------

"""
    epreuve_frugalite(ressources, efficacites, f; tolerance = 1e-9) -> IssueEpreuve

**Épreuve de frugalité εF.** Parmi les processus **déjà éthiquement admissibles**
et d'**efficacité égale**, compare les fonctionnelles `F(π) = αRe + βRc + γRd`
(équation 9.2) et retient la minimale. L'`IssueEpreuve` porte la valeur `F`
minimale et l'indice `retenu` du processus.
"""
function epreuve_frugalite(ressources::AbstractVector{Chaine.Ressources},
                           efficacites::AbstractVector{<:Real},
                           f::Chaine.Frugalite = Chaine.Frugalite();
                           tolerance::Real = 1e-9)
    length(ressources) == length(efficacites) ||
        throw(ArgumentError("ressources et efficacités doivent avoir même longueur"))
    isempty(ressources) &&
        throw(ArgumentError("aucun processus admissible : εF ne s'applique pas"))
    eff_max = maximum(efficacites)
    groupe = findall(e -> abs(float(e) - eff_max) <= tolerance, efficacites)
    couts = [f(ressources[i]) for i in groupe]
    k = argmin(couts)
    i_star = groupe[k]
    return IssueEpreuve(:εF, true,
                        "fonctionnelle minimale à efficacité égale : F = $(couts[k])",
                        float(couts[k]), i_star)
end

# ----------------------------------------------------------------------------
#  εX — épreuve d'explicabilité
# ----------------------------------------------------------------------------

"""
    epreuve_explicabilite(j) -> IssueEpreuve

**Épreuve d'explicabilité εX.** Vérifie que la justification produite satisfait la
**fidélité** et l'**intelligibilité** (définition 9.7), avant toute constitution du
renseignement.
"""
function epreuve_explicabilite(j::Chaine.Justification)
    ok = Chaine.justification_valide(j)
    motif = ok ? "justification fidèle et intelligible" :
                 "justification " * (j.fidele ? "" : "infidèle ") *
                 (j.intelligible ? "" : "inintelligible")
    return IssueEpreuve(:εX, ok, strip(motif))
end

# ----------------------------------------------------------------------------
#  Passage ordonné et non compensable des épreuves
# ----------------------------------------------------------------------------

"""
    Processus

Un processus candidat soumis au trièdre des épreuves : sa figure (pour εE), ses
ressources (pour εF), son efficacité (pour εF) et sa justification (pour εX).
"""
struct Processus
    nom           :: String
    figure        :: Figure
    ressources    :: Chaine.Ressources
    efficacite    :: Float64
    justification :: Chaine.Justification
end

"""
    RapportEpreuves

Le résultat du passage ordonné des trois épreuves sur un ensemble de processus.
"""
struct RapportEpreuves
    epsilon_E       :: IssueEpreuve
    epsilon_F       :: Union{IssueEpreuve,Nothing}
    epsilon_X       :: Union{IssueEpreuve,Nothing}
    retenu          :: Union{String,Nothing}
    rejet_definitif :: Bool
end

function Base.show(io::IO, r::RapportEpreuves)
    print(io, "RapportEpreuves(retenu=", r.retenu,
          r.rejet_definitif ? ", rejet définitif (εE)" : "", ")")
end

"""
    passer_epreuves(processus, frugalite; contraintes, tolerance) -> RapportEpreuves

Applique les trois épreuves **dans l'ordre non compensable** (proposition 11.3) :

1. `εE` d'abord, sur la figure de chaque processus ; les inadmissibles sont écartés
   **définitivement** et n'entrent dans aucune comparaison ultérieure ;
2. `εF` ensuite, parmi les **seuls processus éthiquement admissibles** et
   d'efficacité égale, retient la fonctionnelle minimale ;
3. `εX` enfin, sur la justification du processus retenu.

Si `εE` écarte toutes les candidatures, la procédure s'arrête là : `rejet_definitif`.
"""
function passer_epreuves(processus::AbstractVector{Processus},
                         frugalite::Chaine.Frugalite = Chaine.Frugalite();
                         contraintes::AbstractVector{Pesee.ContrainteEthique} =
                             Pesee.contraintes_ethiques_canoniques(),
                         tolerance::Real = 1e-9)
    # ---- εE : l'épreuve éthique passe d'abord, son rejet est définitif -------
    admissibles = Int[]
    violees = Symbol[]
    for (i, p) in enumerate(processus)
        issue = epreuve_ethique(p.figure, contraintes)
        if issue.conforme
            push!(admissibles, i)
        end
    end
    ok_E = !isempty(admissibles)
    issue_E = IssueEpreuve(:εE, ok_E,
        ok_E ? "conjonction satisfaite pour $(length(admissibles)) processus" :
               "rejet définitif : aucune candidature éthiquement admissible")
    if !ok_E
        return RapportEpreuves(issue_E, nothing, nothing, nothing, true)
    end

    # ---- εF : parmi les seuls admissibles, à efficacité égale ----------------
    ressources = Chaine.Ressources[processus[i].ressources for i in admissibles]
    efficacites = Float64[processus[i].efficacite for i in admissibles]
    issue_F = epreuve_frugalite(ressources, efficacites, frugalite; tolerance = tolerance)
    indice_retenu = admissibles[issue_F.retenu]

    # ---- εX : explicabilité du retenu ----------------------------------------
    issue_X = epreuve_explicabilite(processus[indice_retenu].justification)

    retenu = issue_X.conforme ? processus[indice_retenu].nom : nothing
    return RapportEpreuves(issue_E, issue_F, issue_X, retenu, false)
end
