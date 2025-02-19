// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUSDCDeposits {

    struct USDCDepositInfo {
        uint256 depositId;
        address depositor;
        uint256 usdcAmount;
        uint256 depositExpiry;
        bool redeemed;
    }

    function usdcDeposit(uint256 usdcAmount, uint256 depositPeriod, address depositor) external;

    function getDepositInfo(uint256 depositId) external view returns (USDCDepositInfo memory);

    function getAllUSDCDepositInfo(address depositor) external view returns (USDCDepositInfo[] memory);

    function usdcWithdrawal(uint256 depositId) external;

    function isTreasuryApproved(address newTreasuryAddress) external view returns (bool);
}
