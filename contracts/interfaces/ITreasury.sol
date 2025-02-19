// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface ITreasury is  IERC721Receiver {
    event DepositUSDC(address indexed depositor, uint256 amount);
    event WithdrawalUSDC(address indexed recipient, uint256 amount);
    event FeesDeposited(address indexed payer, uint256 amount);
    event BondIssued(uint256 indexed bondOfferId, address indexed issuer);
    event BondPurchased(uint256 indexed bondOfferId, address indexed buyer, uint256 amount);
    event BondRedeemed(uint256 indexed bondOfferId, address indexed issuer, uint256 amount);
    event BondWithdrawn(uint256 indexed bondOfferId, address indexed issuer);
    event BondStatusUpdated(uint256 indexed bondOfferId, uint256 newStatus);

    function setDefaultDepositPeriod(uint256 newPeriod) external;

    function setDepositUSDCContract(address newUsdcDepositsContract) external;

    function setUsdcTokenContract(address newUsdcTokenAddress) external;

    function setMUSDContract(address newMUSDContract) external;

    function setMRAYContract(address newMRAYContract) external;

    function setRwaNftContract(address newRwaNftContract) external;

    function setWalletNFTContract(address newWalletNFTContract) external;

    function setWalletFeesNFTContract(address newWalletFeesNFTContract) external;

    function depositUsdc(uint256 usdcAmount) external;

    function withdrawalFeesUsdc(uint256 amount) external;

    function withdrawalDisbursementsUsdc(uint256 amount) external;

    function withdrawalUsdc(uint256 nftId) external;

    function depositFees(uint256 usdcAmount) external;

    function treasuryIssueBondOffering(
        uint256 nftId,
        uint256 bondOfferPrice,
        uint256 bondOfferCouponRate,
        uint256 nftPrice,
        uint256 collateralizationRatio
    ) external;

    function buyBond(uint256 bondOfferId, uint256 usdcAmount) external;

    function redeemBond(uint256 bondOfferId) external;

    function redeemNft(uint256 nftId) external;


    function withdrawBondOffering(uint256 bondOfferId) external;

    function updateBondOfferStatus(uint256 bondOfferId, uint256 newStatus) external;

    function getLiquidBalance(address wallet) external view returns (uint256);
}
