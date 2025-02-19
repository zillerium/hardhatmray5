#!/bin/bash

# Deploy all contracts without requiring confirmation
MODULES_DIR="ignition/modules"

echo "🚀 Deploying all contracts..."

for module_file in "$MODULES_DIR"/Deploy*.js; do
    echo "Deploying: $module_file ..."
    npx hardhat ignition deploy "$module_file" --network basesepolia 
done

echo "✅ All contracts deployed!"

