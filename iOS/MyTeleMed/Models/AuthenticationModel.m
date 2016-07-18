//
//  AuthenticationModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/22/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AuthenticationModel.h"
#import "AppDelegate.h"
#import "AuthenticationHTTPSessionManager.h"
#import "TeleMedHTTPRequestOperationManager.h"
#import "KeyChainItemWrapper.h"
#import "AuthenticationXMLParser.h"

@interface AuthenticationModel()

@property (nonatomic) NSDate *AccessTokenExpiration;

@end

@implementation AuthenticationModel

@synthesize AccessToken = _AccessToken;
@synthesize RefreshToken = _RefreshToken;

@synthesize AccessTokenExpiration = _AccessTokenExpiration;

static AuthenticationModel *sharedAuthenticationInstance = nil;

+ (AuthenticationModel *)sharedInstance
{
	static dispatch_once_t token;
	
	dispatch_once(&token, ^
	{
		sharedAuthenticationInstance = [[super alloc] init];
	});
	
	return sharedAuthenticationInstance;
}

- (id)init
{
	if(self = [super init])
	{
		// TEMPORARY: (Version 3.3) - Remove old Login Keychain items - This logic can be removed in a future update.
		KeychainItemWrapper *keyChainLogin = [[KeychainItemWrapper alloc] initWithIdentifier:@"Login" accessGroup:nil];
		
		[keyChainLogin resetKeychainItem];
	}
	
	return self;
}

// Override RefreshToken getter
- (NSString *)RefreshToken
{
	// If RefreshToken is not already set, check Keychain
	if( ! _RefreshToken)
	{
		KeychainItemWrapper *keyChainRefreshToken = [[KeychainItemWrapper alloc] initWithIdentifier:@"RefreshToken" accessGroup:nil];
		
		_RefreshToken = [keyChainRefreshToken objectForKey:(__bridge id)kSecValueData];
		
		if([_RefreshToken isEqualToString:@""])
		{
			_RefreshToken = nil;
		}
	}
	
	return _RefreshToken;
}

// Override AccessToken setter to also store Access Token's Expiration
- (void)setAccessToken:(NSString *)newAccessToken
{
	if(_AccessToken != newAccessToken)
	{
		_AccessTokenExpiration = nil;
		
		if(newAccessToken != nil)
		{
			_AccessTokenExpiration = [[NSDate date] dateByAddingTimeInterval:ACCESS_TOKEN_EXPIRATION_TIME];
		}
		
		//NSLog(@"Access Token Expiration: %@", self.AccessTokenExpiration);
		
		_AccessToken = newAccessToken;
	}
}

// Override RefreshToken setter to store value in Keychain
- (void)setRefreshToken:(NSString *)newRefreshToken
{
	if(_RefreshToken != newRefreshToken)
	{
		KeychainItemWrapper *keyChainRefreshToken = [[KeychainItemWrapper alloc] initWithIdentifier:@"RefreshToken" accessGroup:nil];
		
		[keyChainRefreshToken setObject:newRefreshToken forKey:(__bridge id)(kSecValueData)];
		[keyChainRefreshToken setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
		
		_RefreshToken = newRefreshToken;
	}
}

// Public Method
- (void)getNewTokensWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
	[self getNewTokensWithSuccess:success failure:failure isRetry:NO];
}

// Private Method with Internal Retry Mechanism
- (void)getNewTokensWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure isRetry:(BOOL)isRetry
{
	// If no Refresh Token found, then tokens cannot be refreshed
	if( ! self.RefreshToken)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[self doLogout];
		});
		
		return;
	}
	
	AuthenticationHTTPSessionManager *authenticationManager = [AuthenticationHTTPSessionManager sharedInstance];
	
	// Turn on isWorking
	self.isWorking = YES;
	
	NSString *xmlBody = [NSString stringWithFormat:
		@"<AuthNToken xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://schemas.datacontract.org/2004/07/AuthZ.Models\">"
			"<AccessToken>%@</AccessToken>"
			"<RefreshToken>%@</RefreshToken>"
		"</AuthNToken>",
		(self.AccessToken ?: @""), self.RefreshToken];
	
	NSLog(@"Get New Access and Refresh Tokens");
	//NSLog(@"XML Body: %@", xmlBody);
	
	[authenticationManager PUT:@"AuthN" parameters:nil constructingBodyWithXML:xmlBody success:^(__unused NSURLSessionDataTask *task, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		AuthenticationXMLParser *parser = [[AuthenticationXMLParser alloc] init];
		
		[parser setAuthentication:self];
		[xmlParser setDelegate:parser];
		
		// Parse the XML file
		if([xmlParser parse])
		{
			// Set Tokens if found in response
			if( ! [self.AccessToken isEqualToString:@""] && ! [self.RefreshToken isEqualToString:@""])
			{
				NSLog(@"New Access Token: %@", self.AccessToken);
				NSLog(@"New Refresh Token: %@", self.RefreshToken);
				
				// Run success callback
				return success();
			}
		}
		
		// Tokens not found in response or error parsing the XML file
		NSLog(@"Error Refreshing Tokens");
		
		dispatch_async(dispatch_get_main_queue(), ^
		{
			// Turn off isWorking
			self.isWorking = NO;
			
			[self doLogout];
		});
	}
	failure:^(__unused NSURLSessionDataTask *task, NSError *error)
	{
		AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		UIStoryboard *currentStoryboard = appDelegate.window.rootViewController.storyboard;
		NSString *currentStoryboardName = [currentStoryboard valueForKey:@"name"];
		
		NSData *data = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey];
		
		NSLog(@"Refresh Tokens Error %ld: %@", (long)error.code, [[NSString alloc] initWithData:[NSData dataWithData:data] encoding:NSUTF8StringEncoding]);
		
		// First retry the operation again after a delay
		if( ! isRetry)
		{
			NSLog(@"Retry Refreshing Tokens");
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
			{
				[self getNewTokensWithSuccess:success failure:failure isRetry:YES];
			});
		}
		// Handle timeout issues differently if not in LoginSSO Storyboard
		else if( ! [currentStoryboardName isEqualToString:@"LoginSSO"] && (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorTimedOut || error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorNetworkConnectionLost))
		{
			NSLog(@"Refreshing Tokens Timed Out: %@", error);
			
			// Control timeout errors by setting them to a standard code
			if(error.code != NSURLErrorNotConnectedToInternet)
			{
				error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:NSURLErrorTimedOut userInfo:error.userInfo];
			}
			
			failure(error);
		}
		// If error is not related to device being offline, then RefreshToken is no longer valid so force the user to login again
		else
		{
			NSLog(@"Error Refreshing Tokens: %@", error);
			
			dispatch_async(dispatch_get_main_queue(), ^
			{
				// Turn off isWorking
				self.isWorking = NO;
				
				[self doLogout];
			});
		}
	}];
}

- (BOOL)accessTokenIsValid
{
	return self.AccessToken && [[NSDate date] compare:self.AccessTokenExpiration] == NSOrderedAscending;
}

- (void)doLogout
{
	KeychainItemWrapper *keyChainRefreshToken = [[KeychainItemWrapper alloc] initWithIdentifier:@"RefreshToken" accessGroup:nil];
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	TeleMedHTTPRequestOperationManager *operationManager = [TeleMedHTTPRequestOperationManager sharedInstance];
	
	// Reset Refresh Token in Keychain
	[keyChainRefreshToken resetKeychainItem];
	
	// Reset Operation Manager
	[operationManager doReset];
	
	// Reset tokens in app
	self.AccessToken = nil;
	self.AccessTokenExpiration = nil;
	self.RefreshToken = nil;
	
	// Go to LoginSSO screen
	UIStoryboard *loginSSOStoryboard;
	UIStoryboard *currentStoryboard = appDelegate.window.rootViewController.storyboard;
	NSString *currentStoryboardName = [currentStoryboard valueForKey:@"name"];
	
	NSLog(@"Current Storyboard: %@", currentStoryboardName);
	
	if([currentStoryboardName isEqualToString:@"LoginSSO"])
	{
		loginSSOStoryboard = currentStoryboard;
	}
	else
	{
		loginSSOStoryboard = [UIStoryboard storyboardWithName:@"LoginSSO" bundle:nil];
	}
	
	UIViewController *loginSSOViewController = [loginSSOStoryboard instantiateViewControllerWithIdentifier:@"LoginSSOViewController"];
	[appDelegate.window setRootViewController:loginSSOViewController];
	[appDelegate.window makeKeyAndVisible];
}

@end
