# OtosakuStreamingASR-iOS 🎤

![Otosaku Streaming ASR](https://img.shields.io/badge/OtosakuStreamingASR-iOS-brightgreen.svg)

OtosakuStreamingASR-iOS is a powerful real-time speech recognition engine for iOS, designed to provide efficient audio transcription directly on mobile devices. Built with Swift and leveraging Core ML, this engine uses a fast and lightweight streaming Conformer model optimized for on-device inference. 

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)
- [Links](#links)

## Features 🌟

- **Real-Time Processing**: Achieve immediate audio transcription without delay.
- **On-Device Inference**: Utilize Core ML for efficient processing, reducing reliance on network connections.
- **Lightweight Model**: The Conformer model is optimized for mobile, ensuring fast performance.
- **Easy Integration**: Simple APIs allow for quick setup and use in your iOS applications.
- **Supports Multiple Languages**: Easily adapt the engine for different languages and dialects.

## Installation 📦

To get started with OtosakuStreamingASR-iOS, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Konjevod1/OtosakuStreamingASR-iOS.git
   ```

2. **Open the Project**:
   Navigate to the project directory and open the `.xcodeproj` file in Xcode.

3. **Install Dependencies**:
   If you are using CocoaPods, add the following line to your `Podfile`:
   ```ruby
   pod 'OtosakuStreamingASR-iOS'
   ```
   Then run:
   ```bash
   pod install
   ```

4. **Build the Project**:
   Select your target device and build the project.

5. **Download the Latest Release**:
   For the latest version, visit the [Releases](https://github.com/Konjevod1/OtosakuStreamingASR-iOS/releases) section, download the required files, and execute them as needed.

## Usage 📖

To use OtosakuStreamingASR-iOS in your application, follow these steps:

1. **Import the Framework**:
   In your Swift file, import the framework:
   ```swift
   import OtosakuStreamingASR
   ```

2. **Initialize the Speech Recognizer**:
   Create an instance of the speech recognizer:
   ```swift
   let recognizer = OtosakuStreamingASR()
   ```

3. **Start Listening**:
   Begin the audio transcription process:
   ```swift
   recognizer.startListening { result in
       switch result {
       case .success(let transcription):
           print("Transcription: \(transcription)")
       case .failure(let error):
           print("Error: \(error.localizedDescription)")
       }
   }
   ```

4. **Stop Listening**:
   To stop the transcription, call:
   ```swift
   recognizer.stopListening()
   ```

## Examples 📱

Here are some examples to illustrate how to use the OtosakuStreamingASR-iOS framework effectively.

### Example 1: Basic Usage

This example shows a simple implementation that starts and stops listening based on user interaction.

```swift
import UIKit
import OtosakuStreamingASR

class ViewController: UIViewController {
    let recognizer = OtosakuStreamingASR()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        let startButton = UIButton(frame: CGRect(x: 50, y: 100, width: 200, height: 50))
        startButton.setTitle("Start Listening", for: .normal)
        startButton.addTarget(self, action: #selector(startListening), for: .touchUpInside)
        view.addSubview(startButton)

        let stopButton = UIButton(frame: CGRect(x: 50, y: 200, width: 200, height: 50))
        stopButton.setTitle("Stop Listening", for: .normal)
        stopButton.addTarget(self, action: #selector(stopListening), for: .touchUpInside)
        view.addSubview(stopButton)
    }

    @objc func startListening() {
        recognizer.startListening { result in
            switch result {
            case .success(let transcription):
                print("Transcription: \(transcription)")
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    @objc func stopListening() {
        recognizer.stopListening()
    }
}
```

### Example 2: Handling Multiple Languages

You can easily adapt the engine for different languages. Here’s how:

```swift
import OtosakuStreamingASR

class LanguageViewController: UIViewController {
    let recognizer = OtosakuStreamingASR()

    func setLanguage(to language: String) {
        recognizer.setLanguage(language)
    }
}
```

## Contributing 🤝

We welcome contributions to OtosakuStreamingASR-iOS! If you want to help improve this project, follow these steps:

1. **Fork the Repository**: Click the fork button at the top right of the repository page.
2. **Create a Branch**: Use a descriptive name for your branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make Your Changes**: Implement your feature or fix the bug.
4. **Commit Your Changes**: Write clear commit messages:
   ```bash
   git commit -m "Add new feature"
   ```
5. **Push to Your Branch**:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Open a Pull Request**: Go to the original repository and create a pull request.

## License 📜

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Links 🔗

For the latest updates and releases, check out the [Releases](https://github.com/Konjevod1/OtosakuStreamingASR-iOS/releases) section.

If you encounter any issues or have questions, feel free to open an issue in the repository. Your feedback is important to us.

Thank you for your interest in OtosakuStreamingASR-iOS! We hope you find it useful for your speech recognition needs.