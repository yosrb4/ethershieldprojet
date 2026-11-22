// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/vulnerable/SigVault.sol";
import "../../src/fixed/SafeSigVault.sol";

contract SigReplayFuzzTest is Test {
    SigVault vulnVault;
    SafeSigVault safeVault;
    address alice;
    uint256 alicePk;
    address payable bob;

    function setUp() public {
        (alice, alicePk) = makeAddrAndKey("alice");
        bob = payable(makeAddr("bob"));
        vulnVault = new SigVault{value: 5 ether}(alice);
        safeVault = new SafeSigVault{value: 5 ether}(alice);
    }

    // Signature du contrat VULNERABLE : (to, amount) seulement
    function _signVuln(address to, uint256 amount)
        internal
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 hash = keccak256(abi.encodePacked(to, amount));
        bytes32 ethHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        (v, r, s) = vm.sign(alicePk, ethHash);
    }

    // Signature EIP-712 du contrat CORRIGE, avec la cle privee de notre choix
    function _signSafe(address to, uint256 amount, uint256 nonce, uint256 deadline, uint256 pk)
        internal
        view
        returns (bytes memory)
    {
        bytes32 structHash = keccak256(
            abi.encode(safeVault.WITHDRAW_TYPEHASH(), to, amount, nonce, deadline)
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SafeSigVault")),
                keccak256(bytes("1")),
                block.chainid,
                address(safeVault)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    // VULNERABLE : une signature, rejouee N fois, pour n'importe quel montant
    function testFuzz_exploit_replayNTimes(uint256 amount, uint256 times) public {
        amount = bound(amount, 0.01 ether, 1 ether);
        times = bound(times, 2, 5);

        (uint8 v, bytes32 r, bytes32 s) = _signVuln(bob, amount);
        for (uint256 i = 0; i < times; i++) {
            vulnVault.withdraw(bob, amount, v, r, s);
        }

        assertEq(bob.balance, amount * times); // Alice a autorise 1 fois, Bob a recu N fois
    }

    // CORRIGE : le rejeu est refuse, quel que soit le montant
    function testFuzz_fixed_replayFails(uint256 amount) public {
        amount = bound(amount, 1, 5 ether);
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signSafe(bob, amount, 0, deadline, alicePk);

        safeVault.withdraw(bob, amount, deadline, sig);
        assertEq(bob.balance, amount);

        vm.expectRevert("bad signature");
        safeVault.withdraw(bob, amount, deadline, sig);

        assertEq(bob.balance, amount); // rien de plus
    }

    // CORRIGE : changer le montant invalide la signature
    function testFuzz_fixed_tamperedAmountFails(uint256 signedAmount, uint256 askedAmount) public {
        signedAmount = bound(signedAmount, 1, 5 ether);
        askedAmount = bound(askedAmount, 1, 5 ether);
        vm.assume(signedAmount != askedAmount);

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signSafe(bob, signedAmount, 0, deadline, alicePk);

        vm.expectRevert("bad signature");
        safeVault.withdraw(bob, askedAmount, deadline, sig);

        assertEq(address(safeVault).balance, 5 ether);
    }

    // CORRIGE : apres la deadline, refuse, quel que soit le retard
    function testFuzz_fixed_expiredFails(uint256 delay) public {
        delay = bound(delay, 1, 365 days);
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signSafe(bob, 1 ether, 0, deadline, alicePk);

        vm.warp(deadline + delay);

        vm.expectRevert("signature expired");
        safeVault.withdraw(bob, 1 ether, deadline, sig);
    }

    // CORRIGE : une signature faite avec une AUTRE cle est refusee
    function testFuzz_fixed_wrongSignerFails(uint256 otherPk) public {
        otherPk = bound(otherPk, 1, type(uint128).max);
        vm.assume(otherPk != alicePk);

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signSafe(bob, 1 ether, 0, deadline, otherPk);

        vm.expectRevert("bad signature");
        safeVault.withdraw(bob, 1 ether, deadline, sig);
    }

    // NON-REGRESSION : une signature valide, avant la deadline, marche toujours
    function testFuzz_fixed_validSignatureWorks(uint256 amount, uint256 elapsed) public {
        amount = bound(amount, 1, 5 ether);
        elapsed = bound(elapsed, 0, 1 hours);
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signSafe(bob, amount, 0, deadline, alicePk);

        vm.warp(block.timestamp + elapsed);

        safeVault.withdraw(bob, amount, deadline, sig);
        assertEq(bob.balance, amount);
        assertEq(safeVault.nonces(alice), 1);
    }
}
