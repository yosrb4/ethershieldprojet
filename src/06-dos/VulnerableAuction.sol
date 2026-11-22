// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title VulnerableAuction
/// @notice LABORATOIRE EtherShield : contrat VOLONTAIREMENT vulnérable (Denial of Service).
///         À ne jamais déployer sur un réseau public.
contract VulnerableAuction {
    address public highestBidder;
    uint256 public highestBid;

    event NewHighestBid(address indexed bidder, uint256 amount);

    /// @notice Placer une offre plus élevée que la meilleure offre actuelle.
    function bid() external payable {
        require(msg.value > highestBid, "Offre trop basse");

        address previousBidder = highestBidder;
        uint256 previousBid = highestBid;

        // On met à jour l'état AVANT l'appel externe, pour isoler la faille DoS
        // (et ne pas la mélanger avec une faille de reentrancy).
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit NewHighestBid(msg.sender, msg.value);

        // FAILLE (DoS) : on rembourse l'ancien meilleur offrant avec un appel externe
        // et on exige qu'il réussisse. Si l'ancien offrant est un contrat qui refuse
        // l'argent (revert), TOUTE la transaction échoue : plus personne ne peut enchérir.
        if (previousBidder != address(0)) {
            (bool ok,) = previousBidder.call{value: previousBid}("");
            require(ok, "Remboursement echoue");
        }
    }
}
