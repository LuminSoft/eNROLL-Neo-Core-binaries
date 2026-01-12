//
//  FaceDetectionViewController.swift
//  FaceDetection
//
//  Created by Bahi El Feky on 03/11/2024.
//

import UIKit
import AVFoundation
//@_implementationOnly import MLKit

import MLKitFaceDetection
import MLKitVision
import Photos


enum LivenessStep {
    case lookStraight
    case smile
    case wink
    case turnLeft
    case turnRight
    case lookUp
    case lookDown
}

enum HeadPose {
    case left, right, up, down, center
}

func detectHeadPose(face: Face) -> HeadPose {
    let yaw = face.headEulerAngleY
    let pitch = face.headEulerAngleX

    if yaw > 20 { return .right }
    if yaw < -20 { return .left }
    if pitch > 15 { return .down }
    if pitch < -15 { return .up }
    return .center
}

class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    var captureSession = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    
    // AssetWriter
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isWriting = false
    private var startTime: CMTime?

    var isPhotoCaptured = false // Flag to ensure photo is captured only once
    public var delegate: FaceDetectionDelegate?
    public var withSmileLiveness: Bool = false
    public var withWinkLiveness: Bool = false
    
    var livenessSteps: [LivenessStep] = []
    var currentStepIndex = 0

    
    // Updated implementation of numberOfFaces label
    let textLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont(name: "Avenir-Heavy", size: 30)
        return label
    }()
    
    // UIImageView to display the captured photo
    let capturedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true // Initially hidden
        return imageView
    }()
    
    // UIView to represent the rectangle
    let rectangleView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.borderWidth = 2.0
        view.translatesAutoresizingMaskIntoConstraints = true
        return view
    }()
    
    // Variables to manage label updates
    private var lastLabelText: String = ""
    private var faceDetectionTimer: Timer?
    
    // Images Catched
    
    private var naturalImage: UIImage?
    //private var smileImage: UIImage?
   // private var winkImage: UIImage?
    private var liveneesVideoUrl:URL?
    private var livenessFrames: [UIImage] = []
    
    // Variables to store the circle properties
    var circleRadius: CGFloat = 0.0
    var circleCenter: CGPoint = .zero
    var circleWidth: CGFloat {
        return circleRadius * 2
    }
    var circleHeight: CGFloat {
        return circleRadius * 2
    }
    
    var centerYourFace = Keys.Localizations.centerYourFace
    var lookStraight = Keys.Localizations.lookStraight
    var noFaceDetected = Keys.Localizations.noFaceDetected
    var oneFaceAllowed = Keys.Localizations.oneFaceAllowed
    var holdStill = Keys.Localizations.holdStill
    var moveCloser = Keys.Localizations.moveCloser
    var moveFar = Keys.Localizations.moveFar
    var smile = Keys.Localizations.smile
    var wink = Keys.Localizations.wink
    var keepNaturalFace = Keys.Localizations.keepNaturalFace
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
       // startRecording()
        view.addSubview(rectangleView)
        generateLivenessSteps()
//        if !withSmileLiveness{
//            requiredNaturalStableFrames = 6
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addDimmedLayerWithClearCircle()
        setupLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        captureSession.stopRunning()
    }
    
    //MARK: - Actions
    
    var frameCounter = 0 // Counter to keep track of frames
    let frameSkipInterval = 10 // Process every 5th frame
    
    // Timer properties to manage the "Hold Still" state
    
    var lastSampleBuffer: CMSampleBuffer? // To store the last sample buffer
    
    
    // Function to reset the timer when "Hold Still" is no longer shown
    func resetHoldStillTimer() {
        naturalStableFrameCounter = 0 // Reset the stability counter
        //smileStableFrameCounter = 0
        stableFrameCounter = 0
        naturalImage = nil
        //smileImage = nil
        //winkImage = nil
       // isCapturingSmileImage = false
        //isCapturingWinkImage = false
        isCapturing = false
        isCapturingLivenessStep = false
    }
    
    var naturalStableFrameCounter = 0 // Counter to check stability across multiple frames
    var stableFrameCounter = 0 // Counter to check stability across multiple frames
   // var winkStableFrameCounter = 0
   // var requiredNaturalStableFrames = 3 // Number of consecutive stable frames required
   // let requiredSmileStableFrames = 6 // Number of consecutive stable frames required
   // let requiredWinkStableFrames = 3
    var isCapturing = false
    //var isCapturingSmileImage = false
   // var isCapturingWinkImage = false
    var isCapturingLivenessStep = false
    
    func generateLivenessSteps() {
        let all: [LivenessStep] = [.smile, .wink, .turnLeft, .turnRight, .lookUp, .lookDown]
        livenessSteps = Array(all.shuffled().prefix(3))
        livenessSteps[0] = .lookStraight
        currentStepIndex = 0
    }
    
    func instructionFor(step: LivenessStep) -> String {
        switch step {
        case .smile: return Keys.Localizations.smile
        case .wink: return Keys.Localizations.wink
        case .turnLeft: return Keys.Localizations.turnLeft
        case .turnRight: return Keys.Localizations.turnRight
        case .lookUp: return Keys.Localizations.lookUp
        case .lookDown: return Keys.Localizations.lookDown
        case .lookStraight: return Keys.Localizations.lookStraight + Keys.Localizations.keepNaturalFace
        }
    }
    
    func stableFramesCountFor(step: LivenessStep) -> Int {
        switch step {
        case .smile: return 6
        case .wink: return 3
        case .turnLeft: return 5
        case .turnRight: return 5
        case .lookUp: return 6
        case .lookDown: return 6
        case .lookStraight: return 6
        }
    }
    
    func isStepSatisfied(step: LivenessStep, face: Face) -> Bool {
        switch step {

        case .smile:
            return face.smilingProbability > 0.7

        case .wink:
            let l = face.leftEyeOpenProbability
            let r = face.rightEyeOpenProbability
            return (l < 0.15 && r > 0.8) || (r < 0.15 && l > 0.8)

        case .turnLeft:
            return face.headEulerAngleY < -20

        case .turnRight:
            return face.headEulerAngleY > 20

        case .lookUp:
            return face.headEulerAngleX < -15

        case .lookDown:
            return face.headEulerAngleX > 15

        case .lookStraight:
            return isLookingForward(face: face) && face.smilingProbability < 0.4
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isCapturing else { return } // Skip processing if we're capturing
        
        
        frameCounter += 1
        if frameCounter % frameSkipInterval != 0 {
            return // Skip this frame
        }
        // Store the latest sample buffer
        lastSampleBuffer = sampleBuffer
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Convert the image buffer to a CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // Get the dimensions of the image buffer
        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        
        // Create a UIImage from the full CIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        
        // Use the full image for face detection
        let visionImage = VisionImage(image: uiImage)
        visionImage.orientation = .right // Adjust orientation as needed
        
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        options.landmarkMode = .all // Disable landmarks if not needed
        options.classificationMode = .all // Disable classification if not needed
        options.contourMode = .none // Disable contours if not needed
        
        let faceDetector = FaceDetector.faceDetector(options: options)
        faceDetector.process(visionImage) { faces, error in
            if self.latestBorderColor == .green {
                DispatchQueue.main.async {
                    self.drawCircleBorder(color: .white, lineWidth: 4)
                }
            }
            
            guard error == nil, let faces = faces, !faces.isEmpty else {
                DispatchQueue.main.async {
                    self.textLabel.text = self.noFaceDetected
                    self.resetHoldStillTimer() // Reset the timer
                }
                return
            }
            
            if faces.count > 1 {
                // If more than one face is detected, update the label text
                DispatchQueue.main.async {
                    self.textLabel.text = self.oneFaceAllowed
                    self.resetHoldStillTimer() // Reset the timer
                }
                return
            }
            
            if !self.isWriting{
                let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                self.assetWriter?.startSession(atSourceTime: ts)
                self.startTime = ts
                self.isWriting = true
                print("🎥 Recording started at \(ts.seconds)")
            }
            
            if self.isWriting,
               self.videoInput!.isReadyForMoreMediaData{
                
                self.videoInput!.append(sampleBuffer)
            }
            
            DispatchQueue.main.async {
                if faces.count == 1 {
                    let face = faces.first!
                    
                    
                    // Calculate the center of the detected face in the image buffer coordinates
                    let faceFrame = face.frame
                    
                    let iou = self.calculateIoU(faceFrame: face.frame, imageWidth: imageWidth, imageHeight: imageHeight)
                    
                    let faceCenterX = faceFrame.origin.x + (faceFrame.width / 2)
                    let faceCenterY = faceFrame.origin.y + (faceFrame.height / 2)
                    
                    // Convert the face center to the view's coordinate space
                    let viewFaceCenterX = (faceCenterX / imageWidth) * self.view.bounds.width
                    let viewFaceCenterY = (faceCenterY / imageHeight) * self.view.bounds.height
                    
                    let faceCenter = CGPoint(x: viewFaceCenterX, y: viewFaceCenterY)
                    
                    // Calculate the center of the camera preview
                    let previewCenterX = self.view.bounds.midX
                    let previewCenterY = self.view.bounds.midY
                    
                    // Calculate the distance from the face center to the preview center
                    let distance = hypot(faceCenter.x - previewCenterX, faceCenter.y - previewCenterY)
                    
                    // Define a threshold distance (you can adjust this value)
                    let thresholdDistance: CGFloat =  60.0 // Adjust this as needed
                    
                    if distance < thresholdDistance {
                        
                        if iou < 0.4 {
                            self.textLabel.text = self.moveCloser
                            self.resetHoldStillTimer()
                        }else if iou > 0.55 {
                            self.textLabel.text = self.moveFar
                            self.resetHoldStillTimer()
                        } else {
                            // will begin using random steps
                            let currentStep = self.livenessSteps[self.currentStepIndex]
                            self.textLabel.text = self.instructionFor(step: currentStep)
                            if self.isStepSatisfied(step: currentStep, face: face)  {

                                self.stableFrameCounter += 1
                                self.drawCircleBorder(color: .green, lineWidth: 4)
                                self.textLabel.text = self.holdStill

                                if self.stableFrameCounter >= self.stableFramesCountFor(step: currentStep) {
                                    self.capturePhoto(isNaturalImage: self.currentStepIndex == 0)
                                    self.stableFrameCounter = 0
                                    self.currentStepIndex += 1

                                    if self.currentStepIndex == self.livenessSteps.count {
                                        //self.stopRecording()
                                        self.finishLiveness()
                                        return
                                    }
                                }
                            } else {
                                self.stableFrameCounter = 0
                                self.drawCircleBorder(color: .white, lineWidth: 4)
                            }

                        }
                    }
                }
            }
        }
    }
    
    // Function to capture the last frame when the "Hold Still" state is active
    func capturePhoto(isNaturalImage: Bool, isSinglePhotocapture: Bool? = nil) {
        isCapturing = true //isSinglePhotocapture ?? isSmileImage // Prevent further processing while capturing
        
        guard let sampleBuffer = lastSampleBuffer else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Convert the image buffer to a CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        var capturedImage = UIImage(cgImage: cgImage)

        // Rotate the captured image by 90 degrees clockwise
        if let rotatedImage = capturedImage.rotate(radians: .pi / 2) {
            capturedImage = rotatedImage
        }

        // Mirror the image if it's from the front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front), device.position == .front {
            capturedImage = capturedImage.withHorizontallyFlippedOrientation()
        }
        
        if isNaturalImage && naturalImage == nil{
            naturalImage = capturedImage
        }
        self.livenessFrames.append(capturedImage)
//        if isSmileImage {
//           if (smileImage == nil){
//               smileImage = capturedImage
//           }
//            else {
//                winkImage = capturedImage
//            }
         
            
            // Pass the processed image to the delegate and dismiss the view controller
//            if let naturalImage = naturalImage , let smileImage = smileImage, let winkImage = winkImage{
//                self.dismiss(animated: true) { [weak self] in
//                    self?.delegate?.faceDectionSucceed(with: FaceDetectionSuccessModel(naturalImage: naturalImage, smileImage: smileImage,livenessVideo: self?.liveneesVideoUrl != nil ? self!.liveneesVideoUrl!.lastPathComponent: ""))
//                }
//            }
        //}else {
          //  if naturalImage == nil {
              //  naturalImage = capturedImage
//                if isSinglePhotocapture == true {
//                    self.dismiss(animated: true) { [weak self] in
//                        self?.delegate?.faceDectionSucceed(with: FaceDetectionSuccessModel(naturalImage: capturedImage, smileImage: nil,livenessVideo: self?.liveneesVideoUrl != nil ? self!.liveneesVideoUrl!.lastPathComponent: "" ))
//                    }
//                }
           // }
            
       // }
        // Reset capturing state to allow further processing after showing the photo
        isCapturing = false
    }

    func finishLiveness() {
        if let naturalImage = naturalImage {
            self.dismiss(animated: true) {
                self.delegate?.faceDectionSucceed(
                    with: FaceDetectionSuccessModel(
                        naturalImage: naturalImage,
                        smileImage: self.livenessFrames.last,
                        livenessVideo: self.liveneesVideoUrl?.lastPathComponent ?? ""
                    )
                )
            }
        }
    }

    
    
    func drawRectangles(faceFrame: CGRect, boundingRect: CGRect) {
        // Remove any existing rectangle views
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        
        // Draw the bounding rectangle
        let boundingRectView = UIView(frame: boundingRect)
        boundingRectView.layer.borderColor = UIColor.red.cgColor
        boundingRectView.layer.borderWidth = 2.0
        boundingRectView.tag = 999 // Tag to identify and remove later
        view.addSubview(boundingRectView)
        
        // Draw the face rectangle
        let faceRectView = UIView(frame: faceFrame)
        faceRectView.layer.borderColor = UIColor.blue.cgColor
        faceRectView.layer.borderWidth = 2.0
        faceRectView.tag = 999 // Tag to identify and remove later
        view.addSubview(faceRectView)
    }
    
    
    // Updated IoU function with drawing logic
    func calculateIoU(faceFrame: CGRect, imageWidth: CGFloat, imageHeight: CGFloat) -> CGFloat {
        
        //        // Convert the face center to the view's coordinate space
        let viewFaceCenterX = (faceFrame.origin.y / imageHeight) * self.view.bounds.width
        let viewFaceCenterY = (faceFrame.origin.x / imageWidth) * self.view.bounds.height
        // Convert the top-left x and y, and the width and height of the rectangle to the view's coordinate space
        // Adjust for 90-degree right rotation
        
        let viewWidth = (faceFrame.height / imageHeight) * self.view.bounds.width
        let viewHeight = (faceFrame.width / imageWidth) * self.view.bounds.height
        
        
        // Convert the face frame to the view's coordinate space
        let viewFaceFrame = CGRect(
            x: viewFaceCenterX,
            y: viewFaceCenterY,
            width: viewWidth,
            height: viewHeight
        )
        
        let x = virtualCircleMinX
        let y = virtualCircleMinY
        let width = virtualCircleMaxX - virtualCircleMinX
        let height = virtualCircleMaxY - virtualCircleMinY
        
        
        // Convert the virtual circle's bounding rectangle to the view's coordinate space
        let viewBoundingRect = CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
        
        // Draw the rectangles for visual debugging
        //        drawRectangles(faceFrame: viewFaceFrame, boundingRect: viewBoundingRect)
        
        // Calculate the intersection rectangle
        let intersectionRect = viewFaceFrame.intersection(viewBoundingRect)
        
        // If there is no intersection, IoU is 0
        if intersectionRect.isEmpty {
            return 0.0
        }
        
        // Calculate the areas
        let intersectionArea = intersectionRect.width * intersectionRect.height
        let faceArea = viewFaceFrame.width * viewFaceFrame.height
        let boundingRectArea = viewBoundingRect.width * viewBoundingRect.height
        let unionArea = faceArea + boundingRectArea - intersectionArea
        
        // Calculate IoU
        let iou = intersectionArea / unionArea
        return iou
    }
    
    // Helper function to update the label text only if it has changed
    private func updateLabelText(_ newText: String) {
        if lastLabelText != newText {
            lastLabelText = newText
            textLabel.text = newText
        }
    }
    
    
    
    //MARK: - Helpers
    
    
    // Function to check if the face is looking forward
    func isLookingForward(face: Face) -> Bool {
        // Check the headEulerAngleX, headEulerAngleY, and headEulerAngleZ to determine face orientation
        let headEulerAngleX = face.headEulerAngleX // Rotation around the horizontal axis (pitch)
        let headEulerAngleY = face.headEulerAngleY // Rotation around the vertical axis (yaw)
        let headEulerAngleZ = face.headEulerAngleZ // Rotation around the axis pointing out of the device (roll)
        
        // Define thresholds for "looking forward" and "not looking up or down"
        let yawThreshold: CGFloat = 10.0
        let rollThreshold: CGFloat = 10.0
        let pitchThreshold: CGFloat = 10.0
        
        // Check if the face is within the threshold for all angles
        return abs(headEulerAngleX) < pitchThreshold &&
               abs(headEulerAngleY) < yawThreshold &&
               abs(headEulerAngleZ) < rollThreshold
    }

    
    //MARK: - UI
    
    
    func setupLabel() {
        view.addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 150)
        ])
    }
    
    func setupCamera() {
//        captureSession.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            return
        }
        
        // Create and configure the photo output
        captureSession.addOutput(photoOutput)// Add the photo output to the session
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        captureSession.sessionPreset = .medium
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)
        DispatchQueue.global().async{
            self.captureSession.startRunning()
        }
        view.backgroundColor = .black
        
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("liveness.mp4")
        
        assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
//        let settings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4) ?? [
//            AVVideoCodecKey: AVVideoCodecType.h264,
//            AVVideoWidthKey: 720,
//            AVVideoWidthKey: 720,
//            AVVideoHeightKey: 1280
//        ]
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 480,   // medium resolution width
            AVVideoHeightKey: 640,  // medium resolution height
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1_000_000, // ~1 Mbps (medium quality)
                AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel
            ]
        ]
        
        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        self.videoInput!.expectsMediaDataInRealTime = true
        self.videoInput!.transform = CGAffineTransform(rotationAngle: .pi/2)
        
        if  assetWriter?.canAdd(self.videoInput!) == true {
            // Fix orientation (for portrait recording)
            assetWriter?.add(self.videoInput!)
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: self.videoInput!,
                sourcePixelBufferAttributes: nil
            )
        }
   
        assetWriter?.startWriting()
       
        //startTime = nil
    }
    
    func stopRecording() {
        isWriting = false
        self.videoInput?.markAsFinished()
        assetWriter?.finishWriting {
            
            print("Video saved at: \(self.assetWriter?.outputURL)")
            if let videoURL = self.assetWriter?.outputURL {
                
              //  DispatchQueue.main.async {
                  
                    
                    // (Optional) Move to Documents before saving
                    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let destURL = docs.appendingPathComponent("liveness.mp4")
                    try? FileManager.default.removeItem(at: destURL)
                    try? FileManager.default.moveItem(at: videoURL, to: destURL)
                    
                    PHPhotoLibrary.shared().performChanges({
                          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destURL)
                      }) { success, error in
                          if success {
                              print("✅ Saved to Photos")
                          } else {
                              print("❌ Error saving video: \(String(describing: error))")
                          }
                      }
                    
               // }
                self.liveneesVideoUrl = destURL
               
//                let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//                let destination = documents.appendingPathComponent("liveness.mp4")
//
//                do {
//                  //  try FileManager.default.copyItem(at: videoURL, to: destination)
                 
                  //  print("Video moved to: \(destination.path)")
//                } catch {
//                    print("Error saving video: \(error)")
//                }
            }
        }
    }
    
    
    
    var virtualCircleMinX: CGFloat = 0.0
    var virtualCircleMaxX: CGFloat = 0.0
    var virtualCircleMinY: CGFloat = 0.0
    var virtualCircleMaxY: CGFloat = 0.0
    
    
    // Function to add a dimmed layer with a clear circle in the center
    func addDimmedLayerWithClearCircle() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Calculate the circle radius to be 70% of the screen width
        circleRadius = (view.bounds.width * 0.7) / 2
        circleCenter = overlayView.center
        
        // Calculate the min and max x and y for the bounding rectangle
        virtualCircleMinX = circleCenter.x - circleRadius
        virtualCircleMaxX = circleCenter.x + circleRadius
        virtualCircleMinY = circleCenter.y - circleRadius
        virtualCircleMaxY = circleCenter.y + circleRadius
        
        // Create a circular path in the center of the view
        let circlePath = UIBezierPath(arcCenter: circleCenter, radius: circleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        // Create a rectangular path for the whole view
        let rectPath = UIBezierPath(rect: overlayView.bounds)
        
        // Subtract the circle path from the rectangle path
        rectPath.append(circlePath)
        rectPath.usesEvenOddFillRule = true
        
        // Create a shape layer to apply the path
        let maskLayer = CAShapeLayer()
        maskLayer.path = rectPath.cgPath
        maskLayer.fillRule = .evenOdd
        
        // Apply the mask to the overlay view
        overlayView.layer.mask = maskLayer
        
        // Add the overlay view to the main view
        view.addSubview(overlayView)
        
        // Draw the initial border with the default color (white)
        drawCircleBorder(color: UIColor.white, lineWidth: 4.0)
    }
    
    
    var latestBorderColor: UIColor = .white
    // Separate function to draw or update the circle border
    func drawCircleBorder(color: UIColor, lineWidth: CGFloat) {
        latestBorderColor = color
        // Create a circular path for the border
        let circlePath = UIBezierPath(arcCenter: circleCenter, radius: circleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        // Create a shape layer for the border
        let borderLayer = CAShapeLayer()
        borderLayer.path = circlePath.cgPath
        borderLayer.strokeColor = color.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = lineWidth
        borderLayer.name = "circleBorder" // Name the layer for easy identification
        
        // Remove any existing border layer with the same name
        view.layer.sublayers?.removeAll { $0.name == "circleBorder" }
        
        // Add the new border layer to the main view
        view.layer.addSublayer(borderLayer)
    }

    
}



extension UIImage {
    func rotate(radians: CGFloat) -> UIImage? {
        var newSize = CGRect(origin: .zero, size: self.size).applying(CGAffineTransform(rotationAngle: radians)).integral.size
        // Adjust the size to prevent clipping
        newSize.width = max(newSize.width, newSize.height)
        newSize.height = max(newSize.width, newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Move the origin to the middle of the image so rotation happens around the center
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate the image context
        context.rotate(by: radians)
        // Draw the original image at the center
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }
}

