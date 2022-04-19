//
//  FireTVDiscoveryProvider.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-08.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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

#import "FireTVDiscoveryProvider_Private.h"
#import "ConnectError.h"
#import "DispatchQueueBlockRunner.h"
#import "FireTVService.h"
#import "ServiceDescription.h"

#import <AmazonFling/DiscoveryController.h>
#import <AmazonFling/RemoteMediaPlayer.h>
#import <AmazonFling/InstallDiscoveryController.h>
#import <AmazonFling/RemoteInstallService.h>


@interface FireTVDiscoveryProvider() <InstallDiscoveryListener>

/// Stores the created service descriptions mapped by device's UUID. It also allows to diagnose
/// devices that are lost before discovered (if that can happen).
@property (nonatomic, strong, readonly) NSMutableDictionary *storedServiceDescriptions;

/// Whether the @c flingDiscoveryController has been once initialized. You can
/// call @c -open: only once, otherwise discovery won't work.
@property (nonatomic, assign) BOOL isInitialized;

@end


@implementation FireTVDiscoveryProvider

#pragma mark - Init

- (instancetype)initWithDiscoveryController:(nullable DiscoveryController *)controller {
    if ((self = [super init])) {
        _flingDiscoveryController = controller ?: [DiscoveryController new];
        _storedServiceDescriptions = [NSMutableDictionary dictionary];

        _isInitialized = NO;
    }

    return self;
}

- (instancetype)init {
    return [self initWithDiscoveryController:nil];
}

#pragma mark - Discovery

- (void)startDiscovery {
    if (!self.isRunning) {
        self.isRunning = YES;

        if (self.isInitialized) {
            [self.flingDiscoveryController resume];
        } else {
//            NSString *webAppId = @"amzn.thin.pl";
//            [self.flingDiscoveryController searchPlayerWithId:webAppId andListener:self andEnableLogs:YES];
            [self.flingDiscoveryController searchDefaultPlayerWithListener:self];
            self.isInitialized = YES;
        }
    }
}

- (void)stopDiscovery {
    [self stopDiscoveryWithRemovingServices:YES];
}

- (void)pauseDiscovery {
//    [super pauseDiscovery];
//    if (![self canPause])
//        return;
    [self stopDiscoveryWithRemovingServices:NO];
}

- (void) removeService:(ServiceDescription *)serviceDescription {
    if ([serviceDescription.device respondsToSelector:@selector(uniqueIdentifier)]) {
        id<RemoteMediaPlayer> fireTVDevice = serviceDescription.device;
        [self.storedServiceDescriptions removeObjectForKey: [fireTVDevice uniqueIdentifier]];
    }
}

#pragma mark - DiscoveryListener methods

- (void)deviceDiscovered:(id<RemoteMediaPlayer>)device {
    if (device) {
        [self.delegateBlockRunner runBlock:^{
            NSString *uuid = [device uniqueIdentifier];
            // we don't know the IP address, so replace it with the unique ID
            ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:uuid UUID:uuid];
            serviceDescription.serviceId = kConnectSDKFireTVServiceId;
            serviceDescription.friendlyName = [device name];
            serviceDescription.device = device;
            self.storedServiceDescriptions[uuid] = serviceDescription;

            [self.delegate discoveryProvider:self
                              didFindService:serviceDescription];
        }];
    } else {
        DLog(@"%@: discovered nil media player", self);
    }
}

- (void)deviceLost:(id<RemoteMediaPlayer>)device {
    if (device) {
        [self removeServiceDescriptionWithUUID:[device uniqueIdentifier]];
    } else {
        DLog(@"%@: lost nil media player", self);
    }
}

- (void)discoveryFailure {
    [self.delegateBlockRunner runBlock:^{
        NSError *error = [ConnectError generateErrorWithCode:ConnectStatusCodeError
                                                  andDetails:nil];
        [self.delegate discoveryProvider:self
                        didFailWithError:error];
    }];
}

- (void)installServiceDiscovered:(id<RemoteInstallService>)device {
    NSLog(@"Adding Device: %@", [device name]);
//    FireTV* tv = [self.deviceMap objectForKey:[device uniqueIdentifier]];
//    if (tv == nil) {
//        tv = [[FireTV alloc] init];
//        tv.installService = device;
//        tv.player = nil;
//        [self.deviceMap setObject:tv forKey:[device uniqueIdentifier]];
//    } else {
//        if (tv.installService != nil) {
//            // Handle possible duplicate
//        } else {
//            tv.installService = device;
//        }
//    }
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.picker.image = self.playerController.player != nil ?
//        [[UIImage imageNamed:@"PickerConnected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] :
//        [[UIImage imageNamed:@"Picker"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    });
}

// -------------------------------------------------------------------------------
//    installServiceLost:device
// -------------------------------------------------------------------------------
- (void)installServiceLost:(id<RemoteInstallService>)device {
    NSLog(@"installServiceLost=%@", [device name]);
//    FireTV* tv = [self.deviceMap objectForKey:[device uniqueIdentifier]];
//    if (tv != nil) {
//        tv.installService = nil;
//    }
//    if (tv.player == nil && tv.installService == nil) {
//        [self.deviceMap removeObjectForKey:[device uniqueIdentifier]];
//    }
}


#pragma mark - Properties

- (id<BlockRunner>)delegateBlockRunner {
    if (!_delegateBlockRunner) {
        _delegateBlockRunner = [DispatchQueueBlockRunner mainQueueRunner];
    }

    return _delegateBlockRunner;
}

#pragma mark - Private Methods

/// Closes the @c flingDiscoveryController if the discovery is running and
/// optionally removes found services.
- (void)stopDiscoveryWithRemovingServices:(BOOL)removingServices {
    if (self.isRunning) {
        [self.flingDiscoveryController close];
        self.isRunning = NO;

        if (removingServices) {
            [self removeAllServiceDescriptions];
        }
        /*
         95% крашей генерирует AmazonFling.framework при сворачивании в бэк.
         Поменял местами очистку подписок и девайсов. Возможно поможет.
         */
    }
}

/// Removes a @c ServiceDescription by its @c uuid from the stored dictionary
/// and notifies the delegate. If the @c uuid is not found, does nothing.
- (void)removeServiceDescriptionWithUUID:(NSString *)uuid {
    ServiceDescription *foundServiceDescription = self.storedServiceDescriptions[uuid];
    if (foundServiceDescription) {
        [self.storedServiceDescriptions removeObjectForKey:uuid];

        [self.delegateBlockRunner runBlock:^{
            [self.delegate discoveryProvider:self
                              didLoseService:foundServiceDescription];
        }];
    } else {
        DLog(@"%@: lost device that was not found: %@", self, uuid);
    }
}

/// Removes all stored @c ServiceDescription objects and notifies the delegate.
- (void)removeAllServiceDescriptions {
    [self.storedServiceDescriptions.allKeys enumerateObjectsUsingBlock:
     ^(NSString *uuid, NSUInteger idx, BOOL *stop) {
         [self removeServiceDescriptionWithUUID:uuid];
     }];
}

@end
