# iVision: Apple Vision Assistant

iVision is an iOS application built using SwiftUI and CoreML/Vision frameworks that allows users to classify images using MobileNetV2 and interact with Google Generative AI (Gemini) for generating responses based on user queries.

## Features

- **Image Classification**: Uses MobileNetV2 model to classify images uploaded from the photo library or captured via the device camera.
- **Google Generative AI Integration**: Utilizes Gemini to generate responses based on user queries or classified images.
- **User Interface**: Clean and minimalistic UI inspired by Apple's design principles.
- **Interactive Messaging**: Users can interact with the app by typing queries or clicking buttons to invoke specific actions like uploading images or querying Gemini.

## Screenshots

_I will update it soon_

## Installation

### Requirements

- Xcode 12.0 or later
- iOS 14.0 or later

### Installation Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/iVision.git
   ```

2. Open the project in Xcode:

   ```bash
   cd iVision
   open iVision.xcodeproj
   ```

3. Replace `YOUR_API_KEY` in the code with your Google Generative AI (Gemini) API key. Obtain your API key from the Google Cloud Console if you haven't already.

4. Build and run the project using the iOS Simulator or your physical device.

### Configuration

- **Gemini API Key**: Replace `YOUR_API_KEY` in the code with your actual Gemini API key. This is necessary for the app to communicate with Google Generative AI.

## Usage

1. Launch the app on your iOS device.
2. Use the "Upload Image/Video" button to select an image or "Use Camera" to capture a new image for classification.
3. After classification, interact with the "Ask Gemini" button to query Google's Generative AI for additional insights or responses.
4. Enter text queries in the iMessage-like input box to engage with the app further.

## Authors

- Syed Nabiel Hasaan M
  - Email: msyednabiel@gmail.com

## Known Issues

- Currently, there are no known issues. Please report any bugs or feature requests by opening an issue in the repository.

## Contributing

Contributions are welcome! Feel free to fork the repository and submit pull requests to propose changes.

## License

This project is licensed under the [MIT License](LICENSE).
