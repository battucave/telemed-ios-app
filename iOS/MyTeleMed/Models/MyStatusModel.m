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

+ (instancetype)sharedInstance
{
	static dispatch_once_t token;
	static MyStatusModel *sharedMyStatusInstance = nil;
	
	dispatch_once(&token, ^
	{
		sharedMyStatusInstance = [[self alloc] init];
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
		if ([xmlParser parse])
		{
			// Sort on call now entries by start time
			self.CurrentOnCallEntries = [self.CurrentOnCallEntries sortedArrayUsingComparator:^NSComparisonResult(OnCallEntryModel *onCallEntryModelA, OnCallEntryModel *onCallEntryModelB)
			{
				return [onCallEntryModelA.Started compare:onCallEntryModelB.Started];
			}];
			
			// Sort next on call entries by start time
			self.FutureOnCallEntries = [self.FutureOnCallEntries sortedArrayUsingComparator:^NSComparisonResult(OnCallEntryModel *onCallEntryModelA, OnCallEntryModel *onCallEntryModelB)
			{
				return [onCallEntryModelA.WillStart compare:onCallEntryModelB.WillStart];
			}];
			
			callback(YES, self, nil);
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Status Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving your Status.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MyStatusModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving your Status." andTitle:@"Status Error"];
		
		callback(NO, nil, error);
	}];
}

@end

@implementation OnCallEntryModel

@end
