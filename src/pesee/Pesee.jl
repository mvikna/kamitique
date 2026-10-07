# ============================================================================
#  Module Pesee — la balance de Maât et le registre de pesée
# ----------------------------------------------------------------------------
#  La théorie de la décision de la Kamitique : la balance (principe 8.1),
#  la non-compensation (proposition 8.7), la constatation et le registre
#  (section 8.9), et la dernière pesée humaine (proposition 8.8).
# ============================================================================
module Pesee

using ..Socle

export
    ContrainteEthique, contrainte_neutre, contraintes_ethiques_canoniques, admissibilite,
    RegistrePesee, ResultatPesee, est_resolue, figure_retenue,
    balance, derniere_pesee_humaine, produit_de_la_pesee, nom_figure

include("ethique.jl")
include("registre.jl")
include("balance.jl")

end # module Pesee
