#!/bin/bash

# Directory where modules will be created
MODULES_DIR="ignition/modules"
mkdir -p "$MODULES_DIR"

# Define contracts and their module names
declare -A contracts=(
    ["Bond"]="bond"
    ["DocumentNFT"]="documentNFT"
    ["MRAYToken"]="mray"
    ["Treasury"]="treasury"
    ["BondFeesNFT"]="bondFees"
    ["BondInvestment"]="invest"
    ["MUSD"]="musd"
    ["WalletNFT"]="wallet"
    ["BondOfferNFT"]="bondOffer"
    ["BondOfferNFTView"]="bondOfferView"
    ["UsdcDepositNFT"]="deposit"
    ["MintERC20"]="mintContract"
    ["RealWorldAssetNFT"]="rwaNFT"
    ["WalletFeesNFT"]="walletFees"
)

# Default constructor argument (change as needed)
DEFAULT_ADDRESS="0x9f0BEA7dE67e8Fb333067ed83b468E5082280835"

# Generate module files
for contract in "${!contracts[@]}"; do
    module_name="${contracts[$contract]}"
    module_file="$MODULES_DIR/Deploy${contract}.js"

    cat > "$module_file" <<EOL
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("${contract}Module", (m) => {
  const ${module_name} = m.contract("${contract}", ["$DEFAULT_ADDRESS"]); // Modify if constructor needs different args
  return { ${module_name} };
});
EOL

    echo "Generated: $module_file"
done

echo "✅ All modules generated!"

