// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Nfts are for the USDC deposits

contract UsdcDepositNFT is ERC721, ERC721Burnable, Ownable, AccessControl {
    uint256 public usdcDepositCount; // count of all deposits
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
 
    error CallerNotTreasury(address caller);

    struct USDCDepositInfo {
        uint256 depositId;      // Nft Id for deposit
        address depositor;      // address of depositer
        uint256 usdcAmount;     // amount deposited (from usdc contract)
        uint256 depositExpiry;  // deposits have a vested period (investment period)
        bool redeemed;          // deposit withdrawn from Treasury
    }

    mapping(address => uint256[]) public allDepositerNfts; // depositer address => Nft Id
    mapping(uint256 => USDCDepositInfo) public allUsdcDepositInfo; // Nft Id => Info

    constructor(address initialOwner) ERC721("DepositNFT", "USDCNFT") Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    // Usdc Deposits are recorded as Nfts
    function usdcDeposit(uint256 usdcAmount, uint256 depositPeriod, address depositer) public onlyRole(TREASURY_ROLE)   {
       
        require(usdcAmount > 0, "USDC amount must be greater than 0");
        require(depositPeriod > 0, "Deposit period must be positive");
        usdcDepositCount++; 
        uint256 depositId = usdcDepositCount; 
        uint256 depositExpiry = block.timestamp + depositPeriod;
        bool _redeemed = false;

        allDepositerNfts[depositer].push(depositId); // Treasury owns all Nfts on behalf of the depositer
        allUsdcDepositInfo[depositId] = USDCDepositInfo(depositId, depositer, usdcAmount, depositExpiry, _redeemed);

        // mint NFT to Treasury, msg.sender is the Treasury
        _safeMint(msg.sender, depositId);
 
    }

    // gets investment details into the pool for a specific investment
    function getDepositInfo(uint256 depositId) external view returns (USDCDepositInfo memory) {
        return allUsdcDepositInfo[depositId]; // ✅ Returns struct data
    }

    function getAllUSDCDepositInfo(address depositor) public view returns (USDCDepositInfo[] memory) {
        uint256[] memory nftIds = allDepositerNfts[depositor];
        USDCDepositInfo[] memory deposits = new USDCDepositInfo[](nftIds.length);
        
        for (uint256 i = 0; i < nftIds.length; i++) {
            deposits[i] = allUsdcDepositInfo[nftIds[i]];
        }
        return deposits;
    }


    //*****************************
    // * sets redeem to true
    //*****************

    function usdcWithdrawal(uint256 depositId) public onlyRole(TREASURY_ROLE)    {
       
        USDCDepositInfo storage info = allUsdcDepositInfo[depositId];
        require(block.timestamp > info.depositExpiry, "Request too early");
        require(!info.redeemed, "Already redeemed");

        info.redeemed = true; // set to redeemed
    }

 

    //*************************
    // Approvals
    //**********************

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function approveTreasuryContract(address newTreasuryAddress) public onlyOwner  {
        grantRole(TREASURY_ROLE, newTreasuryAddress);
    }

    function revokeTreasuryContract(address newTreasuryAddress) public onlyOwner  {
        revokeRole(TREASURY_ROLE, newTreasuryAddress);
    }

    function isTreasuryApproved(address newTreasuryAddress) external view returns (bool) {
        return hasRole(TREASURY_ROLE, newTreasuryAddress);
    }
}
