// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

 import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBond is  IERC721Receiver {
    // Setters for Defaults
    function setDefaultBondSalePeriod(uint256 newSalePeriod) external;
    function setDefaultBondOfferTerm(uint256 newTerm) external;
    function setDefaultCollateralizationRatio(uint256 newRatio) external;

    // Setters for External Contract Dependencies
    function setBondOfferNFTContract(address newBondOfferNFTContract) external;
    function setBondFeesNFTContract(address newBondFeesNFTContract) external;
    function setWalletNFTContract(address newWalletNFTContract) external;
    function setWalletFeesNFTContract(address newWalletFeesNFTContract) external;
    function setBondInvestmentContract(address newBondInvestmentContract) external;

    // Bond Offering
    function bondIssueBondOffering(
        uint256 nftId,
        uint256 bondOfferPrice,
        uint256 bondOfferCouponRate,
        uint256 nftPrice,
        uint256 collateralizationRatio,
        address issuer
    ) external returns (uint256);

    // Buying a Bond
    function buyBond(
        uint256 bondOfferId, 
        uint256 usdcAmount, 
        address buyer
    ) external returns (address, uint256, bool);

    // Redeem Bond
    function redeemBond(uint256 bondOfferId) external returns (uint256, address, uint256);

    function redeemBondNft(uint256 nftId) external returns (uint256, address, uint256);

    // Deposit Bond Fees
    function depositBondFees(uint256 usdcAmount, address payer, uint256 bondOfferId) external;

    // Withdraw Bond Offering (if not fully funded)
    function withdrawBondOffer(uint256 bondOfferId, address wallet) external returns (uint256, address);

    // Fund Bond Offer (marks it as fully funded)
    function fundBondOffer(uint256 bondOfferId) external;

    // Update Bond Offer Status
    function updateBondOfferStatus(uint256 bondOfferId, uint256 newStatus) external;

       function bondOfferNFTContract() external view returns (address);
    function walletFeesNFTContract() external view returns (address);
    function bondFeesNFTContract() external view returns (address);

    // Calculate Fees
    function calculateFees(
        uint256 bondFundingTarget,
        uint256 bondCouponRate,
        uint256 bondPeriodInSeconds
    ) external pure returns (uint256);

  
 }
