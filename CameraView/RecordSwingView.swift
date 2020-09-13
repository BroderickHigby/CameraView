//
//  RecordSwingView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI

enum RecordingEventState {
    case findingPerson
    case countdownTimer
    case recording
    case stopRecording
    case cancel
}
enum RecordingTextState: String {
    case bodyInScreenText = "Stand so that you can see your whole body in screen"
    case timerInstructions = "Get ready to swing after the timer"
    case timer = "2"
    case swing = "Swing!"
}


class RecordingState: ObservableObject {
    @Published var countdownFinished = false
    @Published var state = RecordingEventState.findingPerson
    @Published var cancelRecording = false
}


struct RecordSwingView: View {
    @ObservedObject var recordingState = RecordingState()
    
    @State private var countdownTimer = 5
    @State private var golferInView = false
    @State private var recording = false
    @State private var showTimerText = false
    @State private var eventView = RecordingEventState.findingPerson
    @State private var recordingText = RecordingTextState.bodyInScreenText
    
    var body: some View {
        ZStack {
            VideoRecordingView(timeLeft: $countdownTimer, onComplete: $golferInView, recording: $recording)
                
                .padding()
            //            Button(action: {
            //                self.showTimerText.toggle()
            //            }) {
            //                Text("Toggle Timer")
            //            }
            //            Spacer()
            //            Circle()
            //                .stroke(Color.pink, lineWidth: 300)
            //                .frame(width: 300, height: 300)
        }.overlay(
            VStack {
                overlayEvents()
//                HStack {
//                    Button(action: {
//                        if self.eventView == RecordingEventState.countdownTimer {
//                            self.eventView = RecordingEventState.recording
//                        } else if self.eventView == RecordingEventState.findingPerson {
//                            self.eventView = RecordingEventState.countdownTimer
//                        }
//                    }) {
//                        Text("Events")
//                    }
//                    .padding()
//                    Spacer()
//                    Button(action: {
//                        self.showTimerText.toggle()
//                    }) {
//                        Text("Timer")
//                    }
//                }
            }
            
        )
            .onReceive(recordingState.$state, perform: { state in
                if state == .countdownTimer {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.eventView = .countdownTimer
                    }
                }
                else if state == .recording {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.eventView = .recording
                    }
                }
            })
    }
    
    func overlayEvents() -> AnyView {
        switch eventView {
        case .findingPerson:
            return AnyView(EventOne(recordingState: recordingState))
        case .countdownTimer:
            return AnyView(EventTwo(recordingState: recordingState))
        case .recording:
            return AnyView(EventThree())
        default:
            return AnyView(EmptyView())
        }
    }
}

struct RecordSwingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordSwingView()
    }
}
