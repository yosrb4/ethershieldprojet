// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../../src/vulnerable/AccessControlVault.sol";
import "../../src/fixed/SafeAccessControlVault.sol";

contract AccessControlFuzzTest is Test {
    address deployer;
    AccessControlVault vulnVault;
    SafeAccessControlVault safeVault;

    function setUp() public {
        deployer = makeAddr("deployer");
        vm.deal(deployer, 20 ether);

        vm.startPrank(deployer);
        vulnVault = new AccessControlVault{value: 5 ether}();
        safeVault = new SafeAccessControlVault{value: 5 ether}();
        vm.stopPrank();
    }

    // Garde seulement des adresses "normales" (portefeuilles), pas des contrats ni des adresses speciales
    function _isNormalAccount(address a) internal view returns (bool) {
        return a != address(0) && a != deployer && a.code.length == 0;
    }

    // VULNERABLE : n'importe quelle adresse peut prendre le controle et vider le coffre
    function testFuzz_exploit_anyoneCanDrain(address attacker) public {
        vm.assume(_isNormalAccount(attacker));
        assumeNotPrecompile(attacker);
        assumeNotForgeAddress(attacker);

        uint256 before = attacker.balance;

        vm.startPrank(attacker);
        vulnVault.setOwner(attacker);
        vulnVault.withdrawAll();
        vm.stopPrank();

        assertEq(vulnVault.owner(), attacker);
        assertEq(address(vulnVault).balance, 0);
        assertEq(attacker.balance, before + 5 ether);
    }

    // CORRIGE : aucun non-proprietaire ne peut changer le proprietaire
    function testFuzz_fixed_nonOwnerCannotTakeOwnership(address caller, address target) public {
        vm.assume(caller != deployer);

        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller)
        );
        vm.prank(caller);
        safeVault.transferOwnership(target);

        assertEq(safeVault.owner(), deployer);
    }

    // CORRIGE : aucun non-proprietaire ne peut retirer
    function testFuzz_fixed_nonOwnerCannotWithdraw(address caller) public {
        vm.assume(caller != deployer);

        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller)
        );
        vm.prank(caller);
        safeVault.withdrawAll();

        assertEq(address(safeVault).balance, 5 ether);
    }

    // NON-REGRESSION : le proprietaire peut transferer la propriete a n'importe quelle adresse valide
    function testFuzz_fixed_ownerCanTransferToAnyone(address target) public {
        vm.assume(target != address(0));

        vm.prank(deployer);
        safeVault.transferOwnership(target);

        assertEq(safeVault.owner(), target);
    }
}
