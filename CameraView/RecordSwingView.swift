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
    case timer = "5"
    case swing = "Swing!"
}

class RecordingState: ObservableObject {
    @Published var countdownFinished = false
    @Published var state = RecordingEventState.findingPerson
    @Published var cancelRecording = false
    @Published var personInView: Bool = false
    @Published var captureSessionType: CaptureType = .videoStreamForProcessing
    @Published var recording: Bool = false
    
    enum CaptureType {
        case recordMovie, videoStreamForProcessing
    }
}

struct RecordSwingView: View {
    @ObservedObject var recordingState = RecordingState()
    
    @State private var golferInView = false
    @State private var recording = false
    @State private var showTimerText = false
    @State private var eventView = RecordingEventState.findingPerson
    @State private var recordingText = RecordingTextState.bodyInScreenText
    
    var body: some View {
        VStack {
            Group {
                if self.recordingState.state == .findingPerson {
                    CameraStreamView(model: recordingState)
                } else {
                    VideoRecordingView(model: recordingState)
                }
            }
            Button(action: {
                self.recordingState.recording.toggle()
                print("recording state: \(self.recordingState.recording)")
            }, label:
                {
                    Text("Record")
            })

        }
        .edgesIgnoringSafeArea(.all)
//        .overlay(overlayEvents())
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


struct EventOne: View {
    @ObservedObject var recordingState: RecordingState
    
    var body: some View {
        ZStack {
            GradientOverlay()
            TextDisplayOverCameraView(text: RecordingTextState.bodyInScreenText.rawValue)
        }
        .onAppear(perform: { // Temporary
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.recordingState.state = .countdownTimer
            }
        })
        .onReceive(recordingState.$personInView, perform: { detected in
            if detected {
                self.recordingState.personInView = true
            }
        })
    }
}


struct EventTwo: View {
    @ObservedObject var recordingState: RecordingState
    @State private var showTimerText = false
    
    var body: some View {
        ZStack {
            GradientOverlay()
            if showTimerText {
                CountdownTimerView(currentState: self.recordingState)
            } else {
                TextDisplayOverCameraView(text: RecordingTextState.timerInstructions.rawValue)
            }
        }.onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showTimerText = true
            }
        })
    }
}


struct EventThree: View {
    var body: some View {
        ZStack {
            GradientOverlay()
            TextDisplayOverCameraView(text: RecordingTextState.swing.rawValue)
        }
    }
}

struct CountdownTimerView: View {
    @ObservedObject var currentState: RecordingState
    @State var timeRemaining = 5
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {

            TextDisplayOverCameraView(text: "\(timeRemaining)")
            //            .foregroundColor(.white)
            //            .font(.largeTitle)
            //            .multilineTextAlignment(.center)
        }
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

struct HalfSquareOverlayView: View {
    @State private var animationAmount: CGFloat = 1
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var angle: Double = 0
    
    var body: some View {
        VStack {
            Rectangle()
                .trim(from: 0, to: 0.5)
                .stroke(Color.red, lineWidth: 20)
                .frame(width: 200, height: 200)
                //.transition(AnyTransition.move(edge: .leading))
                .animation(
                    
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: true)
            )
            //.rotationEffect(.degrees(angle))
        }
    }
}

struct GradientOverlay: View {
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(
                colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.7)]),
            startPoint: .bottom,
            endPoint: .top)
    }

    var body: some View {
        ZStack {
            Rectangle().fill(gradient)
//            VStack {
//                Spacer()
//                Rectangle()
//                    .fill(Color.white)
//                    .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
//            }
        }
        .allowsHitTesting(false)
    }
}

struct RecordSwingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordSwingView()
    }
}




