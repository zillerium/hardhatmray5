// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IBondOfferNFT.sol";
import "./interfaces/IBondFeesNFT.sol";
import "./interfaces/IWalletNFT.sol";
import "./interfaces/IWalletFeesNFT.sol";
import "./interfaces/IBondInvestment.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Bond is Ownable, AccessControl, IERC721Receiver {
 
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE"); // Treasury only access
    IWalletNFT public walletNFTContract; // wallets for investors
    IWalletFeesNFT public walletFeesNFTContract; // wallets for customers (pay fees)
    IBondOfferNFT public bondOfferNFTContract; // actual bond offering to investors
    IBondFeesNFT public bondFeesNFTContract; // actual fee payments
    IBondInvestment public bondInvestmentContract; // bond investment
    
    uint256 public defaultDepositPeriod = 360 days; // default investment into the liquidity pool
    uint256 public defaultBondOfferTerm = 365 days; // default for the length of the bond term
    uint256 public defaultBondSalePeriod = 1 days; // default for the duration of the bond sale
    uint256 public defaultCollateralizationRatio = 7000; // 70% in basis points

    mapping(address => uint256) public musdDisbursements; // receives fees (bondholders)

    constructor(address initialOwner) Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    //****************************************************
    //** S E T T E R S    for      defaults
    //****************************************************

    function setDefaultBondSalePeriod(uint256 newSalePeriod) public onlyOwner {
        defaultBondSalePeriod = newSalePeriod;
    }

    function setDefaultBondOfferTerm(uint256 newTerm) public onlyOwner {
        defaultBondOfferTerm = newTerm;
    }

    function setDefaultCollateralizationRatio(uint256 newRatio) public onlyOwner {
        defaultCollateralizationRatio = newRatio;
    }


    //******************************************************
    //** S E T T E R S    for      contracts (Composition)
    //******************************************************

    function setBondOfferNFTContract(address newBondOfferNFTContract) external onlyOwner {
        require(newBondOfferNFTContract != address(0), "Invalid BondOfferNFT contract address");
        bondOfferNFTContract = IBondOfferNFT(newBondOfferNFTContract);
    }

     function setBondFeesNFTContract(address newBondFeesNFTContract) external onlyOwner {
        require(newBondFeesNFTContract != address(0), "Invalid BondOfferNFT contract address");
        bondFeesNFTContract = IBondFeesNFT(newBondFeesNFTContract);
    }

    function setWalletNFTContract(address newWalletNFTContract) external onlyOwner {
        require(newWalletNFTContract != address(0), "Invalid Wallet NFT token address");
        walletNFTContract = IWalletNFT(newWalletNFTContract);
    }

    function setWalletFeesNFTContract(address newWalletFeesNFTContract) external onlyOwner {
        require(newWalletFeesNFTContract != address(0), "Invalid Wallet Fees NFT token address");
        walletFeesNFTContract = IWalletFeesNFT(newWalletFeesNFTContract);
    }

    function setBondInvestmentContract(address newBondInvestmentContract) external onlyOwner {
        require(newBondInvestmentContract != address(0), "Invalid Bond Investment token address");
        bondInvestmentContract = IBondInvestment(newBondInvestmentContract);

    }

    //******************************
    // End of Setters 
    //******************************
   

    //******************************
    // Customer issues Bond Offering, fees must have been paid in advance
    //******************************

    function bondIssueBondOffering(
        uint256 nftId, 
        uint256 bondOfferPrice, 
        uint256 bondOfferCouponRate, 
        uint256 nftPrice, 
        uint256 collateralizationRatio,
        address issuer) public onlyRole(TREASURY_ROLE) returns (uint256) {

        require(address(bondOfferNFTContract) != address(0), "BondOfferNFT contract not set");

        // Fees to list bond, and pay for the bond term
        uint256 fees = calculateFees( bondOfferPrice,bondOfferCouponRate, defaultBondOfferTerm);
         
        // must be enough Fees to pay for the bond offering
        uint256 walletFeesNFTId = walletFeesNFTContract.walletToNFTId(issuer);
        require(walletFeesNFTId != 0, "Fees Wallet does not have an NFT");

        // check check of the fees being available (been paid)
        IWalletFeesNFT.WalletFeesInfo memory walletFeesInfo = walletFeesNFTContract.getWalletFeesInfoByNFTId(walletFeesNFTId);
        require(walletFeesInfo.feeBalance >= fees, "Insufficient fees balance in issuer wallet");

        // NFT for actual Bond Offering
        uint256 bondOfferId = bondOfferNFTContract.bondOfferIssueBondOffering(
            nftId, 
            bondOfferPrice, 
            defaultBondOfferTerm, 
            bondOfferCouponRate, 
            nftPrice, 
            collateralizationRatio, 
            issuer);

        // mints bond Fees NFT when fees available in WalletFeesNFT
        bondFeesNFTContract.usdcDepositFees(fees, issuer ,bondOfferId);

        // reduce fees in issuer wallet after the deposit is made
        walletFeesNFTContract.reduceFeeBalance(issuer,fees);

        return bondOfferId;
 
     }

    //**************************
    // Calculate Fees
    //**************************

    function calculateFees(
        uint256 bondFundingTarget,
        uint256 bondCouponRate,
        uint256 bondPeriodInSeconds
    ) public pure returns (uint256) {
        require(bondFundingTarget > 0, "Invalid bond funding target");
        require(bondCouponRate > 0, "Invalid bond coupon rate");
        require(bondPeriodInSeconds > 0, "Invalid bond period");

        // Calculate fees: (bondFundingTarget * bondCouponRate * bondPeriodInSeconds) / (365 * 10000 * 86400)
        uint256 fees = (bondFundingTarget * bondCouponRate * bondPeriodInSeconds) / (365 * 10000 * 86400);
  
        return fees;
    }

    //**************************
    // Buy Bond
    // 1. funds are taken from the liquidity pool (USDC)
    // 2. Investors to the LP already provide funds and these are just reallocated
    // 3. Actual USDC transfers only happen into and out of the LP and with fee payments/receipts
    //**************************

    function buyBond(
        uint256 bondOfferId, 
        uint256 usdcAmount, 
        address buyer) public onlyRole(TREASURY_ROLE) returns (address, uint256, bool) {

        // check there are bonds to buy
        require(bondOfferNFTContract.getRemainingSupply(bondOfferId) >= usdcAmount, "Not enough bonds available");

        // Check the bond investor has a wallet NFT setup
        uint256 walletNFTId = walletNFTContract.walletToNFTId(buyer);
        require(walletNFTId != 0, "Buyer does not have an NFT");

        // Check liquid balance for bond investor is enough to buy the bonds
        IWalletNFT.WalletInfo memory walletInfo = walletNFTContract.getWalletInfoByNFTId(walletNFTId);
        require(walletInfo.liquidBalance >= usdcAmount, "Insufficient liquid balance for buyer");

        // adjust the liquid balance and increase the bond balance   
        // adjusts role for Bond too.
        uint256 investorDisbursement = manageFees(  bondOfferId,   usdcAmount);
        walletNFTContract.increasePendingDisbursementsBalance(buyer, investorDisbursement);

        walletNFTContract.reduceLiquidBalance(buyer, usdcAmount);  
        walletNFTContract.increaseBondBalance(buyer, usdcAmount); 
  
        // Update bond supply in bond offer contract
        bondOfferNFTContract.buyBond(bondOfferId, usdcAmount); 

        // record NFT investment as an NFT for the bond investment
        bondInvestmentContract.mintBondInvestmentNFT(buyer, usdcAmount, bondOfferId, walletNFTId);
 
        if (bondOfferNFTContract.getRemainingSupply(bondOfferId)== 0) {
                // Get bond info to identify the issuer
                IBondOfferNFT.BondOfferInfo memory bondInfo = bondOfferNFTContract.getBondOfferInfo(bondOfferId);
                address bondIssuer = bondInfo.bondOfferIssuer;

                uint256 totalSupply = bondOfferNFTContract.getTotalSupply(bondOfferId);

                // Ensure the bond is marked as funded
                bondOfferNFTContract.fundBondOffer(bondOfferId);

                bondOfferNFTContract.updateBondOfferStatus(bondOfferId, IBondOfferNFT.BondOfferStatus.Funded);
                return (bondIssuer, totalSupply, true);
          }
        
        return (address(0), 0, false);
    }

    // calc pending fees at the time the bond is purchased

    function manageFees(uint256 bondOfferId, uint256 investment) internal view returns (uint256) {

        IBondFeesNFT.BondFeesInfo memory bondFeeInfo = bondFeesNFTContract.getBondFeesInfoByBondOfferId(bondOfferId);
        uint256 fees = bondFeeInfo.usdcAmount;
        IBondOfferNFT.BondOfferInfo memory bondInfo = bondOfferNFTContract.getBondOfferInfo(bondOfferId);
        uint256 totalInvestment = bondInfo.bondOfferPrice;
        uint256 multiplier = totalInvestment / investment; // Avoids truncation errors
        uint256 investorDisbursement = fees / multiplier;  // Correct way to calculate prorated fee
        return investorDisbursement;

    }

    function redeemNft(uint256 nftId) public onlyRole(TREASURY_ROLE)    returns   (uint256, address, uint256) {

        (IBondOfferNFT.BondOfferStatus bondInfoStatus, uint256 bondOfferId) = 
                              bondOfferNFTContract.getLastBondOfferStatus(nftId);
        IBondOfferNFT.BondOfferInfo memory bondInfo = bondOfferNFTContract.getBondOfferInfo(bondOfferId);
        if (bondInfo.bondOfferStatus != IBondOfferNFT.BondOfferStatus.Redeemed) {
            redeemBond(bondInfo.bondOfferId);
        }

        return (nftId, bondInfo.bondOfferIssuer, bondInfo.bondOfferPrice );

 
    }

    //***********************************************
    // Redeem bond, can be done by issuer or any bond investor
    //***********************************************

    function redeemBond(uint256 bondOfferId) public onlyRole(TREASURY_ROLE)  returns (uint256, address, uint256) {

        // check bonds were all sold        
        require(bondOfferNFTContract.getRemainingSupply(bondOfferId)== 0, "Bond not funded");

        IBondOfferNFT.BondOfferInfo memory bondInfo = bondOfferNFTContract.getBondOfferInfo(bondOfferId);

        // check bond offering was fully funded
        require(bondInfo.bondOfferStatus == IBondOfferNFT.BondOfferStatus.Funded, "Bond not funded");

        // check bonds have reach maturity
        require(block.timestamp >= bondInfo.bondOfferMaturity, "Bond not matured");

        IBondInvestment.BondInvestmentInfo[] memory investors = bondInvestmentContract.getBondInvestmentsByBondOfferId(bondOfferId);

        // get fees for the bond offer
        IBondFeesNFT.BondFeesInfo memory bondFeeInfo = bondFeesNFTContract.getBondFeesInfoByBondOfferId(bondOfferId);

        uint256 fees = bondFeeInfo.usdcAmount;
        uint256 totalInvestment = bondInfo.bondOfferPrice;

        for (uint256 i = 0; i < investors.length; i++) {
            address walletAddress = investors[i].walletAddress;

            uint256 investment = investors[i].usdcAmount;

            // ✅ Calculate the proportional disbursement using proper uint256 division
            uint256 multiplier = totalInvestment / investment; // Avoids truncation errors
            uint256 investorDisbursement = fees / multiplier;  // Correct way to calculate prorated fee

            if (investment > 0) {
  
                walletNFTContract.increaseLiquidBalance(walletAddress, investment);
                walletNFTContract.reduceBondBalance(walletAddress, investment);  
                // Allocate fees after bond redeemed (i.e. reached maturity)
                walletNFTContract.increaseDisbursementsBalance(walletAddress, investorDisbursement);
                walletNFTContract.decreasePendingDisbursementsBalance(walletAddress, investorDisbursement);
            }
        }
   
        // Call redeemBond on the bondOfferNFTContract
        bondOfferNFTContract.redeemBond(bondOfferId);
        bondFeesNFTContract.distributeFees(bondOfferId);
        bondOfferNFTContract.updateBondOfferStatus(bondOfferId, IBondOfferNFT.BondOfferStatus.Redeemed);

        address issuer = bondInfo.bondOfferIssuer;

        uint256 nftid=bondOfferNFTContract.getNFTIdForBondOffer(bondOfferId);

        uint256 bondOfferPrice = bondInfo.bondOfferPrice;


        return (nftid, issuer, bondOfferPrice );
   
         
    }

    //***********************************************
    // mints the bond fees 
    //*********************************************** 

    function depositBondFees(uint256 usdcAmount, address payer, uint256 bondOfferId) public onlyRole(TREASURY_ROLE) {

        bondFeesNFTContract.usdcDepositFees(usdcAmount, payer, bondOfferId);   

    }

    //***********************************************
    // when a bond sale is not funded, can be executed by any bondholder or the issuer
    //*********************************************** 
 
    function withdrawBondOffer(uint256 bondOfferId, address wallet) public onlyRole(TREASURY_ROLE) returns (uint256) {

        // checks remaining supply > 0, ie bond offer was not fully funded
        require(bondOfferNFTContract.getRemainingSupply(bondOfferId)> 0, "Bond is funded");

        bool invested = bondInvestmentContract.checkInvestorInBondOffer( wallet, bondOfferId);
        
        IBondOfferNFT.BondOfferInfo memory bondInfo = bondOfferNFTContract.getBondOfferInfo(bondOfferId);
        require(bondInfo.bondOfferIssuer == wallet || invested, "not issuer or funder");

        // bond was still issued (i.e. not funded)
        require(bondInfo.bondOfferStatus == IBondOfferNFT.BondOfferStatus.Issued, "Bond is not in issued status");

        // bond sale has expired (ie not funded during the sale period)
        require(block.timestamp >= bondInfo.BondIssueDate+defaultBondSalePeriod, "Bond sale not expired");

        // sets bond offer status to withdrawn
        bondOfferNFTContract.withdrawBondOffering(bondOfferId, defaultBondSalePeriod);

        // get all investors for the bond
        IBondInvestment.BondInvestmentInfo[] memory investors = bondInvestmentContract.getBondInvestmentsByBondOfferId(bondOfferId);

        for (uint256 i = 0; i < investors.length; i++) {

            // wallet address of investor
            address walletAddress = investors[i].walletAddress;

            // investment made
            uint256 investment = investors[i].usdcAmount;
            uint investorDisbursement = manageFees(bondOfferId, investment);
            walletNFTContract.decreasePendingDisbursementsBalance(walletAddress, investorDisbursement);  

            if (investment > 0) {
                // return investment and rduce bond balance
                walletNFTContract.increaseLiquidBalance(walletAddress, investment);
                walletNFTContract.reduceBondBalance(walletAddress, investment);  
             }
        }

        // Call redeemBond on the bondOfferNFTContract
        bondFeesNFTContract.withdrawFees(bondOfferId);
          
        IBondFeesNFT.BondFeesInfo memory bondFeeInfo = bondFeesNFTContract.getBondFeesInfoByBondOfferId(bondOfferId);

        uint256 fees = bondFeeInfo.usdcAmount;


        // return fees to the issuer wallet
        walletFeesNFTContract.increaseFeeBalance(wallet, fees);

        uint256 nftid=bondOfferNFTContract.getNFTIdForBondOffer(bondOfferId);
        return nftid;
     }

  
    function fundBondOffer(uint256 bondOfferId) public onlyRole(TREASURY_ROLE) {
        require(address(bondOfferNFTContract) != address(0), "BondOfferNFT contract not set");
        bondOfferNFTContract.fundBondOffer(bondOfferId);
    }

    function updateBondOfferStatus(uint256 bondOfferId, uint256 newStatus) public onlyRole(TREASURY_ROLE) {
        require(address(bondOfferNFTContract) != address(0), "BondOfferNFT contract not set");
        bondOfferNFTContract.updateBondOfferStatus(bondOfferId, IBondOfferNFT.BondOfferStatus(newStatus));
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
