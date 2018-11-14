//
//  TimeZoneModel.m
//  Med2Med
//
//  Created by Shane Goodwin on 7/13/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "TimeZoneModel.h"
#import "TimeZoneXMLParser.h"

@implementation TimeZoneModel

- (void)getTimeZones
{
	[self.operationManager GET:@"TimeZone" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		TimeZoneXMLParser *parser = [[TimeZoneXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			// Handle success via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(updateTimeZones:)])
			{
				[self.delegate updateTimeZones:[[parser timeZones] copy]];
			}
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Time Zones Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Time Zones.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if (self.delegate && [self.delegate respondsToSelector:@selector(updateTimeZonesError:)])
			{
				[self.delegate updateTimeZonesError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"TimeZoneModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Time Zones." andTitle:@"Time Zones Error"];
		
		// Handle error via delegate
		if (self.delegate && [self.delegate respondsToSelector:@selector(updateTimeZonesError:)])
		{
			[self.delegate updateTimeZonesError:error];
		}
	}];
}

@end
