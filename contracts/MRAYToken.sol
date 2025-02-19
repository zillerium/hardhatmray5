// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MRAYToken is ERC20, Ownable {
    // Treasury address with permission to mint and burn
    address public treasury;

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    modifier onlyTreasury() {
        require(msg.sender == treasury, "Caller is not the treasury");
        _;
    }
   constructor(address initialOwner) ERC20("MRAY", "MRAY") Ownable(initialOwner) {
        // Initialize the contract with an owner
    }
  

    /**
     * @dev Update the treasury address.
     * Can only be called by the owner.
     */
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    function burnFrom(address from, uint256 amount) external onlyTreasury {
        require(from != address(0), "Cannot burn from zero address");

        // ✅ Check allowance before burning
        require(allowance(from, msg.sender) >= amount, "Insufficient allowance");

        // ✅ Deduct the approved amount first
        _spendAllowance(from, msg.sender, amount);

        // ✅ Burn the tokens
        _burn(from, amount);
    }


    /**
     * @dev Mint MRAY tokens. Only the treasury can mint tokens.
     * @param to Address to receive the minted tokens.
     * @param amount Number of tokens to mint (in smallest units).
     */
    function mint(address to, uint256 amount) external onlyTreasury {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, amount);
    }

    /**
     * @dev Burn MRAY tokens. Only the treasury can burn tokens.
     * @param from Address whose tokens will be burned.
     * @param amount Number of tokens to burn (in smallest units).
     */
    function burn(address from, uint256 amount) external onlyTreasury {
        require(from != address(0), "Cannot burn from zero address");
        _burn(from, amount);
    }
}
