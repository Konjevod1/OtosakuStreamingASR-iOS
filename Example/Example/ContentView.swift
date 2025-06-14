//
//  ContentView.swift
//  Example
//
//  Created by Marat Zainullin on 11/02/2025.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var recognizer = RecognizerObserver()
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {

                Text(recognizer.recognizedText)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    if recognizer.recordWasStarted {
                        recognizer.stop()
                    } else {
                        recognizer.startRecording()
                    }
                }) {
                    Text(recognizer.recordWasStarted ? "Stop" : "Start")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recognizer.recordWasStarted ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .disabled(!recognizer.modelIsReady)
            }
            .padding()
            .opacity(recognizer.modelIsReady ? 1 : 0.3)

            if !recognizer.modelIsReady {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(1.5)
                    Text("Loading speech recognition model...")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .shadow(radius: 10)
            }
        }
//        .animation(.easeInOut, value: recognizer.modelIsReady)
    }
}
