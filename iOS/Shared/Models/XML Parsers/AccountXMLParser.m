//
//  AccountXMLParser.m
//  TeleMed
//
//  Created by SolutionBuilt on 8/16/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "AccountXMLParser.h"
#import "AccountModel.h"
#import "TimeZoneModel.h"

@interface AccountXMLParser()

@property (nonatomic) AccountModel *account;
@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation AccountXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize accounts array
	self.accounts = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"Account"])
	{
		// Initialize an account
		self.account = [[AccountModel alloc] init];
	}
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		// Initialize a time zone
		self.account.TimeZone = [[TimeZoneModel alloc] init];
		
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
		[self.accounts addObject:self.account];
		
		self.account = nil;
	}
	else if ([elementName isEqualToString:@"ID"])
	{
		[self.account setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else if ([elementName isEqualToString:@"TimeZone"])
	{
		self.currentModel = nil;
	}
	else if ([self.currentModel isEqualToString:@"TimeZoneModel"])
	{
		if ([elementName isEqualToString:@"ID"])
		{
			[self.account.TimeZone setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else
		{
			@try
			{
				[self.account.TimeZone setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on Time Zone: %@", elementName);
			}
		}
	}
	else
	{
		@try
		{
			[self.account setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found on Account: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
