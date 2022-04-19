//
//  FileServer.h
//  ScreenSharing
//
//  Created by Vital on 20.10.20.
//  Created by Vital on 4.10.21.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "GCDWebServer.h"

@interface FileServer : NSObject
   
+ (instancetype)shareServer;
 
- (void)startOnPort:(int)port;
 
- (void)stop;
 
- (BOOL)isRunning;
 
- (NSString *)getUrlForLocalVideo:(NSString *)localId quality:(int)quality;
 
- (NSString *)getUrlForLocalImage;

- (NSString *)getUrlFromDocumentPath:(NSString *)path;

@end
