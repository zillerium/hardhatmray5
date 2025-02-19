// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WalletFeesNFT is ERC721, Ownable, AccessControl {
    uint256 public walletFeesNFTCount;
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");
 
    error CallerNotTreasury(address caller);
      error CallerNotAuthorized(address caller);
   
    struct WalletFeesInfo {
        uint256 walletFeesNFTId; // Nft Id for wallet
        address walletFeesAddress; // wallet address
        bool KYC; // true for KYC approved
        bool AML; // true for AML approved
        uint256 feeBalance; // fees paid (when listing bonds), held and then dispersed to the BondFeesNFT
    }

    mapping(address => uint256) public walletToNFTId; // Maps wallet address to NFT ID
    mapping(uint256 => WalletFeesInfo) public walletFeesInfoById; // Maps NFT ID to WalletFeesInfo
    
    constructor(address initialOwner) ERC721("WalletFeesNFT", "WalletFeesNFT") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }


    // Modifier to check for either role
    modifier onlyAuthorizedRole() {
        if (!hasRole(TREASURY_ROLE, msg.sender) && !hasRole(BOND_ROLE, msg.sender)) {
            revert CallerNotAuthorized(msg.sender);
        }
        _;
    }
    //******************************
    //* mints new wallet id for fees
    //**************************

    function mintWalletFeesNFT(address wallet) internal  {
        require(walletToNFTId[wallet] == 0, "Wallet already has an NFT");
        walletFeesNFTCount++;
        uint256 newWalletFeesNFTId = walletFeesNFTCount;
        
        walletToNFTId[wallet] = newWalletFeesNFTId;
        walletFeesInfoById[newWalletFeesNFTId] = WalletFeesInfo({
            walletFeesNFTId: newWalletFeesNFTId,
            walletFeesAddress: wallet,
            KYC: false,
            AML: false,
            feeBalance: 0
        });
        
        // mint to the Treasury which is msg.sender
        _safeMint(msg.sender, newWalletFeesNFTId);
     }

    //*********************
    // get fees info by fees wallet id
    //********************

    function getWalletFeesInfoByNFTId(uint256 walletFeesNFTId) external view returns (WalletFeesInfo memory) {
        require(walletFeesNFTId > 0 && walletFeesNFTId <= walletFeesNFTCount, "Invalid wallet NFT ID");
        return walletFeesInfoById[walletFeesNFTId];
    }

    //***********************
    // get fees info by wallet of issuer
    //******************

    function getWalletFeesInfoByAddress(address wallet) external view returns (WalletFeesInfo memory) {
        uint256 walletFeesNFTId = walletToNFTId[wallet];
        require(walletFeesNFTId != 0, "Wallet does not have an NFT");
        return walletFeesInfoById[walletFeesNFTId];
    }

    //********************
    //* mint new fees wallet
    //*********************

    function conditionallyMintWalletFeesNFT(address wallet) public onlyAuthorizedRole   {
      
        if (walletToNFTId[wallet] == 0) {
            mintWalletFeesNFT(wallet);
        }
    }

    //********************
    //**  add to fees wallet
    //********************

    function updateFeesBalance(address wallet, uint256 amount) public onlyAuthorizedRole {
        
        uint256 walletFeesNFTId = walletToNFTId[wallet];
        require(walletFeesNFTId != 0, "Wallet does not have an NFT");
        walletFeesInfoById[walletFeesNFTId].feeBalance += amount;
    }

    //*******************
    // mint and initialize fees wallet
    //*******************

    function mintAndUpdateFeesBalance(address wallet, uint256 amount) external   onlyAuthorizedRole {
     
        conditionallyMintWalletFeesNFT(wallet);
        updateFeesBalance(wallet, amount);
    }

    //**************************
    // reduce fee balance for issuer, bond offer withdrawn or fees paid to investors (when bond is redeemed)
    //**************************
 
    function reduceFeeBalance(address wallet, uint256 amount) public onlyAuthorizedRole  { 
        uint256 walletFeesNFTId = walletToNFTId[wallet];
        require(walletFeesNFTId != 0, "Wallet does not have an NFT");
        walletFeesInfoById[walletFeesNFTId].feeBalance -= amount;
    }
  
    //**************************
    // issuer deposits fees
    //************************** 
  
    function increaseFeeBalance(address wallet, uint256 amount) public onlyAuthorizedRole  { 
        uint256 walletFeesNFTId = walletToNFTId[wallet];
        require(walletFeesNFTId != 0, "Wallet does not have an NFT");
        walletFeesInfoById[walletFeesNFTId].feeBalance += amount;
    }


    //**************************
    // Get fee balance for a wallet address
    //**************************
    function getFeeBalance(address wallet) external view returns (uint256) {
        uint256 walletFeesNFTId = walletToNFTId[wallet];

        if (walletFeesNFTId == 0) {
            return 0; // Return 0 instead of reverting
        }

        return walletFeesInfoById[walletFeesNFTId].feeBalance;
    }

    

    //***********************
    //* Approvals for Treasury
    //***********************

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function approveTreasuryContract(address newTreasuryAddress) public  onlyOwner  {
        grantRole(TREASURY_ROLE, newTreasuryAddress);
    }

    function revokeTreasuryContract(address newTreasuryAddress) public   onlyOwner {
        revokeRole(TREASURY_ROLE, newTreasuryAddress);
    }

    function isTreasuryApproved(address newTreasuryAddress) external view returns (bool) {
        return hasRole(TREASURY_ROLE, newTreasuryAddress);
    }

      function approveBondContract(address newBond) external onlyOwner {
        require(newBond != address(0), "Invalid address");
        _grantRole(BOND_ROLE, newBond);
    }

    function revokeBondContract(address bond) external onlyOwner {
        _revokeRole(BOND_ROLE, bond);
    }

    function isBondApproved(address bondAddress) external view returns (bool) {
        return hasRole(BOND_ROLE, bondAddress);
    }
}
