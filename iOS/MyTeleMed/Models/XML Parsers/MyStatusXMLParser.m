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

@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation MyStatusXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize My Status and OnCall Entries
	self.currentOnCallEntries = [[NSMutableArray alloc] init];
	self.futureOnCallEntries = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:@"NextOncallEntry"] || [elementName isEqualToString:@"OnCallNowEntry"])
	{
		// Initialize an OnCall Entry
		self.onCallEntry = [[OnCallEntryModel alloc] init];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if( ! self.currentElementValue)
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
	if([elementName isEqualToString:@"OnCallNow"])
	{
		self.myStatus.OnCallNow = [self.currentElementValue boolValue];
	}
	else if([elementName isEqualToString:@"NextOnCallEntries"])
	{
		self.myStatus.FutureOnCallEntries = self.futureOnCallEntries;
	}
	else if([elementName isEqualToString:@"OnCallNowEntries"])
	{
		self.myStatus.CurrentOnCallEntries = self.currentOnCallEntries;
	}
	else if([elementName isEqualToString:@"NextOncallEntry"])
	{
		[self.futureOnCallEntries addObject:self.onCallEntry];
		
		self.onCallEntry = nil;
	}
	else if([elementName isEqualToString:@"OnCallNowEntry"])
	{
		[self.currentOnCallEntries addObject:self.onCallEntry];
		
		self.onCallEntry = nil;
	}
	else
	{
		SEL selector = NSSelectorFromString(elementName);
		
		if([self.myStatus respondsToSelector:selector])
		{
			if([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"ActiveMessageCount"] || [elementName isEqualToString:@"UnreadMessageCount"])
			{
				[self.myStatus setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
			}
			else
			{
				[self.myStatus setValue:self.currentElementValue forKey:elementName];
			}
		}
		else if([self.onCallEntry respondsToSelector:selector])
		{
			if([elementName isEqualToString:@"AccountID"] || [elementName isEqualToString:@"AccountKey"] || [elementName isEqualToString:@"SlotID"])
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
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
