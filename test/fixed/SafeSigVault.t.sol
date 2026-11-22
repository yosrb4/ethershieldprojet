// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/fixed/SafeSigVault.sol";

contract SafeSigVaultTest is Test {
    SafeSigVault vault;
    address alice;
    uint256 alicePk;
    address payable bob;

    function setUp() public {
        (alice, alicePk) = makeAddrAndKey("alice");
        bob = payable(makeAddr("bob"));
        vault = new SafeSigVault{value: 5 ether}(alice);
    }

    // Alice signe un "cheque" EIP-712 pour un coffre donne
    function _sign(
        SafeSigVault target,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(target.WITHDRAW_TYPEHASH(), to, amount, nonce, deadline)
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SafeSigVault")),
                keccak256(bytes("1")),
                block.chainid,
                address(target)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        return abi.encodePacked(r, s, v);
    }

    function test_fixed_replayFails() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _sign(vault, bob, 1 ether, 0, deadline);

        // 1er retrait : legitime, il passe
        vault.withdraw(bob, 1 ether, deadline, sig);
        assertEq(bob.balance, 1 ether);
        assertEq(vault.nonces(alice), 1);

        // Rejeu de la MEME signature : refuse (le nonce attendu est maintenant 1)
        vm.expectRevert("bad signature");
        vault.withdraw(bob, 1 ether, deadline, sig);

        // Bob n'a toujours que 1 ETH, le coffre en garde 4
        assertEq(bob.balance, 1 ether);
        assertEq(address(vault).balance, 4 ether);
    }

    function test_fixed_expiredSignatureFails() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _sign(vault, bob, 1 ether, 0, deadline);

        vm.warp(deadline + 1); // on avance le temps apres la date limite

        vm.expectRevert("signature expired");
        vault.withdraw(bob, 1 ether, deadline, sig);

        assertEq(address(vault).balance, 5 ether);
    }

    function test_fixed_signatureNotValidOnOtherVault() public {
        SafeSigVault otherVault = new SafeSigVault{value: 5 ether}(alice);

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _sign(vault, bob, 1 ether, 0, deadline); // faite pour "vault"

        // Presentee a un AUTRE coffre : refusee (domaine different)
        vm.expectRevert("bad signature");
        otherVault.withdraw(bob, 1 ether, deadline, sig);

        assertEq(address(otherVault).balance, 5 ether);
    }
}
