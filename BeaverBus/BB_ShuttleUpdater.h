//
//  BB_ShuttleUpdater.h
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BB_ShuttleUpdater : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>



@property(strong, readonly) NSURLSession *session;

+ (BB_ShuttleUpdater *)get;
- (BOOL)initialNetworkRequest;
- (void)startShuttleUpdaterHandler;

@end
