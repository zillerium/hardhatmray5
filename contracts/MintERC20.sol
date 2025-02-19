// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintERC20 is ERC20, Ownable {
    // Mapping to keep track of whitelisted addresses (e.g., Bond contracts)
    mapping(address => bool) public whitelist;

 
    constructor(address initialOwner) ERC20("MRAY", "MRAY") Ownable(initialOwner) {
        // Initialize the contract with an owner
    }
  
    // Override decimals to 6 for consistency with USDC
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    // Modifier to restrict function access to whitelisted addresses
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not a whitelisted address");
        _;
    }

    // Function for the owner to add an address to the whitelist
    function addToWhitelist(address account) external onlyOwner {
        whitelist[account] = true;
    }

    // Function for the owner to remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    /**
     * @dev Mint MRAY tokens.
     * Only whitelisted addresses (Bond contracts) can mint tokens.
     */
    function mint(address to, uint256 amount) external onlyWhitelisted {
        _mint(to, amount);
    }

    // Function to check MRAY token balance
    function stablecoinBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }

 
    function increaseApproval(address spender, uint256 addedValue) external {
        require(spender != address(0), "Invalid address");
         
        uint256 newAllowance = allowance(msg.sender, spender) + addedValue;
        _approve(msg.sender, spender, newAllowance);

    }

     function decreaseApproval(address spender, uint256 subtractedValue) external {
        uint256 currentAllowance = allowance(msg.sender, spender);
        uint256 userBalance = balanceOf(msg.sender); // Get the user's actual MRAY balance
        require(currentAllowance >= subtractedValue, "Decrease amount exceeds allowance");
        require(spender != address(0), "Invalid address");
        
        // Ensure the new allowance cannot exceed the user's balance
        uint256 newAllowance = currentAllowance - subtractedValue;
        require(newAllowance <= userBalance, "Allowance cannot exceed user's balance");

        _approve(msg.sender, spender, newAllowance);
    }



    /**
     * @dev Allows a whitelisted bond contract to burn tokens on behalf of the user.
     * The bond contract must first reduce the approval before calling this function.
     */
    function burnFrom(address from, uint256 amount) external onlyWhitelisted {
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "Burn amount exceeds allowance");

        _approve(from, msg.sender, currentAllowance - amount);
        _burn(from, amount);
    }
}
