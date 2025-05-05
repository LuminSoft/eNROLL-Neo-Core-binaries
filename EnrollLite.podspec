Pod::Spec.new do |s|
  s.name             = "EnrollLite"
  s.version          = "1.0.0"
  s.summary          = "An SDK for document, face, and passport detection."
  s.description      = "DESC
                       EnrollLite is a custom SDK that provides various detection functionalities including document, face, and passport detection, utilizing Google ML Kit's Face Detection.
                       DESC"
  s.homepage         = "https://github.com/mariam-lumin/EnrollLite.git" 
  s.license          = { :type => 'MIT', :file => 'LICENSE' } # Adjust as needed
  s.author           = { "Lumia Soft" => "Mariam.ismail@lumminsoft.com" }
  s.platform         = :ios, "13.0" # Set minimum iOS version as required
  s.source           = { :git => 'https://github.com/mariam-lumin/EnrollLite.git', :tag => s.version.to_s }
 
  
  # Specify the source files

   s.source_files = "EnrollLite/**/*.{swift,h}"
   s.resources  = [
      'EnrollLite/**/*.xcassets',
      'EnrollLite/**/*.storyboard',
      'EnrollLite/**/*.ttf',
      'EnrollLite/**/*.otf',
      'EnrollLite/**/*.json',
      'EnrollLite/**/*.svg',
      'EnrollLite/**/*.xib'
    ]
 
    
  # Specify dependencies
  s.dependency "GoogleMLKit/FaceDetection"
  s.static_framework = true
  s.public_header_files = 'EnrollLite/**/*.h'

  # Frameworks and libraries your SDK depends on
  #s.ios.frameworks   = ["UIKit", "Vision"]


  # For Swift compatibility
  s.swift_version    = "5.0" # Specify the Swift version as needed

end
