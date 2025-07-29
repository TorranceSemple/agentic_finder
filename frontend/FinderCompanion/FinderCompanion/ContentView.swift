import SwiftUI
import AppKit
import Security

struct ContentView: View {
    @StateObject private var viewModel = FinderCompanionViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.selectedFolderPath == nil {
                folderSelectionView
            } else {
                activeView
            }
        }
        .frame(minWidth: 400, maxWidth: .infinity)
        .frame(height: viewModel.selectedFolderPath == nil ? 90 : 108)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView(apiKey: $viewModel.apiKey)
                .environmentObject(viewModel)
        }
    }
    
    private var folderSelectionView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Finder Assistant")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Specify a directory for your AI agent to access")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Settings") {
                showingSettings = true
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            
            Button("Select Directory") {
                viewModel.selectFolder()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.blue)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
    }
    
    private var activeView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                }
                
                Text(viewModel.selectedFolderPath ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                Button("Change") {
                    viewModel.selectFolder()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                }
                
                TextField("What would you like me to do? (e.g., 'organize by date', 'delete old files')", text: $viewModel.userInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .focused($isInputFocused)
                    .disabled(viewModel.isProcessing)
                    .onSubmit {
                        viewModel.processCommand()
                    }
                
                Spacer()
                
                ZStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    } else if viewModel.canSend {
                        Button(action: viewModel.processCommand) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .onAppear {
            isInputFocused = true
            viewModel.positionBelowFinder()
        }
    }
}

class FinderCompanionViewModel: ObservableObject {
    @Published var selectedFolderPath: String?
    @Published var userInput: String = ""
    @Published var isProcessing: Bool = false
    @Published var apiKey: String = ""
    
    init() {
        // Load API key from Keychain on startup
        apiKey = loadAPIKey()
    }
    
    var canSend: Bool {
        return !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               selectedFolderPath != nil &&
               !isProcessing
    }
    
    // MARK: - Keychain Storage
    
    func saveAPIKey(_ key: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "gemini-api-key",
            kSecAttrService as String: "FinderCompanion",
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
        
        // Update published property
        apiKey = key
    }
    
    private func loadAPIKey() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "gemini-api-key",
            kSecAttrService as String: "FinderCompanion",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return ""
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select Directory"
        panel.prompt = "Choose"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedFolderPath = url.path
                openInFinder(path: url.path)
            }
        }
    }
    
    private func openInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.positionBelowFinder()
        }
    }
    
    func positionBelowFinder() {
        guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else { return }
        
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return }
        
        for windowInfo in windowList {
            guard let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  ownerName == "Finder",
                  let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat else { continue }
            
            guard let screen = NSScreen.main else { return }
            let screenHeight = screen.frame.height
            
            let windowFrame = NSRect(
                x: x,
                y: screenHeight - y - height - 100,
                width: width,
                height: 100
            )
            
            window.setFrame(windowFrame, display: true, animate: true)
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    func processCommand() {
        guard canSend else { return }
        
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isProcessing = false
            self.userInput = ""
        }
    }
}

struct SettingsView: View {
    @Binding var apiKey: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: FinderCompanionViewModel
    @State private var tempApiKey: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "gear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.blue)
                }
                
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Done") {
                    // Save to Keychain when done
                    viewModel.saveAPIKey(tempApiKey)
                    dismiss()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Gemini API Key")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                TextField("Enter your Gemini API key", text: $tempApiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12).monospaced())
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(width: 400, height: 200)
        .background(.regularMaterial)
        .onAppear {
            tempApiKey = apiKey // Load current value
        }
    }
}

#Preview {
    ContentView()
}
