# ============================================================================
#  Module Categories — les méthodes par catégorie de problèmes
# ----------------------------------------------------------------------------
#  Chaque catégorie de la carte (tableau 13.1) reçoit ici les méthodes que le
#  dispositif unifié produit pour elle. Toutes procèdent du même socle, de la même
#  chaîne et des mêmes épreuves : aucune ne crée une discipline nouvelle
#  (définition 13.1, théorème 8.5).
# ============================================================================
module Categories

using ..Socle
using ..Pesee
using ..Chaine
using ..Methodologie
using ..Dispositif

export
    # Architectures des ordinateurs (ch. 14)
    ResultatPlacement, placement_par_pesee, ResultatFlot, flot_par_composition,
    # Systèmes d'exploitation (ch. 15)
    ResultatOrdonnancement, ordonnancement_par_pesee,
    ResultatAllocation, allocation_memoire_situee,
    # Langages de programmation (ch. 16)
    TypeDegres, compatibilite_types, ResultatCompilation, compilation_par_composition,
    ResultatEvaluation, evaluation_consignee,
    # Structures de données (ch. 17)
    ResultatTri, tri_par_pesee, ResultatParcours, parcours_regle,
    # Calcul scientifique (ch. 18)
    ResultatDescenteScientifique, resolution_par_descente,
    ResultatHarmonisation, convergence_par_harmonisation,
    # Calcul haute performance (ch. 19)
    ResultatGrille, execution_par_harmonie,
    ResultatReponderationCharge, reponderation_sous_charge,
    # Informatique quantique (ch. 20)
    ResultatMesureQuantique, calcul_par_superposition,
    ResultatCorrection, correction_par_harmonisation,
    # Bases de données (ch. 21)
    ResultatRecherche, trouve, recherche_par_relaxation,
    ResultatJointure, jointure_par_composition,
    # Big data (ch. 22)
    ResultatPartition, partitionnement_geometrique,
    ResultatAgregation, agregation_harmonique,
    # Réseaux (ch. 23)
    ResultatRoutage, routage_par_harmonie,
    # Cryptologie (ch. 24)
    Empreinte, hachage_par_pesee, chiffrement_par_redistribution,
    dechiffrement_par_redistribution,
    # Optimisation et recherche opérationnelle (ch. 25)
    ResultatDescenteOptimale, descente_par_harmonisation,
    borne_harmonique, ResultatElagage, elagage_par_pesee,
    # Aide multicritère à la décision (ch. 26)
    ResultatClassement, classement_par_pesee_harmonique, negociation_par_reponderation,
    # Théorie des jeux (ch. 27)
    ResultatEquilibre, pesee_mutuelle, ResultatConception, conception_par_attracteur,
    # Ingénierie des connaissances (ch. 28)
    ETAPES_ACQUISITION, ResultatAcquisition, acquisition_par_pesee,
    ResultatRaisonnement, raisonnement_par_composition,
    # Recherche heuristique et systèmes experts (ch. 29)
    ResultatRechercheHeuristique, recherche_par_pesee_de_promesse, IndexPesee,
    ChampMaat, champ_vers, promesse_optimale, descente_par_champ, hors_bassin,
    ChampDepuis, champ_depuis, promesse_depuis, chemin_depuis,
    ResultatInference, inference_gouvernee,
    # Apprentissage automatique (ch. 30)
    RapportReponderation, reponderation_sous_encadrement

include("architectures.jl")   # ch. 14
include("systemes.jl")        # ch. 15
include("langages.jl")        # ch. 16
include("structures.jl")      # ch. 17
include("scientifique.jl")    # ch. 18
include("hpc.jl")             # ch. 19
include("quantique.jl")       # ch. 20
include("bases.jl")           # ch. 21
include("bigdata.jl")         # ch. 22
include("reseaux.jl")         # ch. 23
include("cryptologie.jl")     # ch. 24
include("optimisation.jl")    # ch. 25
include("multicritere.jl")    # ch. 26
include("jeux.jl")            # ch. 27
include("connaissances.jl")   # ch. 28
include("heuristique.jl")     # ch. 29
include("apprentissage.jl")   # ch. 30

end # module Categories
