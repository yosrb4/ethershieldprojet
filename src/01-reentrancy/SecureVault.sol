// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SecureVault
/// @notice Version corrigee de VulnerableVault : Checks-Effects-Interactions
///         + protection ReentrancyGuard (OpenZeppelin).
contract SecureVault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Montant nul");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Retirer tout son solde, de maniere securisee
    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Solde nul");

        // Effects AVANT Interactions : plus de fenetre d'attaque
        balances[msg.sender] = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Envoi echoue");

        emit Withdraw(msg.sender, amount);
    }

    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
