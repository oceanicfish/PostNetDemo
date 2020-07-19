//
//  MainViewController.swift
//  PostNetDemo
//
//  Created by Yang on 2020/07/16.
//  Copyright © 2020 vstudio. All rights reserved.
//

import UIKit
import VideoToolbox

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // disable idle timer to prevent the screen from locking
        UIApplication.shared.isIdleTimerDisabled = true;
        
        // set postNet implementation to self
        
        // start to capture video frame
    }
    
}

// implement VideoCaptureDelegate here
extension MainViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CGImage?) {
        // to do something
    }
}
