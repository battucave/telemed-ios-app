//
//  OnCallSlotModel.m
//  MedToMed
//
//  Created by Shane Goodwin on 4/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "OnCallSlotModel.h"
#import "OnCallSlotXMLParser.h"

@implementation OnCallSlotModel

- (void)getOnCallSlots:(NSNumber *)accountID
{
	NSDictionary *parameters = @{
		@"acctID"	: accountID
	};
	
	[self.operationManager GET:@"OnCallSlots" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		OnCallSlotXMLParser *parser = [[OnCallSlotXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			// Handle success via delegate
			if ([self.delegate respondsToSelector:@selector(updateOnCallSlots:)])
			{
				[self.delegate updateOnCallSlots:[[parser onCallSlots] mutableCopy]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"On Call Slots Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the On Call Slots.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via delegate
			if ([self.delegate respondsToSelector:@selector(updateOnCallSlotsError:)])
			{
				[self.delegate updateOnCallSlotsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MessageRecipientModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the On Call Slots." andTitle:@"On Call Slots Error"];
		
		// Handle error via delegate
		if ([self.delegate respondsToSelector:@selector(updateOnCallSlotsError:)])
		{
			[self.delegate updateOnCallSlotsError:error];
		}
	}];
}

@end
