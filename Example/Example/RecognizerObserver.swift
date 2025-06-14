//
//  RecognizerObserver.swift
//  Example
//
//  Created by Marat Zainullin on 11/02/2025.
//
import SwiftUI
import AVFoundation
import ZIPFoundation
import OtosakuStreamingASR


class RecognizerObserver: ObservableObject {
    
    private let asr = OtosakuStreamingASR()
    private let TAG: String = "RecognizerObserver"
    private let modelDownloadSrc = "https://..."
    
    private var audioEngine: AVAudioEngine!
    private var audioInputNode: AVAudioInputNode!
    @Published var recordWasStarted: Bool = false
    @Published var recognizedText: String = ""
    @Published var modelIsReady: Bool = false
    
    
    
    init () {
        
        let mainDocumentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var folderURL = mainDocumentURL.appendingPathComponent("quntized-model-ru")
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            do {
                try asr.prepareModel(from: folderURL, units: .cpuOnly)
                modelIsReady = true
            } catch {
                print(TAG, error)
            }
        } else {
            downloadModel(from: modelDownloadSrc) {[weak self] result in
                switch result {
                case .success(let value):
                    do {
                        try self?.asr.prepareModel(from: folderURL, units: .cpuOnly)
                        DispatchQueue.main.async {
                            self?.modelIsReady = true
                        }
                    } catch {
                        print(self?.TAG ?? "OOPS", error)
                    }
                case .failure(let error):
                    print(self?.TAG ?? "OOPS", "error", error)
                }
            }
        }
        
        asr.subscribe { [weak self] text in
            DispatchQueue.main.async { [weak self] in
                self?.recognizedText = text
            }
        }
        
        
        
        audioEngine = AVAudioEngine()
        audioInputNode = audioEngine.inputNode
        
        let bus = 0
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: bus)
        let framesNeeded: Double = 2559
        
        print(inputFormat.sampleRate, UInt32((inputFormat.sampleRate * framesNeeded) / 16000))
        
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: true)!
        
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat)!
        
        audioInputNode.installTap(onBus: 0, bufferSize: UInt32((inputFormat.sampleRate * framesNeeded) / 16000), format: inputFormat) { (buffer, time) in
            
            var newBufferAvailable = true
            
            let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            
            let capacity = AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)
            
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity)!
            
            var error: NSError?
            let _ = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            
            self.handleAudioBuffer(convertedBuffer)
        }
        
        requestMicrophonePermissions()
    }
    
    func startRecording() {
        
        recordWasStarted = true
        recognizedText = ""
        do {
            try audioEngine.start()
            print("Запись началась.")
        } catch {
            print("Ошибка запуска AVAudioEngine: \(error)")
        }
    }
    
    func stop() {
        recordWasStarted = false
        audioEngine.stop()
        print("Запись остановлена.")
        try? asr.stop()
        asr.reset()
    }
    
    func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let intData = buffer.floatChannelData!
        
        var data: [Double] = []
        for channelIdx in 0..<1 {
            data += Array(UnsafeBufferPointer(start: intData[channelIdx], count: Int(buffer.frameLength))).map{ Double($0)}
        }
        
        
        if  data.count != 2559 {
            print(TAG, "handleAudioBuffer: unexpected buffer length", data.count)
            return
        }
        do {
            try self.asr.predictChunk(rawChunk: data)
        } catch {
            print(TAG, "handleAudioBuffer: error: \(error)")
        }
    }
    
    private func requestMicrophonePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { isAllowed in
                
            }
        @unknown default: break
            
        }
    }
    
    private func downloadModel(from url: String, completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 1, userInfo: nil)))
            return
        }
        
        _downloadModel(from: url) {[weak self] result in
            switch result {
            case .success(let zipPath):
                let destUrl = zipPath.deletingLastPathComponent()
                self?.unzipFile(
                    at: zipPath,
                    to: destUrl
                ) { archiveResult in
                    switch archiveResult {
                    case .success(let url):
                        completion(.success(url))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    private func _downloadModel(from url: URL, completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let localURL = localURL else {
                completion(.failure(error ?? NSError(domain: "No data available from URL", code: 1, userInfo: nil)))
                return
            }
            
            let mainDocumentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = mainDocumentURL.appendingPathComponent(url.lastPathComponent)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        task.resume()
    }
    
    private func unzipFile(at sourceURL: URL, to destinationURL: URL, completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
        
        DispatchQueue.global(qos: .utility).async {
            let fileManager = FileManager()
            do {
                try fileManager.unzipItem(at: sourceURL, to: destinationURL)
                try fileManager.removeItem(at: sourceURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
