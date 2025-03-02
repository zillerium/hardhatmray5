// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBondInvestment {
    struct BondInvestmentInfo {
        uint256 bondInvestmentId;
        address walletAddress;
        uint256 usdcAmount;
        uint256 bondOfferId;
        uint256 walletNFTId;
    }

    function mintBondInvestmentNFT(
        address wallet, 
        uint256 usdcAmount,
        uint256 bondOfferId,
        uint256 walletNFTId
    ) external;

    // Get all investments for a wallet
    function getBondInvestmentsByWallet(address wallet) external view returns (BondInvestmentInfo[] memory);

    function getBondInvestmentsByBondOfferId(uint256 bondOfferId) external view returns (BondInvestmentInfo[] memory);

    function checkInvestorInBondOffer(address wallet, uint256 bondOfferId) external view returns (bool);

    function getAllInvestors() external view returns (address[] memory);

}

