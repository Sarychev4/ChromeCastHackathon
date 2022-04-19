//
//  DiscoveryManager.m
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#import "DiscoveryManager_Private.h"


#import "FireTVDiscoveryProvider.h"
#import "CastServiceDiscoveryProvider.h"
#import "SSDPDiscoveryProvider.h"
#import "ZeroConfDiscoveryProvider.h"
#import "FireTVService.h"
#import "CastService.h"
#import "DLNAService.h"
#import "DIALService.h"
#import "RokuService.h"
#import "AirPlayService.h"
#import "WebOSTVService.h"

#import "PingOperation.h"
#import "DiscoveryProvider.h"

#import "ConnectSDKDefaultPlatforms.h"
 
#import "NetcastTVService.h"

#import "ConnectableDevice.h"
#import "DefaultConnectableDeviceStore.h"
#import "ServiceDescription.h"
#import "ServiceConfig.h"
#import "ServiceConfigDelegate.h"
#import "CapabilityFilter.h"
#import "DeviceServiceReachability.h"
#import "AppStateChangeNotifier.h"
#import "DIALService.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#define kReachabilityTimerUpdate 15

@interface DiscoveryManager() <ServiceConfigDelegate>

@end

@implementation DiscoveryManager
{
    NSMutableDictionary *_allDevices;
    NSMutableDictionary *_compatibleDevices;
    NSMutableDictionary *_reachabilityCheckers;
    NSTimer *_reachabilityTimer;
    BOOL _isPinging;
    
    BOOL _shouldResumeSearch;
    BOOL _searching;
    
    DevicePicker *_currentPicker;

    NSTimer *_ssidTimer;
    NSString *_currentSSID;
}

@synthesize pairingLevel = _pairingLevel;
@synthesize useDeviceStore = _useDeviceStore;

+ (DiscoveryManager *) _sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id _sharedManager = nil;

    dispatch_once(&predicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

+ (DiscoveryManager *) sharedManager
{
    DiscoveryManager *manager = [self _sharedManager];

    if (!manager.deviceStore && manager.useDeviceStore)
        [manager setDeviceStore:[DefaultConnectableDeviceStore new]];

    return manager;
}

+ (DiscoveryManager *) sharedManagerWithDeviceStore:(id <ConnectableDeviceStore>)deviceStore
{
    DiscoveryManager *manager = [self _sharedManager];

    if (deviceStore == nil || manager.deviceStore != deviceStore)
        [manager setDeviceStore:deviceStore];

    return manager;
}

- (void) setDeviceStore:(id <ConnectableDeviceStore>)deviceStore
{
    _deviceStore = deviceStore;
    _useDeviceStore = (_deviceStore != nil);
}

- (instancetype)init {
    return [self initWithAppStateChangeNotifier:nil];
}

#pragma mark - Private Init

- (instancetype) initWithAppStateChangeNotifier:(nullable AppStateChangeNotifier *)stateNotifier
{
    self = [super init];
    
    if (self)
    {
        _shouldResumeSearch = NO;
        _searching = NO;
        _useDeviceStore = YES;
        
        _discoveryProviders = [[NSMutableArray alloc] init];
        _deviceClasses = [[NSMutableDictionary alloc] init];

        _allDevices = [[NSMutableDictionary alloc] init];
        _compatibleDevices = [[NSMutableDictionary alloc] init];

        _appStateChangeNotifier = stateNotifier ?: [AppStateChangeNotifier new];
        __weak typeof(self) wself = self;
        _appStateChangeNotifier.didBackgroundBlock = ^{
            typeof(self) sself = wself;
            [sself pauseDiscovery];
        };
        _appStateChangeNotifier.didForegroundBlock = ^{
            typeof(self) sself = wself;
            [sself resumeDiscovery];
        };

        [self startSSIDTimer];
    }
    
    return self;
}

#pragma mark - Setup & Registration

- (void) registerDefaultServices
{
    NSDictionary *defaultPlatforms = kConnectSDKDefaultPlatforms;
    
    [defaultPlatforms enumerateKeysAndObjectsUsingBlock:^(NSString *platformClassName, NSString *discoveryProviderClassName, BOOL *stop) {
        Class platformClass = NSClassFromString(platformClassName);
        Class discoveryProviderClass = NSClassFromString(discoveryProviderClassName);
        
        [self registerDeviceService:platformClass withDiscovery:discoveryProviderClass];
    }];
}

- (void) registerDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass
{
    if (![discoveryClass isSubclassOfClass:[DiscoveryProvider class]])
        return;

    [self registerDeviceService:deviceClass
   withDiscoveryProviderFactory:^DiscoveryProvider *{
       return [discoveryClass new];
   }];
}

- (void)registerDeviceService:(Class)deviceClass
 withDiscoveryProviderFactory:(DiscoveryProvider *(^)(void))providerFactory
{
    if (![deviceClass isSubclassOfClass:[DeviceService class]])
        return;
    
    __block DiscoveryProvider *discoveryProvider;
    // FIXME don't create new provider unless necessary
    DiscoveryProvider *newDiscoveryProvider = providerFactory();
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj class] isSubclassOfClass:[newDiscoveryProvider class]])
        {
            discoveryProvider = obj;
            *stop = YES;
        }
    }];
    
    if (discoveryProvider == nil)
    {
        discoveryProvider = newDiscoveryProvider;
        discoveryProvider.delegate = self;
        _discoveryProviders = [_discoveryProviders arrayByAddingObject:discoveryProvider];
    }
    
    NSDictionary *discoveryParameters = [deviceClass discoveryParameters];
    
    NSString *serviceId = [discoveryParameters objectForKey:@"serviceId"];

    NSMutableDictionary *mutableClasses = [NSMutableDictionary dictionaryWithDictionary:_deviceClasses];
    [mutableClasses setObject:deviceClass forKey:serviceId];
    _deviceClasses = [NSDictionary dictionaryWithDictionary:mutableClasses];
    
    [discoveryProvider addDeviceFilter:discoveryParameters];
}

- (void) unregisterDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass
{
    if (![discoveryClass isSubclassOfClass:[DiscoveryProvider class]])
        return;
    
    if (![deviceClass isSubclassOfClass:[DeviceService class]])
        return;
    
    __block DiscoveryProvider *discoveryProvider;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj class] isSubclassOfClass:discoveryClass])
        {
            discoveryProvider = obj;
            *stop = YES;
        }
    }];
    
    if (discoveryProvider == nil)
        return;
    
    NSDictionary *discoveryParameters = [discoveryClass discoveryParameters];
    
    NSString *serviceId = [discoveryParameters objectForKey:@"serviceId"];

    NSMutableDictionary *mutableClasses = [NSMutableDictionary dictionaryWithDictionary:_deviceClasses];
    [mutableClasses removeObjectForKey:serviceId];
    _deviceClasses = [NSDictionary dictionaryWithDictionary:mutableClasses];
    
    [discoveryProvider removeDeviceFilter:discoveryParameters];
    
    if ([discoveryProvider isEmpty])
    {
        [discoveryProvider stopDiscovery];
        discoveryProvider.delegate = nil;

        NSMutableArray *mutableProviders = [NSMutableArray arrayWithArray:_discoveryProviders];
        [mutableProviders removeObject:discoveryProvider];
        _discoveryProviders = [NSArray arrayWithArray:mutableProviders];
    }
}

#pragma mark - Wireless SSID Change Detection

- (void) startSSIDTimer
{
//    _ssidTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(detectSSIDChange) userInfo:nil repeats:YES];
//    [_ssidTimer fire];
}

- (void) stopSSIDTimer
{
//    [_ssidTimer invalidate];
//    _ssidTimer = nil;
}

- (void) detectSSIDChange
{
    NSArray *interfaces = (__bridge_transfer id) CNCopySupportedInterfaces();

    __block NSString *ssidName;

    [interfaces enumerateObjectsUsingBlock:^(NSString *interface, NSUInteger idx, BOOL *stop)
    {
        if ([interface caseInsensitiveCompare:@"en0"] != NSOrderedSame)
            return;

        CFDictionaryRef cfDict = CNCopyCurrentNetworkInfo((CFStringRef)interface);
        NSDictionary *info = (NSDictionary *)CFBridgingRelease(cfDict);

        if (info && [info objectForKey:@"SSID"])
        {
            ssidName = [info objectForKey:@"SSID"];
            *stop = YES;
        }
    }];

    if (ssidName == nil)
        ssidName = @"";

    if ([ssidName caseInsensitiveCompare:_currentSSID] != NSOrderedSame)
    {
        if (_currentSSID != nil)
        {
            [self purgeDeviceList];

            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectSDKWirelessSSIDChanged object:nil];
        }

        _currentSSID = ssidName;
    }
}

- (void) purgeDeviceList
{
    [self.compatibleDevices enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *stop)
    {
        [device disconnect];
        
        if (self.delegate)
            [self.delegate discoveryManager:self didLoseDevice:device];

        if (self.devicePicker)
            [self.devicePicker discoveryManager:self didLoseDevice:device];
    }];
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *provider, NSUInteger idx, BOOL *stop) {
        [provider stopDiscovery];
        [provider startDiscovery];
    }];

    _allDevices = [NSMutableDictionary new];
    _compatibleDevices = [NSMutableDictionary new];
}

- (void) clearDeviceList
{
    [self.compatibleDevices enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *stop)
    {
        [device disconnect];
        
        if (self.delegate)
            [self.delegate discoveryManager:self didLoseDevice:device];

        if (self.devicePicker)
            [self.devicePicker discoveryManager:self didLoseDevice:device];
    }];
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *provider, NSUInteger idx, BOOL *stop) {
        [provider stopDiscovery];
    }];
    
    [self stopDiscovery];

    _allDevices = [NSMutableDictionary new];
    _compatibleDevices = [NSMutableDictionary new];
}

#pragma mark - Capability Filtering

- (void)setCapabilityFilters:(NSArray *)capabilityFilters
{
    _capabilityFilters = capabilityFilters;

    @synchronized (_compatibleDevices)
    {
        [_compatibleDevices enumerateKeysAndObjectsUsingBlock:^(NSString *address, ConnectableDevice *device, BOOL *stop)
        {
            if (self.delegate)
                [self.delegate discoveryManager:self didLoseDevice:device];
        }];
    }

    _compatibleDevices = [[NSMutableDictionary alloc] init];

    NSArray *allDevices;

    @synchronized (_allDevices) { allDevices = [_allDevices allValues]; }

    [allDevices enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop)
    {
        if ([self deviceIsCompatible:device])
        {
            @synchronized (_compatibleDevices) { [_compatibleDevices setValue:device forKey:device.address]; }

            if (self.delegate)
                [self.delegate discoveryManager:self didFindDevice:device];
        }
    }];
}

- (BOOL) descriptionIsNetcastTV:(ServiceDescription *)description
{
    BOOL isNetcast = NO;

    if ([description.modelName.uppercaseString isEqualToString:@"LG TV"])
    {
        if ([description.modelDescription.uppercaseString rangeOfString:@"WEBOS"].location == NSNotFound)
        {
            isNetcast = [description.serviceId isEqualToString:kConnectSDKNetcastTVServiceId];
        }
    }

    return isNetcast;
}

#pragma mark - Device lists

- (NSDictionary *) allDevices
{
    return [NSDictionary dictionaryWithDictionary:_allDevices];
}

- (NSDictionary *)compatibleDevices
{
    return [NSDictionary dictionaryWithDictionary:_compatibleDevices];
}

- (BOOL) deviceIsCompatible:(ConnectableDevice *)device
{
    if (!_capabilityFilters || _capabilityFilters.count == 0)
        return YES;

    __block BOOL isCompatible = NO;

    [self.capabilityFilters enumerateObjectsUsingBlock:^(CapabilityFilter *filter, NSUInteger idx, BOOL *stop)
    {
        if ([device hasCapabilities:filter.capabilities])
        {
            isCompatible = YES;
            *stop = YES;
        }
    }];

    return isCompatible;
}

- (void) handleDeviceAdd:(ConnectableDevice *)device
{
    if (![self deviceIsCompatible:device])
        return;

    @synchronized (_compatibleDevices) { [_compatibleDevices setValue:device forKey:device.address]; }

    if (self.delegate)
        [self.delegate discoveryManager:self didFindDevice:device];

    if (_currentPicker)
        [_currentPicker discoveryManager:self didFindDevice:device];
}

- (void) handleDeviceUpdate:(ConnectableDevice *)device
{
    [self.deviceStore updateDevice:device];

    if ([self deviceIsCompatible:device])
    {
        @synchronized (_compatibleDevices) {
            if ([_compatibleDevices objectForKey:device.address])
            {
                if (self.delegate)
                    [self.delegate discoveryManager:self didUpdateDevice:device];

                if (_currentPicker)
                    [_currentPicker discoveryManager:self didUpdateDevice:device];
            } else
            {
                [self handleDeviceAdd:device];
            }
        }
    } else
    {
        @synchronized (_compatibleDevices) { [_compatibleDevices removeObjectForKey:device.address]; }

        [self handleDeviceLoss:device];
    }
}

- (void) handleDeviceLoss:(ConnectableDevice *)device
{
    if (self.delegate)
        [self.delegate discoveryManager:self didLoseDevice:device];

    if (_currentPicker)
        [_currentPicker discoveryManager:self didLoseDevice:device];
}

- (void)setPairingLevel:(DeviceServicePairingLevel)pairingLevel
{
    if (_searching == NO) {
        _pairingLevel = pairingLevel;
    }
}

#pragma mark - Control

- (void)startDiscovery
{
    if (_searching)
        return;

    if (_deviceClasses.count == 0)
        [self registerDefaultServices];

    _searching = YES;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *service, NSUInteger idx, BOOL *stop) {
        [service startDiscovery];
    }];
    
    [self startReachabilityTimer];

    [self.appStateChangeNotifier startListening];
}

- (void)stopDiscovery
{
    if (!_searching)
        return;

    _searching = NO;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *service, NSUInteger idx, BOOL *stop) {
        [service stopDiscovery];
    }];
    
    if (!_shouldResumeSearch)
    {
        [self.appStateChangeNotifier stopListening];
    }
}

/// Pauses all discovery providers and the SSID change timer.
- (void)pauseDiscovery {
    // moved from -hAppDidEnterBackground:
    [self stopSSIDTimer];
    [self stopReachabilityTimer];
    
    if (_searching)
    {
        _searching = NO;
        _shouldResumeSearch = YES;

        [self.discoveryProviders makeObjectsPerformSelector:@selector(pauseDiscovery)];
    }
}

/// Resumes all discovery providers and the SSID change timer.
- (void)resumeDiscovery {
    // moved from -hAppDidBecomeActive:
    [self startSSIDTimer];
    [self startReachabilityTimer];

    if (_shouldResumeSearch)
    {
        _searching = YES;
        _shouldResumeSearch = NO;

        [self.discoveryProviders makeObjectsPerformSelector:@selector(resumeDiscovery)];
    }
}

#pragma mark - Reachability Devices
- (void)startReachabilityTimer {
    if (_reachabilityTimer)
        return;
    
    _reachabilityTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(checkReachability) userInfo:nil repeats:YES];
    [_reachabilityTimer fire];
}

- (void) stopReachabilityTimer {
    [_reachabilityTimer invalidate];
    _reachabilityTimer = nil;
}

- (void)checkReachability {
//    if (_isPinging)
        return;

    ConnectableDevice *firstNotPingedDevice = [self findFirstNotPingedDevice];
    if (firstNotPingedDevice) {
        _isPinging = YES;
        [self checkReachability:firstNotPingedDevice onComplete:^(BOOL alive) {
            firstNotPingedDevice.lastPinged = [NSDate.date timeIntervalSince1970];
            if (!alive) {
                [firstNotPingedDevice.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL * _Nonnull stop) {
                    [self discoveryProvider:nil didLoseService:service.serviceDescription];
                }];
            }
            self->_isPinging = false;
//            [self checkReachability];
        }];
    }
}

- (ConnectableDevice *)findFirstNotPingedDevice {
    NSArray *allDevices = _allDevices.allValues;
    __block ConnectableDevice *foundDevice;
    [allDevices enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop) {
        if (device.connected) {
            foundDevice = device;
        }
    }];
//    __block double xmin = 161909404100;
//    NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
//    [allDevices enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop) {
//        if (device.lastPinged < xmin) {
//            xmin = device.lastPinged;
//            if (now - device.lastPinged > kReachabilityTimerUpdate) {
//                foundDevice = device;
//            }
//        }
//    }];
//    NSLog(@"PING: result min: %f, %@", xmin, foundDevice.friendlyName);
    return foundDevice;
}

- (void)checkReachability:(ConnectableDevice *)device onComplete:(DiscoveryManagerPingingBlock)onComplete {
    __block BOOL isPingSuccess = NO;
    __block int attempt = 0;
    __block int pingCount = 10;
    __block float delay = 0;// (arc4random() % 100) / (float) 100;
    
    NSString* urlString = [NSString stringWithFormat:@"%@", device.serviceDescription.address];
    __block NSMutableString *targetURL = [[NSMutableString alloc] initWithString:urlString];
    if (![targetURL containsString:@"."]) {
//        onComplete(YES);
//        return;
        __block BOOL dialFound = NO;
        [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop) {
            if ([service isKindOfClass:[DIALService class]]) {
                targetURL = [[NSMutableString alloc] initWithString:service.serviceDescription.address];
                *stop = YES;
                dialFound = YES;
            }
        }];

//        //Если не нашли dial для fireTV, то считаем что пинг прошел успешно
        if (!dialFound) {
            onComplete(YES);
            return;
        }
    }
    for (NSUInteger i = 0; i < pingCount; i++) {
        NSLog(@"PING: %@, tv:%@", targetURL, device.friendlyName);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            PingOperation *pingOperation = [[PingOperation alloc] initWithIPToPing:targetURL andCompletionHandler:^(NSError * error, NSString *ip) {
                if (error) {
                    NSLog(@"PING ERROR %@, %@", targetURL, error);
                }
                attempt += 1;
                if (error == nil) {
                    isPingSuccess = YES;
                }
                if (attempt == pingCount) {
                    if (isPingSuccess == NO) {
                            dispatch_async(dispatch_get_main_queue(), ^
                            {
//                                NSString *message = [NSString stringWithFormat:@"ip:%@", ip];
//                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ping error" message:message delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];
//                                [alert show];
                            });
                    } else {
                        NSLog(@"PING SUCCESS", targetURL);
                    }
                    onComplete(isPingSuccess);
                }
            }];
            [pingOperation start];
        });
        delay += 0.3;
    }
}

- (void)removeDevice:(ConnectableDevice *)device {
    if (device.connected) {
        [device disconnect];
    }
    [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop) {
//        [device removeServiceWithId:description.serviceId];
        NSString *serviceId = [[NSMutableString alloc]initWithString:service.serviceDescription.serviceId];
        [self discoveryProvider:nil didLoseService:service.serviceDescription];
        __block DiscoveryProvider *foundProvider;
        [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *provider, NSUInteger idx, BOOL * stop) {
            if ([serviceId compare: kConnectSDKFireTVServiceId] == NSOrderedSame &&
                [provider isKindOfClass:[FireTVDiscoveryProvider class]]) {
                foundProvider = provider;
            } else if ([serviceId compare: kConnectSDKCastServiceId] == NSOrderedSame &&
                       [provider isKindOfClass:[CastServiceDiscoveryProvider class]]) {
                foundProvider = provider;
            } else if ([serviceId compare: kConnectSDKAirPlayServiceId] == NSOrderedSame &&
                        [provider isKindOfClass:[ZeroConfDiscoveryProvider class]]) {
                 foundProvider = provider;
             } else if (([serviceId compare: kConnectSDKWebOSTVServiceId] == NSOrderedSame ||
                        [serviceId compare: kConnectSDKDLNAServiceId] == NSOrderedSame ||
                        [serviceId compare: kConnectSDKRokuServiceId] == NSOrderedSame ||
                        [serviceId compare: kConnectSDKDIALServiceId] == NSOrderedSame) &&
                       [provider isKindOfClass:[SSDPDiscoveryProvider class]]) {
                foundProvider = provider;
            }
        }];
        [foundProvider pauseDiscovery];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [foundProvider resumeDiscovery];
        });
    }];
}

#pragma mark - DiscoveryProviderDelegate methods

- (void)discoveryProvider:(DiscoveryProvider *)provider didFindService:(ServiceDescription *)description
{
    DLog(@"%@ (%@)", description.friendlyName, description.serviceId);

    BOOL deviceIsNew = [_allDevices objectForKey:description.address] == nil;
    ConnectableDevice *device;

    if (deviceIsNew)
    {
        if (self.useDeviceStore)
        {
            device = [self.deviceStore deviceForId:description.UUID];

            if (device)
                @synchronized (_allDevices) { [_allDevices setObject:device forKey:description.address]; }
        }
    } else
    {
        @synchronized (_allDevices) { device = [_allDevices objectForKey:description.address]; }
    }

    if (!device)
    {
        device = [ConnectableDevice connectableDeviceWithDescription:description];
        @synchronized (_allDevices) { [_allDevices setObject:device forKey:description.address]; }
        deviceIsNew = YES;
    }

    device.lastDetection = [[NSDate date] timeIntervalSince1970];
    device.lastKnownIPAddress = description.address;
    device.lastSeenOnWifi = _currentSSID;

    [self addServiceDescription:description toDevice:device];

    if (device.services.count == 0)
    {
        // we get here when a non-LG DLNA TV is found

        [_allDevices removeObjectForKey:description.address];
        device = nil;

        return;
    }

    if (deviceIsNew)
        [self handleDeviceAdd:device];
    else
        [self handleDeviceUpdate:device];
}

- (void)discoveryProvider:(DiscoveryProvider *)provider didLoseService:(ServiceDescription *)description
{
    DLog(@"%@ (%@)", description.friendlyName, description.serviceId);
    
    ConnectableDevice *device;

    @synchronized (_allDevices) { device = [_allDevices objectForKey:description.address]; }
    
    if (device)
    {
        [device removeServiceWithId:description.serviceId];
//        for (DiscoveryProvider *provider in _discoveryProviders) {
//            [provider removeService:description];
//        }
        DLog(@"Removed service from device at address %@. Device has %lu services left",
             description.address, (unsigned long)device.services.count);

        if (![device hasServices])
        {
            DLog(@"Device at address %@ has been orphaned (has no services)", description.address);

            @synchronized (_allDevices) { [_allDevices removeObjectForKey:description.address]; }
            @synchronized (_compatibleDevices) { [_compatibleDevices removeObjectForKey:description.address]; }

            [self handleDeviceLoss:device];
        } else
        {
            [self handleDeviceUpdate:device];
        }
    }
}

- (void)discoveryProvider:(DiscoveryProvider *)provider didFailWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
}

#pragma mark - Helper methods

- (void) addServiceDescription:(ServiceDescription *)description toDevice:(ConnectableDevice *)device
{
    Class deviceServiceClass = [_deviceClasses objectForKey:description.serviceId];

    // TODO: move this logic into DeviceService subclass init methods
    if (deviceServiceClass == [DLNAService class])
    {
        if (!description.locationXML)
            return;
    } else if (deviceServiceClass == [NetcastTVService class])
    {
        if (![self descriptionIsNetcastTV:description])
            return;
    }

    ServiceConfig *serviceConfig;

    if (self.useDeviceStore)
        serviceConfig = [self.deviceStore serviceConfigForUUID:description.UUID];

    if (!serviceConfig)
        serviceConfig = [[ServiceConfig alloc] initWithServiceDescription:description];

    serviceConfig.delegate = self;

    __block BOOL deviceAlreadyHasServiceType = NO;
    __block BOOL deviceAlreadyHasService = NO;

    [device.services enumerateObjectsUsingBlock:^(DeviceService *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.serviceDescription.serviceId isEqualToString:description.serviceId])
        {
            deviceAlreadyHasServiceType = YES;

            if ([obj.serviceDescription.UUID isEqualToString:description.UUID])
                deviceAlreadyHasService = YES;

            *stop = YES;
        }
    }];

    if (deviceAlreadyHasServiceType)
    {
        if (deviceAlreadyHasService)
        {
            device.serviceDescription = description;
            
            DeviceService *alreadyAddedService = [device serviceWithName:description.serviceId];
            
            if (alreadyAddedService)
                alreadyAddedService.serviceDescription = description;
            
            return;
        }

        [device removeServiceWithId:description.serviceId];
    }

    DeviceService *deviceService = [DeviceService deviceServiceWithClass:deviceServiceClass serviceConfig:serviceConfig];
    [deviceService setServiceDescription:description];
    [device addService:deviceService];
}

#pragma mark - ConnectableDeviceDelegate methods

- (void) connectableDevice:(ConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed
{
//    [self handleDeviceUpdate:device];
}

- (void)connectableDeviceReady:(ConnectableDevice *)device { }

- (void)connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error { }

#pragma mark - Device Store

- (ConnectableDevice *) lookupMatchingDeviceForDeviceStore:(ServiceConfig *)serviceConfig
{
    __block ConnectableDevice *foundDevice;

    @synchronized (_allDevices) {
        [_allDevices enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *deviceStop)
        {
            [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
            {
                if ([service.serviceConfig.UUID isEqualToString:serviceConfig.UUID])
                {
                    foundDevice = device;

                    *serviceStop = YES;
                    *deviceStop = YES;
                }
            }];
        }];
    }

    return foundDevice;
}

#pragma mark - Device Picker creation

- (DevicePicker *) devicePicker
{
    if (_currentPicker == nil)
    {
        _currentPicker = [[DevicePicker alloc] init];
        
        [self.compatibleDevices enumerateKeysAndObjectsUsingBlock:^(NSString *address, ConnectableDevice *device, BOOL *stop)
        {
            [_currentPicker discoveryManager:self didFindDevice:device];
        }];
    }
    
    return _currentPicker;
}

#pragma mark - ServiceConfigDelegate

- (void)serviceConfigUpdate:(ServiceConfig *)serviceConfig
{
    if (_useDeviceStore && self.deviceStore)
    {
        ConnectableDevice *device = [self lookupMatchingDeviceForDeviceStore:serviceConfig];

        if (device)
            [self.deviceStore updateDevice:device];
    }
}

@end
