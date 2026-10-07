# ============================================================================
#  La Manifestation de la Réalité — la triade conjointe (CQG chap. 4)
# ----------------------------------------------------------------------------
#  « L'application de Kheper (1) se décompose en trois secteurs conjoints :
#
#     K̂(s) = Â_At ∘ P̂_Pt ∘ Ĝ_Kh »   (CQG éq. 13)
#
#    • Â_At — Atoum, secteur d'actualisation globale du substrat :
#      Ψ_Noun ↦ (g⁽⁰⁾_μν, A⁽⁰⁾_μ), à courbure finie |R[g⁽⁰⁾]| ≤ R₀⁻² (éq. 14) ;
#    • P̂_Pt — Ptah, secteur de commande informationnelle :
#      P̂_Pt = Ê_Ren ∘ Ê_Ib : évaluer, sélectionner, inscrire, exciter (éq. 15) ;
#    • Ĝ_Kh — Khnoum, secteur de modelage morphogénétique :
#      Ĝ_Kh[g_μν] = e^{2bθ} g_μν, la roue du potier (éq. 16).
#
#  Les trois secteurs sont co-présents à chaque instant : nulle actualisation sans
#  commande, nulle commande sans modelage. La décomposition est exhaustive et
#  l'ordre de la composition encode la dépendance logique, non une chronologie.
#
#  Source : CQG §4.1 (principe triadique), §4.2 (Atoum), §4.3 (Ptah), §4.4 (Khnoum).
# ============================================================================

"""
    SecteurManifestation(nom, registre, operation)

Un secteur de la manifestation (CQG éq. 13). `nom` est la dénomination
traditionnelle (`:Atoum`, `:Ptah`, `:Khnoum`) ; `registre` le genre d'opération
accompli ; `operation` la forme formelle du secteur.
"""
struct SecteurManifestation
    nom       :: Symbol
    registre  :: String
    operation :: String
end

"""
    MANIFESTATION

La décomposition triadique du principe de manifestation (CQG éq. 13) : Atoum
(l'actualisation), Ptah (la commande), Khnoum (le modelage).
"""
const MANIFESTATION = Dict{Symbol,SecteurManifestation}(
    :Atoum => SecteurManifestation(
        :Atoum, "Actualisation globale du substrat",
        "Â_At[Ψ_Noun] = (g⁽⁰⁾_μν, A⁽⁰⁾_μ),  |R[g⁽⁰⁾]| ≤ R₀⁻²"),
    :Ptah => SecteurManifestation(
        :Ptah, "Commande informationnelle",
        "P̂_Pt = Ê_Ren ∘ Ê_Ib"),
    :Khnoum => SecteurManifestation(
        :Khnoum, "Modelage morphogénétique",
        "Ĝ_Kh[g_μν] = e^{2bθ} g_μν"),
)

"""
    manifestation_triadique() -> NTuple{3,SecteurManifestation}

Les trois secteurs conjoints de la manifestation, dans l'ordre de la composition
`K̂ = Â_At ∘ P̂_Pt ∘ Ĝ_Kh` (CQG éq. 13).
"""
manifestation_triadique() =
    (MANIFESTATION[:Atoum], MANIFESTATION[:Ptah], MANIFESTATION[:Khnoum])

"""
    secteur_manifestation(nom) -> SecteurManifestation

Le secteur de manifestation désigné par son nom traditionnel
(`:Atoum`, `:Ptah`, `:Khnoum`).
"""
function secteur_manifestation(nom::Symbol)
    haskey(MANIFESTATION, nom) ||
        throw(ArgumentError("secteur de manifestation inconnu : $nom"))
    return MANIFESTATION[nom]
end

"""
    composer_manifestation(A, P, G)

Compose les trois secteurs de la manifestation selon `K̂ = Â_At ∘ P̂_Pt ∘ Ĝ_Kh`
(CQG éq. 13). Sur des applications, rend la composition `A ∘ P ∘ G` ; sur des
matrices, le produit `A · P · G`. L'ordre encode la dépendance logique des trois
secteurs, non une chronologie.
"""
composer_manifestation(A::Function, P::Function, G::Function) = A ∘ P ∘ G
composer_manifestation(A::AbstractMatrix, P::AbstractMatrix, G::AbstractMatrix) = A * P * G

"""
    verifie_manifestation() -> Bool

Contrôle que la décomposition triadique est **exhaustive et co-présente**
(CQG §4.1) : exactement les trois secteurs `Atoum`, `Ptah`, `Khnoum`, distincts et
tous présents — aucune actualisation sans commande, aucune commande sans modelage.
"""
function verifie_manifestation()
    secteurs = manifestation_triadique()
    length(secteurs) == 3 || return false
    noms = Set(s.nom for s in secteurs)
    return noms == Set([:Atoum, :Ptah, :Khnoum]) && length(noms) == 3
end
