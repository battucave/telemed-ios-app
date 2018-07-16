//
//  MessageXMLParser.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageXMLParser.h"
#import "AccountModel.h"
#import "MessageModel.h"

@interface MessageXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;
@property (nonatomic) MessageModel *message;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation MessageXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize the array
	self.messages = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"Account"])
	{
		// Initialize account
		self.message.Account = [[AccountModel alloc] init];
		
		self.currentModel = @"AccountModel";
	}
	// ReceivedMessage is current on test server; Message is deprecated but still current on production server
	else if ([elementName isEqualToString:@"ReceivedMessage"] || [elementName isEqualToString:@"Message"])
	{
		// Initialize the message
		self.message = [[MessageModel alloc] init];
	}
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		// Initialize the account time zone
		self.message.Account.TimeZone = [[TimeZoneModel alloc] init];
		
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
	if ([elementName isEqualToString:@"Account"])
	{
		self.currentModel = @"MessageModel";
	}
	else if ([elementName isEqualToString:@"Message"])
	{
		[self.messages addObject:self.message];
		
		self.message = nil;
	}
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		self.currentModel = @"AccountModel";
	}
	else if ([self.currentModel isEqualToString:@"AccountModel"])
	{
		if ([elementName isEqualToString:@"ID"])
		{
			[self.message.Account setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else
		{
			@try
			{
				[self.message.Account setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found: %@", elementName);
			}
		}
	}
	else if ([self.currentModel isEqualToString:@"TimeZoneModel"])
	{
		if ([elementName isEqualToString:@"ID"])
		{
			[self.message.Account.TimeZone setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else
		{
			@try
			{
				[self.message.Account.TimeZone setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on Time Zone: %@", elementName);
			}
		}
	}
	else if ([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"MessageDeliveryID"] || [elementName isEqualToString:@"MessageID"] || [elementName isEqualToString:@"SenderID"])
	{
		[self.message setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	// Future compatibility - State is currently Unread/Read/Archive, but seems to be going to number system
	/*else if ([elementName isEqualToString:@"State"])
	{
		if ([self.currentElementValue isEqualToString:@"0"])
		{
			[self.message setValue:@"Unread" forKey:elementName];
		}
		else if ([self.currentElementValue isEqualToString:@"1"])
		{
			[self.message setValue:@"Read" forKey:elementName];
		}
		else
		{
			[self.message setValue:self.currentElementValue forKey:elementName];
		}
	}*/
	else
	{
		@try
		{
			[self.message setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
