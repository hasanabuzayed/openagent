//
//  ControlView.swift
//  OpenAgentDashboard
//
//  Chat interface for the AI agent with real-time streaming
//

import SwiftUI

struct ControlView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var runState: ControlRunState = .idle
    @State private var queueLength = 0
    @State private var currentMission: Mission?
    @State private var isLoading = true
    @State private var streamTask: Task<Void, Never>?
    @State private var showMissionMenu = false
    
    @FocusState private var isInputFocused: Bool
    
    private let api = APIService.shared
    
    var body: some View {
        ZStack {
            // Background with subtle accent glow
            Theme.backgroundPrimary.ignoresSafeArea()
            
            // Subtle radial gradients for liquid glass refraction
            backgroundGlows
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Messages
                messagesView
                
                // Input area
                inputView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCurrentMission()
            startStreaming()
        }
        .onDisappear {
            streamTask?.cancel()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGlows: some View {
        ZStack {
            RadialGradient(
                colors: [Theme.accent.opacity(0.08), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            RadialGradient(
                colors: [Color.white.opacity(0.03), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Mission info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(currentMission?.displayTitle ?? "Control")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    
                    if let status = currentMission?.status {
                        StatusBadge(status: status.statusType, compact: true)
                    }
                }
                
                HStack(spacing: 8) {
                    StatusDot(status: runState.statusType, size: 6)
                    Text(runState.label)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    
                    if queueLength > 0 {
                        Text("• Queue: \(queueLength)")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Mission menu
            Menu {
                Button {
                    Task { await createNewMission() }
                } label: {
                    Label("New Mission", systemImage: "plus")
                }
                
                if let mission = currentMission {
                    Divider()
                    
                    Button {
                        Task { await setMissionStatus(.completed) }
                    } label: {
                        Label("Mark Complete", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        Task { await setMissionStatus(.failed) }
                    } label: {
                        Label("Mark Failed", systemImage: "xmark.circle")
                    }
                    
                    if mission.status != .active {
                        Button {
                            Task { await setMissionStatus(.active) }
                        } label: {
                            Label("Reactivate", systemImage: "arrow.clockwise")
                        }
                    }
                }
            } label: {
                GlassIconButton(icon: "ellipsis", action: {}, size: 36)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Messages
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if messages.isEmpty && !isLoading {
                        emptyStateView
                    } else if isLoading {
                        LoadingView(message: "Loading conversation...")
                            .frame(height: 200)
                    } else {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Start a Conversation")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                
                Text("Send a message to the AI agent to begin")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Input
    
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.border)
            
            HStack(spacing: 12) {
                // Text input
                TextField("Message the agent...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isInputFocused ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: 1)
                    )
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                // Send/Stop button
                if runState != .idle {
                    Button {
                        Task { await cancelRun() }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Theme.error)
                            .clipShape(Circle())
                    }
                } else {
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.accent.opacity(0.5) : Theme.accent)
                            .clipShape(Circle())
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentMission() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let mission = try await api.getCurrentMission() {
                currentMission = mission
                messages = mission.history.enumerated().map { index, entry in
                    ChatMessage(
                        id: "\(mission.id)-\(index)",
                        type: entry.isUser ? .user : .assistant(success: true, costCents: 0, model: nil),
                        content: entry.content
                    )
                }
            }
        } catch {
            print("Failed to load mission: \(error)")
        }
    }
    
    private func createNewMission() async {
        do {
            let mission = try await api.createMission()
            currentMission = mission
            messages = []
            HapticService.success()
        } catch {
            print("Failed to create mission: \(error)")
            HapticService.error()
        }
    }
    
    private func setMissionStatus(_ status: MissionStatus) async {
        guard let mission = currentMission else { return }
        
        do {
            try await api.setMissionStatus(id: mission.id, status: status)
            currentMission?.status = status
            HapticService.success()
        } catch {
            print("Failed to set status: \(error)")
            HapticService.error()
        }
    }
    
    private func sendMessage() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        inputText = ""
        HapticService.lightTap()
        
        Task {
            do {
                let _ = try await api.sendMessage(content: content)
            } catch {
                print("Failed to send message: \(error)")
                HapticService.error()
            }
        }
    }
    
    private func cancelRun() async {
        do {
            try await api.cancelControl()
            HapticService.success()
        } catch {
            print("Failed to cancel: \(error)")
            HapticService.error()
        }
    }
    
    private func startStreaming() {
        streamTask = api.streamControl { eventType, data in
            Task { @MainActor in
                handleStreamEvent(type: eventType, data: data)
            }
        }
    }
    
    private func handleStreamEvent(type: String, data: [String: Any]) {
        switch type {
        case "status":
            if let state = data["state"] as? String {
                runState = ControlRunState(rawValue: state) ?? .idle
            }
            if let queue = data["queue_len"] as? Int {
                queueLength = queue
            }
            
        case "user_message":
            if let content = data["content"] as? String,
               let id = data["id"] as? String {
                let message = ChatMessage(id: id, type: .user, content: content)
                messages.append(message)
            }
            
        case "assistant_message":
            if let content = data["content"] as? String,
               let id = data["id"] as? String {
                let success = data["success"] as? Bool ?? true
                let costCents = data["cost_cents"] as? Int ?? 0
                let model = data["model"] as? String
                
                // Remove any incomplete thinking messages
                messages.removeAll { $0.isThinking && !$0.thinkingDone }
                
                let message = ChatMessage(
                    id: id,
                    type: .assistant(success: success, costCents: costCents, model: model),
                    content: content
                )
                messages.append(message)
            }
            
        case "thinking":
            if let content = data["content"] as? String {
                let done = data["done"] as? Bool ?? false
                
                // Find existing thinking message or create new
                if let index = messages.lastIndex(where: { $0.isThinking && !$0.thinkingDone }) {
                    messages[index].content += "\n\n---\n\n" + content
                    if done {
                        messages[index] = ChatMessage(
                            id: messages[index].id,
                            type: .thinking(done: true, startTime: Date()),
                            content: messages[index].content
                        )
                    }
                } else if !done {
                    let message = ChatMessage(
                        id: "thinking-\(Date().timeIntervalSince1970)",
                        type: .thinking(done: false, startTime: Date()),
                        content: content
                    )
                    messages.append(message)
                }
            }
            
        case "error":
            if let errorMessage = data["message"] as? String {
                let message = ChatMessage(
                    id: "error-\(Date().timeIntervalSince1970)",
                    type: .error,
                    content: errorMessage
                )
                messages.append(message)
            }
            
        default:
            break
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.isUser {
                Spacer(minLength: 60)
                userBubble
            } else if message.isThinking {
                thinkingBubble
                Spacer(minLength: 60)
            } else {
                assistantBubble
                Spacer(minLength: 60)
            }
        }
    }
    
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 6,
                        topTrailingRadius: 20
                    )
                )
        }
    }
    
    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status header for assistant messages
            if case .assistant(let success, _, let model) = message.type {
                HStack(spacing: 6) {
                    Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(success ? Theme.success : Theme.error)
                    
                    if let model = message.displayModel {
                        Text(model)
                            .font(.caption2.monospaced())
                            .foregroundStyle(Theme.textTertiary)
                    }
                    
                    if let cost = message.costFormatted {
                        Text("•")
                            .foregroundStyle(Theme.textMuted)
                        Text(cost)
                            .font(.caption2.monospaced())
                            .foregroundStyle(Theme.success)
                    }
                }
            }
            
            Text(message.content)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 6,
                        bottomTrailingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.border, lineWidth: 0.5)
                )
        }
    }
    
    private var thinkingBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse, options: message.thinkingDone ? .nonRepeating : .repeating)
                
                Text(message.thinkingDone ? "Thought" : "Thinking...")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.1))
            .clipShape(Capsule())
            
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(message.thinkingDone ? 3 : nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}


#Preview {
    NavigationStack {
        ControlView()
    }
}
