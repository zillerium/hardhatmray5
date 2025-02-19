// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BondInvestment is ERC721, Ownable, AccessControl {
    uint256 public bondInvestmentCount;
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");

     error CallerNotAuthorized(address caller);
    error CallerNotTreasury(address caller);

    struct BondInvestmentInfo {
        uint256 bondInvestmentId; // Nft Id for wallet
        address walletAddress; // wallet address
        uint256 usdcAmount; // amount of investment
        uint256 bondOfferId; // bond offer id
        uint256 walletNFTId; // id of the investor
    }

    // Modifier to check for either role
    modifier onlyAuthorizedRole() {
        if (!hasRole(TREASURY_ROLE, msg.sender) && !hasRole(BOND_ROLE, msg.sender)) {
            revert CallerNotAuthorized(msg.sender);
        }
        _;
    }

    // Maps wallet address to Bond Investment Ids
    mapping(address => uint256[]) public walletToBondInvestmentIds;  
    // bond offerid => investments
    mapping(uint256 => BondInvestmentInfo[]) public bondInvestmentsByOfferId;
    // Maps bondOfferId => wallet => bool (true if the wallet invested)
    mapping(uint256 => mapping(address => bool)) public isInvestorInBond;
        // Maps wallet address to all BondInvestmentInfo
    mapping(address => BondInvestmentInfo[]) public bondInvestmentsByWallet;

    
    constructor(address initialOwner) ERC721("BondInvestmentNFT", "BondInvestmentNFT") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    //****************************************
    //*  Mints the actual investment into a bond
    //****************************************

    function mintBondInvestmentNFT(
        address wallet, 
        uint256 usdcAmount,
        uint256 bondOfferId,
        uint256 walletNFTId) public onlyAuthorizedRole {
        
        bondInvestmentCount++;
        uint256 newBondInvestmentNFTId = bondInvestmentCount;

        BondInvestmentInfo memory newInvestment = BondInvestmentInfo({
            bondInvestmentId: newBondInvestmentNFTId,
            walletAddress: wallet,
            usdcAmount: usdcAmount,
            bondOfferId: bondOfferId,
            walletNFTId: walletNFTId
        });

        bondInvestmentsByOfferId[bondOfferId].push(newInvestment);
        bondInvestmentsByWallet[wallet].push(newInvestment);

        // ✅ Directly mark the wallet as an investor for this bondOfferId
        isInvestorInBond[bondOfferId][wallet] = true;

        // minted to the Bond contract which is msg.sender
        _safeMint(msg.sender, newBondInvestmentNFTId);

        // investor wallet maps to all investments (different bond offers or the same)
        walletToBondInvestmentIds[wallet].push(newBondInvestmentNFTId);
 
    }

    //*************************
    // all investors who invested in a bond offer
    //*************************
    
    function getBondInvestmentsByBondOfferId(uint256 bondOfferId) external view returns (BondInvestmentInfo[] memory) {
        return bondInvestmentsByOfferId[bondOfferId];
    }

    //*************************
    // check if the wallet invested in the bond offering
    //*************************

    function checkInvestorInBondOffer(address wallet, uint256 bondOfferId) external view returns (bool) {
        return isInvestorInBond[bondOfferId][wallet];
    }

    //*************************
    // Get all BondInvestmentInfo for a wallet
    //*************************
    function getBondInvestmentsByWallet(address wallet) external view returns (BondInvestmentInfo[] memory) {
        return bondInvestmentsByWallet[wallet];
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
