//
//  AuthenticationHTTPSessionManager.m
//  TeleMed
//
//  Created by Shane Goodwin on 6/18/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AuthenticationHTTPSessionManager.h"

@implementation AuthenticationHTTPSessionManager

+ (AuthenticationHTTPSessionManager *)sharedInstance
{
	static AuthenticationHTTPSessionManager *_sharedInstance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^
	{
		_sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:AUTHENTICATION_BASE_URL @"api/"]];
	});
	
	return _sharedInstance;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
	if (self = [super initWithBaseURL:url])
	{
		self.requestSerializer = [AFHTTPRequestSerializer serializer];
		self.responseSerializer = [AFXMLParserResponseSerializer serializer];
		
		// Customize Request Serializer
		[self.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringCacheData];
		[self.requestSerializer setTimeoutInterval:NSURLREQUEST_TIMEOUT_PERIOD];
		
		// Set required XML Request Headers
		[self.requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
		[self.requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
		
		// Force all HTTP methods to pass parameters in URI
		[self.requestSerializer setHTTPMethodsEncodingParametersInURI:[NSSet setWithArray:[NSArray arrayWithObjects:@"GET", @"HEAD", @"POST", @"PUT", @"PATCH", @"DELETE", nil]]];
	}
	
	return self;
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString parameters:(id)parameters constructingBodyWithXML:(NSString *)xmlBody success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
	NSError *serializationError = nil;
	NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
	
	[request setHTTPBody:[xmlBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	if (serializationError)
	{
		if (failure)
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
			dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^
			{
				failure(nil, serializationError);
			});
#pragma clang diagnostic pop
		}
		
		return nil;
	}
	
	__block NSURLSessionDataTask *dataTask;
	dataTask = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error)
	{
		if (error)
		{
			if (failure)
			{
				failure(dataTask, error);
			}
		}
		else
		{
			if (success)
			{
				success(dataTask, responseObject);
			}
		}
	}];
	
	[dataTask resume];
	
	return dataTask;
}

@end
