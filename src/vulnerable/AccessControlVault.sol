// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice VOLONTAIREMENT VULNERABLE - usage laboratoire uniquement
contract AccessControlVault {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    // FAILLE : aucune verification de l'appelant, n'importe qui peut devenir owner
    function setOwner(address newOwner) external {
        owner = newOwner;
    }

    // Cette fonction est bien protegee, mais owner peut etre change par n'importe qui
    function withdrawAll() external {
        require(msg.sender == owner, "not owner");
        (bool ok, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}
