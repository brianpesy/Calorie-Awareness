//
//  ViewController.swift
//  Calorie-Awareness
//
//  Created by Brian Sy on 21/06/2018.
//  Copyright © 2018 BrianSy. All rights reserved.
//

//Resource for integration: https://medium.freecodecamp.org/ios-coreml-vision-image-recognition-3619cf319d0b

import UIKit
import AVFoundation
import Vision
import CoreML
import Alamofire
import SwiftyJSON


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    //Creating a label
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    let apiButton: UIButton = UIButton()
    var food = ""

    
    //1. Creating a button. We can use this button to get the API whenever the user wants. It will be good to regulate the checks this way! PROBLEM: Finding a good API for nutrition :(
    //2. Another problem: Inaccurate readings on what food was scanned as well (possibly unavoidable?) 

    private func createButton() {

        //A button that spans the whole bottom of the screen
        apiButton.frame = CGRect(x: 0, y: Int(view.frame.maxY-70), width: Int(view.frame.maxX), height: 70)

        //Title for our button
        apiButton.setTitle("Compute!", for: UIControlState.normal)
        
        //The action to have when pressing it
        apiButton.addTarget(self, action: #selector(beforeAction(_:)), for: .touchDown)
        apiButton.addTarget(self, action: #selector(outAction(_:)), for: .touchUpOutside)
        apiButton.addTarget(self, action: #selector(getAction(_:)), for: .touchUpInside)
        
        //Colors of the button
        apiButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        apiButton.setTitleColor(UIColor(red: 121.0/255.0, green: 200.0/255.0, blue: 133/255.0, alpha: 1), for: .normal)
    }
    
    @objc private func beforeAction(_ sender: UIButton?) {
        //Changes color to indicate a press
        apiButton.backgroundColor = UIColor(red: 149.0/255.0, green: 113.0/255.0, blue: 75.0/255.0, alpha: 0.5)
    }

    @objc private func outAction(_ sender: UIButton?) {
        //Goes back to neutral state
        apiButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    @objc private func getAction(_ sender: UIButton?) {
        print("helo")
        apiButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        //Place API get call over here. Problem: not being able to know what is a good API for nutrition :(
        
        //The variable "food" has the food that we want to work on here!
        print(apiAuth(food: food))
        
        //After a press of the "more info" button (custom button maybe? "..." icon), go to a new view controller that shows the different stats of the food item. Make sure you can back out after. (That's the whole app probs?) If I can't do this part, just have a label that appears somewhere on the screen
        // We display the "more info" after the button was pressed at least one time. 
        //Nav bar on top, shows everything. Back up after! Now... to research on that...
        
        /*
         Option 1: Create a custom button and then display the data in a navigation bar (will need to pass variables through a segue)
         Option 2: Create a slide out menu where we can see the data from without leaving
         Option 3:
         Last resort: Just display calories only as a label right on top of the name of the food (convenient though!)
         */
        
        /*
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let newViewController = storyBoard.instantiateViewController(withIdentifier: "newViewController")
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "newViewController")
        self.present(newViewController, animated: true, completion: nil)
        */
    }
    
    func apiAuth(food: String) -> String{
        //The goal here is to be able to return the authenticated string in order for us to start working on the API gathering
        let key = "144c8119d3414ea7850edf459b180d79"
        let signature = "HMAC-SHA1"
        let timestamp = Int(Date().timeIntervalSince1970)
        //nonce?
        //version - 1.0
        print(timestamp)
        return food
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // establish the capture session and add the label
        setupCaptureSession()
        view.addSubview(label)
        createButton()
        view.addSubview(apiButton)
        setupLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        // create a new capture session
        let captureSession = AVCaptureSession()
        
        // find the available cameras
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        do {
            // select a camera
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            // print an error if the camera is not available
            print(error.localizedDescription)
        }
        
        // setup the video output to the screen and add output to our capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        // buffer the video and start the capture session
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // load our CoreML Food101 model
        guard let model = try? VNCoreMLModel(for: Food101().model) else { return }
        
        // run an inference with CoreML
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            
            // grab the inference results
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            
            // grab the highest confidence result
            guard let Observation = results.first else { return }
            
            // create the label text components
            let predclass = "\(Observation.identifier)"
            self.food = predclass
            let predconfidence = String(format: "%.02f%", Observation.confidence * 100)
            
            // set the label text
            DispatchQueue.main.async(execute: {
                self.label.text = "\(predclass) \(predconfidence)"
            })
        }
        
        // create a Core Video pixel buffer which is an image buffer that holds pixels in main memory
        // Applications generating frames, compressing or decompressing video, or using Core Image
        // can all make use of Core Video pixel buffers
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func setupLabel() {
        // constrain the label in the center
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // constrain the the label to 50 pixels from the bottom
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        
        
    }

}


