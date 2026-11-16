// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {VulnerableVault} from "../../src/01-reentrancy/VulnerableVault.sol";
import {Attacker} from "../../src/01-reentrancy/Attacker.sol";

contract ReentrancyTest is Test {
    VulnerableVault public vault;
    Attacker public attacker;

    address public alice = makeAddr("alice");
    address public eve = makeAddr("eve");

    function setUp() public {
        vault = new VulnerableVault();

        vm.deal(alice, 10 ether);
        vm.prank(alice);
        vault.deposit{value: 10 ether}();

        assertEq(vault.totalBalance(), 10 ether);

        vm.prank(eve);
        attacker = new Attacker(address(vault));
        vm.deal(eve, 1 ether);
    }

    function test_ExploitDrainsVault() public {
        uint256 vaultBefore = vault.totalBalance();
        assertEq(vaultBefore, 10 ether);

        vm.prank(eve);
        attacker.attack{value: 1 ether}();

        assertEq(vault.totalBalance(), 0);
        assertEq(address(attacker).balance, 11 ether);
        assertEq(vault.balances(alice), 10 ether);
    }
}
