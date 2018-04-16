//
//  AccountModel.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AccountModel.h"
#import "AccountXMLParser.h"

@implementation AccountModel

- (void)getAccounts
{
	[self getAccountsWithCallback:nil parameters:nil];
}

- (void)getAccountsWithCallback:(void (^)(BOOL success, NSMutableArray *accounts, NSError *error))callback
{
	[self getAccountsWithCallback:callback parameters:nil];
}

// Private method used for all accounts lookups
- (void)getAccountsWithCallback:(void (^)(BOOL success, NSMutableArray *accounts, NSError *error))callback parameters:(NSDictionary *)parameters
{
	[self.operationManager GET:@"Accounts" parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		AccountXMLParser *parser = [[AccountXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if ([xmlParser parse])
		{
			NSMutableArray *accounts = [parser accounts];
			
			/*/ TESTING ONLY (generate fictitious accounts for testing)
			#ifdef MEDTOMED
				for (int i = 0; i < 5; i++)
				{
					AccountModel *account = [[AccountModel alloc] init];
			 
					[account setID:[NSNumber numberWithInt:i]];
					[account setMyAuthorizationStatus:@"Authorized"]; // Unauthorized, Pending, Authorized
					[account setName:[NSString stringWithFormat:@"Account %d", i]];
					[account setPublicKey:[NSString stringWithFormat:@"%d", i]];
			 
					[accounts addObject:account];
				}
			#endif
			// END TESTING ONLY */
			
			// Handle success via callback block
			if (callback)
			{
				callback(YES, accounts, nil);
			}
			// Handle success via delegate
			else if ([self.delegate respondsToSelector:@selector(updateAccounts:)])
			{
				[self.delegate updateAccounts:accounts];
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
	[self getAccountsByHospital:hospitalID withCallback:nil];
}

- (void)getAccountsByHospital:(NSNumber *)hospitalID withCallback:(void (^)(BOOL, NSMutableArray *, NSError *))callback
{
	NSDictionary *parameters = @{
		@"hospID"	: hospitalID
	};
	
	[self getAccountsWithCallback:callback parameters:parameters];
}

- (BOOL)isAuthorized
{
	return [self.MyAuthorizationStatus isEqualToString:@"Authorized"];
}

- (BOOL)isPending
{
	return [self.MyAuthorizationStatus isEqualToString:@"Pending"];
}
#endif


@end
