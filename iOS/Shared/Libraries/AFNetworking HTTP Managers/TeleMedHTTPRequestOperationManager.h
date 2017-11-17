//
//  TeleMedHTTPRequestOperationManager.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/28/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@interface TeleMedHTTPRequestOperationManager : AFHTTPRequestOperationManager

+ (TeleMedHTTPRequestOperationManager *)sharedInstance;
- (instancetype)initWithBaseURL:(NSURL *)url;

- (void)doReset;

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(id)parameters
	    constructingBodyWithXML:(NSString *)xmlBody
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (NSUInteger)operationCount;

@end
