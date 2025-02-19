// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBondOfferNFT {
    enum BondOfferStatus {
        Unavailable,
        Issued,
        Funded,
        Redeemed,
        Withdrawn
    }

    struct BondSupplyInfo {
        uint256 totalSupply;
        uint256 remainingSupply;
    }

    struct BondOfferInfo {
        uint256 bondOfferId;
        uint256 nftId;
        address bondOfferIssuer;
        uint256 bondOfferTerm;
        uint256 bondOfferPrice;
        uint256 bondOfferCouponRate;
        uint256 bondOfferMaturity;
        uint256 nftPrice;
        uint256 collateralizationRatio;
        BondOfferStatus bondOfferStatus;
        uint256 BondIssueDate;
    }

    function bondOfferIssueBondOffering(
        uint256 nftId,
        uint256 bondOfferPrice,
        uint256 bondOfferTerm,
        uint256 bondOfferCouponRate,
        uint256 nftPrice,
        uint256 collateralizationRatio,
        address bondOfferIssuer
    ) external returns (uint256);

    function getBondOfferInfo(uint256 bondOfferId) external view returns (BondOfferInfo memory);

    function getNFTIdForBondOffer(uint256 bondOfferId) external view returns (uint256);

    function buyBond(uint256 bondOfferId, uint256 usdcAmount) external;

    function getIssuedBondOffersForNFT(uint256 nftId) external view returns (BondOfferInfo[] memory);

    function getBondOffersForNFT(uint256 nftId) external view returns (uint256[] memory);

    function getRemainingSupply(uint256 bondOfferId) external view returns (uint256);

    function getTotalSupply(uint256 bondOfferId) external view returns (uint256);

    function getBondOfferStatus(uint256 bondOfferId) external view returns (uint256);

    function getLastBondOfferStatus(uint256 nftId) external view returns (BondOfferStatus, uint256);

    function fundBondOffer(uint256 bondOfferId) external;

 
 
    function getIssuedBondSupplyInfo(uint256 nftId) external view returns (BondSupplyInfo memory);

    function withdrawBondOffering(uint256 bondOfferId, uint256 defaultSalePeriod) external;

    function redeemBond(uint256 bondOfferId) external;

    function updateBondOfferStatus(uint256 bondOfferId, BondOfferStatus newStatus) external;

    struct FundedNftInfo {
        uint256 nftId;
        uint256 nftPrice;
    }

    struct RedeemedBondNftInfo {
        uint256 nftId;
        uint256 nftPrice;
    }

    struct BondedNftInfo {
        uint256 bondOfferId;
        uint256 bondOfferPrice;
    }

    function bondOfferCount() external view returns (uint256);
    function totalFundedNftValue() external view returns (uint256);
    function getBondOfferAndSupply(uint256 bondOfferId) external view returns (BondOfferInfo memory, BondSupplyInfo memory);
    function getLastBondOfferByStatus(uint256 nftId, BondOfferStatus status) external view returns (uint256);
    }

