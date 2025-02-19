// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MUSD is ERC20, AccessControl, Ownable {
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    constructor(address initialOwner) ERC20("MUSD", "MUSD") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function mint(address to, uint256 amount) external onlyRole(TREASURY_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(TREASURY_ROLE) {
        _burn(from, amount);
    }

    function approveTreasuryContract(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Invalid address");
        _grantRole(TREASURY_ROLE, newTreasury);
    }

    function revokeTreasuryContract(address treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(TREASURY_ROLE, treasury);
    }

    function isTreasuryApproved(address treasuryAddress) external view returns (bool) {
        return hasRole(TREASURY_ROLE, treasuryAddress);
    }
}
