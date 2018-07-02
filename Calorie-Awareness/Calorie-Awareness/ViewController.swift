//
//  ViewController.swift
//  Calorie-Awareness
//
//  Created by Brian Sy on 21/06/2018.
//  Copyright © 2018 BrianSy. All rights reserved.
//

//Resource for integrating with the camera: https://medium.freecodecamp.org/ios-coreml-vision-image-recognition-3619cf319d0b

import UIKit
import AVFoundation
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SVProgressHUD


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
    
    //Calorie label
    let calorieLabel: UILabel = {
        let calorieLabel = UILabel()
        calorieLabel.textColor = .white
        calorieLabel.translatesAutoresizingMaskIntoConstraints = false
        calorieLabel.text = " "
        calorieLabel.font = calorieLabel.font.withSize(20)
        return calorieLabel
    }()
    
    let apiButton: UIButton = UIButton()
    var food = ""
    var calories = 0
    var weight = 0

    
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
        apiButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

        //Authentication and getting of the data
        apiAuth(food: food)
        
        /*
         API request notes:
         
         POST request to: https://trackapi.nutritionix.com/v2/natural/nutrients

         In curl:
         
         curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'x-app-id: 6809025e' --header 'x-app-key: aeb52a68adf82760d6a67f2b04ec6e73' --header 'x-remote-user-id: 1' -d '{
         "query": "water",
         "num_servings": 1,
         "aggregate": "string",
         "line_delimited": false,
         "use_raw_foods": false,
         "include_subrecipe": false,
         "timezone": "US/Eastern",
         "consumed_at": null,
         "lat": null,
         "lng": null,
         "meal_type": 0,
         "use_branded_foods": false,
         "locale": "en_US"
         }' 'https://trackapi.nutritionix.com/v2/natural/nutrients'
         
         
         Parameters example: (We can just change the query to the food item!)
         {
             "query": food,
             "num_servings": 1,
             "aggregate": "string",
             "line_delimited": false,
             "use_raw_foods": false,
             "include_subrecipe": false,
             "timezone": "US/Eastern",
             "consumed_at": null,
             "lat": null,
             "lng": null,
             "meal_type": 0,
             "use_branded_foods": false,
             "locale": "en_US"
         }
         
         
         This is an error. Account for it! "Not in database"
         {
         "message": "We couldn't match any of your foods",
         "id": "a201b9ec-3a1b-4b7e-8afb-0182884a7470"
         }
         
         */

    }
    
    func apiAuth(food: String){
        
        let parameters = [ //This is the JSON we'll be passing over.
            "query": food,
            "num_servings": 1,
            "aggregate": "string",
            "line_delimited": false,
            "use_raw_foods": false,
            "include_subrecipe": false,
            "timezone": "US/Eastern",
            "consumed_at": nil,
            "lat": nil,
            "lng": nil,
            "meal_type": 0,
            "use_branded_foods": false,
            "locale": "en_US"
            ] as [String : Any?]

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "x-app-id": "6809025e",
            "x-app-key": "aeb52a68adf82760d6a67f2b04ec6e73",
            "x-remote-user-id": "1"
            ]
        
        SVProgressHUD.show()
        
        Alamofire.request("https://trackapi.nutritionix.com/v2/natural/nutrients", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
            //JSON parsing here
            
            if((response.result.value) != nil) {
                let json = JSON(response.result.value!)
                if json["message"].stringValue != "We couldn't match any of your foods" {
                    for item in json["foods"].arrayValue {
                        self.calories = item["nf_calories"].intValue
                        self.weight = item["serving_weight_grams"].intValue
                        
                        self.displayCalories(calories: self.calories, weight: self.weight, food: self.food)
                    }
                }
            }
            
            //Progress bar end here
            SVProgressHUD.dismiss()
        }
    }
    
    func displayCalories(calories: Int, weight: Int, food: String){
        calorieLabel.text = "\(food): \(calories)kcal per \(weight)g"
        view.addSubview(calorieLabel)
        setupCalorieLabel()

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
    
    func setupCalorieLabel(){
        calorieLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        calorieLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
    }

}


