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
    "CheckBondFeesTreasuryAccess": { contractFile: "bondFeesAddress.json", abiFile: "bondFeesABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckBondFeesBondAccess": { contractFile: "bondFeesAddress.json", abiFile: "bondFeesABI.json", func: "isBondApproved", checkAgainst: "bondAddress.json" },
    "CheckMUSDTreasuryAccess": { contractFile: "musdAddress.json", abiFile: "musdABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckBondOfferTreasuryAccess": { contractFile: "bondOfferAddress.json", abiFile: "bondOfferABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckBondOfferBondAccess": { contractFile: "bondOfferAddress.json", abiFile: "bondOfferABI.json", func: "isBondApproved", checkAgainst: "bondAddress.json" },
    "CheckUSDCDepositsTreasuryAccess": { contractFile: "depositAddress.json", abiFile: "depositABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckBondInvestmentTreasuryAccess": { contractFile: "investAddress.json", abiFile: "investABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckBondInvestmentBondAccess": { contractFile: "investAddress.json", abiFile: "investABI.json", func: "isBondApproved", checkAgainst: "bondAddress.json" },
    "CheckBondTreasuryAccess": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckWalletTreasuryAccess": { contractFile: "walletAddress.json", abiFile: "walletABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckWalletBondAccess": { contractFile: "walletAddress.json", abiFile: "walletABI.json", func: "isBondApproved", checkAgainst: "bondAddress.json" },
    "CheckWalletFeesTreasuryAccess": { contractFile: "walletFeesAddress.json", abiFile: "walletFeesABI.json", func: "isTreasuryApproved", checkAgainst: "treasuryAddress.json" },
    "CheckBondOfferViewBondOfferAccess": { contractFile: "bondOfferViewAddress.json", abiFile: "bondOfferViewABI.json", func: "isBondOfferApproved", checkAgainst: "bondOfferAddress.json" },
};

async function checkContractAccess(queryType) {
    if (!contractConfigs[queryType]) {
        console.error(`Invalid query type: ${queryType}`);
        return;
    }

    const { contractFile, abiFile, func, checkAgainst } = contractConfigs[queryType];
    
    const contractAddress = loadJSON(contractFile).address;
    const checkAddress = loadJSON(checkAgainst).address;
    const abi = loadJSON(abiFile);

    const contract = await hre.ethers.getContractAt(abi, contractAddress);
    const result = await contract[func](checkAddress);
    
    if (result) {
        console.log(`${queryType}: ✅ Access Approved`);
    } else {
        console.log(`${queryType}: ❌ Access Not Approved`);
    }
}

async function checkAllContracts() {
    console.log("Checking all contract access levels...");
    for (const queryType of Object.keys(contractConfigs)) {
        await checkContractAccess(queryType);
    }
    console.log("✅ All access checks completed.");
}

async function main() {
    if (process.argv.length > 2) {
        const queryType = process.argv[2];
        await checkContractAccess(queryType);
    } else {
        await checkAllContracts();
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});

