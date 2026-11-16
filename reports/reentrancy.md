# Rapport d'audit : Reentrancy — VulnerableVault.sol

## Description
La fonction `withdraw()` envoie l'ETH a l'appelant (via un appel externe
`call`) AVANT de remettre a zero le solde enregistre dans `balances`.
Un contrat appelant malveillant peut, durant la reception de l'ETH,
rappeler `withdraw()` plusieurs fois avant que son solde soit mis a jour,
et ainsi retirer bien plus que ce qu'il possede reellement.

## Severite
Haute (Critique) — perte totale des fonds du contrat.

## Impact
Un attaquant peut vider l'intégralite de l'ETH deposee par tous les
utilisateurs du vault, avec un investissement initial minime.

## Preuve (Proof of Concept)
- Outil 1 : Foundry build linter -> warning `reentrancy-eth`
  (VulnerableVault.sol:27)
- Outil 2 : Slither -> detecteurs `reentrancy-eth`, `reentrancy-events`,
  `low-level-calls`
- Outil 3 : Test Forge `test_ExploitDrainsVault()` (PASS) :
  - Vault avant attaque : 10 ETH (depot d'Alice)
  - Attaquant investit : 1 ETH
  - Vault apres attaque : 0 ETH
  - Solde final de l'attaquant : 11 ETH
  - balances[alice] reste a 10 ETH alors que le vault est vide

## Classement des findings Slither
| Detecteur          | Statut        | Gravite |
|--------------------|---------------|---------|
| reentrancy-eth      | Vrai positif  | Haute   |
| reentrancy-events   | Vrai positif  | Faible  |
| low-level-calls     | Informatif    | -       |

## Correctif (a appliquer en etape 4/fix)
- Appliquer le pattern Checks-Effects-Interactions : mettre
  `balances[msg.sender] = 0` AVANT l'appel `call`.
- Ajouter `ReentrancyGuard` d'OpenZeppelin en protection supplementaire.

## Validation
A completer en etape 5/retest : re-executer `test_ExploitDrainsVault()`
sur le contrat corrige et verifier qu'il echoue (attaque bloquee).
