// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWalletFeesNFT {
    
    struct WalletFeesInfo {
        uint256 walletFeesNFTId;
        address walletFeesAddress;
        bool KYC;
        bool AML;
        uint256 feeBalance;
    }

    function walletToNFTId(address wallet) external view returns (uint256);

    function getWalletFeesInfoByNFTId(uint256 walletFeesNFTId) external view returns (WalletFeesInfo memory);

    function getWalletFeesInfoByAddress(address wallet) external view returns (WalletFeesInfo memory);

    function updateFeesBalance(address wallet, uint256 amount) external;

    function mintAndUpdateFeesBalance(address wallet, uint256 amount) external;

    function conditionallyMintWalletFeesNFT(address wallet) external;

    function increaseFeeBalance(address wallet, uint256 amount) external;

    function reduceFeeBalance(address wallet, uint256 amount) external;

    function isTreasuryApproved(address newTreasuryAddress) external view returns (bool);
}
