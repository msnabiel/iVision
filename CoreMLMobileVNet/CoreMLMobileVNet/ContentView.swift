import SwiftUI
import AVKit
import CoreML
import Vision
import GoogleGenerativeAI

enum MessageSender {
    case user
    case gemini
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let sender: MessageSender
}

struct ContentView: View {
    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var imagePickerPresented = false
    @State private var cameraPresented = false
    @State private var selectedImage: UIImage?
    @State private var classificationResult: String = "No classification yet."
    @State private var showGeminiButton: Bool = false
    
    let config = GenerationConfig(maxOutputTokens: 900)
    let model: GenerativeModel
    
    init() {
        model = GenerativeModel(name: "gemini-1.5-flash", apiKey: "YOUR_API_KEY", generationConfig: config)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(messages) { message in
                            HStack {
                                if message.sender == .user {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(30)
                                        .foregroundColor(.black)
                                        .shadow(radius: 1)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                } else {
                                    Text(message.content)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(30)
                                        .foregroundColor(.black)
                                        .shadow(radius: 1)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: message.sender == .user ? .trailing : .leading)
                        }
                    }
                    .padding(.top, 10)
                }
                
                VStack {
                    HStack{
                        Text("Classification Result: \(classificationResult)")
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.bottom, 10)
                        
                        if showGeminiButton {
                            Button(action: {
                                sendMessage(text: "What is a \(classificationResult)?")
                            }) {
                                Image("GeminiIcon") // Replace "GeminiIcon" with the actual name of your icon asset
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24) // Adjust size as needed
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                    .overlay(
                                                            Circle().stroke(Color.black, lineWidth: 2) // Circle border
                                                        )
                                    .foregroundColor(.black)
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            imagePickerPresented = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 21)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        }
                        .sheet(isPresented: $imagePickerPresented) {
                            ImagePicker(sourceType: .photoLibrary) { image in
                                classifyImage(image)
                                selectedImage = image
                            }
                        }
                        
                        Button(action: {
                            cameraPresented = true
                        }) {
                            Image(systemName: "camera")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 18, height: 21)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        }
                        .fullScreenCover(isPresented: $cameraPresented) {
                            CameraView { image in
                                classifyImage(image)
                                selectedImage = image
                                cameraPresented = false
                            }
                        }
                        
                        Spacer()
                        
                        ZStack(alignment: .leading) {
                            if messageText.isEmpty {
                                Text("Ask Gemini...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .frame(height: 32)
                            }
                            
                            TextField("", text: $messageText)
                                .padding(.horizontal, 10)
                                .frame(height: 32)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 1)
                                .foregroundColor(.black)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        
                        Button(action: {
                            sendMessage(text: messageText)
                            messageText = ""
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.green)
                        }
                        .padding(.trailing, 0)
                    }
                }
                .padding([.horizontal], 20)
                .padding(.bottom, 10)
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("iVision", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                imagePickerPresented = true
            }) {
                Image(systemName: "photo.on.rectangle")
                    .imageScale(.large)
            })
        }
    }

    func classifyImage(_ image: UIImage) {
        guard let model = try? VNCoreMLModel(for: MobileNetV2FP16().model) else {
            classificationResult = "Failed to load model."
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNClassificationObservation] {
                let topResult = results.first
                classificationResult = topResult?.identifier ?? "Unknown"
                showGeminiButton = true
            } else {
                classificationResult = "Unable to classify image."
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            classificationResult = "Unable to convert UIImage to CIImage."
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            classificationResult = "Failed to perform classification: \(error.localizedDescription)"
        }
    }

    func sendMessage(text: String, image: UIImage? = nil) {
        guard !text.isEmpty else { return }

        let userMessage = Message(content: text, sender: .user)
        messages.append(userMessage)

        Task {
            let response: String
            if let image = image {
                response = await generateResponseWithImage(prompt: text, image: image)
            } else {
                response = await generateResponse(query: text)
            }
            messages.append(Message(content: response, sender: .gemini))
        }
    }

    func generateResponse(query: String) async -> String {
        do {
            let response = try await model.generateContent(query)
            return formatResponse(response.text ?? "No response text available.")
        } catch {
            return "Failed to get response: \(error.localizedDescription)"
        }
    }

    func generateResponseWithImage(prompt: String, image: UIImage) async -> String {
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                return "Failed to process image"
            }
            let base64String = imageData.base64EncodedString()
            let fullPrompt = "\(prompt)\n\nImage: \(base64String)"
            let response = try await model.generateContent(fullPrompt)
            return formatResponse(response.text ?? "No response text available.")
        } catch {
            return "Failed to get response: \(error.localizedDescription)"
        }
    }

    func formatResponse(_ text: String) -> String {
        var formattedText = text
        formattedText = formattedText.replacingOccurrences(of: "**", with: "")
        formattedText = formattedText.replacingOccurrences(of: "**", with: "")
        return formattedText
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Image Picker Implementation
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completion: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Camera View Implementation
struct CameraView: UIViewControllerRepresentable {
    var completion: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

