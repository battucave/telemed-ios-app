//
//  SentMessageXMLParser.m
//  TeleMed
//
//  Created by Shane Goodwin on 3/22/17.
//  Copyright (c) 2017 SolutionBuilt. All rights reserved.
//

#import "SentMessageXMLParser.h"
#import "AccountModel.h"
#import "SentMessageModel.h"
#import "TimeZoneModel.h"

@interface SentMessageXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) SentMessageModel *sentMessage;

@end

@implementation SentMessageXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize the array
	self.sentMessages = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	// MyTeleMed only
	if ([elementName isEqualToString:@"Account"])
	{
		// Initialize account
		self.sentMessage.Account = [[AccountModel alloc] init];
		
		self.currentModel = @"AccountModel";
	}
	else if ([elementName isEqualToString:@"SentMessage"])
	{
		// Initialize the sent message
		self.sentMessage = [[SentMessageModel alloc] init];
		self.sentMessage.MessageType = @"Sent";
	}
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		// Initialize the account time zone
		self.sentMessage.Account.TimeZone = [[TimeZoneModel alloc] init];
		
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
	// MyTeleMed only
	if ([elementName isEqualToString:@"Account"])
	{
		self.currentModel = nil;
	}
	else if ([elementName isEqualToString:@"SentMessage"])
	{
		[self.sentMessages addObject:self.sentMessage];
		
		self.sentMessage = nil;
	}
	// MyTeleMed only
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		self.currentModel = @"AccountModel";
	}
	// MyTeleMed only
	else if ([self.currentModel isEqualToString:@"AccountModel"])
	{
		if ([elementName isEqualToString:@"ID"])
		{
			[self.sentMessage.Account setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else
		{
			@try
			{
				[self.sentMessage.Account setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on Account: %@", elementName);
			}
		}
	}
	// MyTeleMed only
	else if ([self.currentModel isEqualToString:@"TimeZoneModel"])
	{
		if ([elementName isEqualToString:@"ID"])
		{
			[self.sentMessage.Account.TimeZone setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else
		{
			@try
			{
				[self.sentMessage.Account.TimeZone setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on Time Zone: %@", elementName);
			}
		}
	}
	else if ([elementName isEqualToString:@"MessageID"] || [elementName isEqualToString:@"SenderID"])
	{
		[self.sentMessage setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else
	{
		@try
		{
			[self.sentMessage setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
