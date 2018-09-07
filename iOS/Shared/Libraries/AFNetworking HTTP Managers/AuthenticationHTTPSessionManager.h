//
//  AuthenticationHTTPSessionManager.h
//  TeleMed
//
//  Created by Shane Goodwin on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface AuthenticationHTTPSessionManager : AFHTTPSessionManager

+ (AuthenticationHTTPSessionManager *)sharedInstance;
- (instancetype)initWithBaseURL:(NSURL *)url;

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
				   parameters:(id)parameters
	  constructingBodyWithXML:(NSString *)xmlBody
					  success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
					  failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end
