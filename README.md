# EnrollLite Framework Integration Guide

Welcome to the **EnrollLite Framework** integration guide. This document provides step-by-step instructions on how to integrate and use the EnrollLite framework in your iOS project. Follow these guidelines to get started quickly and effectively.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Initialization](#initialization)
4. [Usage](#usage)
   - [Passport Detection](#passport-detection)
   - [Card Detection](#card-detection)
   - [Face Detection](#face-detection)
   - [Smile Liveness Detection](#smile-liveness-detection)
5. [Delegate Callbacks](#delegate-callbacks)
6. [Error Handling](#error-handling)
7. [Support](#support)

---

## Requirements

- iOS 15.0 or later
- Xcode 15.2 or later
- Swift 5.0 or later

---

## Installation

1. Add the **EnrollLite** framework to your project:
   - Download the latest version of the framework from [EnrollLite Releases](https://example.com/enrolllite-download).
   - Drag and drop the `EnrollLite.framework` into your Xcode project.
   - Ensure the framework is added to the **Frameworks, Libraries, and Embedded Content** section.

2. Add the following dependency to your Podfile:

   ```ruby
   pod 'GoogleMLKit/FaceDetection'
   ```

   Then, run:

   ```bash
   pod install
   ```

3. Change **User Script Sandboxing** in your project settings:
   - Go to your project's **Build Settings**.
   - Search for "User Script Sandboxing".
   - Set the value to **No**.

4. Import the framework in your files where needed:

   ```swift
   import EnrollLite
   ```

---

## Initialization

1. Place the license file (`license.lic`) in your app bundle.
2. Verify the license during app initialization:

   ```swift
   do {
       try EnrollLiteVerifier.verifyEnrollLiteLicense(resourceName: "license", withExtension: "lic", bundle: Bundle.main)
   } catch let error as EnrollLiteError {
       print(error.message)
   } catch {
       print(error.localizedDescription)
   }
   ```

---

## Usage

### Passport Detection

1. Implement the `PassportDetectionDelegate`:

   ```swift
   extension ViewController: PassportDetectionDelegate {
       func passportDetectionDidCancel() {
           // Handle cancellation
       }

       func passportDetectionDidSucceed(with model: PassportDetectionSuccessModel) {
           // Handle success
           presentImageVC(image: model.image)
       }

       func passportDetectionDidFail(withError error: PassportDetectionErrorModel) {
           // Handle error
       }
   }
   ```

2. Start passport detection:

   ```swift
   do {
       let manager = try PassportDetectionManager(delegate: self)
       manager.startPassportDetection(from: self)
   } catch let error as EnrollLiteError {
       print(error.message)
   } catch {
       print(error.localizedDescription)
   }
   ```

### Card Detection

1. Implement the `CardDetectionDelegate`:

   ```swift
   extension ViewController: CardDetectionDelegate {
       func cardDetectionSuccess(with model: CardDetectionSuccessModel) {
           // Handle success
           presentImageVC(image: model.image)
       }
   }
   ```

2. Start card detection:

   ```swift
   do {
       let manager = try CardDetectionManager(delegate: self)
       manager.startCardDetection(from: self)
   } catch let error as EnrollLiteError {
       print(error.message)
   } catch {
       print(error.localizedDescription)
   }
   ```

### Face Detection

1. Implement the `FaceDetectionDelegate`:

   ```swift
   extension ViewController: FaceDetectionDelegate {
       func faceDectionSucceed(with model: FaceDetectionSuccessModel) {
           // Handle success
           presentImageVC(image: model.naturalImage, secondImage: model.smileImage)
       }

       func faceDetectionFail(withError error: FaceDetectionErrorModel) {
           // Handle error
       }
   }
   ```

2. Start face detection:

   ```swift
   do {
       let manager = try FaceDetectionManager(delegate: self)
       manager.startFaceDetection(from: self)
   } catch let error as EnrollLiteError {
       print(error.message)
   } catch {
       print(error.localizedDescription)
   }
   ```

### Smile Liveness Detection

1. Enable smile liveness detection during initialization:

   ```swift
   do {
       let manager = try FaceDetectionManager(delegate: self, withSmileLiveness: true)
       manager.startFaceDetection(from: self)
   } catch let error as EnrollLiteError {
       print(error.message)
   } catch {
       print(error.localizedDescription)
   }
   ```

---

## Delegate Callbacks

Each detection module in EnrollLite uses delegate methods to return results:

### Passport Detection
- `passportDetectionDidCancel()`
- `passportDetectionDidSucceed(with model: PassportDetectionSuccessModel)`
- `passportDetectionDidFail(withError error: PassportDetectionErrorModel)`

### Card Detection
- `cardDetectionSuccess(with model: CardDetectionSuccessModel)`

### Face Detection
- `faceDectionSucceed(with model: FaceDetectionSuccessModel)`
- `faceDetectionFail(withError error: FaceDetectionErrorModel)`

---

## Error Handling

EnrollLite uses structured error handling to manage issues during detection:

1. Catch `EnrollLiteError` for license verification and detection issues:

   ```swift
   catch let error as EnrollLiteError {
       print(error.message)
   }
   ```

2. Handle other errors:

   ```swift
   catch {
       print(error.localizedDescription)
   }
   ```

---

## Support

For further assistance, please contact our support team or refer to our [documentation](https://example.com/enrolllite-docs).
