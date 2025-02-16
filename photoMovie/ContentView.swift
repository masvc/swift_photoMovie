//
//  ContentView.swift
//  photoMovie
//
//  Created by masato yoshida on 2025/02/16.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var displayedImages: [Image] = []
    @State private var savedMetadata: [PhotoManager.PhotoMetadata] = []
    @State private var showingPhotosPicker = false
    @State private var isCreatingMovie = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var createdMovieURL: URL?
    @State private var showingMoviePreview = false
    
    // アプリ起動時に保存された写真を読み込む
    private func loadSavedPhotos() {
        let photosWithMetadata = PhotoManager.shared.loadAllPhotos()
        savedMetadata = photosWithMetadata.map { $0.0 }
        displayedImages = photosWithMetadata.map { Image(uiImage: $0.1) }
    }
    
    private func loadTransferable(from photoItems: [PhotosPickerItem]) {
        Task {
            var images: [Image] = []
            for item in photoItems {
                if let imageData = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: imageData) {
                    // 写真をローカルに保存
                    do {
                        let metadata = try PhotoManager.shared.savePhoto(imageData: imageData)
                        savedMetadata.append(metadata)
                    } catch {
                        print("Failed to save photo: \(error)")
                    }
                    images.append(Image(uiImage: uiImage))
                }
            }
            
            await MainActor.run {
                self.displayedImages = images
            }
        }
    }
    
    // ムービー作成処理を更新
    private func createMovie() {
        isCreatingMovie = true
        
        let images = savedMetadata.compactMap { metadata -> UIImage? in
            PhotoManager.shared.loadPhoto(fileName: metadata.fileName)
        }
        
        guard !images.isEmpty else {
            alertMessage = "写真が選択されていません"
            showingAlert = true
            isCreatingMovie = false
            return
        }
        
        MovieMaker.shared.createMovie(from: images) { result in
            DispatchQueue.main.async {
                isCreatingMovie = false
                
                switch result {
                case .success(let url):
                    createdMovieURL = url
                    showingMoviePreview = true
                    
                case .failure(let error):
                    alertMessage = "ムービーの作成に失敗しました: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // カメラロールに保存
    private func saveToPhotoLibrary(_ url: URL) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) {
            UISaveVideoAtPathToSavedPhotosAlbum(
                url.path,
                nil,
                nil,
                nil
            )
        }
    }
    
    // 写真グリッドビュー
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(0..<displayedImages.count, id: \.self) { index in
                    displayedImages[index]
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
    }
    
    // 写真選択ボタン
    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images) {
            Label("写真を選択", systemImage: "photo.stack")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    // ムービー作成ボタン
    private var createMovieButton: some View {
        Button(action: {
            createMovie()
        }) {
            Label("ムービーを作成", systemImage: "film")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
        }
        .disabled(isCreatingMovie)
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if displayedImages.isEmpty {
                    ContentUnavailableView {
                        Label("写真が選択されていません", systemImage: "photo.on.rectangle")
                    } description: {
                        Text("写真を選択して、ムービーを作成しましょう")
                    }
                } else {
                    photoGridView
                }
                
                photoPickerButton
                    .onChange(of: selectedPhotos) { oldValue, newValue in
                        loadTransferable(from: newValue)
                    }
                
                if !displayedImages.isEmpty {
                    createMovieButton
                }
            }
            .navigationTitle("フォトムービー")
            .alert("お知らせ", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isCreatingMovie {
                    ProgressView("ムービーを作成中...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .sheet(isPresented: $showingMoviePreview, onDismiss: {
            if let url = createdMovieURL {
                saveToPhotoLibrary(url)
                alertMessage = "ムービーの作成が完了しました"
                showingAlert = true
            }
        }) {
            if let url = createdMovieURL {
                MoviePreviewView(videoURL: url)
            }
        }
        .onAppear {
            loadSavedPhotos()
        }
    }
}

#Preview {
    ContentView()
}
