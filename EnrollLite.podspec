Pod::Spec.new do |s|
  s.name             = "EnrollLite"
  s.version          = "1.0.0"
  s.summary          = "An SDK for document, face, and passport detection."
  s.description      = "DESC
                       EnrollLite is a custom SDK that provides various detection functionalities including document, face, and passport detection, utilizing Google ML Kit's Face Detection.
                       DESC"
  s.homepage         = "https://example.com/enrolllite" # Replace with your SDK's homepage URL
  s.license          = { :type => "MIT"} # Adjust as needed
  s.author           = { "Bahi Elfeky" => "bahi.elfeky1@gmail.com" }
  s.platform         = :ios, "12.0" # Set minimum iOS version as required
  s.source           = { :path => "./" } # Local path, since we are using it locally
  s.static_framework = true
  
  # Specify the source files
  s.source_files = "**/*.{swift,h}"

  # Specify dependencies
  s.dependency "GoogleMLKit/FaceDetection"

  # Frameworks and libraries your SDK depends on
  s.ios.frameworks   = ["UIKit", "CoreGraphics", "AVFoundation"]

  # For Swift compatibility
  s.swift_version    = "5.0" # Specify the Swift version as needed

  # Resources if there are assets (optional)
  # s.resource_bundles = {
  #   'EnrollLiteResources' => ['EnrollLite/Resources/**/*']
  # }
end
