* =======================================
* CALCUL DU MPI NATIONAL, RÉGIONAL ET PAR MILIEU REGROUPE
* Auteur : Pape Mamadou BADJI
* Date : Juin 2025
* =======================================

* -------- 1. Charger la base principale --------

// Ce fichier est rattaché au premier

* -------- 2. Création de la variable milieu_regroupe --------
* Codes connus :
* Dakar = 1
* Urbain = 1
* Rural = 2

gen milieu_regroupe = .
replace milieu_regroupe = 1 if region == 1 & milieu == 1       // Dakar urbain
replace milieu_regroupe = 2 if region != 1 & milieu == 1       // Autres villes urbaines
replace milieu_regroupe = 3 if milieu == 2                     // Rural

label define milieu_regroupe_lbl 1 "Dakar urbain" 2 "Autres villes urbaines" 3 "Rural"
label values milieu_regroupe milieu_regroupe_lbl

tabulate milieu_regroupe, missing

* -------- 3. Indice de privation (poids uniformes) --------
local poids_indic = 1 / 21
gen indice_priv = ///
    `poids_indic' * (priv_freq_scol + priv_educ6 + priv_alfa + ///
                     priv_sante_couv + priv_soins + priv_sante_chronique + priv_handicap + ///
                     priv_chomage + priv_dependance_eco + priv_sousemploi + priv_protection + priv_trav_enfant + ///
                     priv_logement + priv_eclairage + priv_evacuation + priv_ordure + priv_eau + priv_cuisson + priv_toilet + priv_equipement + ///
                     priv_choc)

* -------- 4. Pauvreté multidimensionnelle --------
gen pauvre_multidim = (indice_priv >= 0.32)
label define pauvre 0 "Non pauvre" 1 "Pauvre"
label values pauvre_multidim pauvre

* -------- 5. MPI NATIONAL --------
gen H = pauvre_multidim
sum H
local taux_pauvre = r(mean)
sum indice_priv if pauvre_multidim == 1
local intensite = r(mean)

di "--------------------------------------------------"
di "MPI national = " %6.3f (`taux_pauvre' * `intensite' * 100)
di "=> H (taux de pauvreté) = " %6.3f (`taux_pauvre'*100) "%"
di "=> A (intensité moyenne) = " %6.3f (`intensite'*100) "%"
di "--------------------------------------------------"

* -------- 6. MPI PAR RÉGION --------
tempfile base_indice
save `base_indice', replace

* Taux de pauvreté (H) par région
gen pauvre_poids = pauvre_multidim * hhweight
gen poids = hhweight
collapse (sum) poor_pop = pauvre_poids total_pop = poids, by(region)
gen taux_pauvre = 100 * poor_pop / total_pop
save "${data}/taux_pauvre_region.dta", replace

* Intensité (A) par région
use `base_indice', clear
keep if pauvre_multidim == 1
gen indice_pondere = indice_priv * hhweight
gen poids = hhweight
collapse (sum) somme_indice = indice_pondere total_poids = poids, by(region)
gen intensite = somme_indice / total_poids
save "${data}/intensite_region.dta", replace

* MPI par région
use "${data}/taux_pauvre_region.dta", clear
merge 1:1 region using "intensite_region.dta", nogen
gen MPI = (taux_pauvre / 100) * intensite * 100
save "${data}/MPI_region.dta", replace
di "-----------------------------------------------"
di "MPI par région :"
list region taux_pauvre intensite MPI, sep(0) noobs

export excel region taux_pauvre intensite MPI using "${outputs}/pauvrete_region.xlsx", firstrow(variables) replace

* -------- 7. MPI PAR MILIEU REGROUPE (Dakar urbain, Autres villes urbaines, Rural) --------

use `base_indice', clear

* Taux de pauvreté (H) par milieu_regroupe
gen pauvre_poids = pauvre_multidim * hhweight
gen poids = hhweight
collapse (sum) poor_pop = pauvre_poids total_pop = poids, by(milieu_regroupe)
gen taux_pauvre = 100 * poor_pop / total_pop
save "${data}/taux_pauvre_milieu.dta", replace

* Intensité (A) par milieu_regroupe
use `base_indice', clear
keep if pauvre_multidim == 1
gen indice_pondere = indice_priv * hhweight
gen poids = hhweight
collapse (sum) somme_indice = indice_pondere total_poids = poids, by(milieu_regroupe)
gen intensite = somme_indice / total_poids
save "${data}/intensite_milieu.dta", replace

* MPI par milieu_regroupe
use "${data}/taux_pauvre_milieu.dta", clear
merge 1:1 milieu_regroupe using "${data}/intensite_milieu.dta", nogen
gen MPI = (taux_pauvre / 100) * intensite * 100
save "${data}/MPI_milieu.dta", replace
di "-----------------------------------------------"
di "MPI par milieu_regroupe :"
list milieu_regroupe taux_pauvre intensite MPI, sep(0) noobs

export excel milieu_regroupe taux_pauvre intensite MPI using "${outputs}/pauvrete_milieu.xlsx", firstrow(variables) replace

* -------- 8. CONTRIBUTION DES INDICATEURS ET DIMENSIONS --------
use `base_indice', clear
keep if pauvre_multidim == 1
gen poids = hhweight
local indicateurs priv_freq_scol priv_educ6 priv_alfa ///
                  priv_sante_couv priv_soins priv_sante_chronique priv_handicap ///
                  priv_chomage priv_dependance_eco priv_sousemploi priv_protection priv_trav_enfant ///
                  priv_logement priv_eclairage priv_evacuation priv_ordure priv_eau priv_cuisson priv_toilet priv_equipement ///
                  priv_choc

* Appliquer le poids aux indicateurs
foreach var of local indicateurs {
    gen w_`var' = `poids_indic' * `var'
    gen contrib_`var' = w_`var' * poids
}

* Total des pondérations pour les pauvres
collapse (sum) poids ///
         contrib_priv_*, by(pauvre_multidim)

		 
egen total_contribution = rowtotal(contrib_priv_*)

* Recalcul des parts relatives (% contribution)
foreach var of local indicateurs {
    gen part_`var' = 100 * contrib_`var' / total_contribution
}

* Contribution par dimension
gen part_Education = part_priv_freq_scol + part_priv_educ6 + part_priv_alfa
gen part_Sante     = part_priv_sante_couv + part_priv_soins + part_priv_sante_chronique + part_priv_handicap
gen part_Emploi    = part_priv_chomage + part_priv_dependance_eco + part_priv_sousemploi + part_priv_protection + part_priv_trav_enfant
gen part_CondVie   = part_priv_logement + part_priv_eclairage + part_priv_evacuation + part_priv_ordure + part_priv_eau + part_priv_cuisson + part_priv_toilet + part_priv_equipement
gen part_Choc      = part_priv_choc

* Générer la somme des contributions
gen total_contrib = part_Education + part_Sante + part_Emploi + part_CondVie + part_Choc

* Nettoyage et export
keep part_*
export excel using "${outputs}/contribution_indicateurs_dimensions.xlsx", firstrow(variables) replace
