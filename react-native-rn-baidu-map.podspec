#
#  Be sure to run `pod spec lint react-native-baidu-map.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "react-native-rn-baidu-map"
  s.version      = "1.0.2"
  s.summary      = "Baidu Map for React Native"

  s.description  = <<-DESC
  Baidu Map views and modules for React Native
                   DESC

  s.homepage     = "https://github.com/shijinwu/react-native-rn-baidu-map"

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "lovebing" => "tangyangjian@gmail.com" }
  # s.authors            = { "lovebing" => "tangyangjian@gmail.com" }
  # s.social_media_url   = "https://github.com/lovebing"

  s.platform     = :ios, "9.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source          = { :git => "https://github.com/shijinwu/react-native-rn-baidu-map.git",:tag => 'v1.0.2’}

  s.source_files  = "ios/RCTBaiduMap/**/*.{h,m}"
  s.exclude_files = ""

  # s.public_header_files = "**/*.h"

  s.frameworks = "CoreLocation", "QuartzCore", "OpenGLES", "SystemConfiguration", "CoreGraphics", "Security", "CoreTelephony"
  s.static_framework = true
  s.libraries = "c++", "sqlite3", "ssl", "crypto"

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "React"
  s.dependency 'BaiduMapKit', '6.1.0.'
  s.dependency 'BMKLocationKit', '1.3.0.2'
end
