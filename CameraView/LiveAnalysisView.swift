//
//  LiveAnalysisView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI
import AVKit


struct LivePreview: UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<LivePreview>) -> LiveAnalysisView  {
        let liveView = LiveAnalysisView()
        return liveView
    }
    
    func updateUIView(_ uiView: LiveAnalysisView, context: UIViewRepresentableContext<LivePreview>) {
    }
}


// TODO: Have sample output buffer display
// TODO: Setup predict function in delegate
/// Starts Camera Preview and looks for person in view
class LiveAnalysisView: UIView {
    private var captureSession: AVCaptureSession?
    let videoDataOutput = AVCaptureVideoDataOutput()
    var recordingDelegate: AVCaptureVideoDataOutputSampleBufferDelegate!
    
    
    init() {
        super.init(frame: .zero)
        
        // requests camera access if not granted already
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
    // adds a preview layer to anything that calls our View
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    // Starts the preview & Recording
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        recordingDelegate = self
        
        if let _ = self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspect
            self.captureSession?.startRunning()
        // self.startRecording()
        }
        else {
            self.captureSession?.startRunning()
        }
    }
}

extension LiveAnalysisView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Capturing output")
    }
}


//struct LiveAnalysisView_Previews: PreviewProvider {
//    static var previews: some View {
//        LiveAnalysisView()
//    }
//}
