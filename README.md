# Freewrite with Local LLM Support

A minimalist macOS freewriting app enhanced with local AI capabilities. Built with SwiftUI and powered by MLX for on-device language models.

> This is a fork of the original [Freewrite](https://github.com/BUILD-UNKOWN/freewrite) by Farza Majeed, enhanced with local LLM processing capabilities while maintaining the core philosophy of distraction-free writing.

## Features

### Core Freewriting Features
- **Distraction-free writing**: Clean, minimal interface that fades away during timed sessions
- **Daily entries**: Automatic date-based organization
- **Customizable fonts**: Lato, Arial, System, Times New Roman, or random
- **Adjustable font sizes**: 16-26px
- **Timer with scroll control**: 5-45 minute sessions
- **Auto-save**: Never lose your work
- **PDF export**: Beautiful formatted exports
- **Light/dark themes**: Easy on the eyes

### AI Enhancements (New!)
- **Local LLM Processing**: All AI runs on your Mac, no cloud required
- **Multiple AI Passes**:
  - **Summary**: Condense your freewriting into key points
  - **Core Ideas**: Extract main concepts as bullet points  
  - **Clean Up**: Fix grammar and typos while preserving your voice
  - **Custom Passes**: Create your own AI prompts
- **Model Options**:
  - Qwen 3 (0.6B) - Fast, lightweight
  - Qwen 3 (1.7B) - Higher quality
  - Llama 3.2 (1B) - Balanced performance
- **Tabbed Results**: View all AI outputs in one place
- **Privacy First**: Everything stays on your device

## Installation

### Option 1: Download Pre-built App (Coming Soon)
1. Go to the [Releases](../../releases) page
2. Download the latest `.dmg` or `.zip` file
3. Drag `freewrite.app` to your Applications folder
4. Launch and start writing!

*Note: Pre-built releases are coming soon. For now, please build from source.*

### Option 2: Build from Source
See the "Building from Source" section below.

## Using AI Features

1. Write your freewriting entry as usual
2. In the history sidebar, hover over any entry
3. Click the brain icon to process with AI
4. All passes run automatically
5. View results in tabs, edit, and copy as needed

## Building from Source

### Requirements
- macOS 14.0+
- Xcode 15+
- Swift 5.9+

### Dependencies
Add these Swift packages in Xcode:
- `https://github.com/ml-explore/mlx-swift` (0.10.0+)
- `https://github.com/ml-explore/mlx-swift-examples` (1.15.2+)
- `https://github.com/weichsel/ZIPFoundation` (0.9.0+)

### Build Steps
1. Clone this repository
2. Open `freewrite.xcodeproj` in Xcode
3. Add the package dependencies listed above
4. Build and run (⌘R)

## Philosophy

Freewrite is built on the principle of continuous, unedited writing. The AI features are designed as post-processing tools that respect this philosophy - they never interrupt your flow, only enhance your work after you're done writing.

## Privacy

- All text processing happens locally using MLX
- No data is sent to external servers
- Models are downloaded once and stored locally
- Your writing remains completely private

## Credits

This is a fork of the original [Freewrite](https://github.com/BUILD-UNKOWN/freewrite) app by Farza Majeed.

- Original Freewrite concept and implementation: Farza Majeed
- LLM integration and enhancements: Added in this fork
- Inspiration for local LLM implementation: WalkWrite app

## License

MIT License - see [LICENSE](LICENSE) file for details.

This project maintains the same MIT license as the original Freewrite.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Future Ideas

- Voice input with local Whisper model
- Writing analytics and insights
- Semantic search across entries
- More AI writing coaches
- iOS companion app

---

Built with ❤️ for writers who think by writing