Pod::Spec.new do |s|
  s.name             = "EnrollNeoCore"
  s.version          = "1.0.14"
  s.summary          = "An internally developed identity verification SDK for to be used in eNROLL framework."
  s.description      = "EnrollCoreFramework is a custom SDK that provides various detection functionalities including document, face, and passport detection."
  s.homepage         = "https://github.com/LuminSoft/eNROLL-Neo-Core-binaries" 
  s.license          = { :type => 'MIT', :file => 'LICENSE' } # Adjust as needed
  s.author           = { "Lumia Soft" => "Mariam.ismail@luminsoft.com" }
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
  s.ios.deployment_target = '15.5'
  s.platform     = :ios, '15.5'
  s.vendored_frameworks = s.version.to_s + "/EnrollLite.xcframework"
  
 # Prevent CocoaPods from checking for simulator slices
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 x86_64'
  }


  s.static_framework = true

  #s.public_header_files = 'EnrollLite/**/*.h'

  # Frameworks and libraries your SDK depends on
  #s.ios.frameworks   = ["UIKit", "Vision"]
  s.dependency "GoogleMLKit/FaceDetection"
  s.dependency "lottie-ios"
  s.dependency "QKMRZScanner"

  # For Swift compatibility
  #s.swift_version    = "5.0" # Specify the Swift version as needed


end
