//
//  AccountModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AccountModel.h"
#import "AccountXMLParser.h"

@implementation AccountModel

- (void)getAccounts
{
	[self getAccountsWithCallback:nil];
}

- (void)getAccountsWithCallback:(void (^)(BOOL success, NSMutableArray *accounts, NSError *error))callback
{
	[self.operationManager GET:@"Accounts" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		AccountXMLParser *parser = [[AccountXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			// Handle success via callback block
			if (callback)
			{
				callback(YES, [parser accounts], nil);
			}
			// Handle success via delegate
			else if ([self.delegate respondsToSelector:@selector(updateAccounts:)])
			{
				[self.delegate updateAccounts:[parser accounts]];
			}
		}
		// Error parsing XML file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Accounts Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving the Accounts.", NSLocalizedDescriptionKey, nil]];
			
			// Handle error via callback block
			if (callback)
			{
				callback(NO, nil, error);
			}
			// Handle error via delegate
			else if ([self.delegate respondsToSelector:@selector(updateAccountsError:)])
			{
				[self.delegate updateAccountsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"AccountModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Accounts." andTitle:@"Accounts Error"];
		
		// Handle error via callback block
		if (callback)
		{
			callback(NO, nil, error);
		}
		// Handle error via delegate
		else if ([self.delegate respondsToSelector:@selector(updateAccountsError:)])
		{
			[self.delegate updateAccountsError:error];
		}
	}];
}


#pragma mark - MyTeleMed

#ifdef MYTELEMED
- (void)getAccountByID:(NSNumber *)accountID
{
	NSLog(@"Get Account By ID: %@", accountID);
}

- (void)getAccountByPublicKey:(NSNumber *)publicKey
{
	NSLog(@"Get Account By Public Key: %@", publicKey);
}
#endif


#pragma mark - MedToMed

#ifdef MEDTOMED
- (void)getAccountsByHospital:(NSNumber *)hospitalID
{
	NSLog(@"Get Accounts By Hospital: %@", hospitalID);
}

- (BOOL)isAccountAuthorized:(AccountModel *)account
{
	return [account.MyAuthorizationStatus isEqualToString:@"Authorized"];
}

- (BOOL)isAccountPending:(AccountModel *)account
{
	return [account.MyAuthorizationStatus isEqualToString:@"Pending"];
}
#endif


@end
