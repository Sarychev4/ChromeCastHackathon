# Uncomment the next line to define a global platform for your project
#platform :ios, '9.0'
inhibit_all_warnings!

def common_pods_for_target  
  pod 'CocoaAsyncSocket' 
  pod 'Criollo', :git => 'git@github.com:mirroringcontact/Criollo.git'
  pod 'CSSystemInfoHelper', '~> 2.0'
  pod "GCDWebServer"
  pod 'GPhotos', :git => 'https://github.com/deivitaka/GPhotos.git'
end

target 'MirroringExtension' do
  use_frameworks!
  common_pods_for_target
  pod 'RealmSwift'
end


target 'ChromecastIOS' do
  use_frameworks!
  common_pods_for_target
  pod 'AdvancedPageControl'
  pod 'Agregator', :git => 'git@github.com:mirroringcontact/common.git'
#  pod 'Player'
  pod 'Alamofire'
  pod 'Kingfisher'
  pod 'ReachabilitySwift'
  pod "NextLevelSessionExporter", "~> 0.4.5"
  pod 'google-cast-sdk-no-bluetooth'
  pod 'LNZCollectionLayouts'
  pod 'XCDYouTubeKit-kbexdev', :git => 'https://github.com/kbex-dev/XCDYouTubeKit.git'
  pod 'IndicateKit', '~> 1.0.5'
  pod 'lottie-ios'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Messaging'
  pod 'GoogleAPIClientForREST/Drive'#, '~> 1.2.1'
  pod 'GoogleSignIn'#, '~> 4.1.1'
  pod "NextLevelSessionExporter", "~> 0.4.5"
  pod 'ZMJTipView'
end 

 post_install do |installer_representation|
   installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
            config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
        end
  end
 end
