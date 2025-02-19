// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WalletNFT is ERC721, Ownable, AccessControl {
    uint256 public walletNFTCount;
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant BOND_ROLE = keccak256("BOND_ROLE");
    error CallerNotAuthorized(address caller);

    error CallerNotTreasury(address caller);
   
    struct WalletInfo {
        uint256 walletNFTId; // Nft Id for wallet
        address walletAddress; // wallet address
        bool KYC; // true for KYC approved
        bool AML; // true for AML approved
        uint256 bondBalance; // invested in bonds
        uint256 liquidBalance; // invested and not used
        uint256 disbursementsBalance; // actual earnings waiting to be paid out
        uint256 pendingDisbursementsBalance; // actual earnings waiting to be paid out

    }

    mapping(address => uint256) public walletToNFTId; // Maps wallet address to NFT ID
    mapping(uint256 => WalletInfo) public walletInfoById; // Maps NFT ID to WalletInfo
    
    constructor(address initialOwner) ERC721("WalletNFT", "WalletNFT") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    // Modifier to check for either role
    modifier onlyAuthorizedRole() {
        if (!hasRole(TREASURY_ROLE, msg.sender) && !hasRole(BOND_ROLE, msg.sender)) {
            revert CallerNotAuthorized(msg.sender);
        }
        _;
    }

    //****************
    // Creates new wallet Nft Id
    //*************

    function mintWalletNFT(address wallet) internal  {
        // check wallet does not exist
        require(walletToNFTId[wallet] == 0, "Wallet already has an NFT");
       
        // new Nft Id for wallet
        walletNFTCount++;
        uint256 newWalletNFTId = walletNFTCount;
        
        // create a mapping for wallet to wallet NFT Id
        walletToNFTId[wallet] = newWalletNFTId;

        // initialize wallet details
        walletInfoById[newWalletNFTId] = WalletInfo({
            walletNFTId: newWalletNFTId,
            walletAddress: wallet,
            KYC: false,
            AML: false,
            bondBalance: 0,
            liquidBalance: 0,
            disbursementsBalance: 0,
            pendingDisbursementsBalance: 0
        });
        
        // mint to the Treasury, the Treasury is msg.sender
        _safeMint(msg.sender, newWalletNFTId);  
     }

    //****************
    // adds to Pending Disbursements Balance
    //****************

    function increasePendingDisbursementsBalance(address wallet, uint256 amount) public onlyAuthorizedRole {
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        walletInfoById[walletNFTId].pendingDisbursementsBalance += amount;
    }
    //*************
    // subtracts from Pending Disbursements Balance
    //****************
    
    function decreasePendingDisbursementsBalance(address wallet, uint256 amount) public onlyAuthorizedRole {
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        require(walletInfoById[walletNFTId].pendingDisbursementsBalance >= amount, "Insufficient pending disbursements balance");
        walletInfoById[walletNFTId].pendingDisbursementsBalance -= amount;
    }

    //****************
    // adds to Disbursements Balance
    //****************

    function increaseDisbursementsBalance(address wallet, uint256 amount) public onlyAuthorizedRole {
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        walletInfoById[walletNFTId].disbursementsBalance += amount;
    }

    //****************
    // subtracts from Disbursements Balance
    //****************
    
    function decreaseDisbursementsBalance(address wallet, uint256 amount) public onlyAuthorizedRole {
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        require(walletInfoById[walletNFTId].disbursementsBalance >= amount, "Insufficient disbursements balance");
        walletInfoById[walletNFTId].disbursementsBalance -= amount;
    }

    //****************
    // increase liquid balance
    //****************
    
    function increaseLiquidBalance(address wallet, uint256 amount) public onlyAuthorizedRole  { 
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        walletInfoById[walletNFTId].liquidBalance += amount;
    }

    //****************
    // reduce liquid balance
    //****************

    function reduceLiquidBalance(address wallet, uint256 amount) public onlyAuthorizedRole  { 
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        require(walletInfoById[walletNFTId].liquidBalance >= amount, "Insufficient liquid balance");
        walletInfoById[walletNFTId].liquidBalance -= amount;
    }

    //****************
    // reduce bond balance
    //****************

    function reduceBondBalance(address wallet, uint256 amount) public onlyAuthorizedRole  { 
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        require(walletInfoById[walletNFTId].bondBalance >= amount, "Insufficient bond balance");
        walletInfoById[walletNFTId].bondBalance -= amount;
    }  

    //****************
    // increase bond balance
    //****************

    function increaseBondBalance(address wallet, uint256 amount) public onlyAuthorizedRole  { 
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        walletInfoById[walletNFTId].bondBalance += amount;
    }

    //***********************************
    // returns wallet for an wallet id
    //***********************************

    function getWalletInfoByNFTId(uint256 walletNFTId) external view returns (WalletInfo memory) {
        require(walletNFTId > 0 && walletNFTId <= walletNFTCount, "Invalid wallet NFT ID");
        return walletInfoById[walletNFTId];
    }

    //***********************************
    // returns wallet for an address
    //***********************************

    function getWalletInfoByAddress(address wallet) external view returns (WalletInfo memory) {
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        return walletInfoById[walletNFTId];
    }

    //***********************************
    // mint new wallet
    //***********************************

    function conditionallyMintWalletNFT(address wallet) public onlyAuthorizedRole   {
      
        if (walletToNFTId[wallet] == 0) {
            mintWalletNFT(wallet);
        }
    }

    //***********************************
    // mint new wallet and update liquid balance
    //***********************************

    function mintAndUpdateLiquidBalance(address wallet, uint256 amount) external   onlyAuthorizedRole {
     
        conditionallyMintWalletNFT(wallet);
        updateLiquidBalance(wallet, amount);
    }

    //***********************************
    // add to liquid balance (non invested amounts)
    //***********************************

    function updateLiquidBalance(address wallet, uint256 amount) public onlyAuthorizedRole {
        
        uint256 walletNFTId = walletToNFTId[wallet];
        require(walletNFTId != 0, "Wallet does not have an NFT");
        walletInfoById[walletNFTId].liquidBalance += amount;
    }


    function isAnInvestor(address wallet) external view returns (bool) {
        return walletToNFTId[wallet] != 0;
    }

    //*****************************
    // get balance details
    //*****************************

    function getWalletBalances(address wallet) external view returns 
            (uint256 bondBalance, uint256 liquidBalance, 
            uint256 disbursementsBalance, uint256 pendingDisbursementsBalance) {

        uint256 walletNFTId = walletToNFTId[wallet];

        if (walletNFTId == 0) {
            return (0, 0, 0, 0); // Return zero balances instead of reverting
        }

        WalletInfo memory walletInfo = walletInfoById[walletNFTId];

        // Return actual balances
        return (walletInfo.bondBalance, walletInfo.liquidBalance, walletInfo.disbursementsBalance, 
        walletInfo.pendingDisbursementsBalance);
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
