// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SafeWallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    function transferTo(address payable to, uint256 amount) external {
        require(msg.sender == owner, "not owner"); // CORRECTION
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
