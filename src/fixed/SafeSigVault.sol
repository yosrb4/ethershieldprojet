// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract SafeSigVault is EIP712 {
    // Le "modele" du cheque : ce que signe Alice
    bytes32 public constant WITHDRAW_TYPEHASH =
        keccak256("Withdraw(address to,uint256 amount,uint256 nonce,uint256 deadline)");

    address public immutable signer;
    mapping(address => uint256) public nonces; // la "memoire" : prochain cheque attendu

    constructor(address _signer) payable EIP712("SafeSigVault", "1") {
        require(_signer != address(0), "zero signer");
        signer = _signer;
    }

    receive() external payable {}

    function withdraw(
        address payable to,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external {
        // 1. Expiration : le cheque a une date limite
        require(block.timestamp <= deadline, "signature expired");

        // 2. Empreinte EIP-712 : inclut le nonce attendu + le domaine
        //    (nom, version, chainId, adresse du contrat)
        bytes32 structHash = keccak256(
            abi.encode(WITHDRAW_TYPEHASH, to, amount, nonces[signer], deadline)
        );
        bytes32 digest = _hashTypedDataV4(structHash);

        // 3. Verification de la signature avec OpenZeppelin
        require(ECDSA.recover(digest, signature) == signer, "bad signature");

        // 4. La memoire : le cheque est "mort" AVANT d'envoyer l'ETH
        nonces[signer]++;

        // 5. Envoi
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
