// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBondOfferNFTView {
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

    function getAllRedeemedBondNFTs() external view returns (RedeemedBondNftInfo[] memory);

    function getAllFundedNFTs() external view returns (FundedNftInfo[] memory);

    function getAllBondedNFTs() external view returns (BondedNftInfo[] memory);

    function getAllNftsWithBondOffersIssued() external view returns (uint256[] memory);

    function addFundedNft(uint256 nftId, uint256 nftPrice) external;

    function addBondedNft(uint256 bondOfferId, uint256 bondOfferPrice) external;

    function addIssuedNft(uint256 nftId) external;

    function addRedeemedNft(uint256 nftId, uint256 nftPrice) external;

    function removeFundedNFT(uint256 nftId) external;

    function removeIssuedNFT(uint256 nftId) external;

    function removeBondedNFT(uint256 bondOfferId) external;

 
 
 }
