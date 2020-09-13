//
//  RecordSwingEventHandler.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI

//struct RecordSwingEventHandler: View {
//    @State private var swingText = "This is the recording Swing text"
//    @State private var showTimer = false
//    var body: some View {
////        EventTwo(showTimerText: $showTimer)
//    }
//}
//
//struct RecordSwingEventHandler_Previews: PreviewProvider {
//    static var previews: some View {
//        RecordSwingEventHandler()
//    }
//}


struct EventOne: View {
    @ObservedObject var recordingState: RecordingState
    
    var body: some View {
        ZStack {
                TextDisplayOverCameraView(text: RecordingTextState.bodyInScreenText.rawValue)
        }.onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.recordingState.state = .countdownTimer
            }
        })
    }
}


struct EventTwo: View {
    @ObservedObject var recordingState: RecordingState
    @State private var showTimerText = false

    var body: some View {
        ZStack {
            
            if showTimerText {
                CountdownTimerView(currentState: self.recordingState)
            } else {
                TextDisplayOverCameraView(text: RecordingTextState.timerInstructions.rawValue)
            }
//            LinearGradient(gradient: Gradient(colors: [.gray]), startPoint: .top, endPoint: .bottom)
        }.onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showTimerText = true
            }
        })
    }
}

struct CountdownTimerView: View {
    @ObservedObject var currentState: RecordingState
    @State var timeRemaining = 5
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TextDisplayOverCameraView(text: "\(timeRemaining)")
//            .foregroundColor(.white)
//            .font(.largeTitle)
//            .multilineTextAlignment(.center)
            .onReceive(timer) { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.currentState.countdownFinished = true
                    print(self.currentState.countdownFinished)
                    self.currentState.state = .recording // Transition states
                }
            }
    }
}


struct TextDisplayOverCameraView: View {
    var text: String?
    
    var body: some View {
        Text(text ?? "")
        .foregroundColor(.white)
        .font(.system(size: 46.0))
        .multilineTextAlignment(.center)
        .padding()
    }
}

struct EventThree: View {
    var body: some View {
        VStack {
            TextDisplayOverCameraView(text: RecordingTextState.swing.rawValue)
        }
    }
}



