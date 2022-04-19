//
//  SmartViewService.h
//  ConnectSDK
//
//  Created by Vital on 3.03.21.
//  Copyright © 2021 LG Electronics. All rights reserved.
//

#define kConnectSDKSmartViewServiceId @"SmartView"

#import "ConnectSDK.h"
#import "VolumeControl.h"
#import "MediaControl.h"
#import "MediaPlayer.h"

@class AppStateChangeNotifier;
@interface SmartViewService : DeviceService <MediaPlayer, MediaControl, VolumeControl, Launcher>

/// An @c AppStateChangeNotifier that allows to track app state changes.
@property (nonatomic, readonly) AppStateChangeNotifier * _Nullable appStateChangeNotifier;

/// Initializes the instance with the given @c AppStateChangeNotifier. Using
/// @c nil parameter will create real object.
- (instancetype)initWithAppStateChangeNotifier:(nullable AppStateChangeNotifier *)stateNotifier;

@end
 
