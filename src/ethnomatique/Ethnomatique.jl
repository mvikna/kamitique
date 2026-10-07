# ============================================================================
#  Module Ethnomatique — les savoirs africains formalisés
# ----------------------------------------------------------------------------
#  Le registre des savoirs, chaque savoir occupant un fichier à part et
#  s'enregistrant lui-même au chargement. Ajouter un savoir revient à écrire un
#  fichier qui appelle `enregistrer_savoir!` et à l'`include` ici : rien d'autre
#  ne bouge. C'est la lecture computationnelle de la composition (⊙) appliquée
#  aux savoirs — le registre est le porteur, chaque savoir un site.
# ============================================================================
module Ethnomatique

using Random

export
    # Registre extensible des savoirs
    Savoir, enregistrer_savoir!, savoirs, savoir, savoir_existe,
    savoirs_domaine, domaines_savoirs, savoirs_implementes,
    recensement_savoirs, aide_ethnomatique,
    # Numérations africaines
    SYSTEMES_NUMERATION, numerer_base, numerer_chaine,
    HIEROGLYPHES_EGYPTIENS, numerer_egyptien,
    fraction_egyptienne, somme_unitaire,
    PARTS_OEIL_HORUS, VALEUR_RO, oeil_horus,
    MOTS_YORUBA_UNITES, numerer_vigesimal, numerer_yoruba,
    SYMBOLES_GEEZ, numerer_geez, numerer_cauris,
    # Jeux de semailles (awalé / oware)
    PlateauSemailles, awele_initialiser, awele_total, awele_coups,
    awele_jouable, awele_semer, awele_partie, VARIANTES_SEMAILLES, awele_variantes,
    # Géomancie (sikidy / ifa / cauris)
    MASQUE_GEOMANCIE, LIGNES_GEOMANCIE, GEOMANCIE_NOMS, geomancie_nom,
    geomancie_bits, geomancie_code, geomancie_addition, geomancie_inversion,
    geomancie_reversion, geomancie_actifs, geomancie_filles, geomancie_bouclier,
    sikidy_reny, sikidy_zanaka, sikidy_tableau,
    ifa_figures, ifa_odu_total, ifa_odu, cauris_figure, cauris_oracle,
    # Motifs et symétries (adinkra, frises, sona)
    OPERATIONS_D4, transformer_d4, symetries_d4, groupe_symetrie,
    GROUPES_FRISE, GROUPES_PAPIER, symetries_bande, groupe_frise,
    ADINKRA, adinkra, sona_grille, sona_lignes, sona_monolineaire, sona_circuit,
    # Artefacts à encoches (Ishango, Lebombo)
    OS_ISHANGO, ishango_somme, ishango_analyse,
    LEBOMBO_ENCOCHES, lunaison_jours, lebombo_lunaison,
    SYSTEMES_ENCOCHES, compter_encoches

include("registre.jl")     # socle : registre extensible des savoirs
include("numeration.jl")   # savoir : :numeration
include("semailles.jl")    # savoir : :jeux_semailles
include("geomancie.jl")    # savoir : :geomancie
include("motifs.jl")       # savoir : :motifs
include("artefacts.jl")    # savoir : :artefacts

end # module Ethnomatique
