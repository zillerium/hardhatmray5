// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWalletNFT {
    
    struct WalletInfo {
        uint256 walletNFTId;
        address walletAddress;
        bool KYC;
        bool AML;
        uint256 bondBalance;
        uint256 liquidBalance;
        uint256 disbursementsBalance;
        uint256 pendingDisbursementsBalance;
    }

    function mintAndUpdateLiquidBalance(address wallet, uint256 amount) external;
    
    function getAllLiquidBalances() external view returns (uint256[][] memory);

    function walletToNFTId(address wallet) external view returns (uint256);

    function getWalletInfoByNFTId(uint256 walletNFTId) external view returns (WalletInfo memory);

    function getWalletInfoByAddress(address wallet) external view returns (WalletInfo memory);

    function increasePendingDisbursementsBalance(address wallet, uint256 amount) external;

    function decreasePendingDisbursementsBalance(address wallet, uint256 amount) external;

    function increaseDisbursementsBalance(address wallet, uint256 amount) external;

    function decreaseDisbursementsBalance(address wallet, uint256 amount) external;

    function increaseLiquidBalance(address wallet, uint256 amount) external;

    function reduceLiquidBalance(address wallet, uint256 amount) external;

    function increaseBondBalance(address wallet, uint256 amount) external;

    function reduceBondBalance(address wallet, uint256 amount) external;

    function isAnInvestor(address wallet) external view returns (bool);

    function getWalletBalances(address wallet) 
        external 
        view 
        returns (uint256 bondBalance, uint256 liquidBalance, uint256 disbursementsBalance);
}

