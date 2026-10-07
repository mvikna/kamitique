# ============================================================================
#  Le porteur géométrique  (définitions 5.1, 5.2, 5.4)
# ----------------------------------------------------------------------------
#  Le site est l'unité primitive : il porte un lieu et des relations de
#  voisinage, jamais une valeur. Le porteur G est l'ensemble des sites, muni
#  d'une composition ⊙ et d'une relation de raffinement ≺.
# ============================================================================

"""
    Site(id, lieu = nothing; voisins = Symbol[], echelle = 1)

Un **site** (définition 5.1) : entité primitive douée d'un lieu dans une totalité
et de relations de voisinage avec les autres sites.

Un site ne porte **aucune valeur** — il porte une position. Tout ce qui est calculé
est une figure située (axiome A-K1).

`echelle` est l'échelle (profondeur) du site dans la stratification du porteur
(axiome A-K6) : la coupure de résolution `R₀` de la CQG y devient un entier fini
`≥ 1`. Par défaut, tout site est à l'échelle `1` (porteur non stratifié).
"""
struct Site
    id      :: Symbol
    lieu    :: Any
    voisins :: Vector{Symbol}
    echelle :: Int

    function Site(id::Symbol, lieu::Any = nothing; voisins::AbstractVector{Symbol} = Symbol[],
                  echelle::Integer = 1)
        echelle >= 1 || throw(ArgumentError("l'échelle d'un site est un entier ≥ 1"))
        new(id, lieu, unique(Symbol[voisins...]), Int(echelle))
    end
end

(Base.:(==))(a::Site, b::Site) =
    a.id == b.id && a.lieu == b.lieu && a.voisins == b.voisins && a.echelle == b.echelle
Base.hash(s::Site, h::UInt) = hash(s.id, hash(s.lieu, hash(s.voisins, hash(s.echelle, h))))

"""
    Figure(sites; liens = Tuple{Symbol,Symbol}[])

Une **figure composée** (définition 5.2) : un ensemble fini et ordonné de sites,
avec ses liens de voisinage internes.

Contrairement à un ensemble de bits, la figure **conserve son arrangement** : l'ordre
des sites et les liens font partie de la figure.
"""
struct Figure
    sites :: Vector{Symbol}
    liens :: Set{Tuple{Symbol,Symbol}}

    function Figure(sites::AbstractVector{Symbol}; liens = Tuple{Symbol,Symbol}[])
        vus = Symbol[]
        vuset = Set{Symbol}()
        sizehint!(vus, length(sites))
        sizehint!(vuset, length(sites))
        for s in sites
            s in vuset && continue
            push!(vuset, s)
            push!(vus, s)
        end
        ls = Set{Tuple{Symbol,Symbol}}()
        sizehint!(ls, length(liens))
        for (a, b) in liens
            push!(ls, paire_canonique(a, b))
        end
        new(vus, ls)
    end

    # Construction interne : `sites` est déjà dédupliqué (ordre préservé) et `liens`
    # est déjà canonique et dédupliqué. Réserve la copie et la recanonicalisation aux
    # seules entrées externes, ce qui rend la composition ⊙ cumulative linéaire.
    Figure(::Val{:brut}, sites::Vector{Symbol}, liens::Set{Tuple{Symbol,Symbol}}) =
        new(sites, liens)
end

"""Ordonne canoniquement une paire de sites (relation symétrique)."""
paire_canonique(a::Symbol, b::Symbol) = isless(a, b) ? (a, b) : (b, a)

"""La figure vide : figure neutre de la composition ⊙."""
figure_vide() = Figure(Symbol[])

Base.isempty(f::Figure) = isempty(f.sites)
Base.length(f::Figure) = length(f.sites)
Base.in(s::Symbol, f::Figure) = s in f.sites
Base.in(s::Site, f::Figure) = s.id in f.sites

(Base.:(==))(a::Figure, b::Figure) = a.sites == b.sites && a.liens == b.liens
Base.hash(f::Figure, h::UInt) = hash(f.sites, hash(f.liens, h))

"""
    ⊙(a::Figure, b::Figure)

La **composition** (définition 5.2) : à deux figures, elle associe la figure composée
qui les contient toutes deux **avec leur arrangement**.

Propriétés (vérifiées par les tests) :

- associativité : `(a ⊙ b) ⊙ c == a ⊙ (b ⊙ c)` ;
- figure neutre : `a ⊙ figure_vide() == a` ;
- compatibilité avec le raffinement : `a ≺ a ⊙ b`.
"""
function ⊙(a::Figure, b::Figure)
    sites = Symbol[]
    vu = Set{Symbol}()
    sizehint!(sites, length(a.sites) + length(b.sites))
    for s in a.sites
        s in vu && continue
        push!(vu, s); push!(sites, s)
    end
    for s in b.sites
        s in vu && continue
        push!(vu, s); push!(sites, s)
    end
    return Figure(Val(:brut), sites, union(a.liens, b.liens))
end

⊙(a::Site, b::Site) = Figure([a.id, b.id]; liens = [(a.id, b.id)])
⊙(a::Figure, b::Site) = a ⊙ Figure([b.id])
⊙(a::Site, b::Figure) = Figure([a.id]) ⊙ b
⊙(a::Site, b::Figure, c::Figure) = a ⊙ (b ⊙ c)

"""Alias ASCII de la composition [`⊙`](@ref)."""
composer(a, b) = a ⊙ b

"""
    ≺(a::Figure, b::Figure)

Le **raffinement** (définition 5.2) : `a ≺ b` se lit « `a` est une figure partielle
de `b` », c'est-à-dire que `b` porte tout ce que `a` porte, et davantage.

C'est un ordre partiel compatible avec la composition :
`a ≺ a ⊙ b` quels que soient `a` et `b`.
"""
function ≺(a::Figure, b::Figure)
    all(s -> s in b.sites, a.sites) || return false
    all(l -> l in b.liens, a.liens) || return false
    return true
end

≺(a::Site, b::Figure) = a.id in b.sites
≺(a::Site, b::Site) = a.id == b.id
≺(a::Figure, b::Site) = false

"""Alias ASCII du raffinement [`≺`](@ref)."""
raffine(a, b) = a ≺ b

"""Le raffinement est réflexif, antisymétrique et transitif sur les figures."""
est_ordre_partiel(a::Figure, b::Figure) = (a ≺ b) && (b ≺ a) ? a == b : true

# ----------------------------------------------------------------------------
#  Le porteur géométrique G
# ----------------------------------------------------------------------------

"""
    Porteur(sites = Dict{Symbol,Site}())

Le **porteur géométrique** `G` (définition 5.1) : l'ensemble des sites d'un calcul
donné. C'est la totalité hors de laquelle rien ne calcule et rien n'est calculé
(axiome A-K1).
"""
struct Porteur
    sites :: Dict{Symbol, Site}
end

Porteur() = Porteur(Dict{Symbol,Site}())

"""Ajoute un site au porteur et retourne le porteur (mutation)."""
function ajouter_site!(G::Porteur, s::Site)
    G.sites[s.id] = s
    return G
end

"""
    ajouter_site!(G, id; lieu = nothing, voisins = Symbol[], echelle = 1)

Variante de commodité : construit le site puis l'ajoute.
"""
ajouter_site!(G::Porteur, id::Symbol; lieu::Any = nothing, voisins::AbstractVector{Symbol} = Symbol[],
              echelle::Integer = 1) =
    ajouter_site!(G, Site(id, lieu; voisins = voisins, echelle = echelle))

"""Nombre de sites du porteur."""
Base.length(G::Porteur) = length(G.sites)
Base.haskey(G::Porteur, id::Symbol) = haskey(G.sites, id)

"""Le site d'identifiant `id`, ou une erreur s'il n'est pas attesté dans `G`."""
function site(G::Porteur, id::Symbol)
    haskey(G.sites, id) || throw(KeyError("site non attesté dans le porteur : $id"))
    return G.sites[id]
end

"""Voisins attestés d'un site (liste des identifiants)."""
voisins(G::Porteur, id::Symbol) = site(G, id).voisins

"""Tous les identifiants de sites du porteur, dans l'ordre d'insertion."""
identifiants(G::Porteur) = collect(keys(G.sites))

"""La figure portant tous les sites du porteur, avec les liens de voisinage attestés."""
function figure_totale(G::Porteur)
    liens = Tuple{Symbol,Symbol}[]
    for (id, s) in G.sites
        for v in s.voisins
            haskey(G.sites, v) && push!(liens, (id, v))
        end
    end
    return Figure(identifiants(G); liens = liens)
end

"""Contrôle qu'une figure ne mobilise que des sites attestés dans le porteur."""
function verifier_appartenance(G::Porteur, f::Figure)
    for s in f.sites
        haskey(G.sites, s) || return false
    end
    return true
end

# ----------------------------------------------------------------------------
#  Fermeture canonique du support  (axiome A-K7)
# ----------------------------------------------------------------------------
#  La plénitude du Noun (A1) se lit, côté computationnel, comme une clôture : une
#  figure située ne peut porter que des liens que le porteur atteste entre ses
#  propres sites. Sa clôture est la figure_totale(G) restreinte à ses sites.

"""Clôture d'une suite de sites en une figure close (cœur de [`cloture`](@ref))."""
function _cloture(G::Porteur, sites::AbstractVector{Symbol})
    vus = Set{Symbol}()
    ordre = Symbol[]
    sizehint!(ordre, length(sites))
    for s in sites
        s in vus && continue
        push!(vus, s); push!(ordre, s)
    end
    liens = Set{Tuple{Symbol,Symbol}}()
    for x in ordre
        haskey(G.sites, x) || continue
        for y in G.sites[x].voisins
            y in vus && push!(liens, paire_canonique(x, y))
        end
    end
    return Figure(Val(:brut), ordre, liens)
end

"""
    cloture(G::Porteur, f::Figure) -> Figure

La **clôture canonique** d'une figure (axiome A-K7) : la [`figure_totale`](@ref)`(G)`
restreinte aux sites de `f`. La figure close porte la **même suite de sites** que `f`
(l'arrangement de la définition 5.2 est préservé) et **exactement** les liens de
voisinage que `G` atteste entre eux — les liens internes non attestés sont exclus :
une figure admissible ne porte que des liens *situés*.

La clôture est :

- **idempotente** : `cloture(G, cloture(G, f)) == cloture(G, f)` ;
- **monotone** : `f ≺ g` ⟹ `cloture(G, f) ≺ cloture(G, g)` ;
- **canonique** : deux figures de même suite de sites ont la **même** clôture, quels
  que soient leurs liens ; c'est par elle que l'égalité d'états devient décidable par
  forme normale.
"""
cloture(G::Porteur, f::Figure) = _cloture(G, f.sites)

"""Indique si une figure est **close** : `cloture(G, f) == f` (axiome A-K7)."""
est_close(G::Porteur, f::Figure) = cloture(G, f) == f

"""
    reunion(G::Porteur, a::Figure, b::Figure) -> Figure

La **brique du demi-treillis supérieur** des figures closes (axiome A-K7) : le plus
petit majorant clos de `a` et `b`. Ordonnées par `≺` (qui ne dépend ni de l'ordre des
sites ni des liens non attestés), les figures closes forment un **demi-treillis
supérieur** : `figure_vide()` en est le bas, `figure_totale(G)` le haut.
"""
reunion(G::Porteur, a::Figure, b::Figure) = cloture(G, a ⊙ b)

# `cloture_support` et `canoniser` — qui portent sur `Etat` — sont définies dans
# `etat.jl`, inclus après ce fichier.

# ----------------------------------------------------------------------------
#  Stratification du porteur  (axiome A-K6, coupure de résolution)
# ----------------------------------------------------------------------------

"""Échelles attestées dans le porteur, triées par ordre croissant."""
echelles(G::Porteur) = sort!(unique(s.echelle for s in values(G.sites)))

"""
    profondeur(G::Porteur) -> Int

La **coupure de résolution** `R` du porteur (axiome A-K6) : le nombre fini d'échelles
qu'il stratifie, c'est-à-dire la plus profonde échelle attestée (`0` si le porteur est
vide). C'est la lecture computationnelle de la coupure `R₀ ≠ 0` de la CQG : le cosmos
n'est pas un continuum indéfiniment divisible.
"""
profondeur(G::Porteur) = isempty(G.sites) ? 0 : maximum(s.echelle for s in values(G.sites))

"""
    verifie_ak6(G::Porteur; ecart = 1) -> Bool

**A-K6 — Coupure de résolution.** Le porteur est stratifié en un nombre fini `R`
d'échelles, et la stratification est *cohérente* : chaque site porte une échelle dans
`[1, R]`, et tout voisinage attesté relie des échelles contiguës
(`|r(x) − r(y)| ≤ ecart`). La hiérarchie fractale ordonnée de la CQG ne saute pas
d'échelle sans passer par les échelles intermédiaires.

Un porteur vide satisfait l'énoncé de façon vide.
"""
function verifie_ak6(G::Porteur; ecart::Integer = 1)
    ecart >= 0 || throw(ArgumentError("l'écart d'échelle est un entier ≥ 0"))
    R = profondeur(G)
    R >= 1 || return true                          # porteur vide : énoncé vide
    for s in values(G.sites)
        (1 <= s.echelle <= R) || return false
        for v in s.voisins
            haskey(G.sites, v) || continue
            abs(G.sites[v].echelle - s.echelle) <= ecart || return false
        end
    end
    return true
end

# ----------------------------------------------------------------------------
#  Invariance de signature  (axiome A-K4⁺)
# ----------------------------------------------------------------------------
#  La CQG (A2 — Kheper) attache à chaque configuration des degrés de liberté
#  topologiques invariants : « l'univers se déploie librement dans ses configurations
#  métriques, mais jamais en violation de ses invariants caractéristiques ». Côté
#  computationnel, à chaque figure est attachée une **signature** : sa classe de
#  raffinement (la figure close engendrée par ses sites, c'est-à-dire l'ensemble de ses
#  sous-figures minimales situées) et son profil topologique (β₀, β₁).

"""
    Signature

La **signature** d'une figure (axiome A-K4⁺) : sa **classe de raffinement** `classe`
(la figure close engendrée par ses sites — l'ensemble de ses sous-figures minimales
situées) et son **profil topologique** `(composantes, cycles)` — nombres de composantes
connexes `β₀` et de cycles indépendants `β₁` du graphe `(sites, liens)` de la classe.

Deux figures de même signature portent la même classe de raffinement : elles dénotent
le même cosmos à raffinement près. C'est le **certificat d'identité** qui rend la
mémoïsation sûre (cf. `canoniser`, axiome A-K7).
"""
struct Signature
    classe      :: Figure
    composantes :: Int
    cycles      :: Int
end

Base.:(==)(a::Signature, b::Signature) =
    a.composantes == b.composantes && a.cycles == b.cycles && a.classe == b.classe
Base.hash(s::Signature, h::UInt) =
    hash(s.classe, hash(s.composantes, hash(s.cycles, h)))

"""Composantes connexes du graphe `(f.sites, f.liens)` (union-find, chemins comprimés)."""
function _composantes(f::Figure)
    parent = Dict{Symbol,Symbol}(s => s for s in f.sites)
    # Compression de chemin itérative : profondeur bornée, pas de récursion sur |G|.
    function racine(x::Symbol)
        r = x
        while parent[r] != r
            r = parent[r]
        end
        while parent[x] != r
            parent[x], x = r, parent[x]
        end
        return r
    end
    for (a, b) in f.liens
        (haskey(parent, a) && haskey(parent, b)) || continue
        ra, rb = racine(a), racine(b)
        ra == rb || (parent[ra] = rb)
    end
    vus = Set{Symbol}()
    for s in f.sites
        push!(vus, racine(s))
    end
    return length(vus)
end

"""
    signature(G::Porteur, f::Figure) -> Signature

La signature d'une figure (axiome A-K4⁺) : sa classe de raffinement et son profil
topologique. Elle est **décidable** (pure combinatoire) et **stable** (entièrement
déterminée par l'ensemble des sous-figures minimales situées de `f`).
"""
function signature(G::Porteur, f::Figure)
    cl = cloture(G, f)
    β0 = _composantes(cl)
    β1 = length(cl.liens) - length(cl.sites) + β0
    return Signature(cl, β0, β1)
end

# La signature du support d'un état — `signature(G, Ψ)` — est définie dans `etat.jl`,
# inclus après ce fichier (elle porte le type `Etat`).

"""
    composantes_connexes(G::Porteur) -> Dict{Symbol,Int}

Partition du porteur en composantes **faiblement** connexes de voisinage attesté : à
chaque site, l'identifiant de sa composante. Le voisinage attesté est une relation
**symétrique** (déf. 5.1 ; cf. `paire_canonique`), et le parcours suit les voisinages
dans **les deux sens** : le résultat ne dépend donc pas de l'ordre d'itération du `Dict`.

Un pas admissible ne suit que des voisinages attestés dirigés (`courant → v`) : il ne
peut jamais changer de composante — c'est l'invariant `β₀` que `A-K4⁺` place au service
de l'élagage. Comme la composante faible **contient** la composante dirigée, la
partition est une **sur-approximation** de l'atteignabilité : élaguer hors composante ne
coupe jamais une solution, y compris sur un porteur dont les `voisins` ne seraient pas
mutuellement déclarés.
"""
function composantes_connexes(G::Porteur)
    comp = Dict{Symbol,Int}()
    rev = index_inverse_voisinage(G)
    id = 0
    for depart in keys(G.sites)
        haskey(comp, depart) && continue
        id += 1
        comp[depart] = id
        pile = Symbol[depart]
        while !isempty(pile)
            x = pop!(pile)
            for y in G.sites[x].voisins                 # arêtes sortantes x → y
                (haskey(G.sites, y) && !haskey(comp, y)) || continue
                comp[y] = id
                push!(pile, y)
            end
            for y in get(rev, x, Symbol[])              # arêtes entrantes y → x
                (haskey(G.sites, y) && !haskey(comp, y)) || continue
                comp[y] = id
                push!(pile, y)
            end
        end
    end
    return comp
end

"""Indique si deux sites sont reliés par une chaîne de voisinages attestés (invariant `β₀`)."""
function meme_composante(G::Porteur, a::Symbol, b::Symbol)
    comp = composantes_connexes(G)
    return haskey(comp, a) && haskey(comp, b) && comp[a] == comp[b]
end

"""
    composition(G::Porteur, a, b)

Compose deux figures en enrichissant la figure composée des voisinages attestés
des sites de `a` vers les sites de `b` : la composition de deux figures situées
porte, en plus de leur réunion, les liens que le porteur atteste entre elles.
"""
function ⊙(G::Porteur, a::Figure, b::Figure)
    f = a ⊙ b
    liens = Set{Tuple{Symbol,Symbol}}(f.liens)
    for x in a.sites, y in b.sites
        (haskey(G.sites, x) && y in G.sites[x].voisins) && push!(liens, paire_canonique(x, y))
        (haskey(G.sites, y) && x in G.sites[y].voisins) && push!(liens, paire_canonique(x, y))
    end
    return Figure(Val(:brut), f.sites, liens)
end

"""
    index_inverse_voisinage(G::Porteur) -> Dict{Symbol, Vector{Symbol}}

Index inverse des voisinages attestés : à chaque site `z` de `G`, la liste des sites de
`G` qui le déclarent comme voisin. Il rend la recherche des liens attestés **vers** un
site donné linéaire en son degré entrant, au lieu d'un balayage de tout le porteur.
"""
function index_inverse_voisinage(G::Porteur)
    rev = Dict{Symbol, Vector{Symbol}}()
    for (id, s) in G.sites
        for v in s.voisins
            haskey(G.sites, v) || continue
            push!(get!(rev, v, Symbol[]), id)
        end
    end
    return rev
end

"""
    composer_cumule(figures; G = nothing) -> Figure

Composition cumulative d'une séquence de figures par [`⊙`](@ref). Le résultat est
**identique** au pli `⊙(figures[1], ⊙(figures[2], …))` : les sites sont réunis dans
l'ordre d'apparition, les liens internes fusionnés, et — si `G` est fourni — les liens
attestés entre chaque figure et celles déjà accumulées ajoutés.

L'accumulation est faite **en place** : chaque pas n'ajoute que les sites et les liens
nouveaux, sans recopier ce qui est déjà accumulé. Les liens attestés d'un nouveau site
`s` sont trouvés en consultant le voisinage de `s` et l'[`index_inverse_voisinage`](@ref)
de `G` : la composition est donc **linéaire** en le nombre de sites (à degré borné),
au lieu de quadratique.
"""
function composer_cumule(figures::AbstractVector{Figure}; G::Union{Porteur,Nothing} = nothing)
    isempty(figures) && return figure_vide()
    premier = figures[1]
    sites = copy(premier.sites)
    vu = Set{Symbol}(premier.sites)
    liens = Set{Tuple{Symbol,Symbol}}(premier.liens)
    rev = G === nothing ? nothing : index_inverse_voisinage(G)
    for k in 2:length(figures)
        f = figures[k]
        if G !== nothing
            for y in f.sites
                haskey(G.sites, y) || continue
                for x in G.sites[y].voisins                     # x voisin déclaré de y
                    (x in vu && haskey(G.sites, x)) && push!(liens, paire_canonique(x, y))
                end
                rv = get(rev, y, nothing)
                if rv !== nothing                                # x déclarant y comme voisin
                    for x in rv
                        (x in vu) && push!(liens, paire_canonique(x, y))
                    end
                end
            end
        end
        for s in f.sites
            s in vu && continue
            push!(vu, s); push!(sites, s)
        end
        union!(liens, f.liens)
    end
    return Figure(Val(:brut), sites, liens)
end
