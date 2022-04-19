//
//  CastServiceChannel.m
//  Connect SDK
//
//  Created by Jeremy White on 2/20/14.
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

#import "CastServiceChannel.h"
#import "ConnectError.h"
#import "CastWebAppSession.h"
#import <ScreenMirroring-Swift.h>

@implementation CastServiceChannel
{
    __weak id<WebAppSessionDelegate> _session;
}

- (instancetype)initWithAppId:(NSString *)appId session:(id<WebAppSessionDelegate>)session
{
    NSString *channel = [ChromecastWebApp channelToObjc];
    self = [super initWithNamespace:channel];

    if (self)
    {
        _session = session;
    }

    return self;
}

- (void)didReceiveTextMessage:(NSString *)message
{
    if (!_session && ![_session respondsToSelector:@selector(webAppSession:didReceiveMessage:)])
        return;

    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError;
    id messageJSON = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:&parseError];

    if (parseError || !messageJSON)
    {
        dispatch_on_main(^{
            [self->_session webAppSession:nil didReceiveMessage:message];
        });
    } else
    {
        dispatch_on_main(^{
            [self->_session webAppSession:nil didReceiveMessage:messageJSON];
        });
    }
}

- (void)didConnect
{
    dispatch_on_main(^{
        if (self.connectionSuccess)
            self.connectionSuccess(nil);

        self.connectionSuccess = nil;
        self.connectionFailure = nil;
    });
}

- (void)didDisconnect
{
    if (_session && _session && [_session respondsToSelector:@selector(webAppSessionDidDisconnect:)])
        dispatch_on_main(^{ [self->_session webAppSessionDidDisconnect:self->_session]; });
}

@end
