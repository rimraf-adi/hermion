import SwiftUI
import AppKit

public struct HistoryView: View {
    @ObservedObject var appState = AppState.shared
    @State private var searchText = ""
    
    public init() {}
    
    private var filteredItems: [TranscriptionItem] {
        if searchText.isEmpty {
            return appState.historyItems
        }
        return appState.historyItems.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header & Search
            HStack {
                Text("Transcription History")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    HistoryStorage.shared.clearHistory()
                    appState.historyItems = []
                }) {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            TextField("Search transcripts...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // List
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No transcriptions recorded yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            HistoryCard(item: item)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 420, height: 500)
        .background(Color(red: 0.1, green: 0.1, blue: 0.13))
    }
}

struct HistoryCard: View {
    let item: TranscriptionItem
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if item.durationSeconds > 0 {
                    Text("•  \(String(format: "%.1fs", item.durationSeconds))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.text, forType: .string)
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isCopied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(.caption2)
                    .foregroundColor(isCopied ? .green : .purple)
                }
                .buttonStyle(.plain)
            }
            
            Text(item.text)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineLimit(4)
                .textSelection(.enabled)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
