// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SafeAccessControlVault is Ownable {
    constructor() payable Ownable(msg.sender) {}

    receive() external payable {}

    // transferOwnership (heritee de Ownable) est reservee au proprietaire (onlyOwner).
    // L'ancienne fonction setOwner, sans protection, a disparu.

    function withdrawAll() external onlyOwner {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok, "transfer failed");
    }
}
