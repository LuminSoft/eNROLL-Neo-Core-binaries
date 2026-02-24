Pod::Spec.new do |s|
  s.name             = "EnrollNeoCore"
  s.version          = "1.0.1"
  s.summary          = "An internally developed identity verification SDK for to be used in eNROLL framework."
  s.description      = "DESC
                       EnrollCoreFramework is a custom SDK that provides various detection functionalities including document, face, and passport detection.
                       DESC"
  s.homepage         = "https://github.com/LuminSoft/eNROLL-Neo-Core-binaries" 
  s.license          = { :type => 'MIT', :file => 'LICENSE' } # Adjust as needed
  s.author           = { "Lumia Soft" => "Mariam.ismail@luminsoft.com" }
  s.platform         = :ios, "13.0" # Set minimum iOS version as required
  s.source           = { :git => 'https://github.com/LuminSoft/eNROLL-Neo-Core-binaries.git', :tag => s.version.to_s }
 
  
  # Specify the source files

   #s.source_files = "EnrollLite/**/*.{swift,h}"

  # s.resource_bundles = {
  #  'EnrollLiteFrameworkResources' => [
  #    'EnrollLite/**/*.xcassets',
  #    'EnrollLite/**/*.storyboard',
   #   'EnrollLite/**/*.ttf',
   #   'EnrollLite/**/*.otf',
   #   'EnrollLite/**/*.json',
   #   'EnrollLite/**/*.svg',
    #  'EnrollLite/**/*.xib',
   #   'EnrollLite/**/*.strings'
  #  ]
 #}
 #
    
  # Specify dependencies
  s.ios.deployment_target = '13.0'
  s.platform     = :ios, '13.0'
  s.vendored_frameworks = s.version.to_s + "/EnrollNeoCore.xcframework"
  s.dependency "GoogleMLKit/FaceDetection"
  s.dependency "lottie-ios"
  #s.static_framework = true
  #s.public_header_files = 'EnrollLite/**/*.h'

  # Frameworks and libraries your SDK depends on
  #s.ios.frameworks   = ["UIKit", "Vision"]


  # For Swift compatibility
  #s.swift_version    = "5.0" # Specify the Swift version as needed

end
