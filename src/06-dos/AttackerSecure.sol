// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SecureAuction} from "./SecureAuction.sol";

/// @title AttackerSecure
/// @notice Même attaquant malveillant que Attacker, mais contre SecureAuction.
contract AttackerSecure {
    SecureAuction public immutable auction;

    constructor(address _auction) {
        auction = SecureAuction(_auction);
    }

    function attack() external payable {
        auction.bid{value: msg.value}();
    }

    function tryWithdraw() external {
        auction.withdraw();
    }

    /// Je refuse toujours l'argent.
    receive() external payable {
        revert("Je refuse le remboursement");
    }
}
