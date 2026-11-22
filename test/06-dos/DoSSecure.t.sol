// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SecureAuction} from "../../src/06-dos/SecureAuction.sol";
import {AttackerSecure} from "../../src/06-dos/AttackerSecure.sol";

contract DoSSecureTest is Test {
    SecureAuction auction;
    AttackerSecure attacker;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        auction = new SecureAuction();
        attacker = new AttackerSecure(address(auction));

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(address(this), 10 ether);
    }

    /// L'attaquant ne peut plus bloquer l'enchère : Bob enchérit sans problème.
    function test_AttackerCannotBlockAuction() public {
        attacker.attack{value: 1 ether}();
        assertEq(auction.highestBidder(), address(attacker));

        vm.prank(bob);
        auction.bid{value: 2 ether}(); // plus de revert

        assertEq(auction.highestBidder(), bob);
        assertEq(auction.highestBid(), 2 ether);
        assertEq(auction.pendingReturns(address(attacker)), 1 ether);
    }

    /// Le refus de l'attaquant ne pénalise que lui : l'enchère continue.
    function test_AttackerRefusalOnlyHurtsHimself() public {
        attacker.attack{value: 1 ether}();

        vm.prank(bob);
        auction.bid{value: 2 ether}();

        // Son propre retrait échoue (il refuse l'argent)...
        vm.expectRevert("Retrait echoue");
        attacker.tryWithdraw();

        // ... mais Alice peut quand même enchérir.
        vm.prank(alice);
        auction.bid{value: 3 ether}();
        assertEq(auction.highestBidder(), alice);
    }

    /// Un utilisateur honnête récupère bien son remboursement.
    function test_HonestUserCanWithdraw() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();

        vm.prank(bob);
        auction.bid{value: 2 ether}();

        assertEq(auction.pendingReturns(alice), 1 ether);

        vm.prank(alice);
        auction.withdraw();

        assertEq(auction.pendingReturns(alice), 0);
        assertEq(alice.balance, 10 ether);
    }
}
