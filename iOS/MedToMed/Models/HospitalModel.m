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
			// Sort hospitals by name
			NSMutableArray *hospitals = [[[parser hospitals] sortedArrayUsingComparator:^NSComparisonResult(HospitalModel *hospitalModelA, HospitalModel *hospitalModelB)
			{
				return [hospitalModelA.Name compare:hospitalModelB.Name];
			}] mutableCopy];
			
			/*/ TESTING ONLY (generate fictitious hospitals for testing)
			for (int i = 0; i < 5; i++)
			{
				HospitalModel *hospital = [[HospitalModel alloc] init];
				
				[hospital setID:[NSNumber numberWithInt:i]];
				[hospital setMyAuthenticationStatus:@"OK"]; // NONE, Requested, OK, Admin, Denied, Blocked
				[hospital setName:[NSString stringWithFormat:@"Hospital %d", i]];
				[hospital setAbbreviatedName:[NSString stringWithFormat:@"Hospital %d", i]];
			 
				[hospitals addObject:hospital];
			}
			// END TESTING ONLY */
			
			// Handle success via callback block
			if (callback)
			{
				callback(YES, hospitals, nil);
			}
			// Handle success via delegate
			else if ([self.delegate respondsToSelector:@selector(updateHospitals:)])
			{
				[self.delegate updateHospitals:hospitals];
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

- (BOOL)isAdmin
{
	return [self.MyAuthenticationStatus isEqualToString:@"Admin"];
}

- (BOOL)isAuthenticated
{
	return ([self isAdmin] || [self.MyAuthenticationStatus isEqualToString:@"OK"]);
}

- (BOOL)isBlocked
{
	return [self.MyAuthenticationStatus isEqualToString:@"Blocked"];
}

- (BOOL)isDenied
{
	return [self.MyAuthenticationStatus isEqualToString:@"Denied"];
}

- (BOOL)isRequested
{
	return [self.MyAuthenticationStatus isEqualToString:@"Requested"];
}

@end
