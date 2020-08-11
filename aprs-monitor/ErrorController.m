//
//  Copyright (C) 2020 Twilio, Inc.
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

#import "ErrorController.h"

static ErrorController* sSharedManager = NULL;


@implementation ErrorController



+ (ErrorController*)shared
{
    if( !sSharedManager )
        sSharedManager = [[ErrorController alloc] init];
    
    return sSharedManager;
}


+ (void)unimplemented:(UIWindow* __nullable)window
{
    [[ErrorController shared] showError:@"Hi there, this isn't implemented yet.  Thanks for helping test the beta!" withTitle:@"Feature not available" inWindow:window];
}

- (void)showError:(NSString* __nonnull)message withTitle:(NSString* __nonnull)title inWindow:(UIWindow* __nullable)window
{
    void (^errorBlock)( void ) = ^( void ) {
        UIWindow* presentingWindow = window ? window : [[UIApplication sharedApplication] keyWindow];
        
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIViewController* topController = presentingWindow.rootViewController;
        UIViewController* presentingController = topController;

        do
        {
            presentingController = topController.presentedViewController;
            if( presentingController )
                topController = presentingController;
        }
        while( presentingController );
        
        [topController presentViewController:alertController animated:YES completion:nil];
    };

    if( NSThread.isMainThread )
        errorBlock();
    else
        dispatch_async( dispatch_get_main_queue(), errorBlock );
}


@end
