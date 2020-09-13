//
//  VideoRecordingView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI
import AVKit




struct VideoRecordingView: UIViewRepresentable {
    
    @Binding var timeLeft: Int
    @Binding var onComplete: Bool
    @Binding var recording: Bool
    func makeUIView(context: UIViewRepresentableContext<VideoRecordingView>) -> VideoPreviewView {
        let recordingView = VideoPreviewView()
        recordingView.onComplete = {
            self.onComplete = true
        }
        
        recordingView.onRecord = { timeLeft, totalSeconds in
            self.timeLeft = timeLeft
            self.recording = true
        }
        
        recordingView.onReset = {
            self.recording = false
            self.timeLeft = 5
        }
        return recordingView
    }
    
    func updateUIView(_ uiViewController: VideoPreviewView, context: UIViewRepresentableContext<VideoRecordingView>) {
        
    }
}

extension VideoPreviewView: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(outputFileURL.absoluteString)
    }
}

class VideoPreviewView: UIView {
    private var captureSession: AVCaptureSession?
    private var countdownTimer: Timer?
    let videoFileOutput = AVCaptureMovieFileOutput()
    var recordingDelegate:AVCaptureFileOutputRecordingDelegate!
    
    var recorded = 0
    var secondsToReachGoal = 5
    
    var onRecord: ((Int, Int)->())?
    var onReset: (() -> ())?
    var onComplete: (() -> ())?
    
    init() {
        super.init(frame: .zero)
        
        var allowedAccess = false
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()
        
        if !allowedAccess {
            print("!!! NO ACCESS TO CAMERA")
            return
        }
        
        // setup session
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .front)
        guard videoDevice != nil, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(videoDeviceInput) else {
            print("!!! NO CAMERA DETECTED")
            return
        }
        session.addInput(videoDeviceInput)
        session.commitConfiguration()
        self.captureSession = session
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        recordingDelegate = self
        startTimers()
        
        if let _ = self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspect
            self.captureSession?.startRunning()
            self.startRecording()
        } else {
            self.captureSession?.stopRunning()
        }
    }
    
    private func onTimerFires(){
        print("🟢 RECORDING \(videoFileOutput.isRecording)")
        secondsToReachGoal -= 1
        recorded += 1
        onRecord?(secondsToReachGoal, recorded)
        
        if(secondsToReachGoal == 0){
            stopRecording()
            countdownTimer?.invalidate()
            countdownTimer = nil
            onComplete?()
            videoFileOutput.stopRecording()
        }
    }
    
    func startTimers(){
        if countdownTimer == nil {
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] (timer) in
                self?.onTimerFires()
            }
        }
    }
    
    func startRecording(){
        captureSession?.addOutput(videoFileOutput)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsURL.appendingPathComponent("tempPZDC")
        
        videoFileOutput.startRecording(to: filePath, recordingDelegate: recordingDelegate)
    }
    
    func stopRecording(){
        videoFileOutput.stopRecording()
        print("🔴 RECORDING \(videoFileOutput.isRecording)")
    }
}


//struct VideoPreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPreviewView()
//    }
//}
