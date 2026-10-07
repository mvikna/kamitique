# ============================================================================
#  Module Methodologie — la méthodologie opérationnelle M = (R, P, Γ)
# ----------------------------------------------------------------------------
#  L'image dérivable de la théorie : elle n'ajoute aucun principe étranger et
#  n'en laisse aucun de régulateur sans traduction.
#    R — les règles opérationnelles de la chaîne (11.1 à 11.4)
#    P — les protocoles opérationnels de conduite (Pδ, Pι, Pκ)
#    Γ — les épreuves de gouvernance (εE, εF, εX)
# ============================================================================
module Methodologie

using ..Socle
using ..Pesee
using ..Chaine

export
    # Règles opérationnelles
    Regle, REGLES, regle,
    constate_attestation, constate_question, constate_langage, constate_evaluation_avant_action,
    # Protocoles opérationnels
    Protocole, PROTOCOLES, protocole, RapportProtocole, conforme,
    controler_Pdelta, controler_Piota, controler_Pkappa,
    # Épreuves de gouvernance
    Epreuve, EPREUVES, ordre_epreuves, IssueEpreuve,
    epreuve_ethique, epreuve_frugalite, epreuve_explicabilite,
    Processus, RapportEpreuves, passer_epreuves,
    # Théorèmes et tableau de dérivation
    verifie_lemme_11_1, verifie_proposition_11_2, verifie_non_compensation,
    TEMOINS_INDEPENDANCE, verifie_independance_gouvernes, verifie_suffisance_conjointe,
    Derivation, TABLEAU_DERIVATION, verifie_derivation

include("regles.jl")
include("protocoles.jl")
include("epreuves.jl")
include("theoremes.jl")

end # module Methodologie
