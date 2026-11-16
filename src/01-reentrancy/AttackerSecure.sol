// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SecureVault} from "./SecureVault.sol";

/// @title AttackerSecure
/// @notice Reutilise la meme strategie d'attaque que Attacker.sol,
///         mais ciblee sur SecureVault, pour prouver que la faille
///         est corrigee (non-regression).
contract AttackerSecure {
    SecureVault public immutable vault;
    address public immutable owner;

    constructor(address _vault) {
        vault = SecureVault(_vault);
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.value > 0, "Envoyer de l'ETH pour attaquer");
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= msg.value) {
            vault.withdraw();
        }
    }
}
