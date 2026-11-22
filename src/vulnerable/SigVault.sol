// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice VOLONTAIREMENT VULNERABLE - usage laboratoire uniquement
contract SigVault {
    address public signer; // celui dont la signature autorise un retrait

    constructor(address _signer) payable {
        signer = _signer;
    }

    receive() external payable {}

    function withdraw(
        address payable to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Ce qui est signe : seulement (to, amount)
        bytes32 hash = keccak256(abi.encodePacked(to, amount));
        bytes32 ethHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        address recovered = ecrecover(ethHash, v, r, s);
        require(recovered == signer, "bad signature");

        // FAILLE : aucun nonce, aucune expiration, signature rejouable a l'infini
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
