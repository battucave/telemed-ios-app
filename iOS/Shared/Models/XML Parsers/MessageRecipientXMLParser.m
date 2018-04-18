//
//  MessageRecipientXMLParser.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MessageRecipientXMLParser.h"
#import "MessageRecipientModel.h"

@interface MessageRecipientXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) MessageRecipientModel *messageRecipient;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation MessageRecipientXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize the array
	self.messageRecipients = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"MsgRecip"])
	{
		// Initialize the Message Event.
		self.messageRecipient = [[MessageRecipientModel alloc] init];
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
	if ([elementName isEqualToString:@"MsgRecip"])
	{
		[self.messageRecipients addObject:self.messageRecipient];
		
		self.messageRecipient = nil;
	}
	else if ([elementName isEqualToString:@"ID"])
	{
		[self.messageRecipient setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else if ([elementName isEqualToString:@"Name"])
	{
		[self.messageRecipient setValue:self.currentElementValue forKey:elementName];
		
		// Most MyTeleMed names are of the following format: Lastname, Firstname
		if ([self.currentElementValue rangeOfString:@", "].location != NSNotFound)
		{
			NSArray *nameComponents = [self.currentElementValue componentsSeparatedByString:@", "];
			
			[self.messageRecipient setFirstName:[nameComponents objectAtIndex:1]];
			[self.messageRecipient setLastName:[nameComponents objectAtIndex:0]];
		}
		// Most MedToMed names are of the following format: FirstName LastName
		else if ([self.currentElementValue rangeOfString:@" "].location != NSNotFound)
		{
			NSArray *nameComponents = [self.currentElementValue componentsSeparatedByString:@" "];
			
			[self.messageRecipient setFirstName:[nameComponents objectAtIndex:0]];
			[self.messageRecipient setLastName:[nameComponents objectAtIndex:1]];
		}
		// Some names are not people names (example: "Abundant HH On Call")
		else
		{
			[self.messageRecipient setFirstName:@""];
			[self.messageRecipient setLastName:self.currentElementValue];
		}
	}
	else
	{
		@try
		{
			[self.messageRecipient setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
