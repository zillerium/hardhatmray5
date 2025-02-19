// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMUSD {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function approveTreasuryContract(address newTreasury) external;

    function revokeTreasuryContract(address treasury) external;

    function isTreasuryApproved(address treasuryAddress) external view returns (bool);
}
