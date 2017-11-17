//
//  TeleMedHTTPSessionManager.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/28/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "TeleMedHTTPSessionManager.h"

@implementation TeleMedHTTPSessionManager

+ (TeleMedHTTPSessionManager *)sharedInstance
{
	static TeleMedHTTPSessionManager *_sharedInstance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^
	{
		_sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:API_BASE_URL]];
	});
	
	return _sharedInstance;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
	if(self = [super initWithBaseURL:url])
	{
		self.requestSerializer = [AFHTTPRequestSerializer serializer];
		self.responseSerializer = [AFXMLParserResponseSerializer serializer];
		//self.responseSerializer = [AFHTTPResponseSerializer serializer];
		
		// Set required XML Request Headers
		[self.requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
		[self.requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	}
	
	return self;
}

@end
