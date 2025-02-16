import SwiftUI
import AVKit

struct MoviePreviewView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .navigationTitle("プレビュー")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完了") {
                            dismiss()
                        }
                    }
                }
        }
    }
} 