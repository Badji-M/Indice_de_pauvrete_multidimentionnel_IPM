
*********************************************
***			Title : TP01 - AS2 - Indice de Pauvreté Multidimentionel (IPM)
***			Files : "EHCVM-2021"
***			Last update : 08 JUIN 2025
***	 Author : Pape Mamadou BADJI & Kassi Mamadou MAXWELL  
***********************************************

*_____________________________________________________________________________________________________________________________



* Define root
global root "C:\Users\hp\OneDrive\Bureau\AS2_2024_2025\SEMESTRE 2\STATA SPSS"

* Define sub-paths
global Datawork "${root}/PROJET_STATA_IPM"
global data "${Datawork}/Données"
global codes "${Datawork}/Files"
global outputs "${Datawork}/Outputs"



use "${data}/ehcvm_individu_SEN2021.dta", clear


**************************************************
* //Dimension : Éducation
****************************************************

* Création des variables de privation pour chaque indicateur
* -----------------------------------------------------------

*** INDICATEUR 1 : Fréquentation scolaire ***
* Critère : Le ménage a un enfant de 6 à 16 ans qui ne fréquente pas l'école


**# Bookmark #8
rename numind s01q00a
merge 1:1 grappe menage s01q00a using"${data}/s02_me_SEN2021.dta",keepusing(s02q12) gen(first_merge)
rename s02q12 freq_scol
label variable freq_scol "Frequente t'il l'ecole"

merge 1:1 grappe menage s01q00a using"${data}/s03_me_SEN2021.dta",keepusing(s03q01 s03q05 s03q02) gen(second_merge)
rename s03q01 prob_sante
rename s03q05 consultation
rename s03q02 princ_pb_sante


gen enfant_non_scol = (age >= 6 & age <= 16) & (freq_scol == 2)
bysort hhid (enfant_non_scol): egen priv_freq_scol = max(enfant_non_scol)



*** INDICATEUR 3 : Nombre d'année de scolarité ***
* Critère :  Aucun membre du ménage âgé de 15 ans ou plus n'a complété 6 années d'études (ie le niveau primaire)

	* 1. Créer la variable binaire : a complété ≥6 ans d'études ?
	gen educ6 = .

	replace educ6 = 1 if inlist(educ_hi,3,4,5,6,7,8,9)
	   
	replace educ6 = 0 if inlist(educ_hi,1,2)

	* 2. Ne considérer que les membres de 15 ans ou plus
	gen educ6_15plus = .
	replace educ6_15plus = educ6 if age >= 15

	* 3. Vérifier s'il y a AU MOINS un membre de 15 ans+ avec >=6 ans d'études
	bysort hhid: egen priv_educ = max(educ6_15plus)

	* 4. Générer la variable de privation : 1 = privé (aucun membre 15+ avec 6 ans ou plus)
	gen priv_educ6 = (priv_educ == 0)
	label variable priv_educ6 "Privation : Aucun membre 15+ n'a complété 6 ans d'études"


*** INDICATEUR 4 : Alphabétisation ***
* Critère : Le quart des membres du ménage de 15 ans ou plus ne sait pas lire ou écrire (Français/Arabe/Autre)


	* 1. Marquer les individus de 15 ans ou plus
	gen age15plus = (age >= 15)

	* 2. Créer la variable indicatrice d'analphabétisme
	gen analphabete = .
	replace analphabete = 1 if alfa2 == 0 & age15plus == 1
	replace analphabete = 0 if alfa2 == 1 & age15plus == 1

	* 3. Calculer par ménage :
	* - le nombre total de membres de 15 ans ou plus
	* - le nombre d'analphabètes

	bysort hhid : egen nb_15plus = total(age15plus)
	bysort hhid : egen nb_analphab = total(analphabete)

	* 4. Calcul de la proportion
	gen prop_analphab = nb_analphab / nb_15plus

	* 5. Variable de privation : 1 si ≥ 25% des membres de 15+ sont analphabètes
	gen priv_alfa = (prop_analphab >= 0.25)
	label variable priv_alfa "Privation : ≥25% des 15+ sont analphabètes"


**************************************************
* //Dimension : Santé
****************************************************

* Création des variables de privation pour chaque indicateur
* -----------------------------------------------------------

*** INDICATEUR 1 : Couverture maladie ***
* Seuil de privation : Plus du tiers des membres ne disposent d'aucune couverture maladie

gen sans_couv = (couvmal == 0)
bysort hhid : gen n_menage = _N
bysort hhid : egen n_sans_couv = total(sans_couv)
gen prop_sans_couv = n_sans_couv / n_menage
gen priv_sante_couv = (prop_sans_couv > 1/3)



*** INDICATEUR 2 : Privations de soins de santé***
* Seuil de privation :  le menage compte au moins un membre ayant déclaré un problème de santé au cours des quatre dernières semaines (s03q01 = 1) mais n'ayant pas consulté de structure de soins (s03q05 = 2).

gen privation_soins = (prob_sante == 1 & consultation == 2)
bysort hhid: egen priv_soins = max(privation_soins)



*** INDICATEUR 3 : Maladies chroniques***
* Seuil de privation : Un membre souffre d'une maladie chronique (tension ou diabète)

gen maladie_chronique = inlist(princ_pb_sante, 7, 12)
bysort hhid: egen nb_maladie_chronique = total(maladie_chronique)
gen priv_sante_chronique = (nb_maladie_chronique > 0)



*** INDICATEUR 4 : Handicap***
* Seuil de privation : Un membre a un handicap physique ou mental l'empêchant de travailler ou d'étudier.


gen privation_handicap = .
replace privation_handicap = 1 if handit == 1
replace privation_handicap = 0 if handit == 0
bysort hhid: egen priv_handicap = max(privation_handicap)






**************************************************
* //Dimension : Emploi
****************************************************

* Création des variables de privation pour chaque indicateur
* -----------------------------------------------------------


*** INDICATEUR 1 : Chomage ***
* Seuil de privation : Le nombre de chômeurs est supérieur à la moitié des actifs


	gen actif = (activ7j == 1)
	gen chomeur = (activ7j == 4)
	bysort hhid : egen nb_actif = total(actif)
	bysort hhid : egen nb_chomeur = total(chomeur)
	gen priv_chomage = (nb_chomeur > nb_actif / 2)



*** INDICATEUR 2 : Dépendance économique ***
* Seuil de privation :Le taux de dépendance est supérieur à 2


	*les personnes économiquement dépendantes (non-actifs)
	gen dependant = (activ7j != 1)
	bysort hhid: egen nb_dependant = total(dependant)
	gen taux_dependance = 100 * nb_dependant / nb_actif
	replace taux_dependance = . if nb_actif == 0
	gen priv_dependance_eco = (taux_dependance > 200)
	replace priv_dependance_eco = 1 if missing(taux_dependance)




*** INDICATEUR 3 : Sous-emploi ***
* Seuil de privation :Le nombre de travailleurs sous-employés est supérieur au tiers des occupés du ménage


	* 3. Identifier les sous-employés (moins de 1 040 heures/an, soit la moitié de 2 080 heures)
	gen sous_employe = (actif == 1 & volhor < 1040)

	* 4. Agréger au niveau du ménage
	bysort hhid: egen nb_sous_employe = total(sous_employe)

	* 5. Créer l'indicateur de privation
	gen priv_sousemploi = (nb_sous_employe > nb_actif / 3)



*** INDICATEUR 4 : Protection sociale (Informalité _ abscence de couverture maladie ***
* Seuil de privation :Le ménage est privé si le nombre de travailleurs occupés sans couverture maladie est supérieur à la moitié des occupés du ménage.

	gen occupe_sans_couv = (actif == 1 & couvmal == 0)
	bysort hhid: egen nb_sans_couv = total(occupe_sans_couv)
	gen priv_protection = (nb_sans_couv > nb_actif / 2)



*** INDICATEUR 5 : Travail des enfants ***
* Seuil de privation :Le ménage est privé s'il y a un enfant de moins de 15 ans exerçant un travail

	gen enfant_occupe = (age < 15 & activ7j == 1)
	bysort hhid : egen priv_trav_enfant = max(enfant_occupe)



**PASSATION DE BASE;DTA
	bysort hhid (s01q00a): keep if _n == 1
	save "${data}/privation_education_sante_emploi.dta", replace
	use "${data}/ehcvm_menage_SEN2021"
	merge 1:1 hhid using "${data}/privation_education_sante_emploi.dta"

**************************************************
* //Dimension : Conditions de vie
****************************************************

* Création des variables de privation pour chaque indicateur
* -----------------------------------------------------------


*** INDICATEUR 1 : Type de logement ***
* Seuil de privation : Le logement est une case, une baraque ou un autre type non-durable


gen priv_logement = (mur == 0 | toit == 0)



*** INDICATEUR 2 : Électricité ***
* Seuil de privation : L'éclairage n'est ni électrique, ni par groupe électrogène, ni solaire

gen priv_eclairage = (elec_ua == 0 & elec_ur == 0)



*** INDICATEUR 3 : Évacuation des eaux usées ***
* Seuil de privation : L'évacuation se fait dans la cour ou dans la rue/nature


// gen priv_evacuation = (eva_ea == 0 | eva_toi== 0)
gen priv_evacuation = (eva_ea == 0)



*** INDICATEUR 4 : Évacuation des ordures ***
* Seuil de privation : L'évacuation se fait par tas d'immondices ou dans la route/rue

gen priv_ordure = (ordure == 0)


*** INDICATEUR 5 : Eau potable ***
* Seuil de privation : Le ménage n'a pas accès à l'eau potable


gen priv_eau = (eauboi_sp == 0 & eauboi_ss == 0)

*** INDICATEUR 6 : Énergie de cuisson ***
* Seuil de privation : Le ménage n'utilise pas d'électricité ou de gaz pour la cuisson

gen priv_cuisson = (cuisin == 0)



*** INDICATEUR 7 : Toilettes ***
* Seuil de privation : Le ménage ne dispose pas de toilettes privées améliorées

gen priv_toilet = (toilet == 0)


*** INDICATEUR 8 : Biens d'équipement ***
/* Seuil de privation : Le ménage dispose de moins de 2 équipements dans la liste suivante :
 --ventilateur--, TV, ordinateur, cuisinière, réfrigérateur, --bicyclette--, motocyclette 
 et ne dispose ni de voiture, camion, machine à laver ou groupe électrogène */


gen priv_equipement = ((tv + ordin + cuisin + frigo + fer + decod) < 2) & (car == 0)




**************************************************
* //Dimension : Sécurité et Chocs
****************************************************

* Création des variables de privation pour chaque indicateur
* -----------------------------------------------------------

*** INDICATEUR 1 : Nombre de chocs***
* Seuil de privation :Le ménage a vecu au cours des 12 derniers mois plus de deux de ces 5 chocs (choc covariant economique - Choc covariant naturrel - Choc covariant violence - Choc idio démographique - Choc idio economique)


gen nb_choc = sh_co_eco + sh_co_natu + sh_co_vio + sh_id_demo + sh_id_eco
gen priv_choc = (nb_choc > 2)


save "${data}/base_finale.dta", replace














