#!/bin/bash

# Build script for Freewrite with LLM support

echo "Building Freewrite with local LLM support..."

# Check if we're in the right directory
if [ ! -f "freewrite.xcodeproj/project.pbxproj" ]; then
    echo "Error: Please run this script from the freewrite directory"
    exit 1
fi

# Option 1: Build with Swift Package Manager (if you convert the project)
# swift build -c release

# Option 2: Build with xcodebuild (current setup)
# You'll need to add the Package.swift dependencies to your Xcode project manually
echo "Please add the following dependencies to your Xcode project:"
echo "1. https://github.com/ml-explore/mlx-swift (version 0.10.0+)"
echo "2. https://github.com/ml-explore/mlx-swift-examples (version 1.15.2+)"
echo "3. https://github.com/weichsel/ZIPFoundation (version 0.9.0+)"
echo ""
echo "Then add these to your target:"
echo "- MLX, MLXNN, MLXOptimizers (from mlx-swift)"
echo "- MLXLLM, MLXLMCommon, Tokenizers (from mlx-swift-examples)"
echo "- ZIPFoundation"
echo ""
echo "After adding dependencies, build with:"
echo "xcodebuild -project freewrite.xcodeproj -scheme freewrite -configuration Release"

# Make the script executable
chmod +x build.sh