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
	[self.operationManager GET:@"Accounts" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		AccountXMLParser *parser = [[AccountXMLParser alloc] init];
		
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			if([self.delegate respondsToSelector:@selector(updateAccounts:)])
			{
				[self.delegate updateAccounts:[parser accounts]];
			}
		}
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Error parsing Accounts.", NSLocalizedDescriptionKey, nil]];
			
			if([self.delegate respondsToSelector:@selector(updateAccountsError:)])
			{
				[self.delegate updateAccountsError:error];
			}
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"AccountModel Error: %@", error);
		
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving the Accounts."];
		
		if([self.delegate respondsToSelector:@selector(updateAccountsError:)])
		{
			[self.delegate updateAccountsError:error];
		}
	}];
}

- (void)getAccountByID:(NSNumber *)accountID
{
	
}

- (void)getAccountByPublicKey:(NSNumber *)publicKey
{
	
}


@end
