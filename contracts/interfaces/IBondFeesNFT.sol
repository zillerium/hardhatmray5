// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBondFeesNFT {
    struct BondFeesInfo {
        uint256 feeId;
        address payer;
        uint256 usdcAmount;
        uint256 bondOfferId;
        bool inTreasury;
        bool redeemed;
        bool distributed;
    }

    function distributeFees(uint256 bondOfferId) external;

    function withdrawFees(uint256 bondOfferId) external;

    function getBondFeesInfoByBondOfferId(uint256 bondOfferId) external view returns (BondFeesInfo memory);

    function usdcDepositFees(uint256 usdcAmount, address payer, uint256 bondOfferId) external;

    function getBondFeesInfo(uint256 feesId) external view returns (BondFeesInfo memory);

    function getAllBondFeesInfo(address payer) external view returns (BondFeesInfo[] memory);

    function feesWithdrawal(uint256 feeId) external returns (uint256);

    function feesDistribution(uint256 feeId) external returns (uint256);
}
