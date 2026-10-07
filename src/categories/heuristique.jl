# ============================================================================
#  Recherche heuristique et systèmes experts kamitiques  (chapitre 29)
# ----------------------------------------------------------------------------
#  « pesée de promesse, inférence gouvernée ». Explorer, c'est peser : chaque voie
#  porte une promesse π(g) ; une promesse nulle est écartée, non tue en silence.
#  L'inférence n'est admise que si son épreuve d'explicabilité est franchie.
# ============================================================================

"""
    ResultatRechercheHeuristique

Le résultat d'une recherche par pesée de promesse : le chemin retenu, sa promesse et
le registre.
"""
struct ResultatRechercheHeuristique
    chemin   :: Vector{Symbol}
    promesse :: Float64
    registre :: Vector{String}
end

trouve(r::ResultatRechercheHeuristique) = !isempty(r.chemin)

"""
    recherche_par_pesee_de_promesse(G, depart, but, h; heuristique, max_noeuds, invariant)
        -> ResultatRechercheHeuristique

**Recherche par pesée de promesse** (méthode 29.1). Exploration par meilleure promesse
d'abord : chaque voie porte une promesse cumulée — produit des compatibilités `µ` et de
l'`heuristique` du site. On développe toujours la voie de plus haute promesse ; une voie
de promesse nulle est **écartée en le consignant**, jamais tue en silence. Le résultat
rend le chemin et sa promesse.

Lorsque `invariant = true`, l'**invariant de signature** (axiome A-K4⁺) élague l'espace
de recherche : un pas admissible ne suit que des voisinages attestés, donc ne peut jamais
changer de composante connexe (`β₀`). Si `but` n'est pas dans la composante de `depart`,
aucune voie n'existe — l'espace est élagué **sans développer un seul nœud**, et le
registre le consigne. Cet élagage est **exact** (il ne coupe aucune solution).
"""
function recherche_par_pesee_de_promesse(G::Porteur, depart::Symbol, but::Symbol,
                                         h::Harmonie;
                                         heuristique::Function = _ -> 1.0,
                                         max_noeuds::Integer = 256,
                                         invariant::Bool = false)
    haskey(G, depart) || throw(KeyError("site de départ non attesté : $depart"))
    haskey(G, but)    || throw(KeyError("site de but non attesté : $but"))
    registre = String["recherche par pesée de promesse"]
    if invariant && !meme_composante(G, depart, but)
        push!(registre, "invariant A-K4⁺ : $but hors de la composante de $depart — " *
                        "espace élagué, 0 nœud développé (aucune solution coupée)")
        return ResultatRechercheHeuristique(Symbol[], 0.0, registre)
    end
    frontiere = Tuple{Vector{Symbol},Float64}[(Symbol[depart], 1.0)]
    visite = Set{Symbol}([depart])
    explored = 0
    while !isempty(frontiere) && explored < max_noeuds
        ibest = 1
        for k in 2:length(frontiere)
            frontiere[k][2] > frontiere[ibest][2] && (ibest = k)
        end
        chemin, prom = frontiere[ibest]
        deleteat!(frontiere, ibest)
        courant = chemin[end]
        explored += 1
        if courant == but
            push!(registre, "but atteint : promesse $(round(prom; digits = 4)), $explored nœud(s) développé(s)")
            return ResultatRechercheHeuristique(chemin, prom, registre)
        end
        for v in voisins(G, courant)
            haskey(G, v) || continue
            v in visite && continue
            c = clamp(float(h.compatibilite(Figure([courant]), Figure([v]))), 0.0, 1.0)
            pv = prom * c * clamp(float(heuristique(v)), 0.0, 1.0)
            if pv <= 0.0
                push!(registre, "voie vers $v écartée (promesse nulle)")
                continue
            end
            push!(frontiere, (vcat(chemin, v), pv))
            push!(visite, v)
        end
    end
    push!(registre, "but non atteint en $explored nœud(s)")
    return ResultatRechercheHeuristique(Symbol[], 0.0, registre)
end

"""
    IndexPesee(G, h) -> IndexPesee

**Index précalculé** de la recherche par pesée de promesse (méthode 29.1).

La recherche par pesée de promesse est une exploration *répétée* : une même question
(« quelle voie mène de `depart` à `but` ? ») est posée sur le même cosmos `K = (G, ⊙, ≺, µ)`
avec la même harmonie `h`. Or la boucle recalculait, **à chaque arête développée**, la
compatibilité `µ` de ses deux figures et, à chaque requête, la partition `β₀` du porteur.
L'index fixe une fois pour toutes ce qui ne dépend ni de `depart` ni de `but` :

- `ids` : les identifiants de sites, dans l'ordre d'insertion (l'ordre du `Dict`) ;
- `posi` : l'index inverse `identifiant → rang` ;
- `liens` : pour chaque site, la liste `(rang du voisin attesté, µ)` des arêtes sortantes,
  dans l'ordre de [`voisins`](@ref) — la compatibilité étant précalculée et bornée à `[0, 1]` ;
- `composantes` : la partition `β₀` ([`composantes_connexes`](@ref)), qui sert à
  l'élagage par l'[invariant de signature](@ref Signature) (`A-K4⁺`) sans un parcours de
  `G` par requête.

Le précalcul est **hors** de la boucle de recherche : il ne change aucun chiffre consigné
(`G5`) — il rend seulement la boucle frugale (`εF`). Sa construction est `O(|G| + |E|)` et
n'est rentable que réutilisée (cf. [`recherche_par_pesee_de_promesse`](@ref) sur `IndexPesee`).

Réserve de fidélité : l'index suppose `h.compatibilite` **pure** — la valeur d'une figure
ne dépend que de son contenu, non de son identité. C'est le cas de
[`compatibilite_raffinement`](@ref), comme de toute compatibilité définie par la définition 5.6.
"""
struct IndexPesee
    ids         :: Vector{Symbol}
    posi        :: Dict{Symbol,Int}
    liens       :: Vector{Vector{Tuple{Int,Float64}}}
    composantes :: Dict{Symbol,Int}
end

function IndexPesee(G::Porteur, h::Harmonie)
    ids = identifiants(G)
    n = length(ids)
    posi = Dict{Symbol,Int}()
    sizehint!(posi, n)
    for (i, s) in enumerate(ids)
        posi[s] = i
    end
    liens = Vector{Vector{Tuple{Int,Float64}}}(undef, n)
    for i in 1:n
        s = ids[i]
        fs = Figure([s])
        acc = Tuple{Int,Float64}[]
        for v in G.sites[s].voisins
            j = get(posi, v, 0)
            j == 0 && continue                      # voisin non attesté : hors porteur
            push!(acc, (j, clamp(float(h.compatibilite(fs, Figure([v]))), 0.0, 1.0)))
        end
        liens[i] = acc
    end
    return IndexPesee(ids, posi, liens, composantes_connexes(G))
end

"""Nombre de sites indexés."""
Base.length(idx::IndexPesee) = length(idx.ids)

"""
    recherche_par_pesee_de_promesse(idx::IndexPesee, depart, but; heuristique, max_noeuds, invariant)
        -> ResultatRechercheHeuristique

**Recherche par pesée de promesse amortie** (méthode 29.1) : la variante de
[`recherche_par_pesee_de_promesse`](@ref) qui consomme un [`IndexPesee`](@ref) précalculé.

Elle rend **exactement** ce que rend la forme directe sur `(G, h)` — même exploration,
donc même `chemin`, même `promesse` et même `registre` (jusqu'aux messages
« promesse nulle » et « but non atteint »). Seules les allocations disparaissent : les
compatibilités `µ` ne sont plus recalculées par arête, le chemin n'est plus recopié par
`vcat` mais reconstruit par pointeurs parents, la visite est un `BitVector` et la
frontière des tuples de types primitifs (`Float64`, `Int`).

L'`index` est construit **une fois** par `(G, h)` puis réutilisé pour toutes les requêtes :
c'est là que se trouve le gain, non dans un appel isolé.

Comme la forme directe, `invariant = true` (axiome `A-K4⁺`) élague l'espace de recherche :
si `but` n'est pas dans la composante `β₀` de `depart`, aucun nœud n'est développé et le
registre le consigne. La partition étant précalculée dans l'index, la garde n'y coûte
aucun parcours supplémentaire.
"""
function recherche_par_pesee_de_promesse(idx::IndexPesee, depart::Symbol, but::Symbol;
                                         heuristique::Function = _ -> 1.0,
                                         max_noeuds::Integer = 256,
                                         invariant::Bool = false)
    haskey(idx.posi, depart) || throw(KeyError("site de départ non attesté : $depart"))
    haskey(idx.posi, but)    || throw(KeyError("site de but non attesté : $but"))
    registre = String["recherche par pesée de promesse"]
    if invariant && idx.composantes[depart] != idx.composantes[but]
        push!(registre, "invariant A-K4⁺ : $but hors de la composante de $depart — " *
                        "espace élagué, 0 nœud développé (aucune solution coupée)")
        return ResultatRechercheHeuristique(Symbol[], 0.0, registre)
    end
    si = idx.posi[depart]
    ti = idx.posi[but]
    visite = falses(length(idx.ids))
    parent = zeros(Int, length(idx.ids))
    visite[si] = true
    frontiere = Tuple{Float64,Int}[(1.0, si)]
    explored = 0
    while !isempty(frontiere) && explored < max_noeuds
        ibest = 1
        @inbounds for k in 2:length(frontiere)
            frontiere[k][1] > frontiere[ibest][1] && (ibest = k)
        end
        prom, courant = frontiere[ibest]
        deleteat!(frontiere, ibest)
        explored += 1
        if courant == ti
            chemin = Symbol[]
            k = courant
            while k != 0
                push!(chemin, idx.ids[k]); k = parent[k]
            end
            reverse!(chemin)
            push!(registre, "but atteint : promesse $(round(prom; digits = 4)), $explored nœud(s) développé(s)")
            return ResultatRechercheHeuristique(chemin, prom, registre)
        end
        @inbounds for (j, c) in idx.liens[courant]
            visite[j] && continue
            pv = prom * c * clamp(float(heuristique(idx.ids[j])), 0.0, 1.0)
            if pv <= 0.0
                push!(registre, "voie vers $(idx.ids[j]) écartée (promesse nulle)")
                continue
            end
            push!(frontiere, (pv, j))
            visite[j] = true
            parent[j] = courant
        end
    end
    push!(registre, "but non atteint en $explored nœud(s)")
    return ResultatRechercheHeuristique(Symbol[], 0.0, registre)
end

"""
    TasMaxima

File de priorité binaire (tas-max) du champ d'attraction : couples `(valeur, sommet)`
ordonnés par valeur décroissante. Deux vecteurs parallèles de types primitifs —
aucune allocation par élément.
"""
struct TasMaxima
    valeurs :: Vector{Float64}
    sommets :: Vector{Int}
end

TasMaxima() = TasMaxima(Float64[], Int[])
Base.isempty(t::TasMaxima) = isempty(t.valeurs)

function _tas_pousse!(t::TasMaxima, valeur::Float64, sommet::Int)
    v = t.valeurs; s = t.sommets
    push!(v, valeur); push!(s, sommet)
    i = length(v)
    while i > 1
        p = i >> 1
        v[p] >= v[i] && break
        v[p], v[i] = v[i], v[p]
        s[p], s[i] = s[i], s[p]
        i = p
    end
    return nothing
end

function _tas_retire_max!(t::TasMaxima)
    v = t.valeurs; s = t.sommets
    valeur = v[1]; sommet = s[1]
    n = length(v)
    v[1] = v[n]; s[1] = s[n]
    pop!(v); pop!(s)
    n -= 1
    i = 1
    while true
        g = 2i; d = g + 1; m = i
        g <= n && v[g] > v[m] && (m = g)
        d <= n && v[d] > v[m] && (m = d)
        m == i && break
        v[m], v[i] = v[i], v[m]
        s[m], s[i] = s[i], s[m]
        i = m
    end
    return valeur, sommet
end

# --- outils du champ d'attraction -------------------------------------------

"""Compatibilité `µ` de l'arête `i → j` dans l'index (`0.0` si l'arête n'existe pas)."""
function _compat_lien(idx::IndexPesee, i::Int, j::Int)
    @inbounds for (k, c) in idx.liens[i]
        k == j && return c
    end
    return 0.0
end

"""
    _hvals(idx, heuristique) -> Vector{Float64}

Les valeurs du facteur `heuristique`, **par site**, bornées à `[0, 1]` — précalculées
une fois (`O(V)`). Le champ les **retient** plutôt que la fonction : la descente et la
remontée lisent alors un `Vector{Float64}` (typé, sans dispatch dynamique), ce qui
préserve la frugalité `εF` du chemin de reconstruction.
"""
function _hvals(idx::IndexPesee, heuristique::Function)
    n = length(idx.ids)
    h = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        h[i] = clamp(float(heuristique(idx.ids[i])), 0.0, 1.0)
    end
    return h
end

"""
    _atteint(idx, de, vers) -> Bool

Existe-t-il une **chaîne dirigée** `de → vers` dans les arêtes attestées, la
compatibilité `µ` étant **ignorée** ? Parcours en largeur itératif, `O(E)`.

Sert à lever l'ambiguïté d'une promesse nulle : distinguer « aucune chaîne » (hors du
bassin) de « une chaîne existe, mais elle porte une arête de `µ = 0` » (cf.
[`hors_bassin`](@ref)).
"""
function _atteint(idx::IndexPesee, de::Int, vers::Int)
    de == vers && return true
    vus = falses(length(idx.ids))
    vus[de] = true
    pile = Int[de]
    while !isempty(pile)
        i = pop!(pile)
        @inbounds for (j, _) in idx.liens[i]
            j == vers && return true
            vus[j] && continue
            vus[j] = true
            push!(pile, j)
        end
    end
    return false
end

"""
    ChampMaat

Le **champ d'attraction de Maât** vers un site `but` : pour chaque site `x` du porteur,

    valeur[x] = max Σ_chemins(x → but) Π µ(arêtes) · Π heuristique(nœuds),

la meilleure promesse atteignable de `x` à `but` (`succ[x]` en donne le successeur
optimal, `0.0` marque l'extérieur du bassin). Le facteur `heuristique` est appliqué à
**tous les sites sauf le point de départ** — exactement la convention de
[`recherche_par_pesee_de_promesse`](@ref).

Le champ matérialise l'axiome `A4` (Maât) : l'attracteur étant **unique** et
strictement séparé (`m_gap > 0`), l'optimum est un **point fixe** — il se *calcule*,
il ne s'explore pas. Le champ est un maximum au sens du semi-anneau `(max, ×)` : la
promesse d'un chemin étant un **produit** de compatibilités, elle se compose pas à pas.

L'`heuristique` est **retenue dans le champ**, sous forme **précalculée** (`hval`, un
`Vector{Float64}` par site) : elle sert à la descente pour **recomposer** la promesse de
gauche à droite (identique au bit près à l'exploration, cf. [`descente_par_champ`](@ref)),
sans dispatch dynamique.
"""
struct ChampMaat
    index    :: IndexPesee
    but      :: Symbol
    valeur   :: Vector{Float64}
    succ     :: Vector{Int}
    hval     :: Vector{Float64}
    registre :: Vector{String}
end

"""
    champ_vers(idx::IndexPesee, but; heuristique = _ -> 1.0) -> ChampMaat
    champ_vers(G::Porteur, h::Harmonie, but; heuristique = _ -> 1.0) -> ChampMaat

**Champ d'attraction de Maât** vers `but` (axiome `A4`) : une **seule passe** arrière
depuis `but`, au sens du semi-anneau `(max, ×)` — un Dijkstra de fiabilité maximale, de
complexité `O(E log V)`. On en tire ensuite, **pour toutes les sources à la fois**, la
meilleure promesse et le chemin optimal ([`descente_par_champ`](@ref), `O(L)` par requête).

C'est le remplacement exact de l'exploration par un **calcul de point fixe** ; trois
principes de la théorie de base s'y conjuguent :

- `A4` (Maât) : l'attracteur est unique — donc **calculable**, sans exploration ;
- la compatibilité de deux sites **distincts** n'est jamais un emboîtement, donc
  `µ ≤ c_max < 1` : la promesse décroît **géométriquement** en nombre de pas, ce qui rend
  la borne du champ admissible et la passe déterministe (pas d'égalité, `m_gap > 0`) ;
- `A-K4⁺` (invariant de signature) : les sites hors du bassin reçoivent `valeur = 0` — un
  élagage `β₀` **exact** obtenu de surcroît, sans le parcours `O(|G|)` par requête de la garde.

L'objectif maximisé est le **coût descriptif** d'un chemin (`T-K5`, frugalité structurelle) :
à compatibilité constante, la promesse ne dépend que du **nombre de pas**.

Réserve de fidélité : la valeur rendue coïncide avec celle de la recherche par pesée de
promesse à la **réassociation flottante** près (produit évalué de la droite vers la gauche
ici, de la gauche vers la droite dans la recherche), non au bit près.
"""
function champ_vers(idx::IndexPesee, but::Symbol; heuristique::Function = _ -> 1.0)
    haskey(idx.posi, but) || throw(KeyError("site de but non attesté : $but"))
    n = length(idx.ids)
    ti = idx.posi[but]
    # arêtes inversées : le champ se construit en arrière, de `but` vers toute source
    rev = [Tuple{Int,Float64}[] for _ in 1:n]
    for i in 1:n
        for (j, c) in idx.liens[i]
            push!(rev[j], (i, c))
        end
    end
    valeur = zeros(Float64, n)
    succ = zeros(Int, n)
    hval = _hvals(idx, heuristique)
    valeur[ti] = 1.0                      # promesse du chemin vide, `heuristique` comprise
    tas = TasMaxima()
    _tas_pousse!(tas, 1.0, ti)
    relaxations = 0
    while !isempty(tas)
        val, j = _tas_retire_max!(tas)
        val < valeur[j] && continue                       # entrée périmée : sommet déjà amélioré
        hj = hval[j]
        for (i, c) in rev[j]
            relaxations += 1
            pv = c * hj * val
            if pv > valeur[i]
                valeur[i] = pv
                succ[i] = j
                _tas_pousse!(tas, pv, i)
            end
        end
    end
    bassin = count(>(0.0), valeur)
    registre = String["champ d'attraction de Maât vers $but",
                      "bassin : $bassin site(s) sur $n ; $relaxations arête(s) relaxée(s) " *
                      "en une passe — 0 nœud développé"]
    return ChampMaat(idx, but, valeur, succ, hval, registre)
end

champ_vers(G::Porteur, h::Harmonie, but::Symbol; heuristique::Function = _ -> 1.0) =
    champ_vers(IndexPesee(G, h), but; heuristique = heuristique)

"""
    ChampDepuis

Le **champ d'attraction de Maât** *depuis* un site `source` — le **dual** de
[`ChampMaat`](@ref) : pour chaque site `y` du porteur,

    valeur[y] = max Σ_chemins(source → y) Π µ(arêtes) · Π heuristique(nœuds),

la meilleure promesse atteignable *de `source` vers `y`* (`pred[y]` en donne le
prédécesseur optimal, `0.0` marque l'extérieur du champ).

`ChampMaat` amortit **une** passe sur **toutes les sources** vers **une** cible ;
`ChampDepuis` amortit **une** passe sur **une** source vers **toutes les cibles**. Les
deux motifs coûtent donc `O(E log V)` **chacun**, et non `O(V · E log V)` : le champ est
**directionnel** — une passe **par racine** (la cible vers l'arrière, la source vers
l'avant), amortie sur **toutes** les autres extrémités.
"""
struct ChampDepuis
    index    :: IndexPesee
    source   :: Symbol
    valeur   :: Vector{Float64}
    pred     :: Vector{Int}
    hval     :: Vector{Float64}
    registre :: Vector{String}
end

"""
    champ_depuis(idx::IndexPesee, source; heuristique = _ -> 1.0) -> ChampDepuis
    champ_depuis(G::Porteur, h::Harmonie, source; heuristique = _ -> 1.0) -> ChampDepuis

**Champ d'attraction de Maât *depuis* `source`** (axiome `A4`) : une **seule passe**
*avant* depuis `source`, au sens du semi-anneau `(max, ×)` — le **dual** de
[`champ_vers`](@ref), couvrant le motif « **une source → toutes les cibles** ». On en
tire ensuite, **pour toutes les cibles à la fois**, la meilleure promesse
([`promesse_depuis`](@ref), `O(1)`) et le chemin optimal ([`chemin_depuis`](@ref),
`O(L)` par requête).

La passe **avant** relaxe chaque arête sortante `(j, c)` de l'index :
`valeur[j] = max(valeur[j], valeur[i] · c · heuristique(j))`. Elle n'applique `µ` **que**
sur les arêtes attestées, tout comme [`champ_vers`](@ref) — le facteur `heuristique` est
appliqué à **tous les sites sauf la source**, exactement la convention de
[`recherche_par_pesee_de_promesse`](@ref).
"""
function champ_depuis(idx::IndexPesee, source::Symbol; heuristique::Function = _ -> 1.0)
    haskey(idx.posi, source) || throw(KeyError("site de source non attesté : $source"))
    n = length(idx.ids)
    si = idx.posi[source]
    valeur = zeros(Float64, n)
    pred = zeros(Int, n)
    hval = _hvals(idx, heuristique)
    valeur[si] = 1.0                      # promesse du chemin vide, `heuristique` comprise
    tas = TasMaxima()
    _tas_pousse!(tas, 1.0, si)
    relaxations = 0
    while !isempty(tas)
        val, i = _tas_retire_max!(tas)
        val < valeur[i] && continue                       # entrée périmée : sommet déjà amélioré
        for (j, c) in idx.liens[i]
            relaxations += 1
            pv = val * c * hval[j]
            if pv > valeur[j]
                valeur[j] = pv
                pred[j] = i
                _tas_pousse!(tas, pv, j)
            end
        end
    end
    bassin = count(>(0.0), valeur)
    registre = String["champ d'attraction de Maât depuis $source",
                      "bassin : $bassin site(s) sur $n ; $relaxations arête(s) relaxée(s) " *
                      "en une passe — 0 nœud développé"]
    return ChampDepuis(idx, source, valeur, pred, hval, registre)
end

champ_depuis(G::Porteur, h::Harmonie, source::Symbol; heuristique::Function = _ -> 1.0) =
    champ_depuis(IndexPesee(G, h), source; heuristique = heuristique)

"""
    promesse_optimale(champ::ChampMaat, depart) -> Float64

La meilleure promesse de `depart` vers la cible du champ — `0.0` si le but est hors du
bassin de `depart`. Lecture en `O(1)`, sans développement.

C'est la valeur **du champ** (produit évalué de la droite vers la gauche, de `but` vers
`depart`). Pour la promesse **recomposée de la gauche vers la droite** — identique au bit
près à [`recherche_par_pesee_de_promesse`](@ref) sur le même chemin — voir
[`descente_par_champ`](@ref).
"""
function promesse_optimale(champ::ChampMaat, depart::Symbol)
    haskey(champ.index.posi, depart) || throw(KeyError("site de départ non attesté : $depart"))
    return champ.valeur[champ.index.posi[depart]]
end

"""
    hors_bassin(champ::ChampMaat, depart) -> Bool

`true` si `depart` **ne peut atteindre** le but du champ par **aucune chaîne dirigée**
d'arêtes attestées — la compatibilité `µ` étant **ignorée**. Parcours `O(E)`, hors du
chemin critique : `champ_vers` n'en paie rien.

Lève l'ambiguïté d'une promesse nulle (`valeur = 0`, cause exactement deux cas) :

- **hors du bassin** (`hors_bassin = true`) : aucune chaîne dirigée `depart → but` — le
  but n'est pas dans l'univers de `depart` ;
- **promesse nulle** (`hors_bassin = false`) : une chaîne existe, mais **toutes** portent
  une arête de `µ = 0` — configuration **inadmissible** sous l'hypothèse `κ ∈ (0, 1]` de
  `A4` (compatibilités strictement positives), et dès lors *refusée*, non confondue.
"""
function hors_bassin(champ::ChampMaat, depart::Symbol)
    haskey(champ.index.posi, depart) || throw(KeyError("site de départ non attesté : $depart"))
    idx = champ.index
    return !_atteint(idx, idx.posi[depart], idx.posi[champ.but])
end

"""
    descente_par_champ(champ::ChampMaat, depart) -> ResultatRechercheHeuristique

Le chemin **optimal** de `depart` à `champ.but`, lu par **descente du champ** : un pas
par arête, `O(L)`, sans frontière ni nœud développé. Le chemin est **certifié optimal** au
sens du produit des compatibilités, ce que la forme exploratoire ne garantit pas.

La promesse rendue est **recomposée de gauche à droite** le long du chemin (de `depart`
vers `but`), dans le **même ordre d'évaluation** que
[`recherche_par_pesee_de_promesse`](@ref) : elle lui est donc **identique au bit près**
sur un même chemin (résout la réserve « à la réassociation flottante près »).

Lorsque la promesse du champ est nulle, [`hors_bassin`](@ref) distingue les deux causes —
« hors du bassin » (aucune chaîne) et « promesse nulle » (chaîne à arête `µ = 0`).

Le type rendu est [`ResultatRechercheHeuristique`](@ref) — la descente est un
remplacement direct de la recherche, `trouve` et `.chemin` compris.
"""
function descente_par_champ(champ::ChampMaat, depart::Symbol)
    haskey(champ.index.posi, depart) || throw(KeyError("site de départ non attesté : $depart"))
    idx = champ.index
    registre = String["descente par champ d'attraction de Maât (cible $(champ.but))"]
    si = idx.posi[depart]
    if champ.valeur[si] <= 0.0
        if hors_bassin(champ, depart)
            push!(registre, "but non atteint : $depart hors du bassin de $(champ.but) " *
                            "— aucune chaîne dirigée (champ précalculé, 0 nœud développé)")
        else
            push!(registre, "$depart atteint $(champ.but) par une chaîne attestée, mais " *
                            "promesse nulle : toutes les chaînes portent une arête de " *
                            "compatibilité `µ = 0` — configuration inadmissible sous " *
                            "`κ ∈ (0, 1]` (A4) ; voie refusée")
        end
        return ResultatRechercheHeuristique(Symbol[], 0.0, registre)
    end
    ti = idx.posi[champ.but]
    chemin = Symbol[depart]
    p = 1.0                                   # recomposition gauche→droite = exploration
    k = si
    while k != ti
        j = champ.succ[k]
        p = (p * _compat_lien(idx, k, j)) * champ.hval[j]
        k = j
        push!(chemin, idx.ids[k])
    end
    push!(registre, "but atteint : promesse $(round(p; digits = 4)), $(length(chemin) - 1) pas " *
                    "(champ précalculé, 0 nœud développé)")
    return ResultatRechercheHeuristique(chemin, p, registre)
end

"""
    promesse_depuis(champ::ChampDepuis, cible) -> Float64

La meilleure promesse de la source du champ vers `cible` — `0.0` si `cible` est hors du
champ. Lecture en `O(1)`, sans développement. Dual de [`promesse_optimale`](@ref).
"""
function promesse_depuis(champ::ChampDepuis, cible::Symbol)
    haskey(champ.index.posi, cible) || throw(KeyError("site de cible non attesté : $cible"))
    return champ.valeur[champ.index.posi[cible]]
end

"""
    hors_bassin(champ::ChampDepuis, cible) -> Bool

`true` si `cible` **n'est atteignable** depuis la source du champ par **aucune chaîne
dirigée** d'arêtes attestées (`µ` ignorée). Parcours `O(E)`. Dual de
[`hors_bassin`](@ref)`(::ChampMaat, _)`.
"""
function hors_bassin(champ::ChampDepuis, cible::Symbol)
    haskey(champ.index.posi, cible) || throw(KeyError("site de cible non attesté : $cible"))
    idx = champ.index
    return !_atteint(idx, idx.posi[champ.source], idx.posi[cible])
end

"""
    chemin_depuis(champ::ChampDepuis, cible) -> ResultatRechercheHeuristique

Le chemin **optimal** de `champ.source` à `cible`, lu par **remontée** des prédécesseurs
du champ (`O(L)`, sans frontière ni nœud développé) puis inversion — dual de
[`descente_par_champ`](@ref). La promesse est **recomposée de gauche à droite** le long du
chemin, donc **identique au bit près** à [`recherche_par_pesee_de_promesse`](@ref) sur un
même chemin ; [`hors_bassin`](@ref) y distingue « hors du champ » et « promesse nulle ».
"""
function chemin_depuis(champ::ChampDepuis, cible::Symbol)
    haskey(champ.index.posi, cible) || throw(KeyError("site de cible non attesté : $cible"))
    idx = champ.index
    registre = String["remontée par champ d'attraction de Maât (source $(champ.source))"]
    ci = idx.posi[cible]
    if champ.valeur[ci] <= 0.0
        if hors_bassin(champ, cible)
            push!(registre, "cible non atteinte : $cible hors du champ de $(champ.source) " *
                            "— aucune chaîne dirigée (champ précalculé, 0 nœud développé)")
        else
            push!(registre, "$cible atteint par une chaîne attestée depuis $(champ.source), " *
                            "mais promesse nulle : toutes les chaînes portent une arête de " *
                            "compatibilité `µ = 0` — configuration inadmissible sous " *
                            "`κ ∈ (0, 1]` (A4) ; voie refusée")
        end
        return ResultatRechercheHeuristique(Symbol[], 0.0, registre)
    end
    si = idx.posi[champ.source]
    chemin = Symbol[cible]
    k = ci
    while k != si
        k = champ.pred[k]
        push!(chemin, idx.ids[k])
    end
    reverse!(chemin)                          # source → cible
    p = 1.0                                   # recomposition gauche→droite = exploration
    for t in 2:length(chemin)
        i = idx.posi[chemin[t - 1]]
        j = idx.posi[chemin[t]]
        p = (p * _compat_lien(idx, i, j)) * champ.hval[j]
    end
    push!(registre, "cible atteinte : promesse $(round(p; digits = 4)), $(length(chemin) - 1) pas " *
                    "(champ précalculé, 0 nœud développé)")
    return ResultatRechercheHeuristique(chemin, p, registre)
end

"""
    ResultatInference

Le résultat d'une inférence gouvernée : la conclusion (ou `nothing`), la conformité de
l'épreuve d'explicabilité et le registre.
"""
struct ResultatInference
    conclusion :: Union{String,Nothing}
    conforme   :: Bool
    registre   :: Vector{String}
end

"""
    inference_gouvernee(premisses, regles; justification) -> ResultatInference

**Inférence gouvernée par épreuves** (méthode 29.2). Les règles sont appliquées aux
prémisses, mais **aucune conclusion n'est retenue** si l'épreuve d'explicabilité εX
échoue : la justification doit être fidèle et intelligible. Une inférence non justifiée
est refusée, même productive.
"""
function inference_gouvernee(premisses::AbstractVector{<:AbstractString},
                             regles::AbstractVector{<:Function};
                             justification::Justification)
    conforme = justification_valide(justification)
    registre = String["inférence gouvernée par épreuves"]
    if !conforme
        push!(registre, "épreuve εX échouée : justification non fidèle ou non intelligible")
        return ResultatInference(nothing, false, registre)
    end
    for p in premisses
        for (k, r) in enumerate(regles)
            res = r(p)
            if res !== nothing
                push!(registre, "règle $k appliquée à « $p » → « $res »")
                return ResultatInference(String(res), true, registre)
            end
        end
    end
    push!(registre, "aucune règle n'a produit de conclusion")
    return ResultatInference(nothing, conforme, registre)
end
