// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/fixed/SafeSigVault.sol";

// Robot attaquant : il connait la signature d'Alice (elle est publique)
contract SigHandler is Test {
    SafeSigVault public vault;
    address payable public bob;
    uint256 public deadline;
    bytes public sig;
    address[] public actors;

    constructor(SafeSigVault _vault, address payable _bob, uint256 _deadline, bytes memory _sig) {
        vault = _vault;
        bob = _bob;
        deadline = _deadline;
        sig = _sig;
        actors.push(makeAddr("attacker1"));
        actors.push(makeAddr("attacker2"));
        actors.push(makeAddr("attacker3"));
    }

    // N'importe qui rejoue la signature d'Alice telle quelle
    function replay(uint256 seed) public {
        vm.prank(actors[seed % actors.length]);
        try vault.withdraw(bob, 1 ether, deadline, sig) {} catch {}
    }

    // Un attaquant garde la signature mais change le montant
    function tamperAmount(uint256 seed, uint256 amount) public {
        amount = bound(amount, 1, 5 ether);
        vm.prank(actors[seed % actors.length]);
        try vault.withdraw(bob, amount, deadline, sig) {} catch {}
    }
}

contract SigReplayInvariantTest is Test {
    SafeSigVault vault;
    SigHandler handler;
    address alice;
    uint256 alicePk;
    address payable bob;

    function setUp() public {
        (alice, alicePk) = makeAddrAndKey("alice");
        bob = payable(makeAddr("bob"));
        vault = new SafeSigVault{value: 5 ether}(alice);

        // Alice signe UN SEUL cheque : 1 ETH pour Bob, nonce 0
        uint256 deadline = block.timestamp + 365 days;
        bytes memory sig = _sign(bob, 1 ether, 0, deadline);

        handler = new SigHandler(vault, bob, deadline, sig);
        targetContract(address(handler));
    }

    function _sign(address to, uint256 amount, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes memory)
    {
        bytes32 structHash = keccak256(
            abi.encode(vault.WITHDRAW_TYPEHASH(), to, amount, nonce, deadline)
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SafeSigVault")),
                keccak256(bytes("1")),
                block.chainid,
                address(vault)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        return abi.encodePacked(r, s, v);
    }

    // Regle 1 : au plus 1 ETH sort du coffre (celui qu'Alice a autorise)
    function invariant_atMostOneEtherLeaves() public view {
        assertGe(address(vault).balance, 4 ether);
    }

    // Regle 2 : un seul cheque a ete consomme
    function invariant_nonceNeverAboveOne() public view {
        assertLe(vault.nonces(alice), 1);
    }
}
