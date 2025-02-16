import Foundation
import UIKit

class PhotoManager {
    static let shared = PhotoManager()
    private let fileManager = FileManager.default
    
    // 写真のメタデータ構造体
    struct PhotoMetadata: Codable {
        let id: String
        let fileName: String
        let createdAt: Date
        var isUsedInMovie: Bool
    }
    
    private init() {}
    
    // 写真保存用のディレクトリパスを取得
    private func getPhotosDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let photosDirectory = documentsDirectory.appendingPathComponent("SavedPhotos")
        
        // ディレクトリが存在しない場合は作成
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
        
        return photosDirectory
    }
    
    // 写真を保存し、メタデータを返す
    func savePhoto(imageData: Data) throws -> PhotoMetadata {
        let id = UUID().uuidString
        let fileName = "\(id).jpg"
        let fileURL = getPhotosDirectory().appendingPathComponent(fileName)
        
        // 写真データを保存
        try imageData.write(to: fileURL)
        
        // メタデータを作成
        let metadata = PhotoMetadata(
            id: id,
            fileName: fileName,
            createdAt: Date(),
            isUsedInMovie: false
        )
        
        // メタデータをUserDefaultsに保存
        saveMetadata(metadata)
        
        return metadata
    }
    
    // メタデータをUserDefaultsに保存
    private func saveMetadata(_ metadata: PhotoMetadata) {
        var savedMetadata = getAllMetadata()
        savedMetadata.append(metadata)
        
        if let encoded = try? JSONEncoder().encode(savedMetadata) {
            UserDefaults.standard.set(encoded, forKey: "photoMetadata")
        }
    }
    
    // 保存されている全てのメタデータを取得
    func getAllMetadata() -> [PhotoMetadata] {
        guard let data = UserDefaults.standard.data(forKey: "photoMetadata"),
              let metadata = try? JSONDecoder().decode([PhotoMetadata].self, from: data) else {
            return []
        }
        return metadata
    }
    
    // 保存された写真を読み込む
    func loadPhoto(fileName: String) -> UIImage? {
        let fileURL = getPhotosDirectory().appendingPathComponent(fileName)
        guard let imageData = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: imageData)
    }
    
    // 全ての保存された写真を読み込む
    func loadAllPhotos() -> [(PhotoMetadata, UIImage)] {
        let metadata = getAllMetadata()
        return metadata.compactMap { meta in
            guard let image = loadPhoto(fileName: meta.fileName) else { return nil }
            return (meta, image)
        }
    }
} 