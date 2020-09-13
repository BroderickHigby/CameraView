//
//  LiveAnalysisView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI
import AVKit
import Vision

struct LivePreview: UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<LivePreview>) -> LiveCameraView  {
        let liveView = LiveCameraView()
        return liveView
    }
    
    func updateUIView(_ uiView: LiveCameraView, context: UIViewRepresentableContext<LivePreview>) {
    }
}

typealias ImageBufferHandler = ((_ imageBuffer: CMSampleBuffer) -> ())

// TODO: Have sample output buffer display
// TODO: Setup predict function in delegate
/// Starts Camera Preview and looks for person in view
/// This Camera Buffer is good for capturing frames using SwiftUI
class LiveCameraView: UIView {
    private var captureSession: AVCaptureSession?
    private var videoConnection: AVCaptureConnection!
    var recordingDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
    var imageBufferHandler: ImageBufferHandler?
    
    init() {
        super.init(frame: .zero)
        requestCameraPermissions()
        setupLiveCamera()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    // adds a preview layer to anything that calls our View
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
        //alternate AVCaptureDevice.default(for: .video)
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
    
    // Starts the preview
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        recordingDelegate = self
        
        if let _ = self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspectFill // Change depending on requirements
            self.captureSession?.startRunning()
        }
        else {
            self.captureSession?.startRunning()
        }
    }
}

extension LiveCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // TODO: Stop Buffer once person is found
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Capturing output")
        
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
        
        if let imageBufferHandler = imageBufferHandler
        {
            imageBufferHandler(sampleBuffer)
        }
    }
}


//struct LiveAnalysisView_Previews: PreviewProvider {
//    static var previews: some View {
//        LiveAnalysisView()
//    }
//}





//UIKit

struct CameraView : UIViewControllerRepresentable {
    let model: BarCodeViewModel
    let myBarcode: Int = 0
    
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let controller = BarCodeDetectorViewController()
        controller.bridgeModel = self.model
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraView.UIViewControllerType, context: UIViewControllerRepresentableContext<CameraView>) {}
}

class BarCodeDetectorViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let session = AVCaptureSession()
    var bridgeModel: BarCodeViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startLiveVideo()
    }
    
    func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let cameraPreview = AVCaptureVideoPreviewLayer(session: session)
        
        view.layer.addSublayer(cameraPreview)
        cameraPreview.frame = view.frame
        
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Capturing output")
    }
}