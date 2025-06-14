// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import OtosakuFeatureExtractor
@preconcurrency import CoreML


enum StreaminginASRError: Error {
    case modelDoesNotLoaded
}

private actor ThreadSafeArray<T> {
    
    // MARK: - Private properties
    
    private var _items: [T] = []
    
    // MARK: - Init
    
    init(_ items: [T] = []) {
        self._items = items
    }
    
    // MARK: - Internal methods
    
    func get() -> [T] {
        return _items
    }
    
    func append(_ item: T) {
        _items.append(item)
    }
    
    func remove(at index: Int) -> T? {
        guard _items.indices.contains(index) else { return nil }
        return _items.remove(at: index)
    }
    
    func contains(_ item: T) -> Bool where T: Equatable {
        return _items.contains(item)
    }
    
    func count() -> Int {
        return _items.count
    }
    
    func clear() {
        _items.removeAll()
    }
}



public class OtosakuStreamingASR: @unchecked Sendable {
    
    
    private let TAG: String = "OtosakuStreamingASR"
    private let queue = DispatchQueue(label: "streaming-asr.audio-processing-queue")
    private let cache_size_80ms: Int = 2559
    private let cache_size_480ms: Int = 8959
    private let cache_size_1040ms: Int = 17919
    private var modelDirrenctory: URL?
    private var feautreExtractor: OtosakuFeatureExtractor?
    private var encoder: ConformerEncoder?
    private var decoder: ModelDecoder?
    private var featsForPredit = ThreadSafeArray([MLMultiArray]())
    private var listener: ((String) -> Void)?
    private var buffer: [Double] = []
    private var count480 = 0
    private var count80 = 0
    
    public init () {
        
    }
    
    public func predictChunk(rawChunk: [Double]) throws {
        guard let feautreExtractor = feautreExtractor, encoder != nil, decoder != nil else {
            throw StreaminginASRError.modelDoesNotLoaded
        }
        buffer.append(contentsOf: rawChunk)
        var chunk: [Double]
        if buffer.count >= cache_size_1040ms {
            chunk = Array(buffer.prefix(cache_size_1040ms))
            buffer.removeFirst(cache_size_1040ms)
            count80 = 0
            count480 = 0
        } else if buffer.count >= (count480 + 1) * cache_size_480ms {
            let start = count480 * cache_size_480ms
            let end = start + cache_size_480ms
            chunk = Array(buffer[start..<end])
            count480 += 1
            count80 = 0
        } else {
            let start = count480 * cache_size_480ms + count80 * cache_size_80ms
            let end = start + cache_size_80ms
            chunk = Array(buffer[start..<end])
            count80 += 1
        }
        
        
        let feats = try feautreExtractor.processChunk(chunk: chunk)
        Task { [weak self] in await self?.addToQueue(feature: feats) }
    }
    
    public func stop() throws {
        
        guard let feautreExtractor = feautreExtractor, encoder != nil, decoder != nil else {
            throw StreaminginASRError.modelDoesNotLoaded
        }
        
        if buffer.count <= cache_size_480ms {
            buffer += [Double].zeros(length: cache_size_480ms - buffer.count)
        } else {
            buffer += [Double].zeros(length: cache_size_1040ms - buffer.count)
        }
        let feats = try feautreExtractor.processChunk(chunk: buffer)
        Task { [weak self] in await self?.addToQueue(feature: feats) }
    }
    
    public func prepareModel(from directoryURL: URL, units: MLComputeUnits = .all) throws {
        let config = MLModelConfiguration()
        config.computeUnits = units
        feautreExtractor = try OtosakuFeatureExtractor(directoryURL: directoryURL)
        encoder = try ConformerEncoder(from: directoryURL, configuration: config)
        decoder = try ModelDecoder(from: directoryURL, configuration: config)
    }
    
    
    public func reset() {
        encoder?.reset()
        decoder?.reset()
        buffer = []
        count480 = 0
        count80 = 0
    }
    

    
    public func subscribe(listener: @escaping (String) -> Void) {
        self.listener = listener
    }
    
    private func addToQueue(feature chunk: MLMultiArray) async {
        await featsForPredit.append(chunk)
        await processQueue()
    }
    
    private func processQueue() async {
        guard let chunk = await featsForPredit.remove(at: 0) else { return }
        let text = await processFeature(feature: chunk)
        listener?(text)
    }

    
    private func processFeature(feature: MLMultiArray) async -> String {
        await withCheckedContinuation { [weak self] continuation in
            self?.queue.async { [weak self] in
                guard let self else { return }
                continuation.resume(returning: self.extractFeature(feature: feature))
            }
        }
    }
    
    private func extractFeature(feature: MLMultiArray) -> String {
        guard let encoder = encoder, let decoder = decoder else {
            print(TAG, "No model")
            return ""
        }
        do {
            let encoded = try encoder.predict(x: feature)
            return decoder.decode_ctc(encoded: encoded)
        } catch {
            print(TAG, "E", error)
            return ""
        }
    }
    
}
