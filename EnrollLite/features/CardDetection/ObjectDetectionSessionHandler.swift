//
//  CardDetectionSessionHandler.swift
//  VerIDIDCapture
//
//  Created by Bahi Elfeky on 10/11/2024.


import UIKit
import AVFoundation
import Vision

class ObjectDetectionSessionHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session = AVCaptureSession()
    lazy var captureLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    lazy var rectangleDetectionQueue: DispatchQueue = {
        return DispatchQueue(label: "com.appliedrec.Ver-ID.RectangleDetection", attributes: [])
    }()
    
    lazy var imageConversionOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var device: AVCaptureDevice? = {
        return AVCaptureDevice.default(.builtInWideAngleCamera , for: .video, position: .back)
    }()
    
    var imageOrientation: CGImagePropertyOrientation = .right
    
    weak var delegate: CardDetectionSessionHandlerDelegate?
    
    var isTorchAvailable: Bool {
        guard let device = self.device else {
            return false
        }
        return device.hasTorch && device.isTorchAvailable
    }
    
    var cardDetectionSettings: BaseCardDetectionSettings?
    var torchSettings: TorchSettings?
    
    var imageTransform: CGAffineTransform {
        switch self.imageOrientation {
        case .right, .left:
            return CGAffineTransform(scaleX: self.captureLayer.bounds.width, y: 0-self.captureLayer.bounds.height).concatenating(CGAffineTransform(translationX: 0, y: self.captureLayer.bounds.height))
        default:
            return CGAffineTransform(scaleX: 0-self.captureLayer.bounds.width, y: self.captureLayer.bounds.height).concatenating(CGAffineTransform(translationX: self.captureLayer.bounds.width, y: 0))
        }
    }
    
    func startCamera() {
        guard let device = self.device else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            } else if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            device.unlockForConfiguration()
        } catch {
            
        }
        
        self.imageConversionOperationQueue.isSuspended = false
        
        let input = try! AVCaptureDeviceInput(device: device)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: self.rectangleDetectionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        session.beginConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global().async {
            self.session.startRunning()
        }
        
    }
    
    func stopCamera() {
        self.toggleTorch(on: false)
        self.imageConversionOperationQueue.cancelAllOperations()
        self.imageConversionOperationQueue.isSuspended = true
        session.stopRunning()
    }
    
    func toggleTorch(on: Bool) {
        guard let device = self.device else {
            return
        }
        if device.hasTorch && device.isTorchAvailable {
            do {
                try device.lockForConfiguration()
                if on {
                    if let torchLevel = self.torchSettings?.torchLevel {
                        try device.setTorchModeOn(level: torchLevel)
                    } else {
                        device.torchMode = .on
                    }
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                NSLog("Unable to lock device for configuation: %@", error.localizedDescription)
            }
        }
    }
    
    func featureTransform(fromSize size: CGSize, atOrientation orientation: CGImagePropertyOrientation) -> CGAffineTransform {
        switch orientation {
        case .right, .left:
            return CGAffineTransform(scaleX: size.width, y: 0-size.height).concatenating(CGAffineTransform(translationX: 0, y: size.height))
        default:
            return CGAffineTransform(scaleX: 0-size.width, y: size.height).concatenating(CGAffineTransform(translationX: size.width, y: 0))
        }
    }
    
    func rectangleDetectionRequest(withPixelBuffer pixelBuffer: CVImageBuffer) -> VNDetectRectanglesRequest? {
        guard let delegate = self.delegate, delegate.shouldDetectCardImageWithSessionHandler(self) && !self.imageConversionOperationQueue.isSuspended && self.imageConversionOperationQueue.operationCount == 0 else {
            return nil
        }
        
        let brightnessDegree = analyzeLightingDegree(pixelBuffer: pixelBuffer)
        if brightnessDegree < 70 {
            delegate.brightnessHandler(brightnessDegree: brightnessDegree, message: Keys.Localizations.needMoreLight)
        } else {
            let orientation = self.imageOrientation
            let rectangleDetectionRequest = VNDetectRectanglesRequest() { (request, error) in
                if let rect = request.results?.first as? VNRectangleObservation, !self.imageConversionOperationQueue.isSuspended && self.imageConversionOperationQueue.operationCount == 0 {
                    let op = PerspectiveCorrectionParamsOperation(pixelBuffer: pixelBuffer, orientation: orientation, rect: rect)
                    op.completionBlock = { [weak self, weak op] in
                        let sharpness = op?.sharpness
                        if let cgImage = op?.cgImage, let corners = op?.corners, let params = op?.perspectiveCorrectionParams {
                            DispatchQueue.main.async {
                                guard let `self` = self else {
                                    return
                                }
                                delegate.sessionHandler(self, didDetectCardInImage: cgImage, withTopLeftCorner: corners.topLeft, topRightCorner: corners.topRight, bottomRightCorner: corners.bottomRight, bottomLeftCorner: corners.bottomLeft, perspectiveCorrectionParams: params, sharpness: sharpness, brightnessLevel: brightnessDegree, rect: rect)
                            }
                        }
                    }
                    self.imageConversionOperationQueue.addOperation(op)
                } else {
                    delegate.brightnessHandler(brightnessDegree: brightnessDegree, message: Keys.Localizations.centerYourDocument)
                }
            }
            rectangleDetectionRequest.maximumObservations = 1
            return rectangleDetectionRequest
        }
        return nil
    }
    
    var threshold: Float = 100.0

    func isImageBlurry(pixelBuffer: CVPixelBuffer) -> Bool {
        guard let processedPixelBuffer = applyLaplacianTo(pixelBuffer: pixelBuffer),
              let variance = calculateVarianceOf(pixelBuffer: processedPixelBuffer) else {
            print("Processing failed.")
            return false
        }

        let isBlurry = variance < threshold
        let text = isBlurry ? "Blurry" : "Not Blurry"
        print("\(text): \(variance)")
        return isBlurry
    }

    func applyLaplacianTo(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let context = CIContext()

        // Lock the pixel buffer for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        // Create a CIImage from the pixel buffer
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Define the Laplacian kernel
        let laplacianKernel = CIVector(values: [-1, -1, -1,
                                                 -1,  8, -1,
                                                 -1, -1, -1], count: 9)

        // Create and configure the convolution filter
        guard let filter = CIFilter(name: "CIConvolution3X3") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(laplacianKernel, forKey: "inputWeights")
        filter.setValue(0.0, forKey: "inputBias") // No bias needed for Laplacian

        // Apply the filter
        guard let outputImage = filter.outputImage else { return nil }

        // Create a new pixel buffer to store the output
        var newPixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: CVPixelBufferGetWidth(pixelBuffer),
            kCVPixelBufferHeightKey as String: CVPixelBufferGetHeight(pixelBuffer)
        ]
        CVPixelBufferCreate(kCFAllocatorDefault, Int(outputImage.extent.width), Int(outputImage.extent.height), kCVPixelFormatType_32BGRA, pixelBufferAttributes as CFDictionary, &newPixelBuffer)

        // Render the output image into the new pixel buffer
        if let newPixelBuffer = newPixelBuffer {
            context.render(outputImage, to: newPixelBuffer)
        }

        return newPixelBuffer
    }

    func calculateVarianceOf(pixelBuffer: CVPixelBuffer) -> Float? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        var pixelValues = [UInt8]()

        for y in 0..<height {
            let rowPointer = baseAddress.advanced(by: y * bytesPerRow)
            let row = UnsafeBufferPointer(start: rowPointer.assumingMemoryBound(to: UInt8.self), count: width * 4)

            // Extract grayscale values (assuming BGRA format)
            for x in stride(from: 0, to: row.count, by: 4) {
                let blue = row[x]
                let green = row[x + 1]
                let red = row[x + 2]
                let gray = UInt8(0.299 * Float(red) + 0.587 * Float(green) + 0.114 * Float(blue))
                pixelValues.append(gray)
            }
        }

        // Calculate the variance
        let pixelValuesFloat = pixelValues.map { Float($0) }
        let mean = pixelValuesFloat.reduce(0, +) / Float(pixelValuesFloat.count)
        let variance = pixelValuesFloat.reduce(0) { $0 + pow($1 - mean, 2) } / Float(pixelValuesFloat.count)

        return variance
    }

    
    private func analyzeLightingDegree(pixelBuffer: CVPixelBuffer) -> Float {
            // Perform your lighting analysis here, using the pixel buffer
            
            // Placeholder implementation: Calculate the average pixel brightness
            var totalBrightness: Float = 0.0
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            let buffer = baseAddress?.assumingMemoryBound(to: UInt8.self)
            
            for y in 0..<height {
                let pixelRow = buffer! + y * bytesPerRow
                for x in 0..<width {
                    let pixel = pixelRow[x]
                    totalBrightness += Float(pixel)
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            let averageBrightness = totalBrightness / (Float(width) * Float(height))
            return averageBrightness
        }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let adjustingFocus = self.device?.isAdjustingFocus, adjustingFocus {
            return
        }
        guard let delegate = self.delegate else {
            return
        }
        if !delegate.shouldDetectBarcodeWithSessionHandler(self) && !delegate.shouldDetectCardImageWithSessionHandler(self) {
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let requestOptions: [VNImageOption:Any] = [:]
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.imageOrientation, options: requestOptions)
        
        var requests: [VNRequest] = []
        if let rectangleDetectionRequest = self.rectangleDetectionRequest(withPixelBuffer: pixelBuffer) {
            requests.append(rectangleDetectionRequest)
        }
        
        if !requests.isEmpty {
            do {
                try handler.perform(requests)
            } catch {
                
            }
        }
    }
}

protocol CardDetectionSessionHandlerDelegate: AnyObject {
    func sessionHandler(_ handler: ObjectDetectionSessionHandler, didDetectCardInImage image: CGImage, withTopLeftCorner topLeftCorner: CGPoint, topRightCorner: CGPoint, bottomRightCorner: CGPoint, bottomLeftCorner: CGPoint, perspectiveCorrectionParams: [String:CIVector], sharpness: Float?, brightnessLevel: Float?, rect: VNRectangleObservation?)
    func sessionHandler(_ handler: ObjectDetectionSessionHandler, didDetectBarcodes barcodes: [VNBarcodeObservation])
    func shouldDetectCardImageWithSessionHandler(_ handler: ObjectDetectionSessionHandler) -> Bool
    func shouldDetectBarcodeWithSessionHandler(_ handler: ObjectDetectionSessionHandler) -> Bool
    func brightnessHandler(brightnessDegree:Float, message: String?)
    func drawDetectedRactangles(rect: VNRectangleObservation?)
}
