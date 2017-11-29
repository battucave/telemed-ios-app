//
//  HospitalModel.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/29/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "HospitalModel.h"
#import "HospitalXMLParser.h"

@implementation HospitalModel

- (void)getHospitals
{
	[self.operationManager GET:@"Hospitals" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		HospitalXMLParser *parser = [[HospitalXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateHospitals:)])
			{
				[self.delegate updateHospitals:[parser hospitals]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Hospitals Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Hospitals.", NSLocalizedDescriptionKey, nil]];
			
			// Only handle error if user still on same screen
			if([self.delegate respondsToSelector:@selector(updateHospitalsError:)])
			{
				[self.delegate updateHospitalsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"HospitalModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Hospitals." andTitle:@"Hospitals Error"];
		
		// Only handle error if user still on same screen
		if([self.delegate respondsToSelector:@selector(updateHospitalsError:)])
		{
			[self.delegate updateHospitalsError:error];
		}
	}];
}

@end
