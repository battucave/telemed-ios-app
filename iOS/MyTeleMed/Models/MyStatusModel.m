//
//  MyStatusModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyStatusModel.h"
#import "MyStatusXMLParser.h"

@implementation MyStatusModel

static MyStatusModel *sharedMyStatusInstance = nil;

+ (MyStatusModel *)sharedInstance
{
	static dispatch_once_t token;
	
	dispatch_once(&token, ^
	{
		sharedMyStatusInstance = [[super alloc] init];
	});
	
	return sharedMyStatusInstance;
}

- (void)getWithCallback:(void (^)(BOOL success, MyStatusModel *status, NSError *error))callback
{
	[self.operationManager GET:@"MyStatus" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MyStatusXMLParser *parser = [[MyStatusXMLParser alloc] init];
		
		[parser setMyStatus:self];
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			callback(YES, self, nil);
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Error parsing My Status.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MyStatusModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving your Status."];
		
		callback(NO, nil, error);
	}];
}

@end

@implementation OnCallEntryModel

@end
