# ============================================================================
#  Le registre des savoirs  (socle du module Ethnomatique)
# ----------------------------------------------------------------------------
#  Chaque savoir africain formalisé est une entrée du registre. Le registre est
#  la structure d'accueil : rendre le module extensible revient à écrire un
#  fichier qui appelle `enregistrer_savoir!` au chargement, sans rien modifier
#  au reste du module ni du package. C'est la lecture computationnelle de l'idée
#  que les savoirs ne s'opposent pas mais se composent (⊙) : chaque savoir est
#  un site, le registre en est le porteur.
# ============================================================================

"""
    Savoir(id, nom, domaine, etat, resume, entrees)

Une entrée du registre : un savoir africain formalisé.

- `id`      : identifiant symbolique (unique), p. ex. `:numeration` ;
- `nom`     : libellé lisible ;
- `domaine` : famille du savoir (`:numerations`, `:jeux`, `:geomancie`,
              `:motifs`, `:artefacts`, `:corps`, `:architecture`, `:arts`) ;
- `etat`    : `:implemente` (logique de calcul présente) ou `:prevu` (place
              réservée, à remplir par incrément) ;
- `resume`  : description courte ;
- `entrees` : principaux symboles publics du savoir.

La forme courte `Savoir(id; nom, domaine, ...)` construit l'objet par mots-clés.
"""
struct Savoir
    id      :: Symbol
    nom     :: String
    domaine :: Symbol
    etat    :: Symbol
    resume  :: String
    entrees :: Vector{Symbol}
end

function Savoir(id::Symbol; nom::AbstractString, domaine::Symbol,
                etat::Symbol = :implemente, resume::AbstractString = "",
                entrees::AbstractVector{Symbol} = Symbol[])
    etat in (:implemente, :prevu) ||
        throw(ArgumentError("état de savoir inconnu : $etat (attendu :implemente ou :prevu)"))
    return Savoir(id, String(nom), domaine, etat, String(resume), Symbol[entrees...])
end

"""Registre global des savoirs, indexé par identifiant."""
const _REGISTRE_SAVOIRS = Dict{Symbol, Savoir}()

"""
    enregistrer_savoir!(s::Savoir) -> Savoir

Enregistre un savoir dans le registre. Lève une erreur si l'identifiant est déjà
pris : l'enregistrement est **explicite et non silencieux** (G5 — rien ne change
sans être déclaré).
"""
function enregistrer_savoir!(s::Savoir)
    haskey(_REGISTRE_SAVOIRS, s.id) &&
        throw(ArgumentError("savoir déjà enregistré : $(s.id)"))
    _REGISTRE_SAVOIRS[s.id] = s
    return s
end

"""Liste ordonnée (domaine, puis identifiant) de tous les savoirs enregistrés."""
savoirs() = sort!(collect(values(_REGISTRE_SAVOIRS)); by = s -> (s.domaine, s.id))

"""Le savoir d'identifiant `id`, ou une erreur s'il n'est pas enregistré."""
function savoir(id::Symbol)
    haskey(_REGISTRE_SAVOIRS, id) || throw(KeyError("savoir non enregistré : $id"))
    return _REGISTRE_SAVOIRS[id]
end

savoir(id::AbstractString) = savoir(Symbol(id))

"""Indique si un savoir est enregistré."""
savoir_existe(id) = haskey(_REGISTRE_SAVOIRS, Symbol(id))

"""Savoirs d'un domaine donné, dans l'ordre des identifiants."""
savoirs_domaine(d::Symbol) = sort!([s for s in values(_REGISTRE_SAVOIRS) if s.domaine == d];
                                   by = s -> s.id)

"""Domaines attestés dans le registre, triés."""
domaines_savoirs() = sort!(unique(s.domaine for s in values(_REGISTRE_SAVOIRS)))

"""Savoirs dont la logique de calcul est effectivement implémentée."""
savoirs_implementes() = sort!([s for s in values(_REGISTRE_SAVOIRS) if s.etat == :implemente];
                              by = s -> (s.domaine, s.id))

"""Nombre de savoirs par domaine — vue de synthèse."""
function recensement_savoirs()
    rec = Dict{Symbol,NTuple{2,Int}}()
    for s in values(_REGISTRE_SAVOIRS)
        imp, tot = get(rec, s.domaine, (0, 0))
        rec[s.domaine] = (imp + (s.etat == :implemente ? 1 : 0), tot + 1)
    end
    return rec
end

"""
    aide_ethnomatique() -> String

Rend le registre sous forme lisible : domaines, savoirs, état (implemente/prevu)
et principaux symboles d'entrée.
"""
function aide_ethnomatique()
    io = IOBuffer()
    println(io, "Registre des savoirs africains formalisés — module Ethnomatique")
    println(io, "="^68)
    for d in domaines_savoirs()
        println(io, "\n[", d, "]")
        for s in savoirs_domaine(d)
            marque = s.etat == :implemente ? "•" : "◦"
            println(io, "  ", marque, " ", s.id, " — ", s.nom, " (", s.etat, ")")
            isempty(s.resume) || println(io, "      ", s.resume)
            isempty(s.entrees) || println(io, "      entrées : ", join(s.entrees, ", "))
        end
    end
    println(io, "\n", "•", " = implémenté     ", "◦", " = prévu (à ajouter par incrément)")
    return String(take!(io))
end

# ----------------------------------------------------------------------------
#  Déclaration des savoirs prévus  (place réservée, extension par incrément)
# ----------------------------------------------------------------------------
#  Ces entrées matérialisent la feuille de route : elles n'ont pas encore de
#  logique de calcul mais réservent leur place dans le registre. Les remplir
#  consiste à faire passer `etat` de `:prevu` à `:implemente` dans le fichier du
#  savoir, sans toucher au reste.
for s in Savoir[
    Savoir(:architecture; nom = "Architecture (concessions, fractales)", domaine = :architecture,
           etat = :prevu, resume = "Plans circulaires emboîtés et auto-similarité (famille décrite par R. Eglash)."),
    Savoir(:masques; nom = "Masques et masques-casques", domaine = :corps,
           etat = :prevu, resume = "Analyse de symétrie et de proportions des masques."),
    Savoir(:arts; nom = "Arts, musique et rythmes", domaine = :arts,
           etat = :prevu, resume = "Polyrythmie, cycles rythmiques, canons."),
    Savoir(:philosophie; nom = "Philosophie et sagesse", domaine = :arts,
           etat = :prevu, resume = "Proverbes et systèmes de valeurs formalisés."),
    Savoir(:textile; nom = "Textile et pagnes", domaine = :corps,
           etat = :prevu, resume = "Groupes de symétrie des tissus (kente, ndop, bogolan)."),
    Savoir(:tresse; nom = "Tressage et coiffure", domaine = :corps,
           etat = :prevu, resume = "Tresses et nattes : suites de motifs, groupes de tresse, algorithmes de natte."),
]
    haskey(_REGISTRE_SAVOIRS, s.id) || enregistrer_savoir!(s)
end
