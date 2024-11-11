//
//  FaceDetectionViewController.swift
//  FaceDetection
//
//  Created by Bahi El Feky on 03/11/2024.
//

import UIKit
import AVFoundation
import MLKit

public protocol FaceDetectionDelegate{
    func faceDectionSucceed(withImage image: UIImage)
    func faceDetectionFail(withError error: Error)
}

public class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    var captureSession = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
    var isPhotoCaptured = false // Flag to ensure photo is captured only once
    public var delegate: FaceDetectionDelegate?
    
    // Updated implementation of numberOfFaces label
    let textLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .orange
        label.font = UIFont(name: "Avenir-Heavy", size: 30)
        label.text = "No face"
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
    private var lastLabelText: String = "No face"
    private var faceDetectionTimer: Timer?
    
    // Variables to store the circle properties
    var circleRadius: CGFloat = 0.0
    var circleCenter: CGPoint = .zero
    var circleWidth: CGFloat {
        return circleRadius * 2
    }
    var circleHeight: CGFloat {
        return circleRadius * 2
    }
    
    var centerYourFace = "Center Your Face"
    var lookStraight = "Look Straight"
    var noFaceDetected = "No Face Detected"
    var oneFaceAllowed = "Only One Face Allowed"
    var holdStill = "Hold Still"
    var faceDetected = "Face Detected"
    var moveCloser = "Move Closer"
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupLabel()
        setupImageView()
        addDimmedLayerWithClearCircle()
        view.addSubview(rectangleView)
    }
    
    //MARK: - Actions
    
    var frameCounter = 0 // Counter to keep track of frames
    let frameSkipInterval = 10 // Process every 5th frame
    
    // Timer properties to manage the "Hold Still" state
    
    var lastSampleBuffer: CMSampleBuffer? // To store the last sample buffer
    
    
    // Function to reset the timer when "Hold Still" is no longer shown
    func resetHoldStillTimer() {
        stableFrameCounter = 0 // Reset the stability counter
    }
    
    var stableFrameCounter = 0 // Counter to check stability across multiple frames
    let requiredStableFrames = 3 // Number of consecutive stable frames required
    var isCapturing = false
    
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
        options.performanceMode = .fast
        options.landmarkMode = .all
        options.classificationMode = .all
        options.landmarkMode = .none // Disable landmarks if not needed
        options.classificationMode = .none // Disable classification if not needed
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
            
            
            DispatchQueue.main.async {
                if faces.count == 1 {
                    let face = faces.first!
                    
                    // Calculate the center of the detected face in the image buffer coordinates
                    let faceFrame = face.frame
                    
                    let iou = self.calculateIoU(faceFrame: face.frame, imageWidth: imageWidth, imageHeight: imageHeight)
                    print("IoU: \(iou)")
                    
                    print("IOU: \(iou)")
                    print("Face Frame: \(faceFrame)") // Debug print
                    
                    let faceCenterX = faceFrame.origin.x + (faceFrame.width / 2)
                    let faceCenterY = faceFrame.origin.y + (faceFrame.height / 2)
                    print("Face Center (Image Buffer Coordinates): (\(faceCenterX), \(faceCenterY))") // Debug print
                    
                    // Convert the face center to the view's coordinate space
                    let viewFaceCenterX = (faceCenterX / imageWidth) * self.view.bounds.width
                    let viewFaceCenterY = (faceCenterY / imageHeight) * self.view.bounds.height
                    print("Face Center (View Coordinates): (\(viewFaceCenterX), \(viewFaceCenterY))") // Debug print
                    
                    let faceCenter = CGPoint(x: viewFaceCenterX, y: viewFaceCenterY)
                    
                    // Calculate the center of the camera preview
                    let previewCenterX = self.view.bounds.midX
                    let previewCenterY = self.view.bounds.midY
                    print("Camera Preview Center: (\(previewCenterX), \(previewCenterY))") // Debug print
                    
                    // Calculate the distance from the face center to the preview center
                    let distance = hypot(faceCenter.x - previewCenterX, faceCenter.y - previewCenterY)
                    print("Distance from face center to preview center: \(distance)") // Debug print
                    
                    // Define a threshold distance (you can adjust this value)
                    let thresholdDistance: CGFloat =  60.0 // Adjust this as needed
                    
                    if distance < thresholdDistance {
                        
                        if iou < 0.5 {
                            self.textLabel.text = self.moveCloser
                        }else {
                            if self.isLookingForward(face: face) {
                                self.drawCircleBorder(color: .green, lineWidth: 4)
                                self.textLabel.text = self.holdStill
                                self.stableFrameCounter += 1
                                if self.stableFrameCounter >= self.requiredStableFrames {
                                    // Start the timer for 2 seconds
                                    self.stableFrameCounter = 0 // Reset the stability counter
                                    self.capturePhoto() // Capture the photo after 1 second
                                }
                                
                            } else {
                                self.textLabel.text = self.lookStraight
                                self.resetHoldStillTimer() // Reset the timer
                            }
                        }
                    } else {
                        self.textLabel.text = self.centerYourFace
                        self.resetHoldStillTimer() // Reset the timer
                    }
                } else {
                    self.textLabel.text = self.noFaceDetected
                    self.resetHoldStillTimer() // Reset the timer
                }
            }
        }
    }
    
    // Function to capture the last frame when the "Hold Still" state is active
    func capturePhoto() {
        isCapturing = true // Prevent further processing while capturing
        guard let sampleBuffer = lastSampleBuffer else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Convert the image buffer to a CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let capturedImage = UIImage(cgImage: cgImage)

        // Rotate the captured image by 90 degrees clockwise
        let rotatedImage = capturedImage.rotate(radians: .pi / 2)

//        // Display the rotated image in a simple photo view
//        let photoViewController = UIViewController()
//        photoViewController.view.backgroundColor = .black
//        let imageView = UIImageView(image: rotatedImage)
//        imageView.contentMode = .scaleAspectFit
//        imageView.frame = photoViewController.view.bounds
//        photoViewController.view.addSubview(imageView)
//
//        // Present the photo view controller
//        present(photoViewController, animated: true, completion: nil)
        if let rotatedImage = rotatedImage {
            self.dismiss(animated: true){ [weak self] in
                self?.delegate?.faceDectionSucceed(withImage: rotatedImage)
            }
            
            
        }
        

        // Reset capturing state to allow further processing after showing the photo
        isCapturing = false
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
        
        
        //        print("Face Center (View Coordinates): (\(viewFaceCenterX), \(viewFaceCenterY))") // Debug print
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
    
    // Implement the delegate method to handle the captured photo
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        // Stop the capture session
        captureSession.stopRunning()
        
        // Display the captured image
        DispatchQueue.main.async{
            self.capturedImageView.image = image
            self.capturedImageView.isHidden = false // Show the image view
            self.textLabel.text = "Photo Captured" // Update the label text
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
            textLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50)
        ])
    }
    
    func setupCamera() {
        captureSession.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error accessing camera: \(error)")
            return
        }
        
        // Create and configure the photo output
        captureSession.addOutput(photoOutput) // Add the photo output to the session
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)
        DispatchQueue.global().async{
            self.captureSession.startRunning()
        }
        
    }
    
    func setupImageView() {
        view.addSubview(capturedImageView)
        NSLayoutConstraint.activate([
            capturedImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            capturedImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            capturedImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            capturedImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6)
        ])
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
