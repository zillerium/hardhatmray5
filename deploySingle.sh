#!/bin/bash

# Ensure a contract name is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a contract name."
    echo "Usage: ./deploySingle.sh Treasury"
    exit 1
fi

CONTRACT_NAME=$1
MODULE_FILE="ignition/modules/Deploy${CONTRACT_NAME}.js"

# Check if module file exists
if [ ! -f "$MODULE_FILE" ]; then
    echo "❌ Error: Module file $MODULE_FILE does not exist!"
    exit 1
fi

echo "🚀 Deploying contract: $CONTRACT_NAME ..."
npx hardhat ignition deploy "$MODULE_FILE" --network basesepolia 

echo "✅ Deployment complete for: $CONTRACT_NAME"

