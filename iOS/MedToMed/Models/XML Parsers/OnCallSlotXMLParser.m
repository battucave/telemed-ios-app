//
//  OnCallSlotXMLParser.m
//  MedToMed
//
//  Created by Shane Goodwin on 4/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "OnCallSlotXMLParser.h"
#import "OnCallSlotModel.h"

@interface OnCallSlotXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) OnCallSlotModel *onCallSlot;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation OnCallSlotXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize the array
	self.onCallSlots = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"OnCallSlot"])
	{
		// Initialize the on call slot
		self.onCallSlot = [[OnCallSlotModel alloc] init];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if ( ! self.currentElementValue)
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
	if ([elementName isEqualToString:@"OnCallSlot"])
	{
		[self.onCallSlots addObject:self.onCallSlot];
		
		self.onCallSlot = nil;
	}
	else if ([elementName isEqualToString:@"ID"])
	{
		[self.onCallSlot setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else
	{
		@try
		{
			[self.onCallSlot setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
