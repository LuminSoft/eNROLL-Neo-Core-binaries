//
//  PassportDetectionViewController.swift
//  EnrollLite
//
//  Created by Bahi El Feky on 10/11/2024.
//

import UIKit
import VisionKit


protocol PassportDetectionDelegate {
    func passportDetectionViewController(didFinishWith image: UIImage)
    func passportDetectionViewController(didFailWithError error: Error)
    func passportDetectionViewControllerDidCancelled()
}

class PassportDetectionViewController: UIViewController {
//    @IBOutlet private var imageView: UIImageView!
    
    var delegate: PassportDetectionDelegate?
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        present(scanner, animated: true)
    }

    // MARK: - Action
//    @IBAction private func tapped(scan button: UIButton) {
//        
//    }
    
}

extension PassportDetectionViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            let image = scan.imageOfPage(at: 0)
            strongSelf.delegate?.passportDetectionViewController(didFinishWith: image)
            strongSelf.dismiss(animated: false)

//            UIAlertController.present(title: "Success!", message: "Document \(scan.title) scanned with \(scan.pageCount) pages.", on: strongSelf)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
//            self?.imageView.image = nil
            
            guard let strongSelf = self else { return }
            strongSelf.delegate?.passportDetectionViewControllerDidCancelled()
            strongSelf.dismiss(animated: false)
//            UIAlertController.present(title: "Cancelled", message: "User cancelled operation.", on: strongSelf)
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true) { [weak self] in
//            self?.imageView.image = nil
            
            guard let strongSelf = self else { return }
            strongSelf.delegate?.passportDetectionViewController(didFailWithError: error)
            strongSelf.dismiss(animated: false)
//            UIAlertController.present(title: "Error", message: error.localizedDescription, on: strongSelf)
        }
    }
}

extension UIAlertController {
    static func present(title: String?, message: String?, on viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "OK", style: .default)
        alert.addAction(confirm)
        viewController.present(alert, animated: true)
    }
}
