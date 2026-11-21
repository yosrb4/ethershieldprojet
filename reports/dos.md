# Rapport d'audit : Denial of Service (VulnerableAuction)

## 1. Description
`VulnerableAuction` est une enchère où chaque nouvelle meilleure offre rembourse
automatiquement l'ancien meilleur offrant, avec un appel externe (`call`) dont le
succès est exigé (`require(ok)`).

## 2. Cause racine
Le remboursement est "poussé" (push) par le contrat dans la même transaction que
l'enchère. Si le destinataire est un contrat qui refuse l'ETH (`revert` dans `receive()`),
l'appel échoue, `require(ok)` fait échouer toute la transaction, et plus personne
ne peut enchérir. Le contrat dépend du bon comportement d'une adresse contrôlée par
un tiers.

## 3. Impact
- Blocage permanent de l'enchère : l'attaquant reste meilleur offrant pour toujours.
- Aucun vol de fonds, mais perte de disponibilité du service (Denial of Service).
- L'attaquant peut ainsi remporter l'enchère à bas prix.

## 4. Preuve
Test Forge : `test/06-dos/DoS.t.sol`
- `test_NormalAuction_Works` : sans attaquant, l'enchère fonctionne.
- `test_DoS_BlocksAuction` : avec le contrat `Attacker`, l'offre de Bob est rejetée
  avec l'erreur `Remboursement echoue` et l'attaquant reste en tête.

## 5. Résultats Slither (reports/slither_dos_vulnerable.txt)
| Détecteur | Classification | Remarque |
|---|---|---|
| low-level-calls (bid) | Informationnel, lié à la faille | Pointe la bonne ligne mais ne détecte pas le DoS |
| immutable-states (Attacker.auction) | Faux positif | Optimisation de gas sur le contrat attaquant |
| DoS par échec d'appel externe | Vrai positif non détecté par Slither | Confirmé par le test d'exploitation |

Conclusion : l'analyse statique seule ne suffit pas, la revue manuelle et les tests
d'exploitation sont nécessaires.

## 6. Sévérité
Moyenne : perte de disponibilité sans perte de fonds (à ajuster en équipe).

## 7. Correctif et validation
À compléter après les étapes 4/fix et 5/retest.
