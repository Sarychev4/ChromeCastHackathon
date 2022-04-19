//
//  FileServer.m
//  ScreenSharing
//
//  Created by Vital on 20.10.20.
//  Created by Vital on 4.10.21.
//

#import "GCDWebServerPrivate.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerFileResponse.h"
#import <UIKit/UIKit.h>
#import "DLNAFileServer.h"
#import <ScreenMirroring-Swift.h>

@interface FileServer () <GCDWebServerDelegate>
 
@property (nonatomic, strong) GCDWebServer *webServer;

@end

@implementation FileServer

@synthesize webServer = _webServer;

+ (instancetype)shareServer
{
    static FileServer *s;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        s = [[self alloc] init];
        
    });
    
    return s;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        [GCDWebServer setLogLevel:kGCDWebServerLoggingLevel_Error];
        _webServer = [[GCDWebServer alloc] init];
        _webServer.delegate = self;
    }
    
    return self;
}

- (void)startOnPort:(int)port
{
    if (_webServer.isRunning) {
        return;
    }
    
    [_webServer removeAllHandlers];
     
    GCDWebServerResponse *(^webServerResponseBlock)(GCDWebServerRequest *request) = ^GCDWebServerResponse *(GCDWebServerRequest *request) {
        // according to the UPnP specification, a subscriber must reply with HTTP 200 OK
        // to successfully acknowledge the notification
        return [GCDWebServerResponse responseWithStatusCode:kGCDWebServerHTTPStatusCode_OK];
    };
    
    [_webServer addHandlerForMethod:@"GET" path:@"/video" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
        
//        NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
//        NSArray *queryItems = [components queryItems];
//
//        NSMutableDictionary *dict = [NSMutableDictionary new];
//
//        for (NSURLQueryItem *item in queryItems) {
//            [dict setObject:[item value] forKey:[item name]];
//        }
//        NSString *localId = dict[@"localId"];
        
        
//        NSString *localId = [NSUserDefaults.standardUserDefaults stringForKey:@"testAssetId"];
//        NSNumber *quality = @(3);// dict[@"quality"] ? dict[@"quality"] : @(4);
//
//        if (localId == nil || [localId isEqualToString:@""]) {
//            completionBlock([GCDWebServerResponse responseWithStatusCode:404]);
//            return;
//        }
//
//        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil].firstObject;
//
//        if (asset == nil) {
//            completionBlock([GCDWebServerResponse responseWithStatusCode:404]);
//            return;
//        }
//
//        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
//
//        options.deliveryMode = quality.intValue == 1 ? PHVideoRequestOptionsDeliveryModeFastFormat:
//                               quality.intValue == 2 ? PHVideoRequestOptionsDeliveryModeMediumQualityFormat :
//                               quality.intValue == 3 ? PHVideoRequestOptionsDeliveryModeHighQualityFormat :
//                                                       PHVideoRequestOptionsDeliveryModeAutomatic;
//
//        options.version = PHVideoRequestOptionsVersionOriginal;
//        [options setNetworkAccessAllowed:YES];
//
//        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
//
//            AVURLAsset *avUrlAsset = (AVURLAsset *)asset;
//
//            NSString *filePath = avUrlAsset.URL.path;
//            GCDWebServerFileResponse *response = [GCDWebServerFileResponse responseWithFile:filePath byteRange:request.byteRange];
//            NSLog(@">>> request asset mime:%@ at url: %@", response.contentType, filePath);
//            completionBlock(response);
//
//        }];
         
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//        NSString *cacheDirectory = [paths firstObject];
//        NSString *filePath = [cacheDirectory stringByAppendingString:@"/Video.mp4"];
        NSString *filePath = [NSUserDefaults.standardUserDefaults stringForKey:@"tempAssetPath"];
        GCDWebServerFileResponse *response = [GCDWebServerFileResponse responseWithFile:filePath byteRange:request.byteRange];
        NSLog(@">>> request asset mime:%@ at url: %@", response.contentType, filePath);
        completionBlock(response);
    }];
    
    [_webServer addHandlerForMethod:@"GET" path:@"/image" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheDirectory = [paths firstObject];
        NSString *filePath = [cacheDirectory stringByAppendingString:@"/Image.jpg"];
        GCDWebServerFileResponse *response = [GCDWebServerFileResponse responseWithFile:filePath];
            completionBlock(response);
    }];
     
    [_webServer addHandlerForMethod:@"GET" path:@"/file" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
        
        NSString *url = [request.URL.absoluteString stringByRemovingPercentEncoding];
        
        NSRange range = [url rangeOfString:@"/file?"];
        
        NSString *parameterString = [url substringFromIndex:(range.location + range.length)];
        
        if (parameterString == nil || [parameterString isEqualToString:@""])
        {
            completionBlock([GCDWebServerResponse responseWithStatusCode:404]);
            
            return;
        }
        
        NSRange pathRange = [parameterString rangeOfString:@"path="];
        
        NSString *pathString = [parameterString substringFromIndex:(pathRange.location + pathRange.length)];
        
        if (pathString == nil || [pathString isEqualToString:@""])
        {
            completionBlock([GCDWebServerResponse responseWithStatusCode:404]);
            
            return;
        }
        
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentPath, pathString];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
        {
            completionBlock([GCDWebServerResponse responseWithStatusCode:404]);

            return;
        }
        
        GCDWebServerResponse *response = [GCDWebServerFileResponse responseWithFile:fullPath byteRange:request.byteRange];
        
        completionBlock(response);
        
    }];
    
    [_webServer addHandlerForMethod:@"GET" path:@"/faq" requestClass:[GCDWebServerRequest class] asyncProcessBlock:^(__kindof GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
        completionBlock([GCDWebServerDataResponse responseWithHTML:NSString.FAQ_HTML]);
    }];
//    [_webServer addDefaultHandlerForMethod:@"GET"
//                                     path:@"/image"
//                                requestClass:[GCDWebServerRequest class]
//                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
//
//
//
//       }];
    
    [_webServer addDefaultHandlerForMethod:@"NOTIFY"
                               requestClass:[GCDWebServerDataRequest class]
                               processBlock:webServerResponseBlock];
    
    NSError *myError = nil;
    [_webServer startWithOptions:@{
        GCDWebServerOption_AutomaticallySuspendInBackground : @(YES),
        GCDWebServerOption_Port: [NSNumber numberWithInteger:port]
    } error:&myError];
}

- (void)stop
{
    if (_webServer)
    {
        [_webServer stop];
    }
}

- (BOOL)isRunning
{
    if (!_webServer)
    {
        return NO;
    }
    return [_webServer isRunning];
}

- (NSString *)getUrlForLocalVideo:(NSString *)localId quality:(int)quality {
    [NSUserDefaults.standardUserDefaults setObject:localId forKey:@"testAssetId"];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%@%@?%f", _webServer.serverURL, @"video", timeStamp];
//    return [NSString stringWithFormat:@"%@%@?localId=%@&quality=%d", _webServer.serverURL, @"video", localId, quality];
}

- (NSString *)getUrlForLocalImage {
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%@%@%f", _webServer.serverURL, @"image?", timeStamp];
}

- (NSString *)getUrlFromDocumentPath:(NSString *)path
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *shortPath = [path stringByReplacingOccurrencesOfString:documentPath withString:@""];
    
    NSString *url = [NSString stringWithFormat:@"%@%@path=%@", _webServer.serverURL, @"file?", shortPath];
    
    return [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

#pragma mark - GCDWebServerDelegate

- (void) webServerDidStart:(GCDWebServer *)server {
    
}

- (void)webServerDidStop:(GCDWebServer *)server {
    
} 

@end
