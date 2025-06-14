//
//  CTCDecoder.swift
//  OtosakuStreamingASR
//
//  Created by Marat Zainullin on 14/06/2025.
//


import Foundation
import CoreML



class ModelDecoder {
    var ctcDecoder: CTCDecoder
    private let encoded_size_80ms: NSNumber = 2
    private let encoded_size_480ms: NSNumber = 7
    private let encoded_size_1040ms: NSNumber = 14
    private let blankIdx: Int = 1024
    private var lastIdx: Int = -1
    private var tmpLastIdx: Int = -1
    private var fixedWholeText: String = ""
    private var tokensSequence_80ms: [Int] = []
    private var tokensSequence_480ms: [Int] = []
    private let tokens: [String]
    
    
    public init(from directoryURL: URL, configuration: MLModelConfiguration) throws {
        ctcDecoder = try CTCDecoder(url: directoryURL.appendingPathComponent("ctc_decoder.mlmodelc"), configuration: configuration)
        tokens =  try ModelDecoder.readTokens(url: directoryURL.appendingPathComponent("tokens.txt"))
    }
    
    public func decode_ctc(encoded: MLMultiArray) -> String {
        let bestPath = try! ctcDecoder.predict(encoded: encoded)
        var path: [Int] = []

        for i in 0..<bestPath.shape[1].intValue {
            path.append(bestPath[[0, i as NSNumber]].intValue)
        }
        
        var text: String = ""
        
        if encoded.shape[1] == encoded_size_1040ms {
            tokensSequence_80ms = []
            tokensSequence_480ms = []
        } else if encoded.shape[1] == encoded_size_480ms {
            tokensSequence_480ms += path
            tokensSequence_80ms = []
        } else if encoded.shape[1] == encoded_size_80ms {
            tokensSequence_80ms += path
        }
        
        if encoded.shape[1] == encoded_size_1040ms {
            for i in path {
                if i == lastIdx {
                    continue
                }
                if i == blankIdx {
                    lastIdx = i
                    continue
                }
                var token = tokens[i]
                token = token.replacingOccurrences(of: "▁", with: " ")
                fixedWholeText += token
                lastIdx = i
            }
            tmpLastIdx = lastIdx
        } else {
            for i in tokensSequence_480ms + tokensSequence_80ms {
                if i == tmpLastIdx {
                    continue
                }
                if i == blankIdx {
                    tmpLastIdx = i
                    continue
                }
                var token = tokens[i]
                token = token.replacingOccurrences(of: "▁", with: " ")
                text += token
                tmpLastIdx = i
            }
        }
        
        
        return fixedWholeText + text
    }
    
    public func reset() {
        lastIdx = -1
        tmpLastIdx = -1
        fixedWholeText = ""
        tokensSequence_80ms = []
        tokensSequence_480ms = []
    }
    
    
    private static func readTokens(url: URL) throws -> [String] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return lines
    }
}
