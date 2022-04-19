//
//  CastService.m
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <GoogleCast/GoogleCast.h>
#import "CastServiceDiscoveryProvider.h"
#import "CastService_Private.h"
#import "PingOperation.h"
#import "ConnectError.h"
#import "CastWebAppSession.h"
#import "SubtitleInfo.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "DiscoveryManager.h"
#import "NSObject+FeatureNotSupported_Private.h"
#import "NSMutableDictionary+NilSafe.h"
#import "DeviceServiceReachability.h"
#import <ScreenMirroring-Swift.h>

#define kCastServiceMuteSubscriptionName @"mute"
#define kCastServiceVolumeSubscriptionName @"volume"

static const NSInteger kSubtitleTrackIdentifier = 42;

static NSString *const kSubtitleTrackDefaultLanguage = @"en";

@interface CastService () <ServiceCommandDelegate, GCKUIMediaControllerDelegate, DeviceServiceReachabilityDelegate, GCKSessionManagerListener, GCKRemoteMediaClientListener, GCKRequestDelegate, WebAppSessionDelegate>

@property (nonatomic, strong) MediaPlayStateSuccessBlock immediatePlayStateCallback;
@property (nonatomic, strong) ServiceSubscription *playStateSubscription;
@property (nonatomic, strong) ServiceSubscription *mediaInfoSubscription;

@end

@implementation CastService {
    int UID;

    NSString *_currentAppId;
    NSString *_launchingAppId;

    NSMutableDictionary *_launchSuccessBlocks;
    NSMutableDictionary *_launchFailureBlocks;
    
    NSMutableArray *_subscriptions;

    float _currentVolumeLevel;
    BOOL _currentMuteStatus;
    int _connectRetryCount;
    
    DeviceServiceReachability *_serviceReachability;
}
@synthesize castServiceChannel = _castServiceChannel;

- (void) commonSetup {
    _launchSuccessBlocks = [NSMutableDictionary new];
    _launchFailureBlocks = [NSMutableDictionary new];
    _connectRetryCount = 0;
    _subscriptions = [NSMutableArray new];

    UID = 0;
    
    __weak typeof(self) wself = self;
    
    _appStateChangeNotifier = [AppStateChangeNotifier new];
    _appStateChangeNotifier.didBackgroundBlock = ^{
//        typeof(self) sself = wself;
        // using an ivar here in order not to init the property if it's nil
        typeof(self) sself = wself;
        [sself disconnect:nil];
    };
    
    _appStateChangeNotifier.didForegroundBlock = ^{
        typeof(self) sself = wself;
        GCKSessionManager *sessionManager = GCKCastContext.sharedInstance.sessionManager;
        if ([sessionManager hasConnectedSession]) {
            [sself sessionManager:sessionManager didStartCastSession:sself.castSession];
            return;
        }
    };
}

- (instancetype) init {
    self = [super init];

    if (self)
        [self commonSetup];

    return self;
}

- (instancetype)initWithServiceConfig:(ServiceConfig *)serviceConfig {
    self = [super initWithServiceConfig:serviceConfig];

    if (self)
        [self commonSetup];

    return self;
}

+ (NSDictionary *) discoveryParameters {
    return @{
             @"serviceId":kConnectSDKCastServiceId
             };
}

- (BOOL)isConnectable {
    return YES;
}

- (void) updateCapabilities {
    NSArray *capabilities = [NSArray new];

    capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:@[
            kMediaPlayerSubtitleWebVTT,

            kMediaControlPlay,
            kMediaControlPause,
            kMediaControlStop,
            kMediaControlDuration,
            kMediaControlSeek,
            kMediaControlPosition,
            kMediaControlPlayState,
            kMediaControlPlayStateSubscribe,
            kMediaControlMetadata,
            kMediaControlMetadataSubscribe,

            kWebAppLauncherLaunch,
            kWebAppLauncherMessageSend,
            kWebAppLauncherMessageReceive,
            kWebAppLauncherMessageSendJSON,
            kWebAppLauncherMessageReceiveJSON,
            kWebAppLauncherConnect,
            kWebAppLauncherDisconnect,
            kWebAppLauncherJoin,
            kWebAppLauncherClose
    ]];

    [self setCapabilities:capabilities];
}

- (void)setServiceDescription:(ServiceDescription *)serviceDescription {
    [super setServiceDescription:serviceDescription];
    
    if (!_serviceReachability) {
//        NSURL *url = [[NSURL alloc] initWithString:self.serviceDescription.address];
//        _serviceReachability = [DeviceServiceReachability reachabilityWithTargetURL:url];
//        _serviceReachability.delegate = self;
//        [_serviceReachability start];
    }
}

-(NSString *)castWebAppId {
    if (_castWebAppId == nil) {
        _castWebAppId = [ChromecastWebApp idToObjc];
    }
    return _castWebAppId;
}

#pragma mark - Connection

- (void)connect {
    if (self.connected)
        return;
    
    [self.appStateChangeNotifier startListening];
    
    GCKSessionManager *sessionManager = GCKCastContext.sharedInstance.sessionManager;
    [sessionManager addListener:self];
  
    if ([sessionManager hasConnectedSession]) {
        [self sessionManager:sessionManager didStartCastSession:self.castSession];
        return;
    }
    
    if (self.serviceDescription.device) {
        [sessionManager startSessionWithDevice:self.serviceDescription.device];
    }
}

- (void)disconnect:(NSError *)error {
    if (!self.connected)
        return;

    [self.appStateChangeNotifier stopListening];
    
    [self.castSession removeChannel:self.castServiceChannel];
    self.connected = NO;
 
    [self.castSession endWithAction:GCKSessionEndActionLeave];
    
    [_serviceReachability stop];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}
 
- (void)checkReachability {
//    [_serviceReachability checkReachability];
}

- (void)didLoseReachability:(DeviceServiceReachability *)reachability {
    if (self.connected) {
        [self disconnect:CONNECT_SDK_REACHABILITY_ERROR];
    }
    else {
        [_serviceReachability stop];
        [self.castSession removeChannel:self.castServiceChannel];
//        [DiscoveryManager.sharedManager discoveryProvider:nil didLoseService:self.serviceDescription];
    }
}

#pragma mark - GCKRemoteMediaClientListener
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus {
//    MediaControlPlayState playState;
//    switch (mediaStatus.playerState) {
//        case GCKMediaPlayerStateIdle:
//            if (mediaStatus.idleReason == GCKMediaPlayerIdleReasonFinished)
//                playState = MediaControlPlayStateFinished;
//            else
//                playState = MediaControlPlayStateIdle;
//            break;
//
//        case GCKMediaPlayerStatePlaying:
//            playState = MediaControlPlayStatePlaying;
//            break;
//
//        case GCKMediaPlayerStatePaused:
//            playState = MediaControlPlayStatePaused;
//            break;
//
//        case GCKMediaPlayerStateBuffering:
//            playState = MediaControlPlayStateBuffering;
//            break;
//
//        case GCKMediaPlayerStateUnknown:
//        default:
//            playState = MediaControlPlayStateUnknown;
//    }
//
//    if (_immediatePlayStateCallback) {
//        _immediatePlayStateCallback(playState);
//        _immediatePlayStateCallback = nil;
//    }
//
//    if (_playStateSubscription) {
//        [_playStateSubscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger idx, BOOL *stop)
//        {
//            MediaPlayStateSuccessBlock mediaPlayStateSuccess = (MediaPlayStateSuccessBlock) success;
//
//            if (mediaPlayStateSuccess)
//                mediaPlayStateSuccess(playState);
//        }];
//    }
//
//    if (_mediaInfoSubscription) {
//        [_mediaInfoSubscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger idx, BOOL *stop)
//        {
//            SuccessBlock mediaInfoSuccess = (SuccessBlock) success;
//
//            if (mediaInfoSuccess){
//                mediaInfoSuccess([self metadataInfoFromMediaMetadata:self.remoteMediaClient
//                    .mediaStatus
//                    .mediaInformation
//                    .metadata]);
//            }
//        }];
//    }
}

- (void)remoteMediaClient:(GCKRemoteMediaClient *)client didStartMediaSessionWithID:(NSInteger)sessionID {
    
}

#pragma mark - GCKSessionManager
- (void)sessionManager:(GCKSessionManager *)sessionManager didStartCastSession:(GCKCastSession *)session {
    _connectRetryCount = 0;
    if (!self.castServiceChannel.isConnected) {
        [sessionManager.currentCastSession removeChannel:_castServiceChannel];
        _castServiceChannel = [[CastServiceChannel alloc] initWithAppId:self.castWebAppId session:self];
        [sessionManager.currentCastSession addChannel:_castServiceChannel];
    }
    
    if (self.connected)
        return;
    
    self.connected = YES;
    
    dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didFailToStartCastSession:(GCKCastSession *)session withError:(NSError *)error {
    if (_connectRetryCount == 0) {
        _connectRetryCount += 1;
        [self connect];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)]) {
            [self.delegate deviceService:self didFailConnectWithError:error];            
        }
    }
    NSLog(@">>> CastX didFailToStartCastSession: %@", error.localizedDescription);
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didSuspendCastSession:(GCKCastSession *)session withReason:(GCKConnectionSuspendReason)reason {
//    dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didEndCastSession:(GCKCastSession *)session withError:(NSError *)error {
    [self disconnect:error];
}
 
- (void)sessionManager:(GCKSessionManager *)sessionManager didResumeCastSession:(GCKCastSession *)session {
    
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didStartSession:(GCKSession *)session {
    NSLog(@">>> CastX didStartSession");
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didEndSession:(GCKSession *)session withError:(NSError *)error {
    NSLog(@">>> CastX didEndSession  withError: %@", error.localizedDescription);
    [self disconnect:error];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didSuspendSession:(GCKSession *)session withReason:(GCKConnectionSuspendReason)reason {
    NSLog(@">>> CastX didSuspendSession with reason");
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    NSLog(@">>> CastX didFailToStartSession: %@", error.localizedDescription);
}

#pragma mark - GCKRequestDelegate
- (void)requestDidComplete:(GCKRequest *)request {
    if ([_launchSuccessBlocks objectForKey:@(request.requestID)]) {
        SuccessBlock block = [_launchSuccessBlocks objectForKey:@(request.requestID)];
        
        LaunchSession *launchSession = [LaunchSession new];
        launchSession.sessionType = LaunchSessionTypeMedia;
        launchSession.service = self;
        MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];

        block(launchObject);
        [_launchSuccessBlocks removeObjectForKey:@(request.requestID)];
    }
}

- (void)request:(GCKRequest *)request didFailWithError:(GCKError *)error {
    if ([_launchFailureBlocks objectForKey:@(request.requestID)]) {
        SuccessBlock block = [_launchFailureBlocks objectForKey:@(request.requestID)];
        block(nil);
        [_launchFailureBlocks removeObjectForKey:@(request.requestID)];
    }
}

- (void)request:(GCKRequest *)request didAbortWithReason:(GCKRequestAbortReason)abortReason {
    
}
 
#pragma mark - Subscriptions

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId {
    if (type == ServiceSubscriptionTypeUnsubscribe) {
        if (subscription == _playStateSubscription) {
            _playStateSubscription = nil;
        } else if (subscription == _mediaInfoSubscription) {
            _mediaInfoSubscription = nil;
        } else {
            [_subscriptions removeObject:subscription];
        }
    } else if (type == ServiceSubscriptionTypeSubscribe) {
        [_subscriptions addObject:subscription];
    }
    
    return callId;
}

- (int) getNextId {
    UID = UID + 1;
    return UID;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager session:(GCKSession *)session didReceiveDeviceVolume:(float)volume muted:(BOOL)muted {
    DLog(@"volume: %f isMuted: %d", volume, muted);

    _currentVolumeLevel = volume;
    _currentMuteStatus = muted;

    [_subscriptions enumerateObjectsUsingBlock:^(ServiceSubscription *subscription, NSUInteger idx, BOOL *stop) {
        NSString *eventName = (NSString *) subscription.payload;

        if (eventName)
        {
            if ([eventName isEqualToString:kCastServiceVolumeSubscriptionName])
            {
                [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                {
                    VolumeSuccessBlock volumeSuccess = (VolumeSuccessBlock) success;

                    if (volumeSuccess)
                        dispatch_on_main(^{ volumeSuccess(volume); });
                }];
            }

            if ([eventName isEqualToString:kCastServiceMuteSubscriptionName])
            {
                [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                {
                    MuteSuccessBlock muteSuccess = (MuteSuccessBlock) success;

                    if (muteSuccess)
                        dispatch_on_main(^{ muteSuccess(muted); });
                }];
            }
        }
    }];
}

#pragma mark - Media Player

- (id<MediaPlayer>)mediaPlayer {
    return self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority {
    return CapabilityPriorityLevelHigh;
}

- (void) displayImageWithMediaInfo:(MediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure {
    if (self.castServiceChannel.isConnected) {
        GCKError *error;
        NSString *sendString = [self writeToJSON:@{@"type": mediaInfo.mimeType, @"url": mediaInfo.url.absoluteString}];
        [self.castServiceChannel sendTextMessage:sendString error:&error];
    } else {
        if (self.castSession.connectionState == GCKConnectionStateDisconnected) {
            [self connect];
        }
        [self.castSession removeChannel:_castServiceChannel];
        _castServiceChannel = [[CastServiceChannel alloc] initWithAppId:self.castWebAppId session:self];
        [self.castSession addChannel:_castServiceChannel];
    }
}

- (void) playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    GCKMediaMetadata *metaData = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
    [metaData setString:mediaInfo.title forKey:kGCKMetadataKeyTitle];
    [metaData setString:mediaInfo.description forKey:kGCKMetadataKeySubtitle];
    
    if (iconURL) {
        GCKImage *iconImage = [[GCKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }

    NSArray *mediaTracks;
    if (mediaInfo.subtitleInfo) {
        mediaTracks = @[
            [self mediaTrackFromSubtitleInfo:mediaInfo.subtitleInfo]];
    }
    
    GCKMediaInformationBuilder *mediaInfoBuilder = [[GCKMediaInformationBuilder alloc] initWithContentURL:mediaInfo.url];
    mediaInfoBuilder.contentType = mediaInfo.mimeType;
    mediaInfoBuilder.streamType = GCKMediaStreamTypeNone;
    GCKMediaInformation *mediaInformation = [mediaInfoBuilder build];

    [self playMedia:mediaInformation webAppId:self.castWebAppId success:success failure:failure];
}

- (void) playMedia:(GCKMediaInformation *)mediaInformation webAppId:(NSString *)mediaAppId success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure {
      
    GCKRequest *request = [self.remoteMediaClient loadMedia:mediaInformation];
    if (request != nil) {
      request.delegate = self;
    }

    if (success)
        [_launchSuccessBlocks setObject:success forKey:@(request.requestID)];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:@(request.requestID)];
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure {
    GCKError *error;
    
    if (self.castServiceChannel.isConnected) {
        NSError *err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"type": @"stop"} options:0 error:&err];
        NSString *myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [self.castServiceChannel sendTextMessage:myString error:&error];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (success)
            success(nil);
    });
}

#pragma mark - Media Control

- (id<MediaControl>)mediaControl {
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority {
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSInteger result;

    @try {
        result = [self.remoteMediaClient play].requestID;
    } @catch (NSException *exception) {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID) {
        if (failure)
            failure(nil);
    } else {
        if (success)
            success(nil);
    }
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSInteger result;

    @try {
        result = [self.remoteMediaClient pause].requestID;
    } @catch (NSException *exception) {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID) {
        if (failure)
            failure(nil);
    } else {
        if (success)
            success(nil);
    }
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSInteger result;

    @try {
        result = [self.remoteMediaClient stop].requestID;
    } @catch (NSException *exception) {
        // this exception will be caught when trying to send command with no video
        result = kGCKInvalidRequestID;
    }

    if (result == kGCKInvalidRequestID) {
        if (failure)
            failure(nil);
    } else {
        if (success)
            success(nil);
    }
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure {
    if (!self.remoteMediaClient.mediaStatus) {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    NSInteger result = [self.remoteMediaClient seekToTimeInterval:position].requestID;

    if (result == kGCKInvalidRequestID) {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    } else {
        if (success)
            success(nil);
    }
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure {
    if (self.remoteMediaClient.mediaStatus) {
        if (success)
            success(self.remoteMediaClient.mediaStatus.mediaInformation.streamDuration);
    } else {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure {
    if (self.remoteMediaClient.mediaStatus) {
        if (success)
            success(self.remoteMediaClient.approximateStreamPosition);
    } else {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure {
    if (!self.remoteMediaClient.mediaStatus) {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    _immediatePlayStateCallback = success;

    NSInteger result = [self.remoteMediaClient requestStatus].requestID;

    if (result == kGCKInvalidRequestID) {
        _immediatePlayStateCallback = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure {
    if (!_playStateSubscription)
        _playStateSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_playStateSubscription addSuccess:success];
    [_playStateSubscription addFailure:failure];

    [self.remoteMediaClient requestStatus];

    return _playStateSubscription;
}

- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    if (self.remoteMediaClient.mediaStatus) {
        if (success) {
            success([self metadataInfoFromMediaMetadata:self.remoteMediaClient
                     .mediaStatus
                     .mediaInformation
                     .metadata]);
        }
    } else {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success
                                               failure:(FailureBlock)failure {
    if (!_mediaInfoSubscription)
        _mediaInfoSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_mediaInfoSubscription addSuccess:success];
    [_mediaInfoSubscription addFailure:failure];

    return _mediaInfoSubscription;
}

#pragma mark - WebAppLauncher

- (id<WebAppLauncher>)webAppLauncher {
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority {
    return CapabilityPriorityLevelHigh;
}

- (void)launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    [self launchWebApp:webAppId relaunchIfRunning:YES success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (void)joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure {
}

- (void)closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure {
    GCKRequest *request =  [self.remoteMediaClient stop];
    if (request != nil) {
      request.delegate = self;
    }

    if (success)
        [_launchSuccessBlocks setObject:success forKey:@(request.requestID)];

    if (failure)
        [_launchFailureBlocks setObject:failure forKey:@(request.requestID)];
}

- (void) pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

-(void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure {
    [self sendNotSupportedFailure:failure];
    return nil;
}

#pragma mark - Volume Control

- (id <VolumeControl>)volumeControl {
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority {
    return CapabilityPriorityLevelHigh;
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self getVolumeWithSuccess:^(float volume) {
        if (volume >= 1.0)
        {
            if (success)
                success(nil);
        } else
        {
            float newVolume = volume + 0.01;

            if (newVolume > 1.0)
                newVolume = 1.0;

            [self setVolume:newVolume success:success failure:failure];
        }
    } failure:failure];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [self getVolumeWithSuccess:^(float volume) {
        if (volume <= 0.0)
        {
            if (success)
                success(nil);
        } else
        {
            float newVolume = volume - 0.01;

            if (newVolume < 0.0)
                newVolume = 0.0;

            [self setVolume:newVolume success:success failure:failure];
        }
    } failure:failure];
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSInteger result = [self.remoteMediaClient setStreamMuted:mute].requestID;

    if (result == kGCKInvalidRequestID) {
        if (failure)
            [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil];
    } else {
        [self.remoteMediaClient requestStatus];

        if (success)
            success(nil);
    }
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure {
    if (_currentMuteStatus) {
        if (success)
            success(_currentMuteStatus);
    } else {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure {
    if (_currentMuteStatus) {
        if (success)
            success(_currentMuteStatus);
    }

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kCastServiceMuteSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];

    return subscription;
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSInteger result;
    NSString *failureMessage;

    @try {
        result = [self.remoteMediaClient setStreamVolume:volume].requestID;
    } @catch (NSException *ex) {
        // this is likely caused by having no active media session
        result = kGCKInvalidRequestID;
        failureMessage = @"There is no active media session to set volume on";
    }

    if (result == kGCKInvalidRequestID) {
        if (failure)
            [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:failureMessage];
    } else {
        [self.remoteMediaClient requestStatus];

        if (success)
            success(nil);
    }
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure {
    if (_currentVolumeLevel) {
        if (success)
            success(_currentVolumeLevel);
    } else {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure {
    if (_currentVolumeLevel) {
        if (success)
            success(_currentVolumeLevel);
    }

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kCastServiceVolumeSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];

    [self.remoteMediaClient requestStatus];

    return subscription;
}

#pragma mark - Private 

- (GCKMediaTrack *)mediaTrackFromSubtitleInfo:(SubtitleInfo *)subtitleInfo {
    return [[GCKMediaTrack alloc]
        initWithIdentifier:kSubtitleTrackIdentifier
         contentIdentifier:subtitleInfo.url.absoluteString
               contentType:subtitleInfo.mimeType
                      type:GCKMediaTrackTypeText
               textSubtype:GCKMediaTextTrackSubtypeSubtitles
                      name:subtitleInfo.label
        // languageCode is required when the track is subtitles
              languageCode:subtitleInfo.language ?: kSubtitleTrackDefaultLanguage
                customData:nil];
}

- (NSDictionary *)metadataInfoFromMediaMetadata:(GCKMediaMetadata *)metaData {
    NSMutableDictionary *mediaMetaData = [NSMutableDictionary dictionary];

    [mediaMetaData setNullableObject:[metaData objectForKey:kGCKMetadataKeyTitle]
                              forKey:@"title"];
    [mediaMetaData setNullableObject:[metaData objectForKey:kGCKMetadataKeySubtitle]
                              forKey:@"subtitle"];

    NSString *const kMetadataKeyIconURL = @"iconURL";
    GCKImage *image = [metaData.images firstObject];
    [mediaMetaData setNullableObject:image.URL.absoluteString
                              forKey:kMetadataKeyIconURL];
    if (!mediaMetaData[kMetadataKeyIconURL]) {
        NSDictionary *imageDict = [[metaData objectForKey:@"images"] firstObject];
        [mediaMetaData setNullableObject:imageDict[@"url"]
                                  forKey:kMetadataKeyIconURL];
    }

    return mediaMetaData;
}

- (GCKRemoteMediaClient *)remoteMediaClient {
    return GCKCastContext.sharedInstance.sessionManager.currentCastSession.remoteMediaClient;
}

- (GCKCastSession *)castSession {
    return GCKCastContext.sharedInstance.sessionManager.currentCastSession;
}

- (NSString *) writeToJSON:(id) obj
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonString;
}

#pragma mark - WebAppSessionDelegate
- (void) webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message {
    
}

- (void) webAppSessionDidDisconnect:(WebAppSession *)webAppSession {
    [self disconnect:nil];
//    if (self.castSession.connectionState == GCKConnectionStateConnected) {
//        GCKSessionManager *sessionManager = GCKCastContext.sharedInstance.sessionManager;
////        if ([sessionManager hasConnectedSession]) {
//            [self sessionManager:sessionManager didStartCastSession:self.castSession];
//    }
}

@end
