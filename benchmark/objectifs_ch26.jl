# ============================================================================
#  Benchmark de conformité — catégorie 13 : « Aide multicritère à la décision »
#  (chapitre 26 du tableau 13.1)
# ----------------------------------------------------------------------------
#  Vérifie, engagement par engagement, que la treizième catégorie de la carte
#  (tableau 13.1) tient ce qu'elle consigne :
#
#    1. son inscription à la carte (nom, chapitre 26, problèmes, méthodes) et
#       son attestation par le théorème de couverture T-K4 ;                    (Dispositif)
#    2. la méthode 26.1 `classement_par_pesee_harmonique` : intégrité du
#       classement, degrés µ = min(plancher, agrégat), non-compensation native,
#       registre, cas limites et rejets ;                                        (Categories)
#    3. la méthode 26.2 `negociation_par_reponderation` : repondération des
#       regards, survie du plancher non négociable, bascule du classement,
#       registre, cas limites et rejets ;                                        (Categories)
#    4. la fidélité au socle : aucun chiffre rendu ne s'écarte de la formule
#       consignée (G5).
#
#  Chaque contrôle consigne `[✓]`/`[✗]` ; le script se termine par un bilan.
#  Aucune dépendance externe : `@timed` (Base), scalaires, `Printf`.
#
#  Usage :  julia --project=. --compiled-modules=no benchmark/objectifs_ch26.jl
# ============================================================================

using Printf
using Kamitique

const S = Kamitique.Socle
const D = Kamitique.Dispositif
const K = Kamitique.Categories

# ----------------------------------------------------------------------------
#  Instrumentation du rapport
# ----------------------------------------------------------------------------

const _RESULTATS = Tuple{String,String,Bool}[]
const _sec = Ref("—")
const _ok  = Ref(0)
const _tot = Ref(0)

"""Ouvre une section du rapport."""
function section(titre::AbstractString)
    _sec[] = titre
    println("\n", "━"^70)
    println("▶ ", titre)
end

"""Consigne un contrôle (nom, verdict) et l'affiche."""
function verifier(nom::AbstractString, cond::Bool)
    _tot[] += 1
    cond && (_ok[] += 1)
    push!(_RESULTATS, (_sec[], String(nom), cond))
    @printf("  [%s] %s\n", cond ? "✓" : "✗", nom)
    return cond
end

"""Vérifie qu'un appel échoue proprement (rejet attendu)."""
function rejette(nom::AbstractString, f)
    ok = false
    try
        f()
    catch e
        ok = e isa ArgumentError || e isa KeyError || e isa BoundsError
    end
    return verifier(nom, ok)
end

# ----------------------------------------------------------------------------
#  Fixtures — situées, bornées, reproductibles
# ----------------------------------------------------------------------------

"""
    harmonie_recalee(criteres, nn, poids) -> Vector{Float64}

Recalcule indépendamment l'harmonie de chaque alternative

    µ(a) = min( min des critères non négociables , moyenne pondérée des négociables )

avec les mêmes conventions de bornage (`clamp` dans [0, 1]) et de poids que la
méthode 26.1, afin de contrôler ses degrés sans lui faire confiance.
"""
function harmonie_recalee(criteres::AbstractMatrix{<:Real}, nn::AbstractVector{Bool},
                          poids::AbstractVector{<:Real})
    m, n = size(criteres)
    p = isempty(poids) ? ones(n) : float.(collect(poids))
    degres = zeros(m)
    for a in 1:m
        plancher = Inf
        for j in 1:n
            nn[j] && (plancher = min(plancher, clamp(float(criteres[a, j]), 0.0, 1.0)))
        end
        num = 0.0
        den = 0.0
        for j in 1:n
            nn[j] && continue
            w = max(p[j], 0.0)
            num += w * clamp(float(criteres[a, j]), 0.0, 1.0)
            den += w
        end
        agrege = den > 0 ? num / den : 1.0
        degres[a] = min(plancher, agrege)
    end
    return degres
end

"""Matrice 2×3 de l'énoncé de test : a1 = (0,9 ; 0,2 ; 0,6), a2 = (0,5 ; 0,8 ; 0,8) — critère 1 rédhibitoire."""
const _CRITERES = [0.9 0.2 0.6;
                   0.5 0.8 0.8]
const _NN = [true, false, false]

"""Matrice 2×3 construite pour éprouver la non-compensation : le compensé préfère a2, le natif préfère a1."""
const _CRITERES_FLIP = [0.6 0.6 0.6;
                        0.4 1.0 1.0]

# ============================================================================
println("="^70)
@printf("  BENCHMARK DE CONFORMITÉ — catégorie 13 : Aide multicritère à la décision\n")
@printf("  Julia %s · %d thread(s) · %s\n", VERSION, Threads.nthreads(), Sys.MACHINE)
println("="^70)

# ----------------------------------------------------------------------------
#  1. Inscription à la carte (tableau 13.1) et attestation par T-K4
# ----------------------------------------------------------------------------
section("1. Inscription à la carte (ch. 26) et attestation par la couverture T-K4")

cat = K.CARTE_CATEGORIES[13]
verifier("treizième entrée de la carte = « Aide multicritère à la décision »",
         cat.nom == "Aide multicritère à la décision")
verifier("chapitre 26 consigné", cat.chapitre == 26)
verifier("trois problèmes attestés (classement, pondération, sensibilité)",
         cat.problemes == ["classement", "pondération", "sensibilité"])
verifier("méthodes consignées (pesée des regards, non-compensation native)",
         "pesée des regards" in cat.methodes && "non-compensation native" in cat.methodes)
verifier("résolution de la catégorie par nom", K.categorie("Aide multicritère").chapitre == 26)

cov = S.completude_couverture([c.nom for c in K.CARTE_CATEGORIES])
verifier("T-K4 : triple substitution (support, valuation, dynamique) pour la catégorie",
         haskey(cov, "Aide multicritère à la décision") &&
         all(haskey(cov["Aide multicritère à la décision"], k) for k in (:support, :valuation, :dynamique)))

# ----------------------------------------------------------------------------
#  2. Méthode 26.1 — classement_par_pesee_harmonique
# ----------------------------------------------------------------------------
section("2. Méthode 26.1 — classement_par_pesee_harmonique : degrés, non-compensation")

cl = K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN)

verifier("classement complet (permutation de toutes les alternatives)",
         length(cl) == 2 && sort(cl.ordre) == [1, 2])
verifier("degrés ramenés dans [0, 1]", all(d -> 0.0 <= d <= 1.0, cl.degres))
verifier("degrés = min(plancher non négociable, agrégat des négociables) — recalcul indépendant",
         isapprox(cl.degres, harmonie_recalee(_CRITERES, _NN, Float64[]); atol = 1e-12))
verifier("ordre = degrés décroissants", issorted(cl.degres[cl.ordre]; rev = true))
verifier("registre consigné (entête, non-compensation, degrés)", length(cl.registre) == 3)
verifier("le registre énonce la non-compensation native",
         any(l -> occursin("non-compensation native", l), cl.registre))

# OBJECTIF AFFICHÉ : « le plancher … plafonne l'agrégat des négociables »
verifier("objectif non-compensation : a2 plafonnée à son plancher — min(0,5 ; 0,8) = 0,5",
         isapprox(cl.degres[2], 0.5; atol = 1e-12))
@printf("      µ recalculés = %s ; µ rendus = %s ; ordre = %s\n",
        harmonie_recalee(_CRITERES, _NN, Float64[]), cl.degres, cl.ordre)

cl_flip  = K.classement_par_pesee_harmonique(_CRITERES_FLIP; non_negociables = _NN)
cl_comp  = K.classement_par_pesee_harmonique(_CRITERES_FLIP)
verifier("objectif non-compensation : le critère rédhibitoire fait basculer le classement (compensé [2,1] → natif [1,2])",
         cl_comp.ordre == [2, 1] && cl_flip.ordre == [1, 2])
verifier("le compensé rachèterait le plancher (a2 = 0,8 ≻ a1 = 0,6) mais le natif le refuse (a2 = 0,4 ≺ a1 = 0,6)",
         cl_comp.degres[2] > cl_comp.degres[1] && cl_flip.degres[1] > cl_flip.degres[2])

# prise en compte des poids et de leur bornage
cl_poids = K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN,
                                             poids = [-1.0, -1.0, 1.0])
verifier("poids négatifs ramenés à 0 (seul le 3ᵉ critère compte : a1 = 0,6 ; a2 = 0,8→plafonné 0,5)",
         isapprox(cl_poids.degres, harmonie_recalee(_CRITERES, _NN, [-1.0, -1.0, 1.0]); atol = 1e-12))

# cas limites et rejets
cl1 = K.classement_par_pesee_harmonique(reshape([0.7], 1, 1); non_negociables = [true])
verifier("cas 1×1 non négociable : plancher conservé, aucun négociable ⇒ µ = 0,7",
         cl1.ordre == [1] && isapprox(cl1.degres[1], 0.7; atol = 1e-12))
verifier("classement déterministe (même entrée ⇒ mêmes degrés et même ordre)",
         K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN).ordre == cl.ordre &&
         K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN).degres == cl.degres)
rejette("aucune alternative refusée", () -> K.classement_par_pesee_harmonique(zeros(0, 3)))
rejette("aucun critère refusé",       () -> K.classement_par_pesee_harmonique(zeros(3, 0)))
rejette("un marqueur de non-négociabilité par critère exigé",
        () -> K.classement_par_pesee_harmonique(_CRITERES; non_negociables = [true, false]))
rejette("un poids par critère exigé",
        () -> K.classement_par_pesee_harmonique(_CRITERES; poids = [1.0, 1.0]))

# ----------------------------------------------------------------------------
#  3. Méthode 26.2 — negociation_par_reponderation
# ----------------------------------------------------------------------------
section("3. Méthode 26.2 — negociation_par_reponderation : regards, plancher préservé")

regards = [0.0, 0.0, 1.0]
ng = K.negociation_par_reponderation(_CRITERES, regards; non_negociables = _NN)

verifier("classement complet (permutation de toutes les alternatives)",
         length(ng) == 2 && sort(ng.ordre) == [1, 2])
verifier("degrés = classement par pesée harmonique aux regards donnés — recalcul indépendant",
         isapprox(ng.degres, harmonie_recalee(_CRITERES, _NN, regards); atol = 1e-12))
verifier("la négociation est le classement aux regards (mêmes degrés que 26.1 pondéré)",
         ng.degres == K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN,
                                                       poids = regards).degres)
verifier("registre consigné (3 lignes de classement + 1 ligne de négociation)",
         length(ng.registre) == 4 && any(l -> occursin("négociation", l), ng.registre))

# OBJECTIF AFFICHÉ : « Changer un regard ne touche jamais les critères non négociables »
verifier("objectif affiché — la repondération fait basculer le classement (compensé [2,1] → négocié [1,2])",
         cl.ordre == [2, 1] && ng.ordre == [1, 2])
verifier("objectif affiché — le plancher rédhibitoire survit (a2 maintenue à 0,5 malgré des négociables à 0,8)",
         isapprox(ng.degres[2], 0.5; atol = 1e-12))
ng_nn = K.negociation_par_reponderation(_CRITERES, [100.0, 0.0, 0.0]; non_negociables = _NN)
verifier("un poids arbitraire sur un critère non négociable ne modifie pas son plancher (µ identiques)",
         isapprox(ng_nn.degres, harmonie_recalee(_CRITERES, _NN, [100.0, 0.0, 0.0]); atol = 1e-12))

verifier("négociation déterministe (même entrée ⇒ mêmes degrés et même ordre)",
         K.negociation_par_reponderation(_CRITERES, regards; non_negociables = _NN).ordre == ng.ordre)

# cas limites et rejets
rejette("aucune alternative refusée",
        () -> K.negociation_par_reponderation(zeros(0, 3), [1.0, 1.0, 1.0]))
rejette("aucun critère refusé",
        () -> K.negociation_par_reponderation(zeros(3, 0), Float64[]))
rejette("un regard par critère exigé",
        () -> K.negociation_par_reponderation(_CRITERES, [1.0, 2.0]; non_negociables = _NN))
rejette("un marqueur de non-négociabilité par critère exigé",
        () -> K.negociation_par_reponderation(_CRITERES, regards; non_negociables = [true]))

# ----------------------------------------------------------------------------
#  4. Fidélité au socle et reproductibilité (G5)
# ----------------------------------------------------------------------------
section("4. Fidélité au socle et reproductibilité (G5)")

verifier("le classement ne fait que lire la matrice (aucun chiffre altéré par la méthode)",
         isapprox(cl.degres, harmonie_recalee(_CRITERES, _NN, Float64[]); atol = 1e-12))
verifier("la négociation ne fait que lire la matrice aux regards fournis (aucun chiffre inventé)",
         isapprox(ng.degres, harmonie_recalee(_CRITERES, _NN, regards); atol = 1e-12))
verifier("classement reproductible (même entrée ⇒ mêmes degrés et même ordre)",
         (r1 = K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN);
          r2 = K.classement_par_pesee_harmonique(_CRITERES; non_negociables = _NN);
          r1.degres == r2.degres && r1.ordre == r2.ordre))
verifier("toute alternative est classée : longueur du résultat = nombre d'alternatives",
         length(K.classement_par_pesee_harmonique(_CRITERES_FLIP; non_negociables = _NN)) == 2)

# ----------------------------------------------------------------------------
#  5. Synthèse — bilan objectif par objectif
# ----------------------------------------------------------------------------
println("\n", "="^70)
println("  SYNTHÈSE — la catégorie 13 (ch. 26) atteint-elle ses objectifs ?")
println("="^70)

for s in unique([r[1] for r in _RESULTATS])
    n_ok  = count(r -> r[3], filter(r -> r[1] == s, _RESULTATS))
    n_tot = count(r -> r[1] == s, _RESULTATS)
    @printf("  [%s] %-58s %2d/%2d\n", n_ok == n_tot ? "✓" : "✗", s, n_ok, n_tot)
end

println("-"^70)
@printf("  BILAN CATÉGORIE 13 : %d/%d contrôles conformes\n", _ok[], _tot[])
println("="^70)
if _ok[] == _tot[]
    println("  ⇒ Tous les engagements de la catégorie sont tenus sur cette exécution.")
else
    println("  ⇒ Des engagements de la catégorie ne sont PAS tenus — voir les lignes [✗].")
end
println("="^70)
println("  Fin du benchmark de la catégorie 13.")
println("="^70)
