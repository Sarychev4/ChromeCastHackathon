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
  pod 'Starscream', '~> 4.0.4'
end

target 'Chromecast' do

  platform :ios, '10.0'
  use_frameworks!
  common_pods_for_target
  pod 'Starscream', '~> 4.0.4'
  pod 'GPhotos', :git => 'https://github.com/deivitaka/GPhotos.git'
  pod 'AdvancedPageControl'
  pod 'Kingfisher'
  pod 'ReachabilitySwift'
  pod "NextLevelSessionExporter", "~> 0.4.5"
  pod 'google-cast-sdk-no-bluetooth'
  pod 'LNZCollectionLayouts'
  pod 'XCDYouTubeKit-kbexdev', :git => 'https://github.com/kbex-dev/XCDYouTubeKit.git'
 # pod 'IndicateKit', '~> 1.0.5'
  pod 'MBProgressHUD'
  pod 'lottie-ios'
  pod 'GoogleAPIClientForREST/Drive'
  pod 'GoogleSignIn'
  pod "NextLevelSessionExporter", "~> 0.4.5"
  pod 'ZMJTipView'
  pod 'DeviceKit'
#  pod 'ffmpeg-kit-ios-min'
#pod 'ffmpeg-kit-ios-https-gpl'
end 

 post_install do |installer_representation|
   installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
            config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
            if config.build_settings['WRAPPER_EXTENSION'] == 'bundle'
                config.build_settings['DEVELOPMENT_TEAM'] = 'C2HGX78UB7'
            end
        end
  end
 end
