# ============================================================================
#  Réseaux kamitiques  (chapitre 23)
# ----------------------------------------------------------------------------
#  « routage par harmonie, résilience par pesée locale, protocole par composition,
#  transmission longue portée, toile par figures ». Le routage ne compte pas les sauts :
#  il retient le chemin dont l'harmonie cumulée est la plus haute. Le protocole est une
#  figure stratifiée (ses couches sont ses échelles, A-K6) ; la longue portée fragmente
#  le contenu puis le recompose, et son rendement se mesure au lieu de se revendiquer.
#  La toile par figures en donne l'alternative hypermédia : un document est un site,
#  une adresse un lieu, un hyperlien un voisinage attesté — et la navigation suit les
#  hyperliens d'harmonie maximale.
# ============================================================================

"""
    ResultatRoutage

Le résultat d'un routage : le chemin retenu, son harmonie cumulée, et le registre.
"""
struct ResultatRoutage
    chemin   :: Vector{Symbol}
    harmonie :: Float64
    registre :: Vector{String}
end

trouve(r::ResultatRoutage) = !isempty(r.chemin)

"""Meilleure voie de `depart` à `arrivee` évitant les sites de `interdits` : celle dont
le produit des compatibilités `µ` des pas est maximal. Renvoie `(chemin, harmonie)` ;
en l'absence de voie, `(Symbol[], −1,0)`."""
function _meilleure_voie(G::Porteur, depart::Symbol, arrivee::Symbol, h::Harmonie,
                         interdits::AbstractVector{Symbol}, max_profondeur::Integer)
    meilleur = Symbol[]
    meilleure_h = -1.0
    explorer(chemin::Vector{Symbol}, hcum::Float64) = begin
        courant = chemin[end]
        if courant == arrivee
            if hcum > meilleure_h
                meilleure_h = hcum
                meilleur = copy(chemin)
            end
            return
        end
        length(chemin) >= max_profondeur && return
        for v in voisins(G, courant)
            haskey(G, v) || continue
            (v in interdits) && continue
            v in chemin && continue
            c = clamp(float(h.compatibilite(Figure([courant]), Figure([v]))), 0.0, 1.0)
            explorer(vcat(chemin, v), hcum * c)
        end
    end
    (depart in interdits) || explorer(Symbol[depart], 1.0)
    return meilleur, meilleure_h
end

"""
    routage_par_harmonie(G, depart, arrivee, h; max_profondeur = 32) -> ResultatRoutage

**Routage par harmonie** (chapitre 23). Retient, parmi les chemins simples du
porteur `G` allant de `depart` à `arrivee`, celui dont l'**harmonie cumulée** — le
produit des compatibilités `µ` des pas successifs — est maximale. Le routage
conserve une harmonie, non un compteur de sauts.
"""
function routage_par_harmonie(G::Porteur, depart::Symbol, arrivee::Symbol, h::Harmonie;
                              max_profondeur::Integer = 32)
    haskey(G, depart)  || throw(KeyError("site de départ non attesté : $depart"))
    haskey(G, arrivee) || throw(KeyError("site d'arrivée non attesté : $arrivee"))
    meilleur, meilleure_h = _meilleure_voie(G, depart, arrivee, h, Symbol[], max_profondeur)
    reg = isempty(meilleur) ?
        String["aucun chemin de $depart à $arrivee"] :
        String["chemin retenu : " * join(string.(meilleur), " → "),
               "harmonie cumulée : $(round(meilleure_h; digits = 4))"]
    return ResultatRoutage(meilleur, meilleure_h, reg)
end

"""
    ResultatResilience

Le résultat d'une pesée de résilience : la voie de contournement retenue, son harmonie
cumulée, le verdict de résilience et le registre.
"""
struct ResultatResilience
    chemin    :: Vector{Symbol}
    harmonie  :: Float64
    resilient :: Bool
    registre  :: Vector{String}
end

trouve(r::ResultatResilience) = !isempty(r.chemin)

"""
    resilience_par_pesee_locale(G, depart, arrivee, h; panne, seuil = 0.0, max_profondeur = 32)
        -> ResultatResilience

**Résilience par pesée locale** (méthode 23.2). Un site `panne` est retiré du porteur ;
on recherche localement, par pesée harmonique, une **voie de contournement** de `depart`
à `arrivee`. Le réseau est déclaré **résilient** si une telle voie subsiste et que son
harmonie cumulée atteint `seuil` — la résilience se pèse, elle ne se décrète pas.
"""
function resilience_par_pesee_locale(G::Porteur, depart::Symbol, arrivee::Symbol,
                                     h::Harmonie; panne::Symbol,
                                     seuil::Real = 0.0, max_profondeur::Integer = 32)
    haskey(G, depart)  || throw(KeyError("site de départ non attesté : $depart"))
    haskey(G, arrivee) || throw(KeyError("site d'arrivée non attesté : $arrivee"))
    haskey(G, panne)   || throw(KeyError("site en panne non attesté : $panne"))
    chemin, harmonie = _meilleure_voie(G, depart, arrivee, h, Symbol[panne], max_profondeur)
    resilient = !isempty(chemin) && harmonie >= float(seuil) - 1e-12
    reg = isempty(chemin) ?
        String["résilience : aucune voie de $depart à $arrivee évitant $panne"] :
        String["voie de contournement de $panne : " * join(string.(chemin), " → "),
               "harmonie cumulée : $(round(harmonie; digits = 4))",
               resilient ? "réseau résilient (seuil $seuil)" :
                           "seuil $seuil non atteint : non résilient"]
    return ResultatResilience(chemin, harmonie, resilient, reg)
end

"""
    ResultatProtocole

Le résultat d'une composition de protocole : les couches ordonnées par échelle, la
trame composée par `⊙`, l'accord cumulé, le verdict de conformité et le registre.
"""
struct ResultatProtocole
    couches  :: Vector{Symbol}
    trame    :: Figure
    harmonie :: Float64
    conforme :: Bool
    registre :: Vector{String}
end

Base.length(r::ResultatProtocole) = length(r.couches)

"""
    protocole_par_composition(G, couches, h) -> ResultatProtocole

**Protocole réseau par composition stratifiée** (méthode 23.3). Un protocole réseau est
une **figure stratifiée** (axiome A-K6) : chaque `couche` est un site du porteur, et son
**échelle** est sa profondeur dans la pile — du bas (liaison physique) vers le haut
(application). Le protocole exécute son **encapsulation** en composant ses couches par
`⊙` ; l'**accord** de la pile est l'harmonie cumulée — le produit des compatibilités `µ`
des couches contiguës.

Le protocole est **conforme** si sa stratification ne saute pas d'échelle (A-K6 : la
hiérarchie fractale ordonnée ne passe pas d'une couche à une couche non contiguë) et si
la trame porte exactement les liens que le porteur atteste (A-K7). Empiler l'application
directement sur le physique, ou deux couches de même échelle, n'est pas un protocole
conforme : c'est une pile dégénérée, et elle est **signalée** sans être rejetée.
"""
function protocole_par_composition(G::Porteur, couches::AbstractVector{Symbol}, h::Harmonie)
    isempty(couches) && throw(ArgumentError("un protocole porte au moins une couche"))
    uniques = Symbol[]
    vu = Set{Symbol}()
    for c in couches
        c in vu && continue
        push!(vu, c); push!(uniques, c)
    end
    for c in uniques
        haskey(G, c) || throw(KeyError("couche non attestée dans le porteur : $c"))
    end
    # ordre d'encapsulation : du bas (échelle la plus faible) vers le haut
    ordonnees = sort(uniques; by = c -> (site(G, c).echelle, c))
    trame = composer_cumule(Figure[Figure([c]) for c in ordonnees]; G = G)
    # accord : produit des compatibilités µ des couches contiguës
    harmonie = 1.0
    for k in 2:length(ordonnees)
        harmonie *= clamp(float(h.compatibilite(Figure([ordonnees[k - 1]]),
                                                Figure([ordonnees[k]]))), 0.0, 1.0)
    end
    # conformité : stratification sans saut d'échelle (A-K6) et trame close (A-K7)
    echelles = [site(G, c).echelle for c in ordonnees]
    sans_saut = (maximum(echelles) - minimum(echelles) + 1) == length(echelles)
    conforme = sans_saut && est_close(G, trame)
    registre = String[
        "protocole par composition : $(length(ordonnees)) couche(s)",
        "ordre d'encapsulation : " * join(string.(ordonnees), " → "),
        "échelles : " * join(string.(echelles), ", "),
        "accord cumulé : $(round(harmonie; digits = 4))",
        conforme ? "stratification contiguë (A-K6) : conforme" :
                   "saut d'échelle détecté (A-K6) : pile dégénérée, non conforme"]
    return ResultatProtocole(ordonnees, trame, harmonie, conforme, registre)
end

"""
    ResultatTransmission

Le résultat d'une transmission longue portée : le message réassemblé, l'harmonie de la
voie (le maillon le plus faible), le coût en relais, le rendement mesuré, le verdict
d'intégrité et le registre.
"""
struct ResultatTransmission
    message   :: Figure
    harmonie  :: Float64
    cout      :: Int
    rendement :: Float64
    integre   :: Bool
    registre  :: Vector{String}
end

Base.length(r::ResultatTransmission) = length(r.message.sites)

"""
    transmission_longue_portee(G, message, depart, arrivee, h; capacite = 1, max_profondeur = 64)
        -> ResultatTransmission

**Transmission longue portée par fragmentation harmonique** (méthode 23.4). Le `message`
est une figure de `G` : ses sites sont les **unités de contenu** — les trames d'une voix,
les tuiles d'une image. Le lien longue portée ne porte qu'une charge utile bornée, dite
`capacite` : le message est **fragmenté** en tranches consécutives d'au plus `capacite`
sites, chaque fragment suit la **voie d'harmonie maximale** de `depart` à `arrivee`
(méthode 23.1), et les fragments sont **réassemblés** par `⊙` à l'arrivée — aucun site de
contenu n'est perdu.

L'**efficacité** est **mesurée**, jamais revendiquée : le `rendement` vaut
`sites utiles livrés / relais consommés`. Porter un gros contenu se paie donc en relais,
et c'est la **fragmentation harmonique** qui rend la chose possible : chaque fragment paie
sa traversée, mais tous empruntent la même voie — la plus haute en harmonie. Une capacité
plus large réduit le nombre de fragments, donc le coût, donc accroît le rendement.

**Réserve d'honnêteté.** Cette méthode **ne revendique aucun débit physique**. Un lien
longue portée réel (LoRa et ses pareils) porte une charge utile de l'ordre de quelques
centaines d'octets par message et un débit de quelques kilobits par seconde ; porter un
gros contenu (voix, image) ne se fait donc pas d'un bond, mais par la **fragmentation**,
la **voie harmonique** et la **recomposition** — et l'on ne répond que du rendement
ci-dessus, mesuré sur l'exécution.
"""
function transmission_longue_portee(G::Porteur, message::Figure, depart::Symbol,
                                    arrivee::Symbol, h::Harmonie;
                                    capacite::Integer = 1, max_profondeur::Integer = 64)
    isempty(message) && throw(ArgumentError("aucun contenu à transmettre"))
    capacite >= 1 || throw(ArgumentError("la capacité d'un lien est un entier ≥ 1"))
    haskey(G, depart)  || throw(KeyError("site de départ non attesté : $depart"))
    haskey(G, arrivee) || throw(KeyError("site d'arrivée non attesté : $arrivee"))
    sites = message.sites
    n = length(sites)
    for s in sites
        haskey(G, s) || throw(KeyError("site de contenu non attesté dans le porteur : $s"))
    end
    n_frag = cld(n, capacite)
    registre = String["transmission longue portée : $n site(s) de contenu → $n_frag fragment(s) " *
                      "de capacité $capacite, voie de $depart à $arrivee"]
    livrees = Figure[]
    harmonie = 1.0
    cout = 0
    complet = true
    for k in 1:n_frag
        i0 = (k - 1) * capacite + 1
        fragment = Figure(sites[i0:min(i0 + capacite - 1, n)])
        chemin, hfr = _meilleure_voie(G, depart, arrivee, h, Symbol[], max_profondeur)
        if isempty(chemin)
            complet = false
            push!(registre, "fragment $k ($(length(fragment)) site(s)) : aucune voie — perdu")
            continue
        end
        push!(livrees, fragment)
        harmonie = k == 1 ? hfr : min(harmonie, hfr)
        cout += length(chemin) - 1
        push!(registre, "fragment $k ($(length(fragment)) site(s)) → " *
                        join(string.(chemin), " → ") * " (harmonie $(round(hfr; digits = 4)))")
    end
    isempty(livrees) && (harmonie = 0.0)
    message_recompose = isempty(livrees) ? figure_vide() : composer_cumule(livrees)
    integre = complet && length(message_recompose.sites) == n
    rendement = cout == 0 ? 0.0 : length(message_recompose.sites) / cout
    push!(registre, "message recomposé : $(length(message_recompose.sites)) site(s) ; " *
                    "coût $cout relais ; rendement $(round(rendement; digits = 4)) site(s)/relais")
    return ResultatTransmission(message_recompose, harmonie, cout, rendement, integre, registre)
end

# ----------------------------------------------------------------------------
#  Toile par figures  (méthode 23.5)
# ----------------------------------------------------------------------------
#  Le web actuel résout des noms par une racine globale, relie des pages par des
#  hyperliens, et laisse un client naviguer. La toile kamitique lit ces trois fonctions
#  dans le socle : un document est un site (son `lieu` est son adresse, ses `voisins`
#  sont ses hyperliens), une adresse se résout par pesée de voisinage — non par un
#  registre central —, et l'on navigue en suivant les hyperliens d'harmonie maximale.
#  Comme un site ne porte aucune valeur (A-K1), la toile est indifférente au type
#  d'application : texte, image, son ou code s'y traitent de même.

"""
    lier!(G, a, b) -> Porteur

Atteste un **hyperlien** entre les documents `a` et `b` : le voisinage étant symétrique
(déf. 5.1), l'hyperlien se pose dans les deux sens. C'est la seule écriture que la toile
ajoute au porteur — un lien non attesté n'existe pas (A-K7).
"""
function lier!(G::Porteur, a::Symbol, b::Symbol)
    haskey(G, a) || throw(KeyError("document non attesté : $a"))
    haskey(G, b) || throw(KeyError("document non attesté : $b"))
    a == b && throw(ArgumentError("un hyperlien relie deux documents distincts"))
    sa, sb = site(G, a), site(G, b)
    a in sb.voisins || push!(sb.voisins, a)
    b in sa.voisins || push!(sa.voisins, b)
    return G
end

"""
    ResultatResolution

Le résultat d'une résolution d'adresse : l'adresse demandée, le document retenu (ou
`nothing`), les documents candidats, l'harmonie de résolution et le registre.
"""
struct ResultatResolution
    adresse   :: String
    document  :: Union{Symbol, Nothing}
    candidats :: Vector{Symbol}
    harmonie  :: Float64
    registre  :: Vector{String}
end

Base.length(r::ResultatResolution) = length(r.candidats)
trouve(r::ResultatResolution) = r.document !== nothing

"""
    resoudre_adresse(G, adresse, h; depuis = nothing) -> ResultatResolution

**Résolution d'adresse par pesée de voisinage** (méthode 23.5). Une **adresse** est un
`lieu` : tous les documents de `G` qui le portent sont candidats (`length` du résultat).
Sans requérant (`depuis = nothing`), le document d'identifiant minimal est retenu (choix
canonique, indépendant de l'ordre d'itération du porteur). Avec un requérant, c'est le
candidat **le plus harmonieux** vis-à-vis de lui qui l'emporte : la résolution est
**relationnelle** — un même nom peut désigner des documents distincts selon qui le
demande —, là où le web résout par une racine globale unique.
"""
function resoudre_adresse(G::Porteur, adresse::AbstractString, h::Harmonie;
                          depuis::Union{Symbol, Nothing} = nothing)
    (depuis !== nothing && !haskey(G, depuis)) &&
        throw(KeyError("document requérant non attesté : $depuis"))
    cible = String(adresse)
    candidats = Symbol[]
    for id in identifiants(G)
        lieu = site(G, id).lieu
        lieu === nothing && continue
        string(lieu) == cible && push!(candidats, id)
    end
    sort!(candidats)               # ordre canonique : indépendant de l'itération du Dict
    if isempty(candidats)
        return ResultatResolution(cible, nothing, Symbol[], 0.0,
            String["adresse « $cible » : aucun document attesté"])
    end
    retenu = candidats[1]
    harmonie = 1.0
    if depuis !== nothing
        harmonie = -1.0
        for c in candidats
            k = clamp(float(h.compatibilite(Figure([depuis]), Figure([c]))), 0.0, 1.0)
            if k > harmonie
                harmonie = k
                retenu = c
            end
        end
    end
    reg = String[
        "adresse « $cible » : $(length(candidats)) document(s) attesté(s)",
        depuis === nothing ?
            "document retenu : $retenu (identifiant minimal, sans requérant)" :
            "document retenu : $retenu (le plus harmonieux depuis $depuis)",
        "harmonie de résolution : $(round(harmonie; digits = 4))"]
    return ResultatResolution(cible, retenu, candidats, harmonie, reg)
end

"""
    ResultatNavigation

Le résultat d'une navigation : les documents traversés, la figure (close) qu'ils
forment, l'harmonie cumulée de la traversée et le registre.
"""
struct ResultatNavigation
    chemin   :: Vector{Symbol}
    figure   :: Figure
    harmonie :: Float64
    registre :: Vector{String}
end

Base.length(r::ResultatNavigation) = length(r.chemin)
trouve(r::ResultatNavigation) = !isempty(r.chemin)

"""
    naviguer_toile(G, depart, arrivee, h; max_profondeur = 64) -> ResultatNavigation

**Navigation par hyperliens** (méthode 23.5). On va d'un document à l'autre en suivant
les **hyperliens attestés** (les `voisins`), et l'on retient la traversée dont
l'**harmonie cumulée** — le produit des compatibilités `µ` des sauts — est maximale :
c'est [`routage_par_harmonie`](@ref) appliqué au graphe des documents. La figure rendue
est la **clôture** (A-K7) des documents traversés : elle porte exactement leurs
hyperliens situés. En l'absence d'hyperlien menant à l'arrivée, le chemin est vide, la
figure est vide et l'harmonie est nulle.
"""
function naviguer_toile(G::Porteur, depart::Symbol, arrivee::Symbol, h::Harmonie;
                        max_profondeur::Integer = 64)
    haskey(G, depart)  || throw(KeyError("document de départ non attesté : $depart"))
    haskey(G, arrivee) || throw(KeyError("document d'arrivée non attesté : $arrivee"))
    chemin, harmonie = _meilleure_voie(G, depart, arrivee, h, Symbol[], max_profondeur)
    if isempty(chemin)
        return ResultatNavigation(Symbol[], figure_vide(), 0.0,
            String["navigation de $depart à $arrivee : aucun hyperlien ne les relie"])
    end
    figure = cloture(G, Figure(chemin))
    reg = String[
        "navigation de $depart à $arrivee : $(length(chemin) - 1) saut(s)",
        "documents traversés : " * join(string.(chemin), " → "),
        "harmonie cumulée : $(round(harmonie; digits = 4))"]
    return ResultatNavigation(chemin, figure, harmonie, reg)
end
