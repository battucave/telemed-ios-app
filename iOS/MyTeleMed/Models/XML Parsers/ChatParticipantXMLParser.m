//
//  ChatParticipantXMLParser.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatParticipantXMLParser.h"
#import "ChatParticipantModel.h"

@interface ChatParticipantXMLParser()

@property (nonatomic) ChatParticipantModel *chatParticipant;
@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation ChatParticipantXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize the array
	self.chatParticipants = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"Person"])
	{
		// Initialize the chat participant
		self.chatParticipant = [[ChatParticipantModel alloc] init];
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
	if ([elementName isEqualToString:@"Person"])
	{
		[self.chatParticipants addObject:self.chatParticipant];
		
		self.chatParticipant = nil;
	}
	else if ([elementName isEqualToString:@"ID"])
	{
		[self.chatParticipant setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else if ([elementName isEqualToString:@"FormattedNameLNF"])
	{
		[self.chatParticipant setValue:self.currentElementValue forKey:elementName];
		
		// Manually set name property from formatted name lnf
		[self.chatParticipant setValue:self.currentElementValue forKey:@"Name"];
	}
	else
	{
		@try
		{
			[self.chatParticipant setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
