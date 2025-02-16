import Foundation
import AVFoundation
import UIKit

class MovieMaker {
    static let shared = MovieMaker()
    
    private init() {}
    
    // 動画作成のメインメソッド
    func createMovie(from images: [UIImage], completion: @escaping (Result<URL, Error>) -> Void) {
        let settings = createVideoSettings()
        let outputURL = getOutputURL()
        
        do {
            let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            let videoWriterInput = createVideoWriterInput(with: settings)
            
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriterInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                    kCVPixelBufferWidthKey as String: 1920,
                    kCVPixelBufferHeightKey as String: 1080
                ]
            )
            
            videoWriter.add(videoWriterInput)
            
            if videoWriter.startWriting() {
                videoWriter.startSession(atSourceTime: .zero)
                createFrames(images: images, videoWriter: videoWriter, videoWriterInput: videoWriterInput, adaptor: adaptor) { result in
                    switch result {
                    case .success:
                        completion(.success(outputURL))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(MovieError.writerCreationFailed))
        }
    }
    
    private func createVideoSettings() -> [String: Any] {
        let width: Int = 1920
        let height: Int = 1080
        
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
    }
    
    private func getOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputPath = documentsPath.appendingPathComponent("output.mp4")
        
        // 既存のファイルを削除
        try? FileManager.default.removeItem(at: outputPath)
        
        return outputPath
    }
    
    private func createVideoWriterInput(with settings: [String: Any]) -> AVAssetWriterInput {
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        return input
    }
    
    private func createFrames(
        images: [UIImage],
        videoWriter: AVAssetWriter,
        videoWriterInput: AVAssetWriterInput,
        adaptor: AVAssetWriterInputPixelBufferAdaptor,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let frameDuration = CMTimeMake(value: 1, timescale: 2) // 0.5秒/フレーム
        let queue = DispatchQueue(label: "com.photoMovie.videoQueue")
        
        queue.async {
            var frameCount: Int32 = 0 // Int64からInt32に変更
            
            for image in images {
                while !videoWriterInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount)) // Int32に明示的に変換
                
                if let pixelBuffer = self.createPixelBuffer(from: image),
                   adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                    frameCount += 1
                }
            }
            
            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                if videoWriter.status == .completed {
                    completion(.success(()))
                } else {
                    completion(.failure(MovieError.writingFailed))
                }
            }
        }
    }
    
    private func createPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(image.size.width),
                                       Int(image.size.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                    width: Int(image.size.width),
                                    height: Int(image.size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

enum MovieError: Error {
    case writerCreationFailed
    case inputCreationFailed
    case writingFailed
} 