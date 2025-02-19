const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Load deployed contract addresses and ABIs
const deployedContractsDir = path.join(__dirname, "../deployed_contracts");

const loadJSON = (fileName) => {
    const filePath = path.join(deployedContractsDir, fileName);
    return JSON.parse(fs.readFileSync(filePath, "utf-8"));
};

// ✅ Define the mappings for contract settings
const contractConfigs = {
    "SetMRAYTreasury": { contractFile: "mrayAddress.json", abiFile: "mrayABI.json", func: "setTreasury", targetFile: "treasuryAddress.json" },
    "SetDocumentRWA": { contractFile: "documentNFTAddress.json", abiFile: "documentNFTABI.json", func: "setRWAContract", targetFile: "rwaNFTAddress.json" },
    "SetRWADocument": { contractFile: "rwaNFTAddress.json", abiFile: "rwaNFTABI.json", func: "setDocumentContract", targetFile: "documentNFTAddress.json" },
    "SetTreasuryMUSD": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setMUSDContract", targetFile: "musdAddress.json" },
    "SetTreasuryRwaNft": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setRwaNftContract", targetFile: "rwaNFTAddress.json" },
    "SetTreasuryUSDC": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setUsdcTokenContract", targetFile: "usdcAddress.json" },
    "SetTreasuryUSDDeposit": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setDepositUSDCContract", targetFile: "depositAddress.json" },
    "SetTreasuryMRAY": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setMRAYContract", targetFile: "mrayAddress.json" },
    "SetTreasuryWallet": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setWalletNFTContract", targetFile: "walletAddress.json" },
    "SetTreasuryWalletFees": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setWalletFeesNFTContract", targetFile: "walletFeesAddress.json" },
    "SetTreasuryBond": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "setBondContract", targetFile: "bondAddress.json" },
    "SetBondWallet": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "setWalletNFTContract", targetFile: "walletAddress.json" },
    "SetBondWalletFees": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "setWalletFeesNFTContract", targetFile: "walletFeesAddress.json" },
    "SetBondOfferNFT": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "setBondOfferNFTContract", targetFile: "bondOfferAddress.json" },
    "SetBondFeesNFT": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "setBondFeesNFTContract", targetFile: "bondFeesAddress.json" },
    "SetBondInvestment": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "setBondInvestmentContract", targetFile: "investAddress.json" },
    "SetBondOfferBondOfferView": { contractFile: "bondOfferAddress.json", abiFile: "bondOfferABI.json", func: "setBondOfferNFTViewContract", targetFile: "bondOfferViewAddress.json" },
};

async function updateContractState(queryType) {
    if (!contractConfigs[queryType]) {
        console.error(`❌ Invalid query type: ${queryType}`);
        return;
    }

    const { contractFile, abiFile, func, targetFile } = contractConfigs[queryType];

    const contractAddress = loadJSON(contractFile).address;
    const targetAddress = loadJSON(targetFile).address;
    const abi = loadJSON(abiFile);

    // ✅ Get signer
    const [signer] = await ethers.getSigners();
    console.log(`🔑 Using signer: ${signer.address}`);

    if (!contractAddress || !targetAddress) {
        throw new Error(`❌ Invalid address detected: contract=${contractAddress}, target=${targetAddress}`);
    }

    // ✅ Connect to the contract
    const contract = new ethers.Contract(contractAddress, abi, signer);

    console.log(`🚀 Executing ${func} on ${contractAddress} for ${targetAddress}...`);

    try {
        const tx = await contract[func](targetAddress);
        console.log(`📌 Transaction sent: ${tx.hash}`);
        await tx.wait();
        console.log(`✅ ${queryType} executed successfully.`);
    } catch (error) {
        console.error(`❌ Transaction failed:`, error.reason || error.message);
    }
}

async function updateAllContracts() {
    console.log("🔄 Updating all contract states...");
    for (const queryType of Object.keys(contractConfigs)) {
        await updateContractState(queryType);
    }
    console.log("✅ All contract updates completed.");
}

async function main() {
    if (process.argv.length > 2) {
        const queryType = process.argv[2];
        await updateContractState(queryType);
    } else {
        await updateAllContracts();
    }
}

main().catch((error) => {
    console.error("❌ Script execution error:", error);
    process.exit(1);
});

