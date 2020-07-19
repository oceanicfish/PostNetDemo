//
//  VideoCapture.swift
//  PostNetDemo
//
//  Created by Yang on 2020/07/03.
//  Copyright © 2020 vstudio. All rights reserved.
//

import AVFoundation
import VideoToolbox

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CGImage?)
}

class VideoCapture: NSObject {
    
    enum VideoCaptureError: Error {
        case captureSessionIsMissing
        case InvailidInput
        case InvailidOutput
        case unknown
    }
    
    weak var delegate: VideoCaptureDelegate?
    let captureSession = AVCaptureSession()
    private let videoCaptureQueue = DispatchQueue(
        label: "com.vstudio.postnet-demo.video-capture-queue")
    let videoOutput = AVCaptureVideoDataOutput()
    
    func setupAVCaptureSession(completion: @escaping (Error?) -> Void) {
        videoCaptureQueue.async {
            do {
                try self.setupAVCaptureSession()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    func setupAVCaptureSession() throws {
        // reset capture session
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480
        
        // setup capture session input and output
        try setCaptureSessionInput()
        try setCaptureSessionOutput()
        
        captureSession.commitConfiguration()
    }
    
    /*
     set up capture session input
     */
    func setCaptureSessionInput() throws {
        // create an instance of Capture Device
        guard let captureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back)
        else {
            throw VideoCaptureError.InvailidInput
        }
        
        // remove any existing inputs
        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }
        
        // creating an instance of AVCaptureDeviceInput to capture the data from
        // capture device
        guard let captureDeviceInput = try? AVCaptureDeviceInput(
            device: captureDevice)
        else {
            throw VideoCaptureError.InvailidInput
        }
        
        // check capture session is available to add more input or not
        // throws error if it is not available
        guard captureSession.canAddInput(captureDeviceInput) else {
            throw VideoCaptureError.InvailidInput
        }
        
        // add input to capture session
        captureSession.addInput(captureDeviceInput)
    }
    
    /*
     set up capture session output
     */
    func setCaptureSessionOutput() throws {
        // Remove existing capture session output
        captureSession.outputs.forEach{ output in
            captureSession.removeOutput(output)
        }
        
        // Setup output settings
        let outputSettings: [String: Any] = [
            String(kCVPixelBufferPixelFormatTypeKey):
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoOutput.videoSettings = outputSettings
        
        // Discard newer frames that arrive while the dispatch queue is already
        // busy with an older frame
        videoOutput.alwaysDiscardsLateVideoFrames = true
                
        // Set SampleBufferDelegate
//        videoOutput.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        
        // Check if the capture session could add an output or not
        // if not, throw an exception
        guard captureSession.canAddOutput(videoOutput) else {
            throw VideoCaptureError.InvailidOutput
        }
        
        // Add output to CaptureSession
        captureSession.addOutput(videoOutput)
        
        // OPTIONAL - Update video orientation
        // force image upward if the orientation is changable
        // TO DO ...
    }
    
    public func startCapture(completion completionHandler: (() -> Void)? = nil){
        videoCaptureQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            
            if let localCompletionHandler = completionHandler {
                DispatchQueue.main.async {
                    localCompletionHandler()
                }
            }
            
            /**
                the snipet above means that if completionHandler is not nil
                invoke it in the system main thread. the equivalance is as below
                
                if localCompletionHandler != nil {
                    let localCompletionHandler = completionHander!
                    DispatchQueue.main.async {
                        localCompletionHandler()
                    }
                }
             */
        }
    }
    
    public func stopCapture(completion completionHandler: (() -> Void)? = nil){
        videoCaptureQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            
            if let localCompletionHandler = completionHandler {
                DispatchQueue.main.async {
                    localCompletionHandler()
                }
            }
        }
        
    }
    
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {
        
        guard let delegate = delegate else {
            return
        }
        
        if let pixelBuffer = sampleBuffer.imageBuffer {
            // attempt to lock the image buffer to gain access to its memory
            guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess
                else {
                    return
            }
            
            var image: CGImage?
            
            // create core graphic bitmap image from pixel buffer
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
            
            // release the image buffer
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            DispatchQueue.main.async {
                delegate.videoCapture(self, didCaptureFrame: image)
            }
        }
    }
}
