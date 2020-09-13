//
//  ContentView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI
import AVKit


struct RecordingView: View {
    @State private var timer = 5
    @State private var onComplete = false
    @State private var recording = false
    
    var body: some View {
        ZStack {
            VideoRecordingView(timeLeft: $timer, onComplete: $onComplete, recording: $recording)
            VStack {
                Button(action: {
                    self.recording.toggle()
                }, label: {
                    Text("Toggle Recording")
                })
                    .foregroundColor(.white)
                    .padding()
                Button(action: {
                    self.timer -= 1
                    print(self.timer)
                }, label: {
                    Text("Toggle timer")
                })
                    .foregroundColor(.white)
                    .padding()
                Button(action: {
                    self.onComplete.toggle()
                }, label: {
                    Text("Toggle completion")
                })
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
    
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}


