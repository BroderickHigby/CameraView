//
//  VideoRecordingView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI
import AVKit

typealias ImageBufferHandler = ((_ imageBuffer: CMSampleBuffer) -> ())


struct VideoRecordingView: UIViewRepresentable {
    let model: RecordingState
    
    func makeUIView(context: UIViewRepresentableContext<VideoRecordingView>) -> VideoPreviewView {
        let recordingView = VideoPreviewView(frame: .zero, bridgeModel: model)
        recordingView.bridgeModel = self.model
        return recordingView
    }
    
    func updateUIView(_ uiViewController: VideoPreviewView, context: UIViewRepresentableContext<VideoRecordingView>) {
        
    }
}


/// For Recording Videos
class VideoPreviewView: UIView {
    var bridgeModel: RecordingState?
    private var captureSession: AVCaptureSession?
    /// For Recording
    let videoFileOutput = AVCaptureMovieFileOutput()
    var recordingDelegate:AVCaptureFileOutputRecordingDelegate!

    init(frame: CGRect, bridgeModel: RecordingState) {
        super.init(frame: frame)
        self.bridgeModel = bridgeModel
        requestCameraPermissions()
        setupLiveCamera()
        
        if bridgeModel.captureSessionType == .videoStreamForProcessing {
            setupVideoDataOutput()
        }
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
                
        if let _ = self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
            self.captureSession?.startRunning()
            // Record if set
            if bridgeModel!.captureSessionType == .recordMovie {
                self.startRecording()
            }
            
        } else {
            self.captureSession?.stopRunning()
        }
    }
}
/// This delegate is for recording videos
extension VideoPreviewView: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(outputFileURL.absoluteString)
        
        if bridgeModel!.recording {
            self.startRecording()
        } else {
            stopRecording()
            // TODO: Check video saving completion, make sure resources are dumped
        }
        
    }
    
    func startRecording(){
        print("Recording: \(videoFileOutput.isRecording)")
        captureSession?.addOutput(videoFileOutput)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsURL.appendingPathComponent("temporaryVideoFile")
        videoFileOutput.startRecording(to: filePath,
                                       recordingDelegate: recordingDelegate)
    }
    
    func stopRecording(){
        videoFileOutput.stopRecording()
        print("Recording: \(videoFileOutput.isRecording)")
    }
}


/// This extension is used for streaming frames for machine learning
extension VideoPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setupVideoDataOutput() {
        // setup video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        // If running slowly, set the dispatch to run on the main UI thread
        let queue = DispatchQueue(label: "com.queue.videosamplequeue")
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        guard captureSession!.canAddOutput(videoDataOutput) else {
            fatalError()
        }
        captureSession!.addOutput(videoDataOutput)
        videoConnection = videoDataOutput.connection(with: .video)
    }
    
    // TODO: Stop Buffer once person is found
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
    
        if let imageBufferHandler = imageBufferHandler {
            imageBufferHandler(sampleBuffer)
            
//            DispatchQueue.main.async {
//                self.bridgeModel?.personInView = true // << assign here as needed
            // TODO: When personIsInView, Kill resources and open VideoRecorder
//            }
        }
    }
}


struct CameraStreamView: UIViewRepresentable {
    let model: RecordingState
    
    func makeUIView(context: UIViewRepresentableContext<CameraStreamView>) -> CameraPreviewView {
        let recordingView = CameraPreviewView(frame: .zero, bridgeModel: model)
        recordingView.bridgeModel = self.model
        return recordingView
    }
    
    func updateUIView(_ uiViewController: CameraPreviewView, context: UIViewRepresentableContext<CameraStreamView>) {
        
    }
}


/// For Streaming the camera to process the frames (i.e. with ML)
class CameraPreviewView: UIView {
    var bridgeModel: RecordingState?
    private var captureSession: AVCaptureSession?

    
    /// For Streaming
    private var videoConnection: AVCaptureConnection!
    var videoDataDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
    var imageBufferHandler: ImageBufferHandler?
    

    init(frame: CGRect, bridgeModel: RecordingState) {
        super.init(frame: frame)
        self.bridgeModel = bridgeModel
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
        videoDataDelegate = self
                
        if let _ = self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
            self.captureSession?.startRunning()
            
        } else {
            self.captureSession?.stopRunning()
        }
    }
}


/// This extension is used for streaming frames for machine learning
extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setupVideoDataOutput() {
        // setup video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        // If running slowly, set the dispatch to run on the main UI thread
        let queue = DispatchQueue(label: "com.queue.videosamplequeue")
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        guard captureSession!.canAddOutput(videoDataOutput) else {
            fatalError()
        }
        captureSession!.addOutput(videoDataOutput)
        videoConnection = videoDataOutput.connection(with: .video)
    }
    
    // TODO: Stop Buffer once person is found
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
    
        if let imageBufferHandler = imageBufferHandler {
            imageBufferHandler(sampleBuffer)
            
//            DispatchQueue.main.async {
//                self.bridgeModel?.personInView = true // << assign here as needed
            // TODO: When personIsInView, Kill resources and open VideoRecorder
//            }
        }
    }
}




struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VideoRecordingView(model: RecordingState())
    }
}


struct CameraStreamView_Previews: PreviewProvider {
    static var previews: some View {
        VideoRecordingView(model: RecordingState())
    }
}
