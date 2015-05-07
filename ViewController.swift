//
//  ViewController.swift
//  IsItPink
//
//  Created by Kirby Bryant on 5/3/15.
//  Copyright (c) 2015 AKCB. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore
import CoreGraphics

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var lastChecked = NSDate()
    var colorView = UIView(frame: CGRectMake(CGFloat(0), CGFloat(0), CGFloat(250), CGFloat(250)))

    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        
        self.colorView.frame = CGRectMake(0, self.view.frame.height * (3/4), self.view.frame.width * (1/5), self.view.frame.height * (1/4))
        self.colorView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(colorView)
        
        captureSession.sessionPreset = AVCaptureSessionPreset1920x1080
        
        let devices = AVCaptureDevice.devices()
        
        for device in devices {
            if device.hasMediaType(AVMediaTypeVideo) {
                if device.position == AVCaptureDevicePosition.Back {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if (captureDevice != nil) {
            beginSession()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func beginSession() {
        var err: NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
        
        
        self.view.bringSubviewToFront(colorView)
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        //Get pixel data
        
        
        var now = NSDate()
        
        if now.timeIntervalSinceDate(lastChecked) >= 2 {
            var sampleImage: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
            var ciImage = CIImage(CVPixelBuffer: sampleImage)
            var context = CIContext(options: nil)
            var myImage = context.createCGImage(ciImage, fromRect: CGRectMake(CGFloat(0), CGFloat(0), CGFloat(CVPixelBufferGetWidth(sampleImage)), CGFloat(CVPixelBufferGetHeight(sampleImage))))
            var finalImage = UIImage(CGImage: myImage)
            changeToAverageColorOfImage(finalImage!)
            lastChecked = now
        }
        
        
    }
    
    func changeToAverageColorOfImage(image: UIImage) {
        var rgba = CGColorGetComponents(image.averageColor().CGColor)
        let red = rgba[0]
        let green = rgba[1]
        let blue = rgba[2]
        
        var color = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.5) {
                self.colorView.backgroundColor = color
                }
        }
        
        println("Current background color \(colorView.backgroundColor)")
        
        println("\(red) \(green) \(blue)")
    }

}

extension UIImage {

    //http://www.bobbygeorgescu.com/2011/08/finding-average-color-of-uiimage/ Converted to Swift - Thanks bobby georgescu.
    func averageColor() -> UIColor {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rgba = UnsafeMutablePointer<CUnsignedChar>.alloc(4)
        let bitInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, bitInfo)
        
        CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), self.CGImage)
        println("\(rgba[0]) \(rgba[1]) \(rgba[2]) \(rgba[3])")
        if (rgba[3] > 0) {
            var alpha = (CGFloat(rgba[3])) / 255.0
            var multiplier = alpha / 255.0
            return UIColor(red: CGFloat(rgba[0]) * multiplier, green: CGFloat(rgba[1]) * multiplier, blue: CGFloat(rgba[2]) * multiplier, alpha: alpha)
        } else {
            return UIColor(red: CGFloat(rgba[0]) / 255.0, green: CGFloat(rgba[1]) / 255.0, blue: CGFloat(rgba[2]) / 255.0, alpha: CGFloat(rgba[3]) / 255.0)
        }
    }
}

