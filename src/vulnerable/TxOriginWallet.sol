// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice VOLONTAIREMENT VULNERABLE - usage laboratoire uniquement
contract TxOriginWallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    function transferTo(address payable to, uint256 amount) external {
        require(tx.origin == owner, "not owner"); // FAILLE : mauvaise identite
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
