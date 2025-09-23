#
# Be sure to run `pod lib lint AppsOnAir-Core.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AppsOnAir-Core'
  s.version          = '1.1.1'
  s.summary          = 'AppsOnAir Core'

  s.description      = "AppsOnAir Core provide central configuration for other AppsOnAir services."

  s.homepage         = 'https://documentation.appsonair.com/MobileQuickstart/GettingStarted'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'devtools-logicwind' => 'devtools@logicwind.com' }
  s.source           = { :git => 'https://github.com/apps-on-air/AppsOnAir-iOS-Core.git', :tag => s.version.to_s }

  s.swift_version  = '5.0'
  s.ios.deployment_target = '12.0'

  s.source_files = 'AppsOnAir-Core/**/*.{swift,h,m}'
  s.resource_bundles = {
      'AppsOnAir-Core' => ['AppsOnAir-Core/Resources/**/*']
  }
  # Network connectivity pod
  s.dependency 'ReachabilitySwift', '5.2.4'
end
