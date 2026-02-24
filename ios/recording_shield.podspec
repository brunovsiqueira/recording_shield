#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint recording_shield.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'recording_shield'
  s.version          = '0.1.0'
  s.summary          = 'Screen recording detection and overlay masking for Flutter.'
  s.description      = <<-DESC
A Flutter plugin that detects screen recording in real-time and dynamically overlays visual masks on sensitive widgets.
                       DESC
  s.homepage         = 'https://github.com/brunovsiqueira/recording_shield'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Bruno Siqueira' => 'brunovsiqueira@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
