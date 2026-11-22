// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../../src/fixed/SafeAccessControlVault.sol";

contract SafeAccessControlTest is Test {
    SafeAccessControlVault vault;
    address deployer;
    address hacker;
    address newOwner;

    function setUp() public {
        deployer = makeAddr("deployer");
        hacker = makeAddr("hacker");
        newOwner = makeAddr("newOwner");
        vm.deal(deployer, 10 ether);

        vm.prank(deployer);
        vault = new SafeAccessControlVault{value: 5 ether}();
    }

    // PROTECTION 1 : le hacker ne peut plus se declarer proprietaire
    function test_fixed_hackerCannotTakeOwnership() public {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hacker)
        );
        vm.prank(hacker);
        vault.transferOwnership(hacker);

        assertEq(vault.owner(), deployer);
    }

    // PROTECTION 2 : le hacker ne peut pas vider le coffre
    function test_fixed_hackerCannotWithdraw() public {
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hacker)
        );
        vm.prank(hacker);
        vault.withdrawAll();

        assertEq(address(vault).balance, 5 ether);
        assertEq(hacker.balance, 0);
    }

    // NON-REGRESSION 1 : le vrai proprietaire peut toujours retirer
    function test_fixed_ownerCanStillWithdraw() public {
        uint256 before = deployer.balance;

        vm.prank(deployer);
        vault.withdrawAll();

        assertEq(address(vault).balance, 0);
        assertEq(deployer.balance, before + 5 ether);
    }

    // NON-REGRESSION 2 : le proprietaire peut transferer la propriete legitimement
    function test_fixed_ownerCanTransferOwnership() public {
        vm.prank(deployer);
        vault.transferOwnership(newOwner);
        assertEq(vault.owner(), newOwner);

        // l'ancien proprietaire n'a plus de droits
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, deployer)
        );
        vm.prank(deployer);
        vault.withdrawAll();

        // le nouveau proprietaire peut retirer
        vm.prank(newOwner);
        vault.withdrawAll();
        assertEq(newOwner.balance, 5 ether);
    }
}
