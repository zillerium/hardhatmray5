// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Nfts are for the fee deposits

contract BondFeesNFT is ERC721, ERC721Burnable, Ownable, AccessControl {
    uint256 public bondFeesCount; // count of all deposits
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");
 
    error CallerNotAuthorized(address caller);

    struct BondFeesInfo {
        uint256 feeId;          // Nft Id, fee Id
        address payer;          // issuer of bond
        uint256 usdcAmount;     // amount deposited (from usdc contract)
        uint256 bondOfferId;    // for bond offer
        bool inTreasury;        // fees held in the Treasury
        bool redeemed;          // fees withdrawn from Treasury (sale withdrawn, eg not funded)
        bool distributed;       // paid to the bondholders
    }

    mapping(address => uint256[]) public allFeesNfts; // payer address => Nft Id
    mapping(uint256 => BondFeesInfo) public allBondFeesInfo; // Nft Id => Info
    // Maps bondOfferId => feeId (1:1 mapping, assumes one fee per bond offer)
    mapping(uint256 => uint256) public bondOfferToFeeId;
    // Maps wallet => bondOfferId => feeId (allows direct lookup)
    mapping(address => mapping(uint256 => uint256)) public walletBondOfferToFeeId;



    constructor(address initialOwner) ERC721("FeesNFT", "FeesNFT") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    // Modifier to check for either role
    modifier onlyAuthorizedRole() {
        if (!hasRole(TREASURY_ROLE, msg.sender) && !hasRole(BOND_ROLE, msg.sender)) {
            revert CallerNotAuthorized(msg.sender);
        }
        _;
    }

    function distributeFees(uint256 bondOfferId) public onlyAuthorizedRole {
        uint256 feeId = bondOfferToFeeId[bondOfferId];
        require(feeId != 0, "No fee found for this bond offer");

        BondFeesInfo storage info = allBondFeesInfo[feeId];

        require(info.inTreasury, "Fees already distributed or withdrawn");
        require(!info.redeemed, "Fees have been redeemed and cannot be distributed");
        
        // ✅ Update status
        info.distributed = true;
        info.redeemed = false;
        info.inTreasury = false;
    }

    //************************
    // Fees are withdrawn (due to a failed bond sale)
    //*************************
    function withdrawFees(uint256 bondOfferId) public onlyAuthorizedRole {
        uint256 feeId = bondOfferToFeeId[bondOfferId];
            require(feeId != 0, "No fee found for this bond offer");

        BondFeesInfo storage info = allBondFeesInfo[feeId];

        require(info.inTreasury, "Fees already withdrawn or distributed");
        require(!info.redeemed, "Fees have already been redeemed");

        // ✅ Update status
        info.inTreasury = false;
        info.redeemed = true;
        info.distributed = false;
    }


    //*************************
    // return info for a bond offer for a bond offer id
    //***********************/
    function getBondFeesInfoByBondOfferId(uint256 bondOfferId) external view returns (BondFeesInfo memory) {
        uint256 feeId = bondOfferToFeeId[bondOfferId];
        require(feeId != 0, "No fee found for this bond offer");
        return allBondFeesInfo[feeId];
    }


    // Usdc Deposits are recorded as Nfts
    function usdcDepositFees(uint256 usdcAmount, address payer, uint256 bondOfferId) public onlyAuthorizedRole {
       
        require(usdcAmount > 0, "Bond Fees amount must be greater than 0");
        
        bondFeesCount++; 
        uint256 feeId = bondFeesCount; // new nftid
        bool redeemed = false; // not withdrawn (bond sale was unfunded)
        bool distributed=false; // not paid to bond investors
        bool inTreasury = true; // fees held in the Treasury
        allFeesNfts[payer].push(feeId); // Treasury owns all Nfts on behalf of the depositer

        allBondFeesInfo[feeId] = BondFeesInfo(
            feeId,
            payer,
            usdcAmount, 
            bondOfferId,
            inTreasury,
            redeemed,
            distributed);

        // ✅ Store bondOfferId → feeId mapping
        bondOfferToFeeId[bondOfferId] = feeId;

         // ✅ Store wallet → bondOfferId → feeId mapping
        walletBondOfferToFeeId[payer][bondOfferId] = feeId;

        // minted to the Bond contract which is msg.sender
        _safeMint(msg.sender, feeId);
 
    }

    function getBondFeesInfo(uint256 feesId) external view returns (BondFeesInfo memory) {
        return allBondFeesInfo[feesId]; // ✅ Returns struct data
    }

    function getAllBondFeesInfo(address payer) public view returns (BondFeesInfo[] memory) {
        uint256[] memory feeIds = allFeesNfts[payer];
        BondFeesInfo[] memory feesInfo = new BondFeesInfo[](feeIds.length);
        
        for (uint256 i = 0; i < feesInfo.length; i++) {
            feesInfo[i] = allBondFeesInfo[feeIds[i]];
        }
        return feesInfo;
    }

    // Upon withdrawal the Nft is kept but redeem is set
    function feesWithdrawal(uint256 feeId) public onlyAuthorizedRole returns (uint256)  {

        BondFeesInfo storage info = allBondFeesInfo[feeId];
        require(!info.redeemed, "Already redeemed");
        require(!info.distributed, "Distributed, cannot redeem");

        info.redeemed = true; // set to redeemed

        return info.usdcAmount;
    }

    //**************************
    //* Fees Distribution, sets fees distributed to true
    //*************************

    function feesDistribution(uint256 feeId) public onlyRole(BOND_ROLE) returns (uint256) {
    
        BondFeesInfo storage info = allBondFeesInfo[feeId];
        require(!info.redeemed, "Already redeemed");
        require(!info.distributed, "Distributed, cannot redeem");
        info.distributed = true; // set to distributed
        return info.usdcAmount;
    }

  

    //*****************************
    // Approvals
    //*****************************

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
