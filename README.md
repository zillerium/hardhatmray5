# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

# Hardhat Ignition DeFi Project

This project deploys and interacts with multiple smart contracts using **Hardhat Ignition**. It includes automated deployment scripts, ABI extraction, and contract execution via Hardhat.

## 🚀 Quick Start

### **1️⃣ Setup Hardhat & Install Dependencies**
1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/hardhat-project.git
   cd hardhat-project
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Set up environment variables**:
   ```bash
   cp .env.example .env
   nano .env  # Add your private key and RPC URL
   ```

---

## **2️⃣ Deployment & Testing**
### **2.1 Deploy Contracts with Hardhat Ignition**
We use **Hardhat Ignition** to deploy contracts.

**To deploy all contracts:**
```bash
./deploymods.sh
```

This script:
- Deploys all contracts using Hardhat Ignition.
- Automatically accepts deployment confirmations.

---

### **2.2 Extract ABIs & Addresses**
After deployment, you need contract **ABIs** and **addresses** for integration.

**Run the extraction script:**
```bash
./getABIs.sh
```

This script:
- Extracts contract ABIs into `deployed_contracts/`
- Extracts contract addresses from `ignition/deployments/chain-84532/deployed_addresses.json`

Example extracted files:
```
deployed_contracts/
  ├── bondABI.json
  ├── bondAddress.json
  ├── mrayABI.json
  ├── mrayAddress.json
  ├── ...
```

---

### **2.3 Execute Contract Functions**
You can interact with deployed contracts using **Hardhat Console** or scripts.

#### **🛠 Option A: Hardhat Console**
```bash
npx hardhat console --network basesepolia
```
Example:
```javascript
const contract = await ethers.getContractAt("MRAYToken", "0xYourContractAddress");
const totalSupply = await contract.totalSupply();
console.log("Total Supply:", totalSupply.toString());
```

#### **🛠 Option B: Hardhat Script**
Run:
```bash
npx hardhat run scripts/mintMRAY.js --network basesepolia
```
Example `scripts/mintMRAY.js`:
```javascript
const hre = require("hardhat");

async function main() {
    const contract = await hre.ethers.getContractAt("MRAYToken", "0xYourContractAddress");
    console.log("Minting 500 MRAY...");
    const tx = await contract.mint("0xYourAddress", ethers.utils.parseUnits("500", 18));
    await tx.wait();
    console.log("✅ Minting successful!");
}
main();
```

---

## **3️⃣ Hardhat Configuration & Setup**
### **3.1 Hardhat Config**
The `hardhat.config.js` file configures:
- Solidity optimizer
- Networks (Base Sepolia)
- Ignition deployment settings

Example:
```javascript
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: { optimizer: { enabled: true, runs: 1000 } }
  },
  networks: {
    basesepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
```

---

## **4️⃣ File & Directory Structure**
```
hardhat-project/
│── artifacts/                 # Compiled contract artifacts (ignored in .gitignore)
│── cache/                     # Hardhat cache files (ignored in .gitignore)
│── contracts/                 # Solidity smart contracts
│── deployed_contracts/        # Extracted ABIs & contract addresses
│── ignition/                  # Hardhat Ignition deployment scripts
│   ├── modules/               # Individual contract deployment modules
│── scripts/                   # Hardhat scripts for interaction
│── test/                      # Hardhat Mocha/Chai tests
│── deploymods.sh              # Deploy all contracts
│── getABIs.sh                 # Extract ABIs & contract addresses
│── hardhat.config.js          # Hardhat configuration
│── package.json               # Node.js dependencies
│── .gitignore                 # Files ignored in Git
│── .env                       # Environment variables (not committed)
│── README.md                  # This file
```

---

## **5️⃣ Troubleshooting**
### **❌ Deployment Issues**
- **Error: Node.js version warning** → Ignore using:
  ```bash
  export HARDHAT_IGNORE_NODE_WARNING=1
  ```
- **Error: "max code size exceeded"** → Reduce contract size or enable optimizer in `hardhat.config.js`.

### **❌ Missing ABI or Address Files**
- **Run ABI extraction again:**
  ```bash
  ./getABIs.sh
  ```
- **Manually check for addresses:**
  ```bash
  jq '.' ignition/deployments/chain-84532/deployed_addresses.json
  ```

---

## **6️⃣ Contributing**
1. Fork the repo and create a feature branch.
2. Commit changes and push to GitHub.
3. Open a Pull Request.

---

## **📌 Summary**
✅ **Hardhat Ignition for Deployment** (`deploymods.sh`)
✅ **Automated ABI & Address Extraction** (`getABIs.sh`)
✅ **Hardhat Console & Scripts for Execution** (`npx hardhat console`)
✅ **Optimized Solidity Compilation & Deployment**

🚀 **Now anyone can use and extend this project efficiently!**


