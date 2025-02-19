#!/bin/bash

# Define directories
OUTPUT_DIR="deployed_contracts"
DEPLOYMENT_FILE="ignition/deployments/chain-84532/deployed_addresses.json"
mkdir -p "$OUTPUT_DIR"

# Define contracts
declare -A contracts=(
    ["Bond"]="bond"
    ["BondFeesNFT"]="bondFees"
    ["BondInvestment"]="invest"
    ["BondOfferNFT"]="bondOffer"
    ["BondOfferNFTView"]="bondOfferView"
    ["DocumentNFT"]="documentNFT"
    ["MRAYToken"]="mray"
    ["MUSD"]="musd"
    ["RealWorldAssetNFT"]="rwaNFT"
    ["Treasury"]="treasury"
    ["UsdcDepositNFT"]="deposit"
    ["WalletFeesNFT"]="walletFees"
    ["WalletNFT"]="wallet"
    ["MintERC20"]="mintContract"
)

# Extract ABIs and addresses
for contract in "${!contracts[@]}"; do
    file_prefix="${contracts[$contract]}"

    abi_file="$OUTPUT_DIR/${file_prefix}ABI.json"
    address_file="$OUTPUT_DIR/${file_prefix}Address.json"

    artifact_file="artifacts/contracts/${contract}.sol/${contract}.json"

    # Extract ABI
    if [[ -f "$artifact_file" ]]; then
        jq '.abi' "$artifact_file" > "$abi_file"
        echo "✅ Extracted ABI: $abi_file"
    else
        echo "❌ ABI file missing for $contract!"
    fi

    # Extract Address from `deployed_addresses.json`
    if [[ -f "$DEPLOYMENT_FILE" ]]; then
        address=$(jq -r ".\"${contract}Module#${contract}\"" "$DEPLOYMENT_FILE")
        if [[ "$address" != "null" && -n "$address" ]]; then
            echo "{\"address\": \"$address\"}" > "$address_file"
            echo "✅ Extracted Address: $address_file"
        else
            echo "❌ Address missing for $contract!"
        fi
    else
        echo "❌ Deployment file missing!"
    fi
done

echo "✅ ABI and address extraction complete!"

