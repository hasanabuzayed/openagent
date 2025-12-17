//
//  TerminalView.swift
//  OpenAgentDashboard
//
//  SSH terminal with WebSocket connection
//

import SwiftUI

struct TerminalView: View {
    @State private var terminalOutput: [TerminalLine] = []
    @State private var inputText = ""
    @State private var connectionStatus: StatusType = .disconnected
    @State private var webSocketTask: URLSessionWebSocketTask?
    @State private var isConnecting = false
    
    @FocusState private var isInputFocused: Bool
    
    private let api = APIService.shared
    
    struct TerminalLine: Identifiable {
        let id = UUID()
        let text: String
        let type: LineType
        let attributedText: AttributedString?
        
        enum LineType {
            case input
            case output
            case error
            case system
        }
        
        init(text: String, type: LineType) {
            self.text = text
            self.type = type
            self.attributedText = type == .output ? Self.parseANSI(text) : nil
        }
        
        var color: Color {
            switch type {
            case .input: return Theme.accent
            case .output: return Theme.textPrimary
            case .error: return Theme.error
            case .system: return Theme.textTertiary
            }
        }
        
        /// Parse ANSI escape codes and return AttributedString with colors
        private static func parseANSI(_ text: String) -> AttributedString? {
            var result = AttributedString()
            var currentColor: Color = .white
            var isBold = false
            
            // Pattern to match ANSI escape sequences
            let pattern = "\u{001B}\\[([0-9;]*)m"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return nil
            }
            
            let nsText = text as NSString
            var lastEnd = 0
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            
            for match in matches {
                // Add text before this escape sequence
                if match.range.location > lastEnd {
                    let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                    let substring = nsText.substring(with: textRange)
                    var attr = AttributedString(substring)
                    attr.foregroundColor = currentColor
                    if isBold {
                        attr.font = .system(size: 13, weight: .bold, design: .monospaced)
                    } else {
                        attr.font = .system(size: 13, weight: .regular, design: .monospaced)
                    }
                    result.append(attr)
                }
                
                // Parse the escape code
                if match.numberOfRanges > 1 {
                    let codeRange = match.range(at: 1)
                    let codes = nsText.substring(with: codeRange).split(separator: ";").compactMap { Int($0) }
                    
                    for code in codes {
                        switch code {
                        case 0: // Reset
                            currentColor = .white
                            isBold = false
                        case 1: // Bold
                            isBold = true
                        case 30: currentColor = Color(white: 0.3) // Black
                        case 31: currentColor = Color(red: 1, green: 0.33, blue: 0.33) // Red
                        case 32: currentColor = Color(red: 0.33, green: 0.85, blue: 0.33) // Green
                        case 33: currentColor = Color(red: 1, green: 0.85, blue: 0.33) // Yellow
                        case 34: currentColor = Color(red: 0.4, green: 0.6, blue: 1) // Blue
                        case 35: currentColor = Color(red: 0.85, green: 0.45, blue: 0.85) // Magenta
                        case 36: currentColor = Color(red: 0.4, green: 0.9, blue: 0.9) // Cyan
                        case 37: currentColor = .white // White
                        case 90: currentColor = Color(white: 0.5) // Bright black (gray)
                        case 91: currentColor = Color(red: 1, green: 0.5, blue: 0.5) // Bright red
                        case 92: currentColor = Color(red: 0.5, green: 1, blue: 0.5) // Bright green
                        case 93: currentColor = Color(red: 1, green: 1, blue: 0.5) // Bright yellow
                        case 94: currentColor = Color(red: 0.6, green: 0.8, blue: 1) // Bright blue
                        case 95: currentColor = Color(red: 1, green: 0.6, blue: 1) // Bright magenta
                        case 96: currentColor = Color(red: 0.6, green: 1, blue: 1) // Bright cyan
                        case 97: currentColor = .white // Bright white
                        default: break
                        }
                    }
                }
                
                lastEnd = match.range.location + match.range.length
            }
            
            // Add remaining text after last escape sequence
            if lastEnd < nsText.length {
                let textRange = NSRange(location: lastEnd, length: nsText.length - lastEnd)
                let substring = nsText.substring(with: textRange)
                var attr = AttributedString(substring)
                attr.foregroundColor = currentColor
                if isBold {
                    attr.font = .system(size: 13, weight: .bold, design: .monospaced)
                } else {
                    attr.font = .system(size: 13, weight: .regular, design: .monospaced)
                }
                result.append(attr)
            }
            
            return result.characters.isEmpty ? nil : result
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Terminal background
            Color(red: 0.04, green: 0.04, blue: 0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Terminal output (full height)
                terminalOutputView
                
                // Input field
                inputView
            }
            
            // Floating connection header (overlay)
            connectionHeader
        }
        .navigationTitle("Terminal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Status indicator
                    HStack(spacing: 6) {
                        StatusDot(status: connectionStatus, size: 6)
                        Text(connectionStatus == .connected ? "Live" : connectionStatus.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(connectionStatus == .connected ? Theme.success : Theme.textSecondary)
                    }
                    
                    // Connect/Disconnect button
                    Button {
                        if connectionStatus == .connected {
                            disconnect()
                        } else {
                            connect()
                        }
                    } label: {
                        Text(connectionStatus == .connected ? "End" : "Connect")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(connectionStatus == .connected ? Theme.error : Theme.accent)
                    }
                }
            }
        }
        .onAppear {
            connect()
        }
        .onDisappear {
            disconnect()
        }
    }
    
    private var connectionHeader: some View {
        // Only show reconnect overlay when disconnected
        Group {
            if connectionStatus != .connected && !isConnecting {
                VStack(spacing: 16) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.textMuted)
                        
                        Text("Disconnected")
                            .font(.headline)
                            .foregroundStyle(Theme.textSecondary)
                        
                        Button {
                            connect()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Reconnect")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            } else if isConnecting {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Theme.accent)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private var terminalOutputView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(terminalOutput) { line in
                        Group {
                            if let attributed = line.attributedText {
                                Text(attributed)
                            } else {
                                Text(line.text)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundStyle(line.color)
                            }
                        }
                        .textSelection(.enabled)
                        .id(line.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 80) // Space for input
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: terminalOutput.count) { _, _ in
                if let lastLine = terminalOutput.last {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputView: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.success)
            
            TextField("", text: $inputText, prompt: Text("command").foregroundStyle(Color.white.opacity(0.3)))
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendCommand()
                }
            
            if !inputText.isEmpty {
                Button {
                    sendCommand()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                }
                .disabled(connectionStatus != .connected)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.white.opacity(0.1)),
            alignment: .top
        )
    }
    
    // MARK: - WebSocket Connection
    
    private func connect() {
        guard connectionStatus != .connected && !isConnecting else { return }
        
        isConnecting = true
        connectionStatus = .connecting
        addSystemLine("Connecting to \(api.baseURL)...")
        
        guard let wsURL = buildWebSocketURL() else {
            addErrorLine("Invalid WebSocket URL")
            connectionStatus = .error
            isConnecting = false
            return
        }
        
        var request = URLRequest(url: wsURL)
        
        // Add auth via subprotocol if available
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("openagent, jwt.\(token)", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessages()
        
        // Send initial resize message after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if connectionStatus == .connecting {
                connectionStatus = .connected
                addSystemLine("Connected.")
            }
            isConnecting = false
            sendResize(cols: 80, rows: 24)
        }
    }
    
    private func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionStatus = .disconnected
        addSystemLine("Disconnected.")
    }
    
    private func buildWebSocketURL() -> URL? {
        guard var components = URLComponents(string: api.baseURL) else { return nil }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/api/console/ws"
        return components.url
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.handleOutput(text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.handleOutput(text)
                        }
                    }
                @unknown default:
                    break
                }
                // Continue receiving
                receiveMessages()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    if connectionStatus != .disconnected {
                        connectionStatus = .error
                        addErrorLine("Connection error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func handleOutput(_ text: String) {
        // Split by newlines and add each line
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if !line.isEmpty {
                terminalOutput.append(TerminalLine(text: line, type: .output))
            }
        }
        
        // Limit history
        if terminalOutput.count > 1000 {
            terminalOutput.removeFirst(terminalOutput.count - 1000)
        }
    }
    
    private func sendCommand() {
        guard !inputText.isEmpty, connectionStatus == .connected else { return }
        
        let command = inputText
        inputText = ""
        
        // Show the command in output
        terminalOutput.append(TerminalLine(text: "$ \(command)", type: .input))
        
        // Send to WebSocket
        let message = ["t": "i", "d": command + "\n"]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        addErrorLine("Send error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        HapticService.lightTap()
    }
    
    private func sendResize(cols: Int, rows: Int) {
        let message = ["t": "r", "c": cols, "r": rows] as [String: Any]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(jsonString)) { _ in }
        }
    }
    
    private func addSystemLine(_ text: String) {
        terminalOutput.append(TerminalLine(text: text, type: .system))
    }
    
    private func addErrorLine(_ text: String) {
        terminalOutput.append(TerminalLine(text: text, type: .error))
    }
}

#Preview {
    NavigationStack {
        TerminalView()
    }
}
