//
//  CastServiceDiscoveryProvider.m
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

#import "CastServiceDiscoveryProvider.h"
#import <GoogleCast/GoogleCast.h>
#import "ServiceDescription.h"
#import "CastService.h"
#import <ScreenMirroring-Swift.h>

static const BOOL kDebugLoggingEnabled = YES;

@interface CastServiceDiscoveryProvider () <GCKLoggerDelegate, GCKDiscoveryManagerListener, GCKSessionManagerListener>
{
    GCKDiscoveryManager *_deviceScanner;
    NSMutableDictionary *_devices;
    NSMutableDictionary *_deviceDescriptions;
}

@end

@implementation CastServiceDiscoveryProvider

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        NSString *receiverAppID = [ChromecastWebApp idToObjc];
        GCKDiscoveryCriteria *criteria = [[GCKDiscoveryCriteria alloc]
                                          initWithApplicationID:receiverAppID];
        
        GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:criteria];
        options.disableDiscoveryAutostart = YES;
        options.disableAnalyticsLogging = YES;
        options.stopReceiverApplicationWhenEndingSession = YES;
        options.physicalVolumeButtonsWillControlDeviceVolume = YES;
        options.startDiscoveryAfterFirstTapOnCastButton = NO;
       
        GCKLaunchOptions *launchOptions = [[GCKLaunchOptions alloc] initWithRelaunchIfRunning:YES];
        options.launchOptions = launchOptions;
        
        [GCKCastContext setSharedInstanceWithOptions:options];
        
        GCKLogger.sharedInstance.delegate = self;
        
        _deviceScanner = GCKCastContext.sharedInstance.discoveryManager;
        [_deviceScanner addListener:self];
        
        _devices = [NSMutableDictionary new];
        _deviceDescriptions = [NSMutableDictionary new];
        [GCKCastContext.sharedInstance.sessionManager addListener:self];
    }
    
    return self;
}

- (void)startDiscovery {
    self.isRunning = YES;

    if (_deviceScanner.discoveryState == GCKDiscoveryStateStopped) {
        [_deviceScanner startDiscovery];
    }
}

- (void)pauseDiscovery {
//    [super pauseDiscovery];
//    if (![self canPause])
//        return;
    self.isRunning = NO;
    
    if (_deviceScanner.discoveryState == GCKDiscoveryStateRunning) {
        [_deviceScanner stopDiscovery];
    }
}

- (void)stopDiscovery {
    self.isRunning = NO;

    if (_deviceScanner.discoveryState == GCKDiscoveryStateRunning) {
        [_deviceScanner stopDiscovery];
    } else {
        
    }
    
    _devices = [NSMutableDictionary new];
    _deviceDescriptions = [NSMutableDictionary new];
}

- (void) removeService:(ServiceDescription *)serviceDescription {
    if (serviceDescription.UUID != nil) {
        [_devices removeObjectForKey:serviceDescription.UUID];
        [_deviceDescriptions removeObjectForKey:serviceDescription.UUID];
    }
}

- (BOOL) isEmpty
{
    // Since we are only searching for one type of device & parameters are unnecessary
    return NO;
}

#pragma mark - GCKDiscoveryManagerListener
- (void) didUpdateDeviceList {
    
}

- (void) didInsertDevice:(GCKDevice *)device atIndex:(NSUInteger)index {
    DLog(@"%@", device.friendlyName);

    if ([_devices objectForKey:device.deviceID])
        return;

    ServiceDescription *serviceDescription =
    [ServiceDescription descriptionWithAddress:device.networkAddress.ipAddress UUID:device.deviceID];
    serviceDescription.serviceId = kConnectSDKCastServiceId;
    serviceDescription.friendlyName = device.friendlyName;
    serviceDescription.port = device.servicePort;
    serviceDescription.modelName = device.modelName;
    serviceDescription.device = device;

    [_devices setObject:device forKey:device.deviceID];
    [_deviceDescriptions setObject:serviceDescription forKey:device.deviceID];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate discoveryProvider:self didFindService:serviceDescription];
    });
}

- (void) didRemoveDevice:(GCKDevice *)device atIndex:(NSUInteger)index {
    DLog(@"%@", device.friendlyName);

    if (![_devices objectForKey:device.deviceID])
        return;

    ServiceDescription *serviceDescription = [_deviceDescriptions objectForKey:device.deviceID];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate discoveryProvider:self didLoseService:serviceDescription];
    });

    [_devices removeObjectForKey:device.deviceID];
    [_deviceDescriptions removeObjectForKey:device.deviceID];
}

- (void) didUpdateDevice:(GCKDevice *)device atIndex:(NSUInteger)index {
    [self didInsertDevice:device atIndex:index];
}

#pragma mark - GCKLoggerDelegate

- (void)logMessage:(NSString *)message
           atLevel:(GCKLoggerLevel)level
      fromFunction:(NSString *)function
          location:(NSString *)location {
  if (kDebugLoggingEnabled) {
    NSLog(@"CASTXX: %@ - %@, %@", function, message, location);
  }
}

@end
