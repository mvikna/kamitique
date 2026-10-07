# ============================================================================
#  Kamitique.jl — Science Computationnelle de la Cosmologie Quantique Géométrique
# ----------------------------------------------------------------------------
#  Package de la Kamitique, la science computationnelle alternative au paradigme
#  binaire, dérivée de la Cosmologie Quantique Géométrique (CQG).
#
#  Organisation en modules :
#    Loi            — la Loi fondamentale de la CQG (axiomes A1–A4, espace des
#                     phases, Loi Universelle, Heka, principe de manifestation) ;
#    Socle          — l'appareil formel (sites, états, ΣK, δ/ι/κ, théorèmes)
#    Pesee          — la balance de Maât et le registre de pesée
#    Chaine         — la chaîne épistémologique (7 dimensions) gouvernée
#    Methodologie   — M = (R, P, Γ) : règles, protocoles, épreuves
#    Dispositif     — les quatre mouvements du dispositif unifié de résolution
#    Categories     — les méthodes et algorithmes par catégorie de problèmes
#    Ethnomatique   — les savoirs africains formalisés (registre extensible)
# ============================================================================
module Kamitique

include("loi/Loi.jl")
include("socle/Socle.jl")
include("pesee/Pesee.jl")
include("chaine/Chaine.jl")
include("methodologie/Methodologie.jl")
include("dispositif/Dispositif.jl")
include("categories/Categories.jl")
include("ethnomatique/Ethnomatique.jl")

using .Loi
using .Socle
using .Pesee
using .Chaine
using .Methodologie
using .Dispositif
using .Categories
using .Ethnomatique

# --- ré-export des symboles publics des sous-modules --------------------------
const _SOUS_MODULES = (Loi, Socle, Pesee, Chaine, Methodologie, Dispositif, Categories,
                       Ethnomatique)

for m in _SOUS_MODULES
    for n in names(m)
        n == nameof(m) && continue
        n in (:eval, :include) && continue
        isdefined(@__MODULE__, n) || continue
        @eval export $n
    end
end

end # module Kamitique
