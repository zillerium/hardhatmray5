#!/bin/bash

# Set the module file for MintERC20 deployment
MODULE_FILE="ignition/modules/DeployUsdcDepositNFT.js"

echo "🚀 Deploying MintERC20 contract..."

npx hardhat ignition deploy "$MODULE_FILE" --network basesepolia

echo "✅ MintERC20 contract deployed!"

