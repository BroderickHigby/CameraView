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
    let model: CameraViewModel
    
    func makeUIView(context: UIViewRepresentableContext<VideoRecordingView>) -> VideoPreviewView {
        let recordingView = VideoPreviewView()
        recordingView.bridgeModel = self.model
        
        recordingView.onComplete = {
            self.model.onComplete = true
        }
        
        recordingView.onRecord = { timeLeft, currentRecordingTime in
            self.model.timeLeft = timeLeft
            self.model.recording = true
        }
        
        recordingView.onReset = {
            self.model.recording = false
            self.model.timeLeft = 30
        }
        return recordingView
    }
    
    func updateUIView(_ uiViewController: VideoPreviewView, context: UIViewRepresentableContext<VideoRecordingView>) {
        
    }
}



class VideoPreviewView: UIView {
    var bridgeModel: CameraViewModel?
    private var captureSession: AVCaptureSession?
    private var countdownTimer: Timer?
    let videoFileOutput = AVCaptureMovieFileOutput()
    var recordingDelegate:AVCaptureFileOutputRecordingDelegate!
    
    var recorded = 0
    var recordingTimeLimit = 30
    
    var onRecord: ((Int, Int)->())? // countdown & duration
    var onReset: (() -> ())?
    var onComplete: (() -> ())?
    
    init() {
        super.init(frame: .zero)
        requestCameraPermissions()
        setupLiveCamera()
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
    
    /// Requests camera access if not granted already
    func requestCameraPermissions() {
        var allowedAccess = false
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()
        
        if allowedAccess == false {
            print("No camera Access") // TODO: Create User notification
        }
    }
    
    func setupLiveCamera() {
         // setup session
         let session = AVCaptureSession()
         session.beginConfiguration()
         guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                         for: .video, position: .front) else {
                                                             print("Built in Camera is not active") // TODO: Add Notification to user
                                                             return
         }
         guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice), session.canAddInput(videoDeviceInput) else {
             print("No Camera Detected")
             return
         }
         
         session.addInput(videoDeviceInput)
         session.commitConfiguration()
         self.captureSession = session
     }
    
    //NOTE: The only difference between this and LiveCameraView are startTimers() & startRecording() are called here
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
}
extension VideoPreviewView: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(outputFileURL.absoluteString)
    }
    
    private func onTimerFires() {
        print("Start Recording: \(videoFileOutput.isRecording)")
        recordingTimeLimit -= 1
        recorded += 1
        onRecord?(recordingTimeLimit, recorded)
        
        if(recordingTimeLimit == 0){
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
        let filePath = documentsURL.appendingPathComponent("temporaryVideoFile")
        
        videoFileOutput.startRecording(to: filePath,
                                       recordingDelegate: recordingDelegate)
    }
    
    func stopRecording(){
        videoFileOutput.stopRecording()
        print("Stop Recording: \(videoFileOutput.isRecording)")
    }

    
    
    
    
}




//struct VideoPreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPreviewView()
//    }
//}
