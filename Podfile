# Uncomment the next line to define a global platform for your project
#platform :ios, '9.0'
inhibit_all_warnings!

def common_pods_for_target
  pod 'CSSystemInfoHelper', '~> 2.0'
  pod "GCDWebServer", :git => 'git@github.com:Sarychev4/GCDWebServer.git'
end

target 'MirroringExtension' do
  use_frameworks!
  common_pods_for_target
  pod 'RealmSwift'
end

target 'Chromecast iOS' do
  use_frameworks!
  common_pods_for_target
  pod 'GPhotos', :git => 'https://github.com/deivitaka/GPhotos.git'
  pod 'AdvancedPageControl'
  pod 'Agregator', :git => 'git@github.com:mirroringcontact/common.git'
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
  pod 'GoogleAPIClientForREST/Drive'
  pod 'GoogleSignIn'
  pod "NextLevelSessionExporter", "~> 0.4.5"
  pod 'ZMJTipView'
  pod 'ffmpeg-kit-ios-min'
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
