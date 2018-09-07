//
//  TeleMedHTTPSessionManager.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/28/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface TeleMedHTTPSessionManager : AFHTTPSessionManager

+ (TeleMedHTTPSessionManager *)sharedInstance;
- (instancetype)initWithBaseURL:(NSURL *)url;

@end
