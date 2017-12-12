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
	[self getHospitalsWithCallback:nil];
}

- (void)getHospitalsWithCallback:(void (^)(BOOL success, NSMutableArray *hospitals, NSError *error))callback
{
	[self.operationManager GET:@"Hospitals" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		HospitalXMLParser *parser = [[HospitalXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			// Handle success via callback block
			if (callback)
			{
				callback(YES, [parser hospitals], nil);
			}
			// Handle success via delegate
			else if ([self.delegate respondsToSelector:@selector(updateHospitals:)])
			{
				[self.delegate updateHospitals:[parser hospitals]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Hospitals Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Hospitals.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback block
			if (callback)
			{
				callback(NO, nil, error);
			}
			// Handle error via delegate
			else if ([self.delegate respondsToSelector:@selector(updateHospitalsError:)])
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
		
		// Handle error via callback block
		if (callback)
		{
			callback(NO, nil, error);
		}
		// Handle error via delegate
		else if ([self.delegate respondsToSelector:@selector(updateHospitalsError:)])
		{
			[self.delegate updateHospitalsError:error];
		}
	}];
}

- (BOOL)isHospitalAdmin:(HospitalModel *)hospital
{
	return [hospital.MyAuthenticationStatus isEqualToString:@"Admin"];
}

- (BOOL)isHospitalAuthorized:(HospitalModel *)hospital
{
	return ([self isHospitalAdmin:hospital] || [hospital.MyAuthenticationStatus isEqualToString:@"OK"]);
}

- (BOOL)isHospitalBlocked:(HospitalModel *)hospital
{
	return [hospital.MyAuthenticationStatus isEqualToString:@"Blocked"];
}

- (BOOL)isHospitalDenied:(HospitalModel *)hospital
{
	return [hospital.MyAuthenticationStatus isEqualToString:@"Denied"];
}

- (BOOL)isHospitalPending:(HospitalModel *)hospital
{
	return [hospital.MyAuthenticationStatus isEqualToString:@"Requested"];
}

@end
