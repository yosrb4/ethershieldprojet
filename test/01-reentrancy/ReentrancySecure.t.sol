// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SecureVault} from "../../src/01-reentrancy/SecureVault.sol";
import {AttackerSecure} from "../../src/01-reentrancy/AttackerSecure.sol";

contract ReentrancySecureTest is Test {
    SecureVault public vault;
    AttackerSecure public attacker;

    address public alice = makeAddr("alice");
    address public eve = makeAddr("eve");

    function setUp() public {
        vault = new SecureVault();

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        vault.deposit{value: 10 ether}();

        assertEq(vault.totalBalance(), 10 ether);

        vm.prank(eve);
        attacker = new AttackerSecure(address(vault));
        vm.deal(eve, 1 ether);
    }

    /// @notice Preuve de non-regression : l'exploit echoue sur SecureVault
    function test_ExploitFailsOnSecureVault() public {
        assertEq(vault.totalBalance(), 10 ether);

        vm.prank(eve);
        vm.expectRevert();
        attacker.attack{value: 1 ether}();

        // Le vault garde l'argent d'Alice, l'attaque n'a rien pu voler
        assertEq(vault.totalBalance(), 10 ether);
    }

    /// @notice Verifie qu'un retrait normal fonctionne toujours
    function test_HonestWithdrawStillWorks() public {
        vm.prank(alice);
        vault.withdraw();

        assertEq(vault.totalBalance(), 0);
        assertEq(alice.balance, 10 ether);
    }
}
