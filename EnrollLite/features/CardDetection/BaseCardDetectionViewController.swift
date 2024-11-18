//
//  BaseCardDetectionViewController.swift
//  IDCardCamera
//
//  Created by Bahi Elfeky on 10/11/2024.

import UIKit
import AVFoundation
import Vision


class BaseCardDetectionViewController: ObjectDetectionViewController {
    
    // MARK: - To override in subclasses
    
    var imagePoolSize: Int {
        1
    }
    
    var cardAspectRatio: CGFloat {
        1
    }
    
    func qualityOfImage(_ image: CGImage) -> Float? {
        return nil
    }
    
    func didCropImageToImage(_ image: CGImage) {
    }
    
    func delegateCancel() {
    }
    
    func flipCardOrientation() {
    }
    
    // MARK: -
    
    private var viewSizeObserverContext: Int = 0
    @IBOutlet var cardOverlayView: UIView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var flipCardView: UIView!
    private var detectedCorners: [Bool] = [false, false, false, false]
    private var collectedImages: [(CGImage,Float)] = []
    private let detectionThreshold: CGFloat = 10.0
    var latestVisibleText = ""
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .black
        label.text = "Need more light"
        return label
    }()

    private let lblView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.5) // White background with low opacity
        view.layer.cornerRadius = 10 // Rounded corners
        view.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout
        return view
    }()
    
    @objc public init() {
        super.init(nibName: "CardDetectionViewController", bundle: Bundle.enrollBundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction override func cancel() {
        super.cancel()
        self.delegateCancel()
    }
    
    @IBAction func rotateCard() {
        self.flipCardOrientation()
        if let aspectRatioConstraint = self.cardOverlayView.constraints.first(where: {$0.identifier == "aspectRatio"}) {
            self.cardOverlayView.removeConstraint(aspectRatioConstraint)
        }
        let cardAspectRatioConstraint = NSLayoutConstraint(item: self.cardOverlayView!, attribute: .width, relatedBy: .equal, toItem: self.cardOverlayView!, attribute: .height, multiplier: self.cardAspectRatio, constant: 0)
        cardAspectRatioConstraint.identifier = "aspectRatio"
        self.cardOverlayView.addConstraint(cardAspectRatioConstraint)
    }
    
    func expectedCorners(inSize size: CGSize) -> [CGPoint] {
        let transform = self.transformToViewFromImageSize(size).inverted()
        let overlayRect = self.cardOverlayView.frame.applying(transform)
        return [
            CGPoint(x: overlayRect.minX, y: overlayRect.minY),
            CGPoint(x: overlayRect.maxX, y: overlayRect.minY),
            CGPoint(x: overlayRect.maxX, y: overlayRect.maxY),
            CGPoint(x: overlayRect.minX, y: overlayRect.maxY)
        ]
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.cardOverlayView.addObserver(self, forKeyPath: "bounds", options: .new, context: &self.viewSizeObserverContext)
        let cardAspectRatioConstraint = NSLayoutConstraint(item: self.cardOverlayView!, attribute: .width, relatedBy: .equal, toItem: self.cardOverlayView!, attribute: .height, multiplier: self.cardAspectRatio, constant: 0)
        cardAspectRatioConstraint.identifier = "aspectRatio"
        self.cardOverlayView.addConstraint(cardAspectRatioConstraint)
        // Add the label to the view
        lblView.addSubview(label)
        // Add constraints for the label inside lblView
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: lblView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: lblView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: lblView.leadingAnchor, constant: 30),
            label.trailingAnchor.constraint(equalTo: lblView.trailingAnchor, constant: -30)
        ])
//        lblView.center = cardOverlayView.center
        showLabelWithText(text: Keys.Localizations.centerYourDocument)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.viewSizeObserverContext && keyPath == "bounds" {
            self.drawCardOverlay()
        }
    }

    override func updateCameraOrientation() {
        super.updateCameraOrientation()
        self.drawCardOverlay()
    }
    
    func transformToViewFromImageSize(_ size: CGSize) -> CGAffineTransform {
        let viewSize = self.cameraPreview.bounds.size
        let imageRect = AVMakeRect(aspectRatio: viewSize, insideRect: CGRect(origin: CGPoint.zero, size: size))
        let scale = viewSize.width / imageRect.width
        return CGAffineTransform(translationX: 0-imageRect.minX, y: 0-imageRect.minY).concatenating(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func drawCorners(_ corners: [Bool], in view: UIView) {
        let overlayRect = CGRect(origin: CGPoint.zero, size: view.bounds.size)
        let paths: [UIBezierPath] = [
            UIBezierPath(), UIBezierPath(), UIBezierPath(), UIBezierPath()
        ]
        let cornerLength: CGFloat = min(overlayRect.height, overlayRect.width) / 4
        let cornerRadius: CGFloat = 12
        paths[0].move(to: CGPoint(x: overlayRect.minX, y: overlayRect.minY + cornerLength))
        paths[0].addLine(to: CGPoint(x: overlayRect.minX, y: overlayRect.minY + cornerRadius))
        paths[0].addArc(withCenter: CGPoint(x: overlayRect.minX + cornerRadius, y: overlayRect.minY + cornerRadius), radius: cornerRadius, startAngle: 0 - CGFloat.pi, endAngle: 0 - CGFloat.pi / 2, clockwise: true)
        paths[0].addLine(to: CGPoint(x: overlayRect.minX + cornerLength, y: overlayRect.minY))
        paths[1].move(to: CGPoint(x: overlayRect.maxX - cornerLength, y: overlayRect.minY))
        paths[1].addLine(to: CGPoint(x: overlayRect.maxX - cornerRadius, y: overlayRect.minY))
        paths[1].addArc(withCenter: CGPoint(x: overlayRect.maxX - cornerRadius, y: overlayRect.minY + cornerRadius), radius: cornerRadius, startAngle: 0 - CGFloat.pi / 2, endAngle: 0, clockwise: true)
        paths[1].addLine(to: CGPoint(x: overlayRect.maxX, y: overlayRect.minY + cornerLength))
        paths[2].move(to: CGPoint(x: overlayRect.maxX, y: overlayRect.maxY - cornerLength))
        paths[2].addLine(to: CGPoint(x: overlayRect.maxX, y: overlayRect.maxY - cornerRadius))
        paths[2].addArc(withCenter: CGPoint(x: overlayRect.maxX - cornerRadius, y: overlayRect.maxY - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
        paths[2].addLine(to: CGPoint(x: overlayRect.maxX - cornerLength, y: overlayRect.maxY))
        paths[3].move(to: CGPoint(x: overlayRect.minX + cornerLength, y: overlayRect.maxY))
        paths[3].addLine(to: CGPoint(x: overlayRect.minX + cornerRadius, y: overlayRect.maxY))
        paths[3].addArc(withCenter: CGPoint(x: overlayRect.minX + cornerRadius, y: overlayRect.maxY - cornerRadius), radius: cornerRadius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi, clockwise: true)
        paths[3].addLine(to: CGPoint(x: overlayRect.minX, y: overlayRect.maxY - cornerLength))
        for i in 0..<paths.count {
            let cardOverlayLayer = CAShapeLayer()
            cardOverlayLayer.path = paths[i].cgPath
            cardOverlayLayer.fillColor = nil
            cardOverlayLayer.strokeColor = corners[i] ? UIColor.green.cgColor : UIColor.white.cgColor
            cardOverlayLayer.lineWidth = 6
            cardOverlayLayer.lineCap = CAShapeLayerLineCap.round
            view.layer.addSublayer(cardOverlayLayer)
        }
    }
    
    func drawCardOverlay() {
        while let sub = self.cardOverlayView.layer.sublayers?.first {
            sub.removeFromSuperlayer()
        }
        self.drawCorners(self.detectedCorners, in: self.cardOverlayView)
    }
    
    func dewarpImage(_ image: CGImage, withParams params: [String:CIVector]) -> CGImage? {
        let ciImage = CIImage(cgImage: image).applyingFilter("CIPerspectiveCorrection", parameters: params)
        return CIContext().createCGImage(ciImage, from: ciImage.extent)
    }
    
    override func brightnessHandler(brightnessDegree: Float) {
        if brightnessDegree < 70.0 {
            DispatchQueue.main.async {
                self.showLabelWithText(text: Keys.Localizations.needMoreLight)
            }
        }else {
            self.showLabelWithText(text: latestVisibleText)
        }
    }
    
    // Helper function to calculate area of a quadrilateral
    private func calculateQuadrilateralArea(points: [CGPoint]) -> CGFloat {
        guard points.count == 4 else { return 0 }
        
        // Using the shoelace formula (also known as surveyor's formula)
        let x = points.map { $0.x }
        let y = points.map { $0.y }
        
        var area: CGFloat = 0
        for i in 0..<4 {
            let nextIndex = (i + 1) % 4
            area += x[i] * y[nextIndex]
            area -= y[i] * x[nextIndex]
        }
        
        return abs(area) / 2
    }
    
    private func calculateIOU(expectedCorners: [CGPoint], detectedCorners: [CGPoint]) -> CGFloat {
        // Convert corners to CGRect (bounding box)
        let expectedRect = boundingBox(from: expectedCorners)
        let detectedRect = boundingBox(from: detectedCorners)
        
        // Calculate intersection
        let intersection = expectedRect.intersection(detectedRect)
        
        // Calculate areas
        let intersectionArea = intersection.width * intersection.height
        let expectedArea = expectedRect.width * expectedRect.height
        let detectedArea = detectedRect.width * detectedRect.height
        
        // Calculate union
        let unionArea = expectedArea + detectedArea - intersectionArea
        
        // Calculate IOU
        let iou = intersectionArea / unionArea
        
        return iou
    }

    private func boundingBox(from corners: [CGPoint]) -> CGRect {
        let xCoordinates = corners.map { $0.x }
        let yCoordinates = corners.map { $0.y }
        
        let minX = xCoordinates.min() ?? 0
        let maxX = xCoordinates.max() ?? 0
        let minY = yCoordinates.min() ?? 0
        let maxY = yCoordinates.max() ?? 0
        
        return CGRect(x: minX,
                     y: minY,
                     width: maxX - minX,
                     height: maxY - minY)
    }
    override func sessionHandler(_ handler: ObjectDetectionSessionHandler, didDetectCardInImage image: CGImage, withTopLeftCorner topLeftCorner: CGPoint, topRightCorner: CGPoint, bottomRightCorner: CGPoint, bottomLeftCorner: CGPoint, perspectiveCorrectionParams: [String:CIVector], sharpness: Float?, brightnessLevel: Float?, rect: VNRectangleObservation?) {
//        drawDetectedRactangles(rect: rect)
//        brightnessHandler(brightnessDegree: brightnessLevel!)
        let imageSize = CGSize(width: image.width, height: image.height)
        let expected = self.expectedCorners(inSize: imageSize)
        let maxDistance: CGFloat = (expected[3].y - expected[0].y) / 7
        let detected: [CGPoint] = [
            topLeftCorner, topRightCorner, bottomRightCorner, bottomLeftCorner
        ]
        
//        self.drawDetectedRectangle(topLeft: topLeftCorner, topRight: topRightCorner, bottomRight: bottomRightCorner, bottomLeft: bottomLeftCorner)
        
        // Calculate IOU
        let iou = calculateIOU(expectedCorners: expected, detectedCorners: detected)
        
        
        if iou < 0.4 {
            showLabelWithText(text: Keys.Localizations.centerYourDocument)
        } else if iou > 0.4 && iou <= 0.8 {
            showLabelWithText(text: Keys.Localizations.moveCloser)
        }
        
        // Update detection status
        self.detectedCorners = [false, false, false, false]
        
        for pt in expected {
            /// get the first index from the detected corners and check the straight line between the detected corner and the expected corner
            if let index = detected.firstIndex(where: { hypot($0.x - pt.x, $0.y - pt.y) < maxDistance }) {
                /// if the distance is ok return true for that corner
                self.detectedCorners[index] = true
            }
        }
        
        // Update UI
        self.drawCardOverlay()
        
        /// check if the all the corners are valid
        if self.detectedCorners.reduce(true, { $0 ? $1 : false }) {
            showLabelWithText(text: Keys.Localizations.holdStill)
            // All corners detected
            let originalPrompt = self.navigationItem.prompt
            if self.backgroundOperationQueue.isSuspended || self.backgroundOperationQueue.operationCount > 0 {
                return
            }
            self.backgroundOperationQueue.addOperation { [weak self] in
                guard let `self` = self else {
                    return
                }
                /// extracting the card image from the main image in dewrapedImage variable
                guard let dewarpedImage = self.dewarpImage(image, withParams: perspectiveCorrectionParams) else {
                    self.collectedImages = []
                    DispatchQueue.main.async {
                        self.navigationItem.prompt = originalPrompt
                        self.cardOverlayView.isHidden = false
                        self.cameraPreview.isHidden = false
                    }
                    return
                }
                if let quality = self.qualityOfImage(dewarpedImage) {
                    self.collectedImages.append((dewarpedImage,quality))
                } else if let quality = sharpness {
                    self.collectedImages.append((dewarpedImage,quality))
                } else {
                    self.backgroundOperationQueue.isSuspended = true
                    self.didCropImageToImage(dewarpedImage)
                    return
                }
                if self.collectedImages.count >= self.imagePoolSize {
                    self.collectedImages.sort(by: { $0.1 > $1.1 })
                    guard let (image, _) = self.collectedImages.first else {
                        return
                    }
                    self.backgroundOperationQueue.isSuspended = true
                    self.didCropImageToImage(image)
                }
            }
        } else {
            self.collectedImages = []
        }
    }

    
    override func shouldDetectCardImageWithSessionHandler(_ handler: ObjectDetectionSessionHandler) -> Bool {
        return !self.backgroundOperationQueue.isSuspended && self.backgroundOperationQueue.operationCount == 0
    }
    
    func showLabelWithText(text: String){
        self.latestVisibleText = text
        DispatchQueue.main.async {
            self.label.text = text
            self.view.addSubview(self.lblView)
            // Add constraints to center the label inside the view
            NSLayoutConstraint.activate([
                self.lblView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.lblView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                self.lblView.heightAnchor.constraint(equalToConstant: 60),
            ])
        }
    }
    
    func removeLbl(){
        DispatchQueue.main.async {
            self.lblView.removeFromSuperview()
        }
    }
    
    // MARK: - Adaptive presentation controller delegate
    
    public override func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.collectedImages = []
        self.delegateCancel()
    }
}
