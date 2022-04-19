//
//  SmartViewService.m
//  ConnectSDK
//
//  Created by Vital on 3.03.21.
//  Copyright © 2021 LG Electronics. All rights reserved.
//

#import "SmartViewService.h"
#import <SmartView/SmartView.h>
#import "AppStateChangeNotifier.h"
#import "NSObject+FeatureNotSupported_Private.h"
#import "ConnectError.h"
#import <ScreenMirroring-Swift.h>
#import "DLNAService.h"

@interface SmartViewService() <VideoPlayerDelegate, ServiceSearchDelegate, ChannelDelegate, ConnectionDelegate, PhotoPlayerDelegate>
{
    NSInteger _currentVideoProgress;
}
@property (nonatomic, strong) VideoPlayer *videoPlayer;
@property (nonatomic, strong) PhotoPlayer *photoPlayer;
@property (nonatomic, strong) Application *application;
@property (nonatomic, strong, readonly) DLNAService *dlnaService;

@end
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
// unimplemented protocol methods are forwarded to a certain implementation object
@implementation SmartViewService
@synthesize dlnaService = _dlnaService;

#pragma clang diagnostic pop

#pragma mark - Init
- (instancetype)initWithAppStateChangeNotifier:(nullable AppStateChangeNotifier *)stateNotifier {
    self = [super init];

    _appStateChangeNotifier = stateNotifier ?: [AppStateChangeNotifier new];
    __weak typeof(self) wself = self;
    _appStateChangeNotifier.didBackgroundBlock = ^{
//        typeof(self) sself = wself;
    };
    _appStateChangeNotifier.didForegroundBlock = ^{
        typeof(self) sself = wself;
//  temp vr 1 проверить как работает!      [sself->_photoPlayer resumeApplicationInForeground:nil];
//        [sself->_videoPlayer resumeApplicationInForeground:nil];
    };

    return self;
}

- (instancetype)init {
    return [self initWithAppStateChangeNotifier:nil];
}

#pragma mark - Media

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure {

    if (self.dlnaService) {
        [self.dlnaService closeMedia:launchSession success:success failure:failure];
    }
    
    [self.videoPlayer disconnect:YES completionHandler:^(NSError * error) {
    }];
    
    [self.photoPlayer disconnect:YES completionHandler:^(NSError * error) {
    }];
     
    if (self.application) {
        [SmartViewHelper publishMessage:@"streamStop" params:@{} in:self.application];
        [SmartViewHelper stopApplication:self.application onComplete:nil];
    }
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure {
     
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:imageURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self displayImageWithMediaInfo:mediaInfo success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void)displayImage:(MediaInfo *)mediaInfo success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure { 
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void)displayImageWithMediaInfo:(MediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure {
    
    if (self.dlnaService) {
        [self.dlnaService displayImageWithMediaInfo:mediaInfo success:success failure:failure];
    } else {
        [self.photoPlayer clearList];
        [self.photoPlayer playContent:mediaInfo.url completionHandler:^(NSError * error) {
            if (error) {
                failure(error);
            } else {
                LaunchSession *launchSession = [LaunchSession launchSessionForAppId:@"smartView"];
                launchSession.name = @"simpleplayer";
                launchSession.sessionType = LaunchSessionTypeMedia;
                launchSession.service = self;
                
                MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
                if(success){
                    success(launchObject);
                }
            }
        }];
    }
}

- (id<MediaPlayer>)mediaPlayer { 
    return  self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority { 
    return CapabilityPriorityLevelVeryHigh;
}

- (void)playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure { 
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void)playMedia:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure {
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void)playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure {
    
    if (self.dlnaService) {
        [self.dlnaService playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:success failure:failure];
    } else {
        [self.videoPlayer playContent:mediaInfo.url title:mediaInfo.title thumbnailURL:nil completionHandler:^(NSError * error) {
            if (error) {
                failure(error);
            } else {
                _currentVideoProgress = 0;
                
                LaunchSession *launchSession = [LaunchSession launchSessionForAppId:@"smartView"];
                launchSession.name = @"simpleplayer";
                launchSession.sessionType = LaunchSessionTypeMedia;
                launchSession.service = self;
                
                MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
                if(success){
                    success(launchObject);
                }
            }
        }];
    }
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure { 

}

- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure {
    NSTimeInterval result = (double)_currentVideoProgress/1000;
    success(result);
}

#pragma mark - Media Control
- (id<MediaControl>)mediaControl { 
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority { 
    return CapabilityPriorityLevelVeryHigh;
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    [_videoPlayer pause];
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    [_videoPlayer play];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    [_videoPlayer stop];
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    return [self sendNotSupportedFailure: failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure { 
    return [self sendNotSupportedFailure: failure];
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure { 
        
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure {
    if (self.dlnaService) {
        [self.dlnaService setVolume:volume success:success failure:failure];
    } else {
        [_videoPlayer setVolume:volume * 100];
    }
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure { 
    return [self sendNotSupportedFailure: failure];
}

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure { 
    return [self sendNotSupportedFailure: failure];
}

#pragma mark - Volume Control
- (id<VolumeControl>)volumeControl { 
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority { 
    return CapabilityPriorityLevelHigh;
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure { 
    
}

#pragma mark - Overridden DeviceService Methods

+ (NSDictionary *)discoveryParameters {
    return @{@"serviceId": kConnectSDKSmartViewServiceId};
}

//- (void)updateCapabilities {
//    NSArray *capabilities = @[kMediaPlayerDisplayImage,
//                              kMediaPlayerPlayVideo,
//                              kMediaPlayerPlayAudio,
//                              kMediaPlayerClose,
//                              kMediaPlayerMetaDataTitle,
//                              kMediaPlayerMetaDataDescription,
//                              kMediaPlayerMetaDataThumbnail,
//                              kMediaPlayerMetaDataMimeType,
//                              kMediaPlayerSubtitleWebVTT,
//
//                              kMediaControlPlay,
//                              kMediaControlPause,
//                              kMediaControlStop,
//                              kMediaControlDuration,
//                              kMediaControlPosition,
//                              kMediaControlSeek,
//                              kMediaControlPlayState,
//                              kMediaControlPlayStateSubscribe,
//                              kMediaControlMetadata];
//
//    self.capabilities = capabilities;
//}

//- (void)setServiceDescription:(ServiceDescription *)serviceDescription {
//    [super setServiceDescription:serviceDescription];
//
//}

- (BOOL)isConnectable {
    return YES;
}

- (void)connect {
    if (self.connected) {
        return;
    }
    
    self.connected = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)]) {
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
    }
}

- (void) disconnect:(NSError *)error {
    if (!self.connected) {
        return;
    }
    self.connected = NO;

    [self.videoPlayer disconnect:YES completionHandler:^(NSError *error) {
    }];

    [self.photoPlayer disconnect:YES completionHandler:^(NSError *error) {
    }];
  
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

- (void)checkReachability {
    //TODO:!!! Доделай!!!! Хотя скорее всего из-за сокета оно будет нормально работать
}

#pragma mark - Launcher

- (id <Launcher>)launcher
{
    return self;
}

- (CapabilityPriorityLevel) launcherPriority
{
    return CapabilityPriorityLevelVeryHigh;
}

- (void)installApp:(NSString *)appId params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    self.application = [SmartViewHelper createApplication:self.smartViewService args:params];
    [SmartViewHelper installApplication:self.application params:params onComplete:^(BOOL suc, NSError *error) {
        if (error) {
            failure(error);
        } else {
            success(nil);
        }
    }];
}

- (void)launchApp:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApp:appId params:nil success:success failure:failure];
}
 
- (void)launchAppWithInfo:(AppInfo *)appInfo success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchAppWithInfo:appInfo params:nil success:success failure:failure];
}

- (void)launchApp:(NSString *)appId params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    if (!appId || [appId isEqualToString:@""]) {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid app id"]);
        return;
    }

    AppInfo *appInfo = [AppInfo appInfoForId:appId];
    appInfo.name = appId;

    [self launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchAppWithInfo:(AppInfo *)appInfo params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure {
    if (self.application == nil) {
        self.application = [SmartViewHelper createApplication:self.smartViewService args:params];
    }
    [SmartViewHelper connectApplication:self.application params:params onComplete:^(NSError *error) {
        [SmartViewHelper publishMessage:@"streamPlay" params:params in:self.application];
        if (error) {
            failure(error);
        } else {
            success(nil);
        }
    }];
}

- (void) launchAppStore:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [SmartViewHelper createBrowserApplication:self.smartViewService];
//    NSString *appID = @"org.tizen.browser"; //@"com.samsung.browser"
//    Channel *channel = [self.smartViewService createChannel:appID];
//    Message *message = [Message new];
//    message.from = ""
//    Application *application = [self.smartViewService
//                                createApplication:appID
//                                channelURI:@"com.samsung.helloworld"
//                                args:
//                                @{
//                                    @"data":
//                                        @{ @"appId":appID,
//                                           @"action_type" : @"NATIVE_LAUNCH",
//                                           @"metaTag": target.absoluteString
//                                        }
//                                }];
//
    //    "{\"method\":\"ms.channel.emit\",\"params\":{\"event\":\"ed.apps.launch\",\"to\":\"host\",\"data\":{\"appId\":\"org.tizen.browser\",\"action_type\":\"NATIVE_LAUNCH\",\"metaTag\":\"\(url)\"}}}"
//    
//    
//    [application connect:nil completionHandler:^(ChannelClient *channelClient, NSError *error) {
//
//    }];
//    [application start:^(BOOL success, NSError *error) {
//        NSLog(@"Application started");
//    }];
}

- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)launchNetflix:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params;

    if (contentId && ![contentId isEqualToString:@""])
        params = @{ @"v" : contentId }; // TODO: verify this works

    AppInfo *appInfo = [AppInfo appInfoForId:@"Netflix"];
    appInfo.name = appInfo.id;

    [self.launcher launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchYouTube:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.launcher launchYouTube:contentId startTime:0.0 success:success failure:failure];
}

- (void) launchYouTube:(NSString *)contentId startTime:(float)startTime success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.application)
        return;
    
    [SmartViewHelper startApplication:self.application onComplete:^(BOOL suc, NSError * _Nullable error) {
        if (error) {
            failure(error);
        } else {
            success(nil);
        }
    }];
}

- (ServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
}

- (void)getAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribeAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
}

- (void)closeApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession || !launchSession.sessionId)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid launch session"]);

        return;
    }
    
    NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@", self.serviceDescription.commandURL.host, self.serviceDescription.commandURL.port];
    if ([launchSession.sessionId hasPrefix:@"http://"] || [launchSession.sessionId hasPrefix:@"https://"])
      commandPath = launchSession.sessionId;//chromecast returns full url
    else
      commandPath = [commandPath stringByAppendingPathComponent:launchSession.sessionId];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"DELETE";
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getAppListWithSuccess:(AppListSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)getRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    Application *application = [SmartViewHelper createApplication:self.smartViewService args:nil];
    [SmartViewHelper getInfo:application onComplete:^(NSDictionary *info, NSError *error) {
        if (error) {
            failure(error);
        } else {
            AppInfo *appInfo = [[AppInfo alloc] init];
            appInfo.name = [info objectForKey:@"name"];
            appInfo.id = [info objectForKey:@"id"];
            appInfo.rawData = [info copy];
            success(appInfo);
        }
    }];
}

#pragma mark - Players

- (VideoPlayer * __nonnull)videoPlayer {
    if (!_videoPlayer) {
        _videoPlayer = [SmartViewHelper creatVideoPlayerWith:self.smartViewService delegate: self];
    }

    return _videoPlayer;
}

- (PhotoPlayer * __nonnull)photoPlayer {
    if (!_photoPlayer) {
        _photoPlayer = [SmartViewHelper createPhotoPlayerWith:self.smartViewService delegate: self];
    }
    return _photoPlayer;
}

- (Service* __nullable)smartViewService {
    return self.serviceDescription.device;
}

#pragma mark - MediaPlayerDelegate

- (void)onConnect:(NSError * _Nullable)error {
    NSLog(@">>> SmartView onConnect: %@", error.localizedDescription);
}

- (void)onDisconnect:(NSError * _Nullable)error {
    NSLog(@">>> SmartView onDisconnect: %@", error.localizedDescription);
}

- (void)onClientConnect:(ChannelClient * _Nonnull)client {
    NSLog(@">>> SmartView onClientConnect: %@", client.description);
}

- (void)onClientDisconnect:(ChannelClient * _Nonnull)client {
    NSLog(@">>> SmartView onClientDisconnect: %@", client.description);
}

- (void)onError:(NSError * _Nonnull)error {
    NSLog(@">>> SmartView onError: %@", error.description);
    _currentVideoProgress = 0;
}

- (void)onReady {
    NSLog(@">>> onReady");
}

#pragma mark - VideoPlayerDelegate
- (void)onStreamingStarted:(NSInteger)duration {
    _currentVideoProgress = 0;
}

- (void)onStreamCompleted {
    _currentVideoProgress = 0;
}

- (void)onCurrentPlayTime:(NSInteger)progress {
    _currentVideoProgress = progress;
}

#pragma mark - DLNA
- (DLNAService *)dlnaService
{
    if (_dlnaService == nil)
    {
        DiscoveryManager *discoveryManager = [DiscoveryManager sharedManager];
        ConnectableDevice *device = [discoveryManager.allDevices objectForKey:self.serviceDescription.address];

        if (device)
        {
            __block DLNAService *foundService;

            [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
            {
                if ([service isKindOfClass:[DLNAService class]])
                {
                    foundService = (DLNAService *)service;
                    *stop = YES;
                }
            }];

            _dlnaService = foundService;
        }
    }

    return _dlnaService;
}
@end
