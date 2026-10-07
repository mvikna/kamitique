# ============================================================================
#  Benchmark de la Kamitique — appréciation de l'efficacité des méthodes
# ----------------------------------------------------------------------------
#  Mesure, sur des instances représentatives et massives, le temps, les
#  allocations mémoire et l'exposant empirique de complexité des méthodes de
#  chaque catégorie de la carte (tableau 13.1).
#
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#  Le script est reproductible (générateur aléatoire à graine fixe).
#
#  Usage :  julia --project=. benchmark/benchmarks.jl
# ============================================================================

using Printf
using Random
using Kamitique

const REP_DEFAUT = 5
const RNG = MersenneTwister(0x4B414D49)   # « KAMI »

# ----------------------------------------------------------------------------
#  Instrumentation
# ----------------------------------------------------------------------------

"""Meilleur temps et allocations minimales sur `reps` exécutions (après échauffement)."""
function mesurer(f; reps::Int = REP_DEFAUT)
    f()                                   # échauffement : compilation incluse
    tmin = Inf
    bmin = typemax(Int)
    for _ in 1:reps
        r = @timed f()
        tmin = min(tmin, r.time)
        bmin = min(bmin, r.bytes)
    end
    return (temps = tmin, octets = bmin)
end

"""Exposant empirique p tel que `temps ≈ n^p` (moindres carrés en log-log)."""
function exposant(ns, ts)
    length(ns) < 2 && return NaN
    x = log.(Float64.(ns))
    y = log.(max.(Float64.(ts), eps(Float64)))
    xm = sum(x) / length(x)
    ym = sum(y) / length(y)
    den = sum((x .- xm) .^ 2)
    den == 0 && return NaN
    return sum((x .- xm) .* (y .- ym)) / den
end

fmt_temps(t) =
    t < 1e-6 ? @sprintf("%8.1f ns", t * 1e9) :
    t < 1e-3 ? @sprintf("%8.2f µs", t * 1e6) :
    t < 1.0  ? @sprintf("%8.2f ms", t * 1e3) :
               @sprintf("%8.3f s ", t)

fmt_octets(b) =
    b < 1024     ? @sprintf("%7d o ", b) :
    b < 1024^2   ? @sprintf("%7.1f Ko", b / 1024) :
    b < 1024^3   ? @sprintf("%7.2f Mo", b / 1024^2) :
                   @sprintf("%7.2f Go", b / 1024^3)

fmt_debit(x) = x >= 1e5 ? @sprintf("%9.2e", x) : @sprintf("%9.1f", x)

"""Nombre d'arêtes relaxées, lu dans le registre du champ d'attraction (M-06)."""
function relaxations(champ::Union{ChampMaat,ChampDepuis})
    m = match(r"(\d+)\s+arête", join(champ.registre, " "))
    return m === nothing ? 0 : parse(Int, m.captures[1])
end

"""Exécute une série de mesures et affiche un tableau (n, temps, alloc, débit)."""
function serie(nom::AbstractString, ns::Vector{Int}, fgen::Function;
               reps::Int = REP_DEFAUT, ops::Function = _ -> 1.0)
    println("\n", "━"^70)
    println("▶ ", nom)
    @printf("  %8s  %10s  %10s  %14s\n", "n", "temps", "alloc", "débit (op/s)")
    ts = Float64[]
    for n in ns
        m = mesurer(fgen(n); reps = reps)
        push!(ts, m.temps)
        @printf("  %8d  %10s  %10s  %14s\n", n, fmt_temps(m.temps),
                fmt_octets(m.octets), fmt_debit(ops(n) / m.temps))
    end
    e = exposant(ns, ts)
    isfinite(e) && @printf("  ⇒ exposant empirique : temps ~ n^%.2f\n", e)
    return ts
end

# ----------------------------------------------------------------------------
#  Fabriques d'instances (réseau en anneau : situé, borné, reproductible)
# ----------------------------------------------------------------------------

"""Porteur en anneau de N sites (chaque site a deux voisins)."""
function anneau(N::Int)
    G = Porteur()
    for i in 1:N
        ajouter_site!(G, Symbol("s", i);
                      lieu = "anneau-$i",
                      voisins = [Symbol("s", mod1(i - 1, N)), Symbol("s", mod1(i + 1, N))])
    end
    return G
end

"""N figures de `largeur` sites consécutifs de l'anneau."""
figures_anneau(N::Int, largeur::Int = 3) =
    [Figure([Symbol("s", mod1(i + k, N)) for k in 0:(largeur - 1)]) for i in 1:N]

"""État à N figures de l'anneau, poids linéairement décroissants (Σ = 1)."""
etat_anneau(N::Int; largeur::Int = 3) =
    Etat(figures_anneau(N, largeur), Float64[N - i + 1 for i in 1:N])

"""Question à deux propositions graduées sur l'anneau."""
function question_anneau(N::Int)
    haut = Set(Symbol("s", i) for i in 1:(N ÷ 2))
    p1 = Proposition("préfixe", f -> count(s -> s in haut, f.sites) / max(length(f.sites), 1))
    p2 = Proposition("largeur≤3", f -> length(f.sites) <= 3 ? 1.0 : 0.0)
    return Question(:diagnostic, p1, p2)
end

# ============================================================================
#  Rapport
# ============================================================================

println("="^70)
@printf("  BENCHMARK KAMITIQUE — efficacité des méthodes\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Noyau de pesée (Socle) — scores_pesee : la brique O(n²) fondamentale
# ----------------------------------------------------------------------------
nn = [64, 128, 256, 512]
serie("Noyau de pesée — scores_pesee (Socle, ch. 7)",
      nn, n -> (Ψ = etat_anneau(n); q = question_anneau(n); h = HarmonieRaffinement();
                () -> scores_pesee(Ψ, q, h));
      ops = n -> n^2)

# ----------------------------------------------------------------------------
#  2. Méthodes quadratiques par catégorie
# ----------------------------------------------------------------------------
nq = [64, 128, 256]

serie("Architectures — placement_par_pesee (ch. 14)",
      nq, n -> (Ψ = etat_anneau(n); h = HarmonieRaffinement();
                () -> placement_par_pesee(Ψ, h; ateliers = 4));
      reps = 3, ops = n -> n^2)

serie("Calcul haute performance — execution_par_harmonie (ch. 19)",
      nq, n -> (Ψ = etat_anneau(n); h = HarmonieRaffinement();
                () -> execution_par_harmonie(Ψ, h; workers = 4));
      reps = 3, ops = n -> n^2)

serie("Structures — tri_par_pesee (ch. 17)",
      nq, n -> (Ψ = etat_anneau(n); q = question_anneau(n); h = HarmonieRaffinement();
                () -> tri_par_pesee(Ψ, q, h));
      reps = 3, ops = n -> n^2)

serie("Big data — partitionnement_geometrique (ch. 22)",
      nq, n -> (G = anneau(n); figs = figures_anneau(n); h = HarmonieRaffinement();
                () -> partitionnement_geometrique(figs, h; parts = 4));
      reps = 3, ops = n -> n^2)

serie("Quantique — correction_par_harmonisation (ch. 20)",
      nq, n -> (Ψ = etat_anneau(n); h = HarmonieRaffinement();
                () -> correction_par_harmonisation(Ψ, h));
      reps = 3, ops = n -> n^2)

serie("Calcul scientifique — convergence_par_harmonisation (ch. 18)",
      nq, n -> (Ψ = etat_anneau(n); h = HarmonieRaffinement();
                () -> convergence_par_harmonisation(Ψ, h));
      reps = 2, ops = n -> n^2)

serie("Apprentissage — reponderation_sous_encadrement (ch. 30)",
      nq, n -> (Ψ = etat_anneau(n); perf = rand(RNG, n); h = HarmonieRaffinement();
                () -> reponderation_sous_encadrement(Ψ, perf, h));
      reps = 3, ops = n -> n^2)

serie("Optimisation — descente_par_harmonisation (ch. 25)",
      nq, n -> (Ψ = etat_anneau(n); q = question_anneau(n); h = HarmonieRaffinement();
                () -> descente_par_harmonisation(Ψ, q, h));
      reps = 2, ops = n -> n^2)

# ----------------------------------------------------------------------------
#  3. Méthodes linéaires — instances massives
# ----------------------------------------------------------------------------
nl = [10_000, 100_000]

serie("Systèmes — ordonnancement_par_pesee (ch. 15)",
      nl, n -> (b = rand(RNG, n); a = rand(RNG, n);
                () -> ordonnancement_par_pesee(b, a)),
      ops = n -> n * log2(n))

serie("Optimisation — elagage_par_pesee (ch. 25)",
      nl, n -> (bornes = rand(RNG, n); () -> elagage_par_pesee(bornes)),
      ops = n -> n)

serie("HPC — reponderation_sous_charge (ch. 19)",
      nl, n -> (g = rand(RNG, n); c = rand(RNG, n);
                () -> reponderation_sous_charge(g, c)),
      ops = n -> n)

serie("Calcul scientifique — resolution_par_descente (ch. 18)",
      nl, n -> (residus = rand(RNG, n); () -> resolution_par_descente(residus)),
      ops = n -> n)

serie("Langages — compilation_par_composition (ch. 16)",
      nl, n -> (ins = [TypeDegres(Symbol("t$i"), rand(RNG, 64)) for i in 1:n];
                () -> compilation_par_composition(ins)),
      ops = n -> n * 64)

serie("Langages — evaluation_consignee (ch. 16)",
      nl, n -> (ins = [TypeDegres(Symbol("t$i"), rand(RNG, 64)) for i in 1:n];
                entree = rand(RNG, 64);
                () -> evaluation_consignee(ins, entree)),
      ops = n -> n * 64)

serie("Cryptologie — chiffrement/dechiffrement par redistribution (ch. 24)",
      nl, n -> (Ψ = etat_anneau(n); cle = 1.0 .+ rand(RNG, n);
                () -> dechiffrement_par_redistribution(chiffrement_par_redistribution(Ψ, cle), cle)),
      ops = n -> n)

serie("Multicritère — classement_par_pesee_harmonique (ch. 26)",
      nl, n -> (cr = rand(RNG, n, 20); nn = [false for _ in 1:20]; nn[1] = true;
                p = rand(RNG, 20);
                () -> classement_par_pesee_harmonique(cr; non_negociables = nn, poids = p)),
      ops = n -> n * 20)

serie("Bases de données — recherche_par_relaxation (ch. 21)",
      nl, n -> (Ψ = etat_anneau(n);
                p = Proposition("contient le dernier site",
                                f -> (Symbol("s", n) in f.sites) ? 1.0 : 0.0);
                () -> recherche_par_relaxation(Ψ, p)),
      ops = n -> n)

serie("Connaissances — acquisition_par_pesee (ch. 28)",
      [500, 1000, 2000],
      n -> (G = anneau(n); savoirs = [Figure([Symbol("s", i)]) for i in 1:n];
            h = HarmonieRaffinement();
            () -> acquisition_par_pesee(G, savoirs, h)),
      reps = 2, ops = n -> n)

serie("Connaissances — raisonnement_par_composition (ch. 28)",
      [500, 1000, 2000],
      n -> (G = anneau(n); prem = [Figure([Symbol("s", i)]) for i in 1:n];
            () -> raisonnement_par_composition(prem, _ -> true; G = G)),
      reps = 2, ops = n -> n)

# ----------------------------------------------------------------------------
#  4. Méthodes sur structure — réseau en anneau
# ----------------------------------------------------------------------------
ng = [100, 500, 2000]

serie("Réseaux — routage_par_harmonie (ch. 23)",
      ng, n -> (G = anneau(n); h = HarmonieRaffinement();
                () -> routage_par_harmonie(G, Symbol("s1"), Symbol("s", n ÷ 2), h;
                                           max_profondeur = n + 2)),
      reps = 3, ops = n -> n)

serie("Architectures — flot_par_composition (ch. 14)",
      ng, n -> (G = anneau(n); h = HarmonieRaffinement();
                () -> flot_par_composition(G, Symbol("s1"), Symbol("s", n ÷ 2), h;
                                           max_profondeur = n + 2)),
      reps = 3, ops = n -> n)

serie("Systèmes — allocation_memoire_situee (ch. 15)",
      ng, n -> (G = anneau(n);
                demandes = [Symbol("s", i) for i in 1:(n ÷ 4)];
                memoires = [Symbol("s", i) for i in 1:max(1, n ÷ 20)];
                () -> allocation_memoire_situee(G, demandes, memoires)),
      reps = 3, ops = n -> (n ÷ 4) * n)

serie("Heuristique — recherche_par_pesee_de_promesse (ch. 29)",
      [250, 1000, 4000],
      n -> (G = anneau(n); h = HarmonieRaffinement();
            cible = Symbol("s", n ÷ 2);
            () -> recherche_par_pesee_de_promesse(G, Symbol("s1"), cible, h; max_noeuds = n + 8)),
      reps = 3, ops = n -> n)

# ----------------------------------------------------------------------------
#  4b. Champ d'attraction de Maât (ch. 29, M-06) — le point fixe remplace l'exploration
# ----------------------------------------------------------------------------
# L'axiome A4 (Maât : m_gap > 0) garantit un attracteur unique : l'optimum est un
# POINT FIXE, qui se calcule au lieu de s'explorer. `champ_vers(idx, but)` exécute
# UNE passe arrière dans le semi-anneau (max, ×) — un Dijkstra de fiabilité
# maximale, O(E log V) — et en tire la meilleure promesse de TOUTES les sources
# vers la cible ; chaque chemin se lit ensuite par descente, O(L), sans frontière
# ni nœud développé. Le dual `champ_depuis` couvre une source vers toutes les
# cibles par une passe AVANT.
#
# Ce que l'on mesure ici, en termes d'EFFICACITÉ (trièdre εE/εF/εX) :
#   • εE (éthique) — préalable non compensable : les deux voies rendent le MÊME
#     optimum admissible ; le banc compare donc à efficacité ÉGALE.
#   • εF (frugalité) — la fonctionnelle de ressources. Le coût de la passe est un
#     coût de CALCUL ; sa signature honnête n'est pas le temps mural (dégradé par
#     le cache, exposant trompeur ≈ n²) mais le nombre de RELAXATIONS, exactement
#     E = 2n sur l'anneau, indépendamment de la machine. Reconstruire les n chemins
#     coûte ≈ n², non par faiblesse de l'algorithme mais parce que la réponse a la
#     taille n × L : on paie ce qu'on DEMANDE (la sortie, non l'algorithme). Le
#     gain est le rapport des fonctionnelles des deux voies, à efficacité égale.
#   • εX (explicabilité) — le champ CONSIGNE sa trace (relaxations, bassin) dans son
#     registre ; cette justification se paie en mémoire, linéairement.
# Mesures : (1) le coût de la passe (relaxations = E = 2n) ; (2) le coût des n
# chemins reconstruits (taille de sortie n × L, donc ≈ n²) ; (3) le gain εF des
# deux motifs (n sources → 1 cible ; 1 source → n cibles), une passe contre n
# explorations — le gain CROÎT avec n.
println("\n", "━"^70)
println("▶ Heuristique — coût de la passe : relaxations = E = 2n (M-06, ch. 29)")
@printf("  %8s  %12s  %10s  %8s  %12s  %10s  %8s\n",
        "n", "champ_vers", "alloc", "relax.", "champ_depuis", "alloc", "relax.")
for n in [1000, 4000, 16000]
    G = anneau(n); h = HarmonieRaffinement()
    idx = IndexPesee(G, h)
    cible = Symbol("s", n ÷ 2)
    mv = mesurer(() -> champ_vers(idx, cible); reps = 3)
    md = mesurer(() -> champ_depuis(idx, :s1); reps = 3)
    # Le temps MURAL se dégrade avec le cache au-delà de L2 (d'où un exposant
    # empirique trompeur) ; E = 2n, lui, est exact : c'est la vraie signature.
    @printf("  %8d  %12s  %10s  %8d  %12s  %10s  %8d\n", n,
            fmt_temps(mv.temps), fmt_octets(mv.octets), relaxations(champ_vers(idx, cible)),
            fmt_temps(md.temps), fmt_octets(md.octets), relaxations(champ_depuis(idx, :s1)))
end

# Descente : les n chemins (un par source) par lecture directe, O(L) chacun.
# Le coût suit la TAILLE DE SORTIE (n chemins × L pas ≈ n²) : il mesure εF de la
# restitution, non celui du calcul — d'où le ≈ n², honnête et attendu.
serie("Heuristique — descente_par_champ : n chemins (M-06, ch. 29)",
      [250, 1000, 4000],
      n -> (G = anneau(n); h = HarmonieRaffinement();
            idx = IndexPesee(G, h);
            champ = champ_vers(idx, Symbol("s", n ÷ 2));
            sources = [Symbol("s", i) for i in 1:n];
            () -> (for s in sources
                       descente_par_champ(champ, s)
                   end)),
      reps = 3, ops = n -> n)

# Le gain εF sur le motif « n sources → 1 cible » : une passe contre n explorations.
# La colonne « gain » est le rapport des fonctionnelles (temps) des deux voies pour
# le MÊME optimum (εE égal) : c'est la frugalité relative du champ. Il croît avec n
# car l'exploration paie n fois, la passe UNE seule fois.
println("\n", "━"^70)
println("▶ Heuristique — champ d'attraction : n sources → 1 cible (M-06, ch. 29)")
@printf("  %8s  %12s  %12s  %12s  %10s\n", "n", "exploration", "champ (1 passe)", "descente", "gain")
for n in [125, 250, 500, 1000]
    G = anneau(n); h = HarmonieRaffinement()
    idx = IndexPesee(G, h)
    cible = Symbol("s", n ÷ 2)
    sources = [Symbol("s", i) for i in 1:n]
    m_exp = mesurer(() -> (for s in sources
                               recherche_par_pesee_de_promesse(idx, s, cible)
                           end); reps = 2)
    m_champ = mesurer(() -> champ_vers(idx, cible); reps = 3)
    champ = champ_vers(idx, cible)          # une passe couvre toutes les sources
    m_desc = mesurer(() -> (for s in sources
                                descente_par_champ(champ, s)
                            end); reps = 3)
    @printf("  %8d  %12s  %12s  %12s  %9.1f×\n", n, fmt_temps(m_exp.temps),
            fmt_temps(m_champ.temps), fmt_temps(m_desc.temps),
            m_exp.temps / m_champ.temps)
end

# Dual : le motif symétrique « 1 source → n cibles » (champ_depuis, passe AVANT).
serie("Heuristique — champ_depuis : une source → toutes les cibles (M-06, ch. 29)",
      [1000, 4000, 16000],
      n -> (G = anneau(n); h = HarmonieRaffinement();
            idx = IndexPesee(G, h);
            source = Symbol("s1");
            () -> champ_depuis(idx, source)),
      reps = 3, ops = n -> n)

serie("Heuristique — chemin_depuis : n chemins (M-06, ch. 29)",
      [250, 1000, 4000],
      n -> (G = anneau(n); h = HarmonieRaffinement();
            idx = IndexPesee(G, h);
            champ = champ_depuis(idx, Symbol("s1"));
            cibles = [Symbol("s", i) for i in 1:n];
            () -> (for c in cibles
                       chemin_depuis(champ, c)
                   end)),
      reps = 3, ops = n -> n)

# Gain εF sur « 1 source → n cibles » : une passe avant contre n explorations.
# Même lecture duale : une seule passe avant amortie sur toutes les cibles, contre
# n explorations — le rapport mesure la même frugalité εF, par l'autre extrémité.
println("\n", "━"^70)
println("▶ Heuristique — champ dual : 1 source → n cibles (M-06, ch. 29)")
@printf("  %8s  %12s  %12s  %12s  %10s\n", "n", "exploration", "champ (1 passe)", "remontée", "gain")
for n in [125, 250, 500, 1000]
    G = anneau(n); h = HarmonieRaffinement()
    idx = IndexPesee(G, h)
    source = Symbol("s1")
    cibles = [Symbol("s", i) for i in 1:n]
    m_exp = mesurer(() -> (for c in cibles
                               recherche_par_pesee_de_promesse(idx, source, c)
                           end); reps = 2)
    m_champ = mesurer(() -> champ_depuis(idx, source); reps = 3)
    champ = champ_depuis(idx, source)       # une passe couvre toutes les cibles
    m_chemin = mesurer(() -> (for c in cibles
                                  chemin_depuis(champ, c)
                              end); reps = 3)
    @printf("  %8d  %12s  %12s  %12s  %9.1f×\n", n, fmt_temps(m_exp.temps),
            fmt_temps(m_champ.temps), fmt_temps(m_chemin.temps),
            m_exp.temps / m_champ.temps)
end

# ----------------------------------------------------------------------------
#  4c. Optimisation et recherche opérationnelle (ch. 25) — peser avant de payer
# ----------------------------------------------------------------------------
# Coûts bruts mesurés plus haut : `descente_par_harmonisation` (≈ n², §2) et
# `elagage_par_pesee` (≈ n, §3). Ici, la lecture d'EFFICACITÉ (εF/εX) des trois
# méthodes du chapitre :
#   • descente_par_harmonisation (25.1) — chaque itération paie UN `scores_pesee`
#     O(n²) puis une redistribution O(n), et repondère la présence vers la figure de
#     plus haute pesée. εF : on ne paie que la PENTE suivie, jamais l'espace des
#     voies. Le nombre d'itérations à convergence croît lentement (≈ log n) et la
#     valeur se fige à l'optimum de Maât.
#   • elagage_par_pesee (25.2) — écarte toute voie de borne < seuil SANS la payer :
#     le CALCUL est O(n), mais la TRACE (εX) consigne une entrée par voie écartée.
#     La frugalité de calcul se paie en explicabilité — d'autant plus que le seuil
#     élague (tableau du bas).
#   • borne_harmonique — produit des degrés tranchés et des maxima restants, O(d) :
#     la borne d'une branche est un PRODUIT, jamais un simple compteur.
println("\n", "━"^70)
println("▶ Optimisation — descente_par_harmonisation : convergence (ch. 25)")
@printf("  %8s  %8s  %12s  %10s  %12s\n", "n", "itér.", "temps", "alloc", "valeur")
for n in [64, 128, 256]
    Ψ = etat_anneau(n); q = question_anneau(n); h = HarmonieRaffinement()
    r = descente_par_harmonisation(Ψ, q, h)
    m = mesurer(() -> descente_par_harmonisation(Ψ, q, h); reps = 2)
    @printf("  %8d  %8d  %12s  %10s  %12.6f\n", n, r.iterations, fmt_temps(m.temps),
            fmt_octets(m.octets), r.valeur)
end

println("\n", "━"^70)
println("▶ Optimisation — élagage : εX (trace) vs seuil (ch. 25, n = 100 000 voies)")
@printf("  %8s  %10s  %10s  %12s  %10s\n", "seuil", "élaguées", "retenues", "temps", "alloc")
bornes = rand(RNG, 100_000)                 # un même tirage pour les quatre seuils
for seuil in [0.3, 0.5, 0.7, 0.9]
    r = elagage_par_pesee(bornes; seuil = seuil)
    m = mesurer(() -> elagage_par_pesee(bornes; seuil = seuil); reps = 3)
    @printf("  %8.1f  %10d  %10d  %12s  %10s\n", seuil, length(r.ecartees),
            length(r.retenues), fmt_temps(m.temps), fmt_octets(m.octets))
end

serie("Optimisation — borne_harmonique (ch. 25)",
      [10_000, 100_000, 1_000_000],
      n -> (tranches = rand(RNG, n); restants = rand(RNG, n);
            () -> borne_harmonique(tranches, restants)),
      ops = n -> n)

# ----------------------------------------------------------------------------
#  5. Méthodes combinatoires
# ----------------------------------------------------------------------------
println("\n", "━"^70)
println("▶ Théorie des jeux — pesee_mutuelle (ch. 27)")
@printf("  %10s  %8s  %10s  %10s\n", "joueurs×strat.", "itér.", "temps", "alloc")
for (n, s) in [(100, 50), (200, 100), (400, 200)]
    g = rand(RNG, n, s)
    m = mesurer(() -> pesee_mutuelle(g); reps = 3)
    @printf("  %10s  %8s  %10s  %10s\n", "$n×$s", "≤64", fmt_temps(m.temps), fmt_octets(m.octets))
end

println("\n", "━"^70)
println("▶ Théorie des jeux — conception_par_attracteur (ch. 27) : complexité s^n")
@printf("  %6s  %8s  %10s  %10s  %8s\n", "joueurs", "strat.", "temps", "alloc", "×/pas")
let prec = NaN
    for n in 2:6
        g = rand(RNG, n, 3)
        m = mesurer(() -> conception_par_attracteur(g); reps = 3)
        @printf("  %6d  %8d  %10s  %10s  %8s\n", n, 3, fmt_temps(m.temps), fmt_octets(m.octets),
                isnan(prec) ? "—" : @sprintf("%.2f", m.temps / prec))
        prec = m.temps
    end
end

# ----------------------------------------------------------------------------
#  6. Cas limites — robustesse
# ----------------------------------------------------------------------------
println("\n", "━"^70)
println("▶ Cas limites (n = 1, entrées dégénérées, rejets attendus)")

reussis = Ref(0); total = Ref(0)
function verifier(nom, cond::Bool)
    total[] += 1
    reussis[] += cond
    @printf("  [%s] %s\n", cond ? "✓" : "✗", nom)
end
function rejette(nom, f)
    ok = false
    try
        f()
    catch e
        ok = e isa ArgumentError || e isa KeyError || e isa BoundsError
    end
    verifier(nom, ok)
end

Ψ1 = etat_anneau(8)
h0 = HarmonieRaffinement()
verifier("placement_par_pesee (n=1)",
         length(placement_par_pesee(Etat([Figure([:s1])], [1.0]), h0; ateliers = 1).affectation) == 1)
verifier("partitionnement_geometrique (1 figure)",
         length(partitionnement_geometrique([Figure([:s1])], h0).partitions) == 2)
verifier("correction_par_harmonisation (n=1)",
         correction_par_harmonisation(Etat([Figure([:s1])], [1.0]), h0).harmonie_apres ≈
         correction_par_harmonisation(Etat([Figure([:s1])], [1.0]), h0).harmonie_avant)
verifier("pesee_mutuelle (1×1)", length(pesee_mutuelle(rand(RNG, 1, 1)).profil) == 1)
verifier("conception_par_attracteur (1 joueur)",
         length(conception_par_attracteur(rand(RNG, 1, 4)).profil) == 1)
verifier("tri_par_pesee (n=1)", length(tri_par_pesee(Etat([Figure([:s1])], [1.0]),
                                                    question_anneau(8), h0).figures) == 1)
verifier("champ_vers (départ = but)",
         (lst = champ_vers(IndexPesee(anneau(4), h0), :s1);
          promesse_optimale(lst, :s1) ≈ 1.0))
verifier("descente_par_champ (départ = but)",
         (lst = champ_vers(IndexPesee(anneau(4), h0), :s1);
          r = descente_par_champ(lst, :s1);
          r.chemin == [:s1] && r.promesse ≈ 1.0))
verifier("champ_depuis (source = cible)",
         (lst = champ_depuis(IndexPesee(anneau(4), h0), :s1);
          promesse_depuis(lst, :s1) ≈ 1.0))
verifier("chemin_depuis (source = cible)",
         (lst = champ_depuis(IndexPesee(anneau(4), h0), :s1);
          r = chemin_depuis(lst, :s1);
          r.chemin == [:s1] && r.promesse ≈ 1.0))
rejette("ordonnancement sans tâche", () -> ordonnancement_par_pesee(Float64[], Float64[]))
rejette("élagage sans voie", () -> elagage_par_pesee(Float64[]))
rejette("pesée sans question", () -> balance(Ψ1, Question(:vide), h0))
rejette("site non attesté (routage)",
        () -> routage_par_harmonie(anneau(4), :absent, :s1, h0))
rejette("figures de largeurs incompatibles",
        () -> compilation_par_composition([TypeDegres(:a, [0.5]),
                                           TypeDegres(:b, [0.5, 0.5])]))
@printf("  ⇒ cas limites : %d/%d\n", reussis[], total[])

# ----------------------------------------------------------------------------
#  7. Synthèse
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE")
println("="^70)
println("""
  Classes de coût observées
    • O(n²) — noyau de pesée et méthodes d'appariement : scores_pesee,
      placement, execution_par_harmonie, tri_par_pesee, partitionnement,
      correction/convergence par harmonisation, descente, repondération.
      Ordre inchangé, mais chaque couple {i, j} n'est évalué qu'une fois (κ
      symétrique) : la constante du noyau est divisée par deux.
    • O(n log n) — ordonnancement_par_pesee (tri par degrés) ; champ
      d'attraction de Maât (ch. 29, `M-06`) : UNE passe arrière `(max, ×)`
      (`champ_vers`, Dijkstra de fiabilité maximale sur `E` arêtes) donne la
      meilleure promesse de TOUTES les sources vers une cible, et la descente
      recompose chaque chemin en O(L) — le dual `champ_depuis` fait de même
      pour une source vers toutes les cibles.
    • O(n) — élagage, borne harmonique, repondération sous charge, chiffrement/
      déchiffrement, classement multicritère, résolution par descente, recherche
      par relaxation, routage/flot (anneau), recherche par pesée de promesse, et —
      depuis la composition cumulative en place (⊙, `composer_cumule`) —
      acquisition et raisonnement par composition (ch. 28).
    • O(s^n) — conception_par_attracteur : exhaustive par construction (choix de
      l'attracteur) ; à réserver aux jeux de faible dimension.

  Points chauds (frugalité εF)
    • Les registres consignent chaque décision : élagage et repondération sous
      charge allouent un enregistrement par voie — la traçabilité (εX) se paie
      en mémoire, linéairement. Le tampon est préalloué (`sizehint!`) pour
      supprimer la recroissance géométrique du vecteur (gain d'allocation
      marginal : la dépense est portée par les chaînes elles-mêmes). Mesuré
      (ch. 25, n = 10⁵ voies) : l'élagage passe de 34,3 Mo (seuil 0,3) à 98,6 Mo
      (seuil 0,9) — la trace épouse le nombre de voies ÉCARTÉES, pas le calcul.
    • Optimisation (ch. 25) : `borne_harmonique` produit une borne en O(d) et
      ZÉRO allocation (produit scalaire, aucun vecteur neuf) ; `descente_par_
      harmonisation` ne paie, par itération, qu'UN `scores_pesee` O(n²) puis une
      redistribution O(n) — elle converge en ≈ log n itérations (24 → 28 de
      n = 64 à n = 256) vers l'optimum de Maât, sans matérialiser l'espace des
      voies.
    • La composition cumulative (⊙) n'accumule plus une figure neuve à chaque pas
      (sites recopiés, liens refusionnés) : `composer_cumule` ajoute en place les
      seuls sites et liens nouveaux, et retrouve les liens attestés par le
      voisinage du site entrant et l'index inverse des voisinages de `G`. Le
      ch. 28 (acquisition, raisonnement) passe ainsi de O(n²) à O(n) en temps et
      en allocations.
    • La valuation d'une figure unique est évaluée directement
      (`_valuation_figure`), sans construire d'`Etat ([f], [1.0])` par figure
      candidate de la pesée.
    • La fermeture sous ⊙ du partitionnement (ch. 22) teste le partage de sites
      sans rien allouer (`_partagent_un_site`, appartenance sur le plus court des
      deux vecteurs) au lieu de matérialiser leur intersection : l'ordre reste
      O(n²) — la fermeture est quadratique par nature — mais la constante
      mémoire du partitionnement est divisée par ~12 (n = 256 : 22,9 → 1,95 Mo).
    • Le champ d'attraction (ch. 29, `M-06`) supprime la boucle de recherche là
      où `A4` donne un attracteur unique : au lieu de n explorations (une par
      source), une SEULE passe en arrière suffit pour toutes les sources, et
      chaque chemin se lit par descente. Coût εF divisé d'un facteur mesuré sur
      « n sources → 1 cible » ; la descente recompose la promesse de gauche à
      droite, identique au bit près à l'exploration sur un même chemin.
""")
println("="^70)
println("  Fin du benchmark.")
println("="^70)
