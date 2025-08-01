# Freewrite Local LLM Integration

This document describes the local LLM support added to Freewrite, enabling users to process their freewriting with AI-powered passes directly on their Mac.

## Features

### 1. Multiple LLM Passes
- **Summary**: Condenses your freewriting into 3-4 key sentences
- **Core Ideas**: Extracts the main ideas as a bulleted list
- **Clean Up**: Corrects grammar, punctuation, and removes filler words
- **Custom Passes**: Create your own prompts for specific processing needs

### 2. Local Model Support
The app supports these local models (downloaded on-demand):
- **Qwen 3 (0.6B)**: Smaller, faster model for basic summaries (~200 MB)
- **Qwen 3 (1.7B)**: Mid-size model with higher quality output (~900 MB)
- **Llama 3.2 (1B)**: Apple-optimized model with balanced performance (~630 MB)

### 3. User Interface

#### Settings Button
A new settings button (gear icon) has been added to the left of the history button in the bottom navigation bar.

#### LLM Processing Button
Each entry in the history sidebar now has a brain icon that appears on hover. Clicking it shows a menu with:
- Built-in passes (Summary, Core Ideas, Clean Up)
- Custom passes you've created
- "Add Custom Pass..." option

#### Settings View
Access via the settings button to:
- Select your default LLM model
- Download additional models
- Manage custom passes (add, view, delete)

#### Results Popup
After processing, results appear in a popup where you can:
- View the processed text
- Edit the result
- Copy to clipboard
- Save changes

## Implementation

### Architecture
The implementation follows the pattern from WalkWrite with adaptations for macOS:

1. **LLMEngine.swift**: Core engine handling model loading and text processing
2. **LLMModelManager.swift**: Manages model downloads and selection
3. **LLMModel.swift**: Defines available models and their properties
4. **LLMPass.swift**: Defines processing passes (built-in and custom)
5. **PassStore.swift**: Manages custom passes with persistence
6. **UI Components**: 
   - LLMDownloadSheet: Model selection and download
   - LLMResultSheet: Display processing results
   - SettingsView: Configure models and passes
   - AddCustomPassSheet: Create custom passes

### Dependencies
The app uses MLX-Swift for on-device model execution:
- MLX: Core machine learning framework
- MLXLLM: Language model support
- Tokenizers: Text tokenization
- ZIPFoundation: Model archive extraction

## Usage

### First Time Setup
1. Click the brain icon on any entry
2. You'll be prompted to download a model
3. Choose a model based on your needs (speed vs quality)
4. Wait for download to complete

### Processing Text
1. Write your freewriting as usual
2. In the history sidebar, hover over an entry
3. Click the brain icon
4. Select a pass from the menu
5. View and optionally edit the results

### Creating Custom Passes
1. Click the settings button (gear icon)
2. In the Custom Passes section, click the + button
3. Name your pass and write a prompt
4. Use {{text}} as a placeholder for the freewriting content
5. Your custom pass will appear in the processing menu

## Privacy & Performance

- All processing happens locally on your Mac
- No data is sent to external servers
- Models are stored in ~/Documents/LLMModels
- Processing speed depends on your Mac's capabilities
- Models are kept in memory for faster subsequent processing
- Memory is automatically managed based on system pressure

## Tips

- Start with the 0.6B model for quick processing
- Use larger models for more complex or nuanced text
- Custom passes work best with specific, clear instructions
- The Clean Up pass is great for preparing text to share
- Summary pass helps create quick overviews of long entries
- Core Ideas extracts actionable items from brainstorming sessions