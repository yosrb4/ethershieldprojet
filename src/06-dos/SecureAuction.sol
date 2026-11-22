// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SecureAuction
/// @notice Version corrigée de VulnerableAuction : modèle "pull over push".
///         Les remboursements ne sont plus envoyés automatiquement, chaque
///         offrant retire lui-même son argent avec withdraw().
contract SecureAuction {
    address public highestBidder;
    uint256 public highestBid;

    /// Montants à rembourser, par adresse.
    mapping(address => uint256) public pendingReturns;

    event NewHighestBid(address indexed bidder, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function bid() external payable {
        require(msg.value > highestBid, "Offre trop basse");

        // CORRECTION : on note simplement ce qu'on doit à l'ancien offrant,
        // sans aucun appel externe. Rien ne peut donc faire échouer bid().
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit NewHighestBid(msg.sender, msg.value);
    }

    /// Chaque offrant récupère lui-même son remboursement.
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Rien a retirer");

        // Checks-Effects-Interactions : état et événement AVANT l'appel externe.
        pendingReturns[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);

        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Retrait echoue");
    }
}
