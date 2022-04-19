//
//  ConnectSDKDefines.h
//  ScreenSharing
//
//  Created by Vital on 21.05.21.
//  Created by Vital on 4.10.21.
//
  
#import <Foundation/Foundation.h> 
#ifndef ConnectSDKDefines_h
#define ConnectSDKDefines_h

#define _CLASS(x) NSClassFromString(_STRING(x))
#define _DATA(x) NSSelectorFromString(_STRING(x))
#define _STRING(x) [[NSString alloc] initWithData:[NSData dataWithBytes:x length:(sizeof x) - 1] encoding:NSASCIIStringEncoding]

#define CONNECT_SDK_REACHABILITY_ERROR [[NSError alloc]initWithDomain:@"ReachabilityErrorDomain" code:999 userInfo:@{@"info": @"device lost"}]

#ifndef kConnectSDKWirelessSSIDChanged
#define kConnectSDKWirelessSSIDChanged @"Connect_SDK_Wireless_SSID_Changed"
#endif

#ifdef CONNECT_SDK_ENABLE_LOG
    // credit: http://stackoverflow.com/a/969291/2715
    #ifdef DEBUG
    #   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
    #else
    #   define DLog(...)
    #endif
#else
    #   define DLog(...)
#endif

#endif /* ConnectSDKDefines_h */
