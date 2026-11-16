// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title VulnerableVault
/// @notice CONTRAT VOLONTAIREMENT VULNERABLE (reentrancy).
///         Usage pedagogique, reseau local uniquement. Ne jamais deployer en reel.
contract VulnerableVault {
    // Solde de chaque utilisateur
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Deposer de l'ETH dans le vault
    function deposit() external payable {
        require(msg.value > 0, "Montant nul");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Retirer TOUT son solde
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Solde nul");

        // FAILLE : on envoie l'ETH AVANT de mettre le solde a zero
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Envoi echoue");

        // Trop tard : le solde n'est remis a zero qu'apres l'envoi
        balances[msg.sender] = 0;
        emit Withdraw(msg.sender, amount);
    }

    /// @notice ETH total detenu par le vault
    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
