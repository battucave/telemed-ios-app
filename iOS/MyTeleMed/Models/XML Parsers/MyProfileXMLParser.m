//
//  MyProfileXMLParser.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyProfileXMLParser.h"
#import "AccountModel.h"
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"
#import "TimeZoneModel.h"

@interface MyProfileXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;
@property (nonatomic) NSMutableArray *myRegisteredDevices;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) RegisteredDeviceModel *registeredDevice;
@property (nonatomic) TimeZoneModel *timeZone;

@end

@implementation MyProfileXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize my registered devices array
	self.myRegisteredDevices = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"MyPreferredAccount"])
	{
		// Initialize a preferred account
		self.myProfile.MyPreferredAccount = [[AccountModel alloc] init];
		
		self.currentModel = @"MyPreferredAccountModel";
	}
	else if ([elementName isEqualToString:@"RegisteredDevice"])
	{
		// Initialize a registered device
		self.registeredDevice = [[RegisteredDeviceModel alloc] init];
		
		self.currentModel = @"RegisteredDeviceModel";
	}
	else if ([elementName isEqualToString:@"TimeZone"] || [elementName isEqualToString:@"MyTimeZone"])
	{
		// Initialize a time zone
		self.timeZone = [[TimeZoneModel alloc] init];
		
		self.currentModel = @"TimeZoneModel";
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (! self.currentElementValue)
	{
		self.currentElementValue = [[NSMutableString alloc] initWithString:string];
	}
	else
	{
		[self.currentElementValue appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
{
	if ([elementName isEqualToString:@"MyPreferredAccount"])
	{
		self.currentModel = nil;
	}
	else if ([elementName isEqualToString:@"MyRegisteredDevices"])
	{
		self.myProfile.MyRegisteredDevices = self.myRegisteredDevices;
	}
	else if ([elementName isEqualToString:@"MyTimeZone"])
	{
		self.myProfile.MyTimeZone = self.timeZone;
		self.timeZone = nil;
		self.currentModel = nil;
	}
	else if ([elementName isEqualToString:@"RegisteredDevice"])
	{
		[self.myRegisteredDevices addObject:self.registeredDevice];
		
		self.registeredDevice = nil;
		self.currentModel = nil;
	}
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		self.myProfile.MyPreferredAccount.TimeZone = self.timeZone;
		self.timeZone = nil;
		self.currentModel = nil;
	} 
	else if (! [elementName isEqualToString:@"MyProfile"])
	{
		if ([self.currentModel isEqualToString:@"MyPreferredAccountModel"])
		{
			@try
			{
				if ([elementName isEqualToString:@"ID"])
				{
					[self.myProfile.MyPreferredAccount setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
				}
				else
				{
					[self.myProfile.MyPreferredAccount setValue:self.currentElementValue forKey:elementName];
				}
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on My Preferred Account: %@", elementName);
			}
		}
		else if ([self.currentModel isEqualToString:@"RegisteredDeviceModel"])
		{
			@try
			{
				[self.registeredDevice setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on Registered Device: %@", elementName);
			}
		}
		else if ([self.currentModel isEqualToString:@"TimeZoneModel"])
		{
			@try
			{
				if ([elementName isEqualToString:@"ID"])
				{
					[self.timeZone setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
				}
				else
				{
					[self.timeZone setValue:self.currentElementValue forKey:elementName];
				}
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on Time Zone: %@", elementName);
			}
		}
		else
		{
			@try
			{
				if ([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"TimeoutPeriodMins"])
				{
					[self.myProfile setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
				}
				else if ([elementName isEqualToString:@"BlockCallerID"])
				{
					self.myProfile.BlockCallerID = [self.currentElementValue boolValue];
				}
				else if ([elementName isEqualToString:@"IsAuthorized"])
				{
					self.myProfile.IsAuthorized = [self.currentElementValue boolValue];
				}
				else if ([elementName isEqualToString:@"MayDisableTimeout"])
				{
					self.myProfile.MayDisableTimeout = [self.currentElementValue boolValue];
				}
				else if ([elementName isEqualToString:@"PasswordChangeRequired"])
				{
					self.myProfile.PasswordChangeRequired = [self.currentElementValue boolValue];
				}
				else
				{
					[self.myProfile setValue:self.currentElementValue forKey:elementName];
				}
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on My Profile: %@", elementName);
			}
		}
	}
	
	self.currentElementValue = nil;
}

@end
