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
Correction dans `src/06-dos/SecureAuction.sol` : modèle "pull over push".

- `bid()` ne fait plus aucun appel externe : il enregistre seulement le montant dû
  à l'ancien meilleur offrant dans `pendingReturns`. Rien ne peut donc faire échouer
  une nouvelle offre.
- `withdraw()` permet à chaque offrant de retirer lui-même son remboursement, selon
  le schéma Checks-Effects-Interactions (solde remis à zéro et événement émis avant
  l'appel externe).

Un attaquant qui refuse l'ETH ne bloque plus que son propre retrait.

## 8. Validation
Tests Forge : `test/06-dos/DoSSecure.t.sol` (3 tests, tous passés).
- `test_AttackerCannotBlockAuction` : Bob peut enchérir malgré l'attaquant.
- `test_AttackerRefusalOnlyHurtsHimself` : le retrait de l'attaquant échoue, mais
  l'enchère continue.
- `test_HonestUserCanWithdraw` : un utilisateur honnête récupère son remboursement.

Résultat global : 5 tests passés (2 sur la version vulnérable, 3 sur la version corrigée).
Rapport Slither de la version corrigée : `reports/slither_dos_fixed.txt`.

## 9. Limites résiduelles
- Un offrant dont le contrat refuse l'ETH ne récupère jamais son remboursement
  (il n'a que lui-même à blâmer, mais ses fonds restent bloqués dans le contrat).
- Pas de date de fin d'enchère ni de vendeur dans ce contrat de laboratoire.
