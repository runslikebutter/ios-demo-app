# Uncomment the next line to define a global platform for your project
# platform :ios, '10.0'

target 'ButterflyMX Demo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ButterflyMX Demo
  pod 'BMXCore', '~> 2.0.0'
  pod 'BMXCall', '~> 1.0.16'
  pod 'Japx/CodableAlamofire', :git => 'https://github.com/runslikebutter/Japx'
  pod 'SVProgressHUD'
  pod 'TwilioVideo', '~> 4.4'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      if ['BMXCall', 'BMXCore', 'Alamofire', 'Japx', 'OAuthSwift'].include? target.name
        target.build_configurations.each do |config|
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
            config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64 i386'
        end
      end
    end
end
