# Indice de Pauvreté Multidimensionnelle (IPM) du Sénégal

Construction de l'Indice de Pauvreté Multidimensionnelle du Sénégal selon la méthode Alkire-Foster, à partir de l'Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM 2021).

**Auteurs :** Pape Mamadou BADJI, Kassi Mamadou MAXWELL (ENSAE)
**Date :** juin 2025
**Outil :** Python, R & Stata" 

---

## Objectif

La pauvreté monétaire ne capture pas toutes les privations que subissent les ménages. Ce projet mesure la pauvreté sous plusieurs dimensions à la fois (éducation, santé, emploi, conditions de vie, exposition aux chocs) et identifie les régions et milieux de résidence les plus touchés.

## Méthodologie

### 1. Indicateurs de privation

21 indicateurs binaires sont construits au niveau du ménage, par exemple :

| Dimension | Exemples d'indicateurs |
|---|---|
| Éducation | Enfant de 6 à 16 ans non scolarisé ; aucun membre de 15 ans ou plus n'a achevé 6 années d'études ; au moins 25 % des membres de 15 ans ou plus sont analphabètes |
| Santé | Plus d'un tiers des membres sans couverture maladie ; problème de santé sans consultation ; maladie chronique ; handicap |
| Emploi | Chômeurs plus nombreux que la moitié des actifs ; taux de dépendance supérieur à 200 % ; sous-emploi ; absence de protection sociale ; travail des enfants |
| Conditions de vie | Logement, éclairage, évacuation des eaux, ordures, eau potable, combustible de cuisson, toilettes, équipements |
| Chocs | Exposition du ménage à un choc |

### 2. Agrégation (Alkire-Foster)

- **Score de privation** : moyenne pondérée des 21 indicateurs (poids uniformes de 1/21)
- **Identification** : un ménage est pauvre multidimensionnel si son score est supérieur ou égal à 0,32
- **H** : incidence, c'est-à-dire la part de la population pauvre
- **A** : intensité, c'est-à-dire le score moyen des pauvres
- **IPM = H × A**

Tous les calculs sont pondérés par les poids de sondage de l'EHCVM.

### 3. Niveaux de désagrégation

- National
- Régional (14 régions)
- Par milieu : Dakar urbain, autres villes urbaines, rural

Le projet calcule aussi la contribution de chaque indicateur et de chaque dimension à l'IPM.

## Structure du dépôt

```
.
├── Données/      Bases EHCVM 2021 et bases intermédiaires (.dta)
├── Files/
│   ├── IPM_Sabina_Alkir.do   Construction des 21 indicateurs de privation
│   └── CALCULS.do            Calcul de H, A et de l'IPM (national, régions, milieux)
└── Outputs/      Rapport PDF, cartes et graphiques (.png), tableaux (.xlsx)
```

## Reproduire l'analyse

1. Ouvrir `Files/IPM_Sabina_Alkir.do` et modifier le chemin `global root` pour pointer vers le dossier du projet.
2. Exécuter `IPM_Sabina_Alkir.do`, puis `CALCULS.do`.
3. Les résultats sont exportés dans `Outputs/`.

## Résultats

Le rapport complet se trouve dans `Outputs/BADJI_MAXWELL_IPM_Alkire_&_Foster_STATA.pdf`. Il présente :

- l'IPM national et sa décomposition en incidence et intensité ;
- la cartographie de l'IPM par région ;
- les écarts entre Dakar, les autres villes et le milieu rural ;
- la contribution de chaque dimension à la pauvreté multidimensionnelle.

## Source des données

Agence Nationale de la Statistique et de la Démographie (ANSD), Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM) 2021, Sénégal.
