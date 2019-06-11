//
//  TimeZoneXMLParser.m
//  Med2Med
//
//  Created by Shane Goodwin on 7/13/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "TimeZoneXMLParser.h"
#import "TimeZoneModel.h"

@interface TimeZoneXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) TimeZoneModel *timeZone;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation TimeZoneXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize time zones array
	self.timeZones = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"TimeZone"])
	{
		// Initialize a time zone
		self.timeZone = [[TimeZoneModel alloc] init];
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
	if ([elementName isEqualToString:@"TimeZone"])
	{
		[self.timeZones addObject:self.timeZone];
		
		self.timeZone = nil;
	}
	else if ([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"Offset"])
	{
		[self.timeZone setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else
	{
		@try
		{
			[self.timeZone setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found on Time Zone: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
