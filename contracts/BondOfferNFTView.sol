// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract BondOfferNFTView is  Ownable, AccessControl {
    bytes32 public constant BOND_OFFER_ROLE = keccak256("BOND_OFFER_ROLE");
    error CallerNotAuthorized(address caller);

    error InsufficientBondSupply(uint256 available, uint256 requested);
   
    // needed due to stack too deep on compiler when included in BondOfferInfo
 
    //uint256[] public fundedNFTs; // Stores the actual funded NFTs
    uint256[] public nftsWithIssuedOffers; // Stores the actual NFTs with a bond offering issued

    // Define new struct for funded NFT information
    struct FundedNftInfo {
        uint256 nftId;
        uint256 nftPrice;
    }

    // Change fundedNFTs to store structs instead of just nftIds
    FundedNftInfo[] public fundedNFTs;

    // Define new struct for redeemed NFT information
    struct RedeemedBondNftInfo {
        uint256 nftId;
        uint256 nftPrice;
    }

    RedeemedBondNftInfo[] public redeemedBondNFTs;

      // Define new struct for funded Bond Info information
    struct BondedNftInfo {
        uint256 bondOfferId;
        uint256 bondOfferPrice;
    }

    // Change bondedNFTs to store structs instead of just bondOfferIds
    BondedNftInfo[] public bondedNFTs;


    constructor(address initialOwner) Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    // Modifier to check for either role
    modifier onlyAuthorizedRole() {
        if (!hasRole(BOND_OFFER_ROLE, msg.sender)) {
            revert CallerNotAuthorized(msg.sender);
        }
        _;
    }

    function getAllRedeemedBondNFTs() external view returns (RedeemedBondNftInfo[] memory) {
         return redeemedBondNFTs;
    }

    function getAllFundedNFTs() external view returns (FundedNftInfo[] memory) {
   // function getAllFundedNFTs() external view returns (uint256[] memory) {
        return fundedNFTs;
    }

    function getAllBondedNFTs() external view returns (BondedNftInfo[] memory) {
        return bondedNFTs;
    }

    function addFundedNft(uint256 nftId, uint256 nftPrice) external onlyAuthorizedRole {
        fundedNFTs.push(FundedNftInfo(nftId, nftPrice));

    }
    function addBondedNft(uint256 bondOfferId, uint256 bondOfferPrice) external onlyAuthorizedRole {
        bondedNFTs.push(BondedNftInfo(bondOfferId, bondOfferPrice));
    }

    function addIssuedNft(uint256 nftId) external onlyAuthorizedRole {
        nftsWithIssuedOffers.push(nftId);
    }

    function getAllNftsWithBondOffersIssued() external view returns (uint256[] memory) {
        return nftsWithIssuedOffers;
    }

    function addRedeemedNft(uint256 nftId, uint256 nftPrice) external  onlyAuthorizedRole {
        redeemedBondNFTs.push(RedeemedBondNftInfo(nftId, nftPrice));
    }
    function removeFundedNFT(uint256 nftId) public onlyAuthorizedRole {
        removeFundedNFTInternal(nftId);
        fundedNFTs.pop();
    }

    // storage arrays cannot be passed solidity, so this is needed
    // the nftid is switched with the last enrty
    // then the last entry can be popped outside the function (note, popping in the loop does not work)
    function removeFundedNFTInternal(uint256 nftId) internal {
        for (uint256 i = 0; i < fundedNFTs.length; i++) {
            if (fundedNFTs[i].nftId == nftId) {
                fundedNFTs[i] = fundedNFTs[fundedNFTs.length - 1];
                return;
            }
        }
    }

    function removeIssuedNFT(uint256 nftId) public onlyAuthorizedRole {
        removeIssuedNFTInternal(nftId);
        nftsWithIssuedOffers.pop();
    }

    function removeIssuedNFTInternal(uint256 nftId) internal {
        for (uint256 i = 0; i < nftsWithIssuedOffers.length; i++) {
            if (nftsWithIssuedOffers[i] == nftId) {
                nftsWithIssuedOffers[i] = nftsWithIssuedOffers[nftsWithIssuedOffers.length - 1];
                return;
            }
        }
    }

    function removeBondedNFT(uint256 nftId) public onlyAuthorizedRole {
        removeBondedNFTInternal(nftId);
        bondedNFTs.pop();
 
    }

    function removeBondedNFTInternal(uint256 bondOfferId) internal  {
        for (uint256 i = 0; i < bondedNFTs.length; i++) {
            if (bondedNFTs[i].bondOfferId == bondOfferId) {
                bondedNFTs[i] = bondedNFTs[bondedNFTs.length - 1];
                return;
            }
        }
    }

    //**********************
    //** Approvals
    //**********************

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function approveBondOfferContract(address bondOfferAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bondOfferAddress != address(0), "Invalid address");
        _grantRole(BOND_OFFER_ROLE, bondOfferAddress);
    }

    function revokeBondOfferContract(address bondOfferAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BOND_OFFER_ROLE, bondOfferAddress);
    }

    function isBondOfferApproved(address bondOfferAddress) external view returns (bool) {
        return hasRole(BOND_OFFER_ROLE, bondOfferAddress);
    }
}
