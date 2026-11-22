// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/fixed/SafeAccessControlVault.sol";

// Le "robot attaquant" : Forge appelle ces fonctions au hasard, avec des adresses au hasard
contract AccessControlHandler is Test {
    SafeAccessControlVault public vault;
    address public deployer;

    constructor(SafeAccessControlVault _vault, address _deployer) {
        vault = _vault;
        deployer = _deployer;
    }

    function attackerTransferOwnership(address caller, address target) public {
        if (caller == deployer) return; // le proprietaire n'est pas un attaquant
        vm.prank(caller);
        try vault.transferOwnership(target) {} catch {}
    }

    function attackerWithdraw(address caller) public {
        if (caller == deployer) return;
        vm.prank(caller);
        try vault.withdrawAll() {} catch {}
    }
}

contract AccessControlInvariantTest is Test {
    SafeAccessControlVault vault;
    AccessControlHandler handler;
    address deployer;

    function setUp() public {
        deployer = makeAddr("deployer");
        vm.deal(deployer, 10 ether);

        vm.prank(deployer);
        vault = new SafeAccessControlVault{value: 5 ether}();

        handler = new AccessControlHandler(vault, deployer);
        targetContract(address(handler)); // Forge n'appelle que le handler
    }

    // Regle 1 : quoi que fassent les attaquants, le proprietaire ne change jamais
    function invariant_ownerNeverChanges() public view {
        assertEq(vault.owner(), deployer);
    }

    // Regle 2 : quoi que fassent les attaquants, les 5 ETH restent dans le coffre
    function invariant_balanceUntouched() public view {
        assertEq(address(vault).balance, 5 ether);
    }
}
