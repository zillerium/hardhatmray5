// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUSDCDepositNFT.sol";
import "./interfaces/IMUSD.sol";
import "./interfaces/IRwaNft.sol";
import "./interfaces/IMRAYToken.sol";
import "./interfaces/IWalletNFT.sol";
import "./interfaces/IWalletFeesNFT.sol";
import "./interfaces/IBond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Treasury is Ownable, AccessControl, IERC721Receiver {
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    IERC20 public usdcTokenContract; // usdc erc20 contract (maintained by USDC)
    IMUSD public musdTokenContract; // internal m usd (owned by Treasury)
    IMRAYToken public mrayTokenContract; // mray erc20 tokens
    IRwaNft public rwaNftContract; // rwa nfts
    IWalletNFT public walletNFTContract; // wallets for investors
    IWalletFeesNFT public walletFeesNFTContract; // wallets for customers (pay fees)
    IUSDCDeposits public usdcDepositsContract; // deposits into the liquidity pool, actual txns
    IBond public bondContract; // bond contract

    uint256 public defaultDepositPeriod = 360 days; // default investment into the liquidity pool
 
    constructor(address initialOwner) Ownable(initialOwner) {}

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
    function setDefaultDepositPeriod(uint256 newPeriod) public onlyOwner {
        defaultDepositPeriod = newPeriod;
    }

    //******************************************************
    //** S E T T E R S    for      contracts (Composition)
    //******************************************************

    function setBondContract(address newBondContract) external onlyOwner {
        require(newBondContract != address(0), "Invalid Bond token address");
        bondContract = IBond(newBondContract);
    }


    function setDepositUSDCContract(address newUsdcDepositsContract) external onlyOwner {
        require(newUsdcDepositsContract != address(0), "Invalid USDC token address");
        usdcDepositsContract = IUSDCDeposits(newUsdcDepositsContract);
    }

    function setUsdcTokenContract(address newUsdcTokenAddress) external onlyOwner {
        require(newUsdcTokenAddress != address(0), "Invalid USDC token address");
        usdcTokenContract = IERC20(newUsdcTokenAddress);
    }


    function setMUSDContract(address newMUSDContract) external onlyOwner {
        require(newMUSDContract != address(0), "Invalid MUSD token address");
        musdTokenContract = IMUSD(newMUSDContract);
    }

   function setMRAYContract(address newMRAYContract) external onlyOwner {
        require(newMRAYContract != address(0), "Invalid MUSD token address");
        mrayTokenContract = IMRAYToken(newMRAYContract);
    }

    function setRwaNftContract(address newRwaNftContract) external onlyOwner {
        require(newRwaNftContract != address(0), "Invalid RWA NFT token address");
        rwaNftContract = IRwaNft(newRwaNftContract);
    }

    function setWalletNFTContract(address newWalletNFTContract) external onlyOwner {
        require(newWalletNFTContract != address(0), "Invalid Wallet NFT token address");
        walletNFTContract = IWalletNFT(newWalletNFTContract);
    }

    function setWalletFeesNFTContract(address newWalletFeesNFTContract) external onlyOwner {
        require(newWalletFeesNFTContract != address(0), "Invalid Wallet Fees NFT token address");
        walletFeesNFTContract = IWalletFeesNFT(newWalletFeesNFTContract);
    }

    //******************************
    // End of Setters 
    //******************************
    //******************************
    // Deposit USDC into the Investment Pool
    //******************************

    function depositUsdc(uint256 usdcAmount) public {
        require(usdcAmount > 0, "USDC amount must be greater than 0");
        
        // Checks the USDC ERC20 has enough balance and approvals done
        require(usdcTokenContract.balanceOf(msg.sender) >= usdcAmount, "Insufficient USDC balance");
        require(usdcTokenContract.allowance(msg.sender, address(this)) >= usdcAmount, "Insufficient allowance");

        // Deposits into the liquidity pool (txns are NFTs, and vested for a time period)
        usdcDepositsContract.usdcDeposit(usdcAmount, defaultDepositPeriod, msg.sender);
        
        // Actual USDC transfer to the Treasury
        usdcTokenContract.transferFrom(msg.sender, address(this), usdcAmount);
        
        // Mints a MUSD Balance to the Treasury
        musdTokenContract.mint(address(this), usdcAmount);  

        // Updates the Investor internal wallet with the investment amount
        walletNFTContract.mintAndUpdateLiquidBalance(msg.sender, usdcAmount);
    }

    //******************************
    // Withdrawal USDC from the Investment Pool
    //******************************

    function wholeWithdrawalFeesUsdc() public {

        uint256 walletFeesNFTId = walletFeesNFTContract.walletToNFTId(msg.sender);
        require(walletFeesNFTId != 0, "Fees Wallet does not balance");

        // check check of the fees being available (been paid)
        IWalletFeesNFT.WalletFeesInfo memory walletFeesInfo = walletFeesNFTContract.getWalletFeesInfoByNFTId(walletFeesNFTId);
      
        require(walletFeesInfo.feeBalance>0,"amount for fee withdrawal is 0");

        require(
            usdcTokenContract.balanceOf(address(this)) >= walletFeesInfo.feeBalance,
            "Insufficient contract USDC balance for fees transfer"
        ); 

        // reduce fee balance
        walletFeesNFTContract.reduceFeeBalance(msg.sender, walletFeesInfo.feeBalance);

        require(usdcTokenContract.transfer(msg.sender, walletFeesInfo.feeBalance), "Transfer usdc fees failed");

    }


    function withdrawalFeesUsdc(uint256 amount) public {

        uint256 walletFeesNFTId = walletFeesNFTContract.walletToNFTId(msg.sender);
        require(walletFeesNFTId != 0, "Fees Wallet does not balance");

        // check check of the fees being available (been paid)
        IWalletFeesNFT.WalletFeesInfo memory walletFeesInfo = walletFeesNFTContract.getWalletFeesInfoByNFTId(walletFeesNFTId);
      
        require(walletFeesInfo.feeBalance>=amount,"amount too high");

        require(
            usdcTokenContract.balanceOf(address(this)) >= amount,
            "Insufficient contract USDC balance"
        ); 

        // reduce fee balance
        walletFeesNFTContract.reduceFeeBalance(msg.sender, amount);

        require(usdcTokenContract.transfer(msg.sender, amount), "Transfer failed");

    }

    //******************************
    // Withdrawal disbursements
    //******************************

    function wholeWithdrawalDisbursementsUsdc() public {
        uint256 walletNFTId = walletNFTContract.walletToNFTId(msg.sender);
        require(walletNFTId != 0, "Investor does not have a wallet");

        // Check liquid balance for bond investor is enough to buy the bonds
        IWalletNFT.WalletInfo memory walletInfo = walletNFTContract.getWalletInfoByNFTId(walletNFTId);
        require(walletInfo.disbursementsBalance > 0, "Disbursement balance is 0");

        require(
            usdcTokenContract.balanceOf(address(this)) >= walletInfo.disbursementsBalance,
            "Insufficient contract USDC balance"
        ); 

        // reduce disbursements balance
        walletNFTContract.decreaseDisbursementsBalance(msg.sender, walletInfo.disbursementsBalance);

        require(usdcTokenContract.transfer(msg.sender, walletInfo.disbursementsBalance), "Transfer of Disbursements failed");


    }


    function withdrawalDisbursementsUsdc(uint256 amount) public {

        uint256 walletNFTId = walletNFTContract.walletToNFTId(msg.sender);
        require(walletNFTId != 0, "Investor does not have a wallet");

        // Check liquid balance for bond investor is enough to buy the bonds
        IWalletNFT.WalletInfo memory walletInfo = walletNFTContract.getWalletInfoByNFTId(walletNFTId);
        require(walletInfo.disbursementsBalance >= amount, "Insufficient disbursements balance for buyer");

        require(
            usdcTokenContract.balanceOf(address(this)) >= amount,
            "Insufficient contract USDC balance"
        ); 

        // reduce disbursements balance
        walletNFTContract.decreaseDisbursementsBalance(msg.sender, amount);

        require(usdcTokenContract.transfer(msg.sender, amount), "Transfer failed");
    }

    //******************************
    // Withdrawal USDC from the Investment Pool
    //******************************

    function withdrawalUsdc(uint256 nftId) public {

        // nftId is the actual NFT for the txn which was the original deposit
        IUSDCDeposits.USDCDepositInfo memory info = usdcDepositsContract.getDepositInfo(nftId);

        // Only the depositor can withdraw
        require(msg.sender == info.depositor, "Caller is not the depositor");

        // Check the vested period has expired
        require(block.timestamp > info.depositExpiry, "too early to withdraw" );

        // The Treasury needs to have enough funds to transfer out to the investor
        require(
            usdcTokenContract.balanceOf(address(this)) >= info.usdcAmount,
            "Insufficient contract USDC balance"
        );  
   
        // Checks the investment funds are not invested in a bond, ie liquid
        uint256 walletNFTId = walletNFTContract.walletToNFTId(msg.sender);
        require(walletNFTId != 0, "Wallet does not have an NFT");

        IWalletNFT.WalletInfo memory walletInfo = walletNFTContract.getWalletInfoByNFTId(walletNFTId);
        require(walletInfo.liquidBalance >= info.usdcAmount, "Insufficient liquid balance");
         
        // Checks not already redeemed
        require(
            !info.redeemed,
            "Already redeemed"
        ); 
  
        // Liquid Balance is reduced
        walletNFTContract.reduceLiquidBalance(msg.sender, info.usdcAmount); 

        usdcDepositsContract.usdcWithdrawal(nftId); // sends redeemed status to true

        // actual USDC transfer
        require(usdcTokenContract.transfer(msg.sender, info.usdcAmount), "Transfer failed"); 
     }


    //******************************
    // Deposit Fees in the customer fees wallet (customer paying for liquidity services)
    //******************************

    function depositFees(uint256 usdcAmount) public {
        require(usdcAmount > 0, "USDC amount must be greater than 0");
        // Checks the customer can pay
        require(usdcTokenContract.balanceOf(msg.sender) >= usdcAmount, "Insufficient USDC balance");
        require(usdcTokenContract.allowance(msg.sender, address(this)) >= usdcAmount, "Insufficient allowance");

        // Transfer to the Treasury the USDC sum
        usdcTokenContract.transferFrom(msg.sender, address(this), usdcAmount);
        
        // Internal MUSD minted
        musdTokenContract.mint(address(this), usdcAmount);  

        // mints fees to a customer wallet id
        walletFeesNFTContract.mintAndUpdateFeesBalance(msg.sender, usdcAmount);
    }

    //******************************
    // Customer issues Bond Offering, fees must have been paid in advance
    //******************************

    function treasuryIssueBondOffering(
        uint256 nftId, 
        uint256 bondOfferPrice, 
        uint256 bondOfferCouponRate, 
        uint256 nftPrice, 
        uint256 collateralizationRatio) public {
           
        //++++ add bond.sol
        uint256 bondOfferId = bondContract.bondIssueBondOffering(nftId, 
          bondOfferPrice, 
          bondOfferCouponRate, 
          nftPrice, 
          collateralizationRatio,
          msg.sender);
        

        // Check NFT can be transferred to the Treasury
        require(rwaNftContract.getApproved(nftId) == address(this), "Treasury not approved to transfer NFT");

        // Transfer RWA NFT to the Treasury
        rwaNftContract.transferFrom(msg.sender, address(this), nftId); // actual transfer
    }


    //**************************
    // Buy Bond
    //**************************

    function buyBond(uint256 bondOfferId, uint256 usdcAmount) public {

        // process bond in the bond contract
        (address bondIssuer, uint256 totalSupply, bool funded) = bondContract.buyBond(  bondOfferId, usdcAmount, msg.sender);
   
        // when funded, process
        if (funded) {
            // mint mray tokens to the issuer
            mrayTokenContract.mint(bondIssuer, totalSupply);
      
        }
    
    }

    // Redeems the bonds after maturity date 

    function redeemBond(uint256 bondOfferId) public {

        // ++++ redeem in Bond.sol
        (uint256 nftid, address issuer, uint256 amount) = bondContract.redeemBond(bondOfferId);

        
    }

    // redeem Nft
    // 1. Bond already redeemed, then redeem Nft only
    // 2. Bond not redeemed but funded, then redeem bond and Nft
    function redeemNft(uint256 nftId) public {
        
        // ++++ redeem in Bond.sol
        (uint256 nftid, address issuer, uint256 amount) = bondContract.redeemNft(nftId);
        require(issuer == msg.sender, "only the bond issuer can initate this action");

        // burn mray tokens when nft is returned
        mrayTokenContract.burnFrom(issuer, amount);

        // return NFT to the issuer
        rwaNftContract.transferFrom(address(this), issuer, nftid);
        
    }

    // when a bond sale is not funded, can be executed by any bondholder or the issuer
    function withdrawBondOffering(uint256 bondOfferId) public {
        // +++ withdrawal call in Bond

        uint nftid = bondContract.withdrawBondOffer(bondOfferId, msg.sender);

         // return nft to the bond offer issuer
        rwaNftContract.transferFrom(address(this), msg.sender, nftid);   
    }

    function updateBondOfferStatus(uint256 bondOfferId, uint256 newStatus) public {
         bondContract.updateBondOfferStatus(bondOfferId, newStatus);
    }

    function getLiquidBalance(address wallet) external view returns (uint256) {
        (, uint256 liquidBalance, ) = walletNFTContract.getWalletBalances(wallet);
        return liquidBalance;
    }

}
