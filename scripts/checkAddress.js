const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

// Load deployed contract addresses and ABIs
const deployedContractsDir = path.join(__dirname, "../deployed_contracts");

const loadJSON = (fileName) => {
    const filePath = path.join(deployedContractsDir, fileName);
    return JSON.parse(fs.readFileSync(filePath, "utf-8"));
};

const contractConfigs = {
    "GetMRAYTreasury": { contractFile: "mrayAddress.json", abiFile: "mrayABI.json", func: "treasury", expectedFile: "treasuryAddress.json" },
    "GetDocumentRWA": { contractFile: "documentNFTAddress.json", abiFile: "documentNFTABI.json", func: "rwaContract", expectedFile: "rwaNFTAddress.json" },
    "GetRWADocument": { contractFile: "rwaNFTAddress.json", abiFile: "rwaNFTABI.json", func: "documentContract", expectedFile: "documentNFTAddress.json" },
    "GetTreasuryMUSD": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "musdTokenContract", expectedFile: "musdAddress.json" },
    "GetTreasuryMRAY": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "mrayTokenContract", expectedFile: "mrayAddress.json" },
    "GetTreasuryRwaNft": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "rwaNftContract", expectedFile: "rwaNFTAddress.json" },
    "GetTreasuryUSDDeposit": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "usdcDepositsContract", expectedFile: "depositAddress.json" },
    "GetTreasuryUSDC": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "usdcTokenContract", expectedFile: "usdcAddress.json" },
    "GetTreasuryWallet": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "walletNFTContract", expectedFile: "walletAddress.json" },
    "GetTreasuryWalletFees": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "walletFeesNFTContract", expectedFile: "walletFeesAddress.json" },
    "GetTreasuryBond": { contractFile: "treasuryAddress.json", abiFile: "treasuryABI.json", func: "bondContract", expectedFile: "bondAddress.json" },
    "GetBondWallet": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "walletNFTContract", expectedFile: "walletAddress.json" },
    "GetBondWalletFees": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "walletFeesNFTContract", expectedFile: "walletFeesAddress.json" },
    "GetBondOfferNFT": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "bondOfferNFTContract", expectedFile: "bondOfferAddress.json" },
    "GetBondFeesNFT": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "bondFeesNFTContract", expectedFile: "bondFeesAddress.json" },
    "GetBondInvestment": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "bondInvestmentContract", expectedFile: "investAddress.json" },
    "GetBondOfferBondOfferView": { contractFile: "bondOfferAddress.json", abiFile: "bondOfferABI.json", func: "bondOfferNFTViewContract", expectedFile: "bondOfferViewAddress.json" },
};

async function checkContractGetter(queryType) {
    if (!contractConfigs[queryType]) {
        console.error(`Invalid query type: ${queryType}`);
        return;
    }

    const { contractFile, abiFile, func, expectedFile } = contractConfigs[queryType];
    
    const contractAddress = loadJSON(contractFile).address;
    const expectedAddress = loadJSON(expectedFile).address;
    const abi = loadJSON(abiFile);

    const contract = await hre.ethers.getContractAt(abi, contractAddress);
    const result = await contract[func]();
    
    if (result.toLowerCase() === expectedAddress.toLowerCase()) {
        console.log(`${queryType}: ✅ Set correctly`);
    } else {
        console.log(`${queryType}: ❌ Not set correctly (expected: ${expectedAddress}, got: ${result})`);
    }
}

async function checkAllContracts() {
    console.log("Checking all contract addresses...");
    for (const queryType of Object.keys(contractConfigs)) {
        await checkContractGetter(queryType);
    }
    console.log("✅ All checks completed.");
}

async function main() {
    if (process.argv.length > 2) {
        const queryType = process.argv[2];
        await checkContractGetter(queryType);
    } else {
        await checkAllContracts();
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

