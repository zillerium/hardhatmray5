const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Load deployed contract addresses and ABIs
const deployedContractsDir = path.join(__dirname, "../deployed_contracts");

const loadJSON = (fileName) => {
    const filePath = path.join(deployedContractsDir, fileName);
    return JSON.parse(fs.readFileSync(filePath, "utf-8"));
};

const contractConfigs = {
    "SetBondFeesTreasuryAccess": { contractFile: "bondFeesAddress.json", abiFile: "bondFeesABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetBondFeesBondAccess": { contractFile: "bondFeesAddress.json", abiFile: "bondFeesABI.json", func: "approveBondContract", targetFile: "bondAddress.json" },
    "SetMUSDTreasuryAccess": { contractFile: "musdAddress.json", abiFile: "musdABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetBondOfferTreasuryAccess": { contractFile: "bondOfferAddress.json", abiFile: "bondOfferABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetBondOfferBondAccess": { contractFile: "bondOfferAddress.json", abiFile: "bondOfferABI.json", func: "approveBondContract", targetFile: "bondAddress.json" },
    "SetUSDCDepositsTreasuryAccess": { contractFile: "depositAddress.json", abiFile: "depositABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetBondInvestmentTreasuryAccess": { contractFile: "investAddress.json", abiFile: "investABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetBondInvestmentBondAccess": { contractFile: "investAddress.json", abiFile: "investABI.json", func: "approveBondContract", targetFile: "bondAddress.json" },
    "SetBondTreasuryAccess": { contractFile: "bondAddress.json", abiFile: "bondABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetWalletTreasuryAccess": { contractFile: "walletAddress.json", abiFile: "walletABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetWalletBondAccess": { contractFile: "walletAddress.json", abiFile: "walletABI.json", func: "approveBondContract", targetFile: "bondAddress.json" },
    "SetWalletFeesTreasuryAccess": { contractFile: "walletFeesAddress.json", abiFile: "walletFeesABI.json", func: "approveTreasuryContract", targetFile: "treasuryAddress.json" },
    "SetWalletFeesBondAccess": { contractFile: "walletFeesAddress.json", abiFile: "walletFeesABI.json", func: "approveBondContract", targetFile: "bondAddress.json" },
    "SetBondOfferViewBondOfferAccess": { contractFile: "bondOfferViewAddress.json", abiFile: "bondOfferViewABI.json", func: "approveBondOfferContract", targetFile: "bondOfferAddress.json" },
};

async function updateContractState(queryType) {
    if (!contractConfigs[queryType]) {
        console.error(`Invalid query type: ${queryType}`);
        return;
    }

    const { contractFile, abiFile, func, targetFile } = contractConfigs[queryType];
    
    const contractAddress = loadJSON(contractFile).address;
    const targetAddress = loadJSON(targetFile).address;
    const abi = loadJSON(abiFile);

    const [signer] = await ethers.getSigners();
    console.log(`Using signer: ${signer.address}`);

    if (!contractAddress || !targetAddress) {
        throw new Error(`Invalid address detected: contract=${contractAddress}, target=${targetAddress}`);
    }

    const contract = new ethers.Contract(contractAddress, abi, signer);

    console.log(`Executing ${func} on ${contractAddress} for ${targetAddress}...`);
    const tx = await contract[func](targetAddress);
    console.log(`Transaction sent: ${tx.hash}`);
    await tx.wait();
    console.log(`✅ ${queryType} executed successfully.`);
}

async function updateAllContracts() {
    console.log("Updating all contract states...");
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
    console.error(error);
    process.exit(1);
});

