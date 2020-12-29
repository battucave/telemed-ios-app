//
//  MyStatusXMLParser.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyStatusXMLParser.h"
#import "MyStatusModel.h"

@interface MyStatusXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSMutableArray *currentOnCallEntries;
@property (nonatomic) NSMutableArray *futureOnCallEntries;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) OnCallEntryModel *onCallEntry;

@end

@implementation MyStatusXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize current on call entries array
	self.currentOnCallEntries = [[NSMutableArray alloc] init];
	
	// Initialize future on call entries array
	self.futureOnCallEntries = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"NextOncallEntry"] || [elementName isEqualToString:@"OnCallNowEntry"])
	{
		// Initialize an on call entry
		self.onCallEntry = [[OnCallEntryModel alloc] init];
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
	if ([elementName isEqualToString:@"OnCallNow"])
	{
		self.myStatus.OnCallNow = self.currentElementValue.boolValue;
	}
	else if ([elementName isEqualToString:@"NextOnCallEntries"])
	{
		self.myStatus.FutureOnCallEntries = self.futureOnCallEntries;
	}
	else if ([elementName isEqualToString:@"OnCallNowEntries"])
	{
		self.myStatus.CurrentOnCallEntries = self.currentOnCallEntries;
	}
	else if ([elementName isEqualToString:@"NextOncallEntry"])
	{
		[self.futureOnCallEntries addObject:self.onCallEntry];
		
		self.onCallEntry = nil;
	}
	else if ([elementName isEqualToString:@"OnCallNowEntry"])
	{
		[self.currentOnCallEntries addObject:self.onCallEntry];
		
		self.onCallEntry = nil;
	}
	else
	{
		SEL selector = NSSelectorFromString(elementName);
		
		// Store date strings as NSDate
		if ([elementName isEqualToString:@"NextOnCall"] || [elementName isEqualToString:@"Started"] || [elementName isEqualToString:@"WillEnd"] || [elementName isEqualToString:@"WillStart"])
		{
			//@"2016-10-03T10:55:17.7924093-0400"
			self.currentElementValue = (NSMutableString *)[NSString stringWithFormat:@"%@.1234567-04:00", self.currentElementValue];
			
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			//NSDate *UTCDate;
			NSDate *localDate;
			
			if (self.currentElementValue != nil && ! [self.currentElementValue isEqualToString:@"Never"])
			{
				// Get date in utc timezone (not needed at this time, but keep here for future changes)
				/* [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
				UTCDate = [dateFormatter dateFromString:self.currentElementValue];
				
				if (UTCDate == nil)
				{
					[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
					UTCDate = [dateFormatter dateFromString:self.currentElementValue];
				} */
				
				// Get date as-is (server provides correct timezone)
				self.currentElementValue = (NSMutableString *)[self.currentElementValue substringToIndex:19];
				
				[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
				[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
				localDate = [dateFormatter dateFromString:self.currentElementValue];
			}
			
			// Store dates as NSDate
			if ([self.myStatus respondsToSelector:selector])
			{
				[self.myStatus setValue:localDate forKey:elementName];
			}
			else if ([self.onCallEntry respondsToSelector:selector])
			{
				[self.onCallEntry setValue:localDate forKey:elementName];
			}
		}
		else if ([self.myStatus respondsToSelector:selector])
		{
			if ([@[@"ActiveChatConvoCount", @"ActiveMessageCount", @"UnopenedChatConvoCount", @"UnreadMessageCount"] containsObject:elementName])
			{
				[self.myStatus setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
			}
			else
			{
				[self.myStatus setValue:self.currentElementValue forKey:elementName];
			}
		}
		else if ([self.onCallEntry respondsToSelector:selector])
		{
			if ([elementName isEqualToString:@"AccountID"] || [elementName isEqualToString:@"AccountKey"] || [elementName isEqualToString:@"SlotID"])
			{
				[self.onCallEntry setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
			}
			else
			{
				[self.onCallEntry setValue:self.currentElementValue forKey:elementName];
			}
		}
		else
		{
			NSLog(@"Key not found on My Status: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
