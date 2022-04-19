//
//  SmartViewDiscoveryProvider.m
//  ConnectSDK
//
//  Created by Vital on 3.03.21.
//  Copyright © 2021 LG Electronics. All rights reserved.
//

#import "SmartViewDiscoveryProvider.h"
#import <SmartView/SmartView.h>
#import "ServiceDescription.h"
#import "SmartViewService.h"
#import <ScreenMirroring-Swift.h>

@interface SmartViewDiscoveryProvider () <ServiceSearchDelegate>
{
    ServiceSearch *_deviceScanner;
    NSMutableDictionary *_devices;
    NSMutableDictionary *_deviceDescriptions;
}

@end

@implementation SmartViewDiscoveryProvider

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        _devices = [NSMutableDictionary new];
        _deviceDescriptions = [NSMutableDictionary new];

        _deviceScanner = [Service search];
        [_deviceScanner setDelegate:self];
    }
    
    return self;
}

- (void)startDiscovery
{
    self.isRunning = YES;

    if (!_deviceScanner.isSearching)
    {
        __weak typeof(self) wself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) sself = wself;
            [sself->_deviceScanner start];
        });
    }
}

- (void)pauseDiscovery {
//    [super pauseDiscovery];
//    if (![self canPause])
//        return;
    
    self.isRunning = NO;

    if (_deviceScanner.isSearching) {
        [_deviceScanner stop];
    }
    
}

- (void)stopDiscovery {
    self.isRunning = NO;

    if (_deviceScanner.isSearching) {
        [_deviceScanner stop];
    }
    
    _devices = [NSMutableDictionary new];
    _deviceDescriptions = [NSMutableDictionary new];
}

- (BOOL) isEmpty {
    // Since we are only searching for one type of device & parameters are unnecessary
    return NO;
}

#pragma mark - ServiceSearchDelegate

- (void)onServiceFound:(Service *)service {
    NSString *serviceID = [SmartViewHelper idOf:service];
    if ([_devices objectForKey:serviceID])
        return;
//    [service getDeviceInfo:5 completionHandler:^(NSDictionary<NSString *,id> * response, NSError * error) {
//        NSLog(@"responseX: %@", response);
//    }];

    NSString *address = [[[SmartViewHelper uriOf:service] componentsSeparatedByString:@":"][1] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:address UUID:serviceID];
    serviceDescription.serviceId = kConnectSDKSmartViewServiceId;
    serviceDescription.friendlyName = [SmartViewHelper nameOf:service];
    serviceDescription.manufacturer = @"Samsung";
    serviceDescription.modelName = @"";//[[json valueForKey:@"device"] valueForKey:@"modelName"];
    serviceDescription.device = service;
    [_devices setObject:service forKey:serviceID];
    [_deviceDescriptions setObject:serviceDescription forKey:serviceID];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate discoveryProvider:self didFindService:serviceDescription];
    });
}

- (void)onServiceLost:(Service *)service {
    NSString *serviceID = [SmartViewHelper idOf:service];
    if (![_devices objectForKey:serviceID])
        return;

    ServiceDescription *serviceDescription = [_deviceDescriptions objectForKey:serviceID];

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate discoveryProvider:self didLoseService:serviceDescription];
    });

    [_devices removeObjectForKey:serviceID];
    [_deviceDescriptions removeObjectForKey:serviceID];
}

@end
