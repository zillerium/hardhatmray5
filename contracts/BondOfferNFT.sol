// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBondOfferNFTView.sol";

contract BondOfferNFT is ERC721, ERC721Burnable, Ownable, AccessControl {
    uint256 public bondOfferCount; // count of all bond offers issued
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");
    IBondOfferNFTView public bondOfferNFTViewContract; // actual bond offering to investors


    error CallerNotAuthorized(address caller);

    error InsufficientBondSupply(uint256 available, uint256 requested);

    //**********************************************************************
    // 1. A bond is issued, this can be funded or withdrawn.
    // 2. A funded bond can be redeemed only.
    // 3. A redeemed bond is the final state for the original path following the issue.
    // 4. A withdrawn bond is also the final state for that path.
    // 5. An issued or funded bond are interim states. 
    // 6. Once a nft has a bond offer in a final state (ie redeemed or withdrawn) it can be re-issued. 
    // eg a bond is issued and redeemed (due to no funding) and then re-issued at a better price or rate.
    //**********************************************************************

    enum BondOfferStatus {
        Unavailable, // 0
        Issued,  // 1
        Funded,    // 2
        Redeemed,  // 3
        Withdrawn  // 4
    }
 
    // needed due to stack too deep on compiler when included in BondOfferInfo
    struct BondSupplyInfo {
       uint256 totalSupply; // normalized at 1 usd for each bond, eg 100K USD Offer = 100,000 bonds
       uint256 remainingSupply; // as bonds are sold, the availablity decreases
    }

    struct BondOfferInfo {
        uint256 bondOfferId; // NFT Id for Bond Offer
        uint256 nftId; // NFT Id for the actual Bond Offering
        address bondOfferIssuer; // issuer of the bond offering, also the fee payer
        uint256 bondOfferTerm; // term of bond 
        uint256 bondOfferPrice; // price for the offering
        uint256 bondOfferCouponRate; // bond interest rate
        uint256 bondOfferMaturity; // maturity date
        uint256 nftPrice; // rwa price
        uint256 collateralizationRatio; // in basis points x100, percentage of RWA price
        BondOfferStatus bondOfferStatus; // status of the offer
        uint256 BondIssueDate; // date of issue
     }

    uint256 public totalFundedNftValue; // total value of all Nfts funded

    mapping(address => uint256[]) public allBondOffers; // Issuer => All bond offers
    mapping(uint256 => BondOfferInfo) public allBondOffersInfo; // Offer Id => BondOfferInfo
    // last entry is the current bond offer, ordered map
    mapping(uint256 => uint256[]) public nftToBondOffers; // NFT Id => All bond offers nfts associated with it
    mapping(uint256 => BondSupplyInfo) public bondSupply; // Offer Id => BondSupplyInfo
    mapping(uint256 => uint256) public issuedBondForNFT; // nftId => bondOfferId
    //uint256[] public fundedNFTs; // Stores the actual funded NFTs
 
     

    constructor(address initialOwner) ERC721("BondOfferNFT", "BondOffer") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    // Modifier to check for either role
    modifier onlyAuthorizedRole() {
        if (!hasRole(TREASURY_ROLE, msg.sender) && !hasRole(BOND_ROLE, msg.sender)) {
            revert CallerNotAuthorized(msg.sender);
        }
        _;
    }

    function getLastBondOfferStatus(uint256 nftId) external view returns (BondOfferStatus, uint256) {
        uint256[] memory bondOfferIds = nftToBondOffers[nftId];

        if (bondOfferIds.length == 0) {
            return (BondOfferStatus(0), 0); // "Not Issued" case - default enum value
        }

        uint256 lastBondOfferId = bondOfferIds[bondOfferIds.length - 1]; // Get last entry
        return (allBondOffersInfo[lastBondOfferId].bondOfferStatus, lastBondOfferId);
    }


   function setBondOfferNFTViewContract(address newBondOfferNFTViewContract) external onlyOwner {
        require(newBondOfferNFTViewContract != address(0), "Invalid BondOfferNFTView contract address");
        bondOfferNFTViewContract = IBondOfferNFTView(newBondOfferNFTViewContract);
    }

    //************************************
    // ISSUES the Bond Offering
    //*******************************
    function bondOfferIssueBondOffering(
        uint256 nftId,
        uint256 bondOfferPrice,
        uint256 bondOfferTerm,
        uint256 bondOfferCouponRate,
        uint256 nftPrice, 
        uint256 collateralizationRatio,
        address bondOfferIssuer

    ) public onlyAuthorizedRole returns (uint256) {  // Returns the bondOfferId
        
        // must have a real bond offer price       
        require(bondOfferPrice > 0, "Bond offer price must be greater than 0");

        // bond term must be > 0 (in seconds)
        require(bondOfferTerm > 0, "Bond offer term must be positive");

        // interest rate for the bond, stored in basis points
        require(bondOfferCouponRate > 0, "Coupon rate must be positive");

        // current sale on-going
        require(issuedBondForNFT[nftId] == 0, "NFT already has an issued bond");

       
        // assume an ordered mapping for the NftIds to bond offerids.   
        uint256[] memory bondOfferIds = nftToBondOffers[nftId];

        if (bondOfferIds.length > 0) {
            BondOfferStatus lastStatus = allBondOffersInfo[bondOfferIds[bondOfferIds.length - 1]].bondOfferStatus;
            require(lastStatus == BondOfferStatus.Withdrawn || lastStatus == BondOfferStatus.Redeemed, "Last bond is still active");
        }

        bondOfferCount++;  // increament NFT Id for the Bond Offer
        uint256 bondOfferId = bondOfferCount;  // Assign AFTER incrementing (starts at 1)
        uint256 initialBondMaturity = 0; // bond is not funded so no date is set

        // maps issuers to Bond Offer NFTs
        allBondOffers[bondOfferIssuer].push(bondOfferId);

        // maps the RWA NfT Id to the bond offer NFT 
        nftToBondOffers[nftId].push(bondOfferId);

        // Issue Bond Offering
        allBondOffersInfo[bondOfferId] = BondOfferInfo(
            bondOfferId, // bond offer NFT id
            nftId, // rwa nft id
            bondOfferIssuer, // issuer address
            bondOfferTerm, // term of bond (funding date until maturity)
            bondOfferPrice, // bond offer price
            bondOfferCouponRate, // interest rate
            initialBondMaturity, // Date to mature
            nftPrice,   // RWA Price
            collateralizationRatio, // CR
            BondOfferStatus.Issued, // Issued status
            block.timestamp // date of issue
        );

        // Set initial bond supply
        bondSupply[bondOfferId] = BondSupplyInfo({
            totalSupply: bondOfferPrice, // 1 USD = 1 bond, stored in 1e6 format
            remainingSupply: bondOfferPrice // At issuance, remaining supply = total supply
        });

        issuedBondForNFT[nftId] = bondOfferId; // Track issued bond

        // mints to the Bond contract which is msg.sender
        _safeMint(msg.sender, bondOfferId);  

        bondOfferNFTViewContract.addIssuedNft(nftId);

 

        return bondOfferId;  // Return the new bondOfferId
    }

    function getBondOfferAndSupply(uint256 bondOfferId) external view returns (
        BondOfferInfo memory, BondSupplyInfo memory
    ) {
        require(allBondOffersInfo[bondOfferId].bondOfferId != 0, "Bond offer does not exist");
        return (allBondOffersInfo[bondOfferId], bondSupply[bondOfferId]);
    }

    function getLastBondOfferByStatus(uint256 nftId, BondOfferStatus status) external view returns (uint256) {
        uint256[] memory bondOfferIds = nftToBondOffers[nftId];
        require(bondOfferIds.length > 0, "No bond offers for this NFT");

        uint256 lastBondOfferId = bondOfferIds[bondOfferIds.length - 1]; // Get last entry
        require(allBondOffersInfo[lastBondOfferId].bondOfferStatus == status, "Last bond offer does not match the requested status");

        return lastBondOfferId;
    }

 
   

    function getTotalSupply(uint256 bondOfferId) external view returns (uint256) {
        return bondSupply[bondOfferId].totalSupply;
    }

    //**********************************************************
    // get BondOfferInfo
    //**********

    function getBondOfferInfo(uint256 bondOfferId) external view returns (BondOfferInfo memory ) {
      //  require(allBondOffersInfo[bondOfferId].bondOfferId != 0, "Bond offer does not exist");
        return allBondOffersInfo[bondOfferId];
    }

    //**********************************************************
    // get nftid
    //**********

    function getNFTIdForBondOffer(uint256 bondOfferId) external view returns (uint256) {
     //   require(allBondOffersInfo[bondOfferId].bondOfferId != 0, "Bond offer does not exist");
        return allBondOffersInfo[bondOfferId].nftId;
    }

    //**********************************************************
    // bonds sold
    //*******************************
  
    function buyBond(uint256 bondOfferId, uint256 usdcAmount) public onlyAuthorizedRole {
        BondSupplyInfo storage supply = bondSupply[bondOfferId];

        if (supply.remainingSupply < usdcAmount) {
            revert InsufficientBondSupply(supply.remainingSupply, usdcAmount);
        }

        supply.remainingSupply -= usdcAmount;
    }

    function getIssuedBondOffersForNFT(uint256 nftId) external view returns (BondOfferInfo memory) {
        uint256 bondOfferId = issuedBondForNFT[nftId];
        require(bondOfferId != 0, "No issued bond for this NFT");

        return allBondOffersInfo[bondOfferId];
    }
    

    function getBondOffersForNFT(uint256 nftId) external view returns (uint256[] memory) {
        return nftToBondOffers[nftId]; // ✅ Access mapping directly
    }

    function getRemainingSupply(uint256 bondOfferId) external view returns (uint256) {
        return bondSupply[bondOfferId].remainingSupply;
    }
 
    function getBondOfferStatus(uint256 bondOfferId) external view returns (uint256) {
        return uint256(allBondOffersInfo[bondOfferId].bondOfferStatus);
    }

    //**********************************************************
    // adjusts the status to show the bond offer was funded and sets the maturity date
    //*******************************

    function fundBondOffer(uint256 bondOfferId) public  onlyAuthorizedRole  {
       
        // NFT for Bond Offering 
        BondOfferInfo storage bondOffer = allBondOffersInfo[bondOfferId];
        // not in issued status
        require(bondOffer.bondOfferStatus == BondOfferStatus.Issued, "Bond offer not in issued status");
        // not all sold
        require(bondSupply[bondOfferId].remainingSupply == 0, "Bond offer not fully funded");

        totalFundedNftValue += bondOffer.nftPrice; // store a value for the total Nft value held with AUM

        // set the maturity date
        bondOffer.bondOfferMaturity = block.timestamp + bondOffer.bondOfferTerm;

        // update the bond status
        bondOffer.bondOfferStatus = BondOfferStatus.Funded;
       // fundedNFTs.push(bondOffer.nftId);
        bondOfferNFTViewContract.addFundedNft(bondOffer.nftId, bondOffer.nftPrice);
        bondOfferNFTViewContract.addBondedNft(bondOfferId, bondOffer.bondOfferPrice);
        bondOfferNFTViewContract.removeIssuedNFT(bondOffer.nftId);
 
    }

    
 

    //***********************
    // return all the supply for an on-going sale
    //***********************

    function getIssuedBondSupplyInfo(uint256 nftId) external view returns (BondSupplyInfo memory) {
        uint256 bondOfferId = issuedBondForNFT[nftId];

        if (bondOfferId == 0) {
            return BondSupplyInfo(0, 0); // No issued bond
        }

        return bondSupply[bondOfferId];
    }

    //**********************************************************
    // Withdraw the bond offer, this is usually when the bond offer was not sold 
    //*******************************
 
    function withdrawBondOffering(uint256 bondOfferId, uint256 defaultSalePeriod) onlyAuthorizedRole public {
       
        // gets the bond offer Id       
        BondOfferInfo storage bondOffer = allBondOffersInfo[bondOfferId];
         
        
        // bond is not issued, ie sold already, or withdrawn already
        require(bondOffer.bondOfferStatus == BondOfferStatus.Issued, "Bond is not in issued status");

        // sale period has expired
        require(block.timestamp >= bondOffer.BondIssueDate+defaultSalePeriod, "Bond sale not expired");

        // Clear issued bond tracking for this NFT
        delete issuedBondForNFT[bondOffer.nftId];

        // set to withdrawn
        bondOffer.bondOfferStatus = BondOfferStatus.Withdrawn;
      
        bondOfferNFTViewContract.removeIssuedNFT(bondOffer.nftId); // remove nftid from issued array
       

    }

    //**********************************************************
    // Withdraw the bond offer, this is usually when the bond offer was not sold 
    //*******************************
 
    function redeemBond(uint256 bondOfferId) public  onlyAuthorizedRole {
       
        // get Nft for the Bond Offer
        BondOfferInfo storage bondOffer = allBondOffersInfo[bondOfferId];
        
        // Redeem happens after funding
        require(bondOffer.bondOfferStatus == BondOfferStatus.Funded, "Bond not funded");

        totalFundedNftValue -= bondOffer.nftPrice; // store a value for the total Nft value held with AUM

        // Bond Offer did not mature
        require(block.timestamp >= bondOffer.bondOfferMaturity, "Bond not matured");

        // set to redeemed
        bondOffer.bondOfferStatus = BondOfferStatus.Redeemed;
 
        bondOfferNFTViewContract.removeFundedNFT(bondOffer.nftId); // remove nftid from issued array
     
        bondOfferNFTViewContract.removeBondedNFT(bondOfferId);
       
        bondOfferNFTViewContract.addRedeemedNft(bondOffer.nftId, bondOffer.nftPrice);
 
    }

    //**********************************************************
    // generic status manager
    //*******************************

    function updateBondOfferStatus(uint256 bondOfferId, BondOfferStatus newStatus) public onlyAuthorizedRole {
      
        // must not be withdrawn
        require(allBondOffersInfo[bondOfferId].bondOfferStatus != BondOfferStatus.Withdrawn, 
        "Bond offer already withdrawn");

        // updates status
        allBondOffersInfo[bondOfferId].bondOfferStatus = newStatus;
    }
   
    //**********************
    //** Approvals
    //**********************

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

       function approveTreasuryContract(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTreasury != address(0), "Invalid address");
        _grantRole(TREASURY_ROLE, newTreasury);
    }

    function revokeTreasuryContract(address treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(TREASURY_ROLE, treasury);
    }

    function isTreasuryApproved(address treasuryAddress) external view returns (bool) {
        return hasRole(TREASURY_ROLE, treasuryAddress);
    }

    function approveBondContract(address newBond) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBond != address(0), "Invalid address");
        _grantRole(BOND_ROLE, newBond);
    }

    function revokeBondContract(address bond) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BOND_ROLE, bond);
    }

    function isBondApproved(address bondAddress) external view returns (bool) {
        return hasRole(BOND_ROLE, bondAddress);
    }
}
