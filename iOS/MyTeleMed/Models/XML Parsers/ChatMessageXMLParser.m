//
//  ChatMessageXMLParser.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 6/30/16.
//  Copyright (c) 2016 SolutionBuilt. All rights reserved.
//

#import "ChatMessageXMLParser.h"
#import "ChatMessageModel.h"
#import "ChatParticipantModel.h"

@interface ChatMessageXMLParser()

@property (nonatomic) ChatMessageModel *chatMessage;
@property (nonatomic) ChatParticipantModel *chatParticipant;
@property (nonatomic) NSMutableArray *chatParticipants;
@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) BOOL isChatParticipant;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation ChatMessageXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize chat messages array
	self.chatMessages = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"ChatMessage"])
	{
		// Initialize a chat message
		self.chatMessage = [[ChatMessageModel alloc] init];
	}
	else if ([elementName isEqualToString:@"Participants"])
	{
		// Initialize chat participants
		self.chatParticipants = [[NSMutableArray alloc] init];
	}
	else if ([elementName isEqualToString:@"Person"])
	{
		// Initialize a chat participant
		self.chatParticipant = [[ChatParticipantModel alloc] init];
		
		self.isChatParticipant = YES;
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
	if ([elementName isEqualToString:@"ChatMessage"])
	{
		[self.chatMessages addObject:self.chatMessage];
		
		self.chatMessage = nil;
	}
	else if ([elementName isEqualToString:@"Participants"])
	{
		[self.chatMessage setChatParticipants:self.chatParticipants];
	}
	else if ([elementName isEqualToString:@"Person"])
	{
		[self.chatParticipants addObject:self.chatParticipant];
		
		self.isChatParticipant = NO;
	}
	else if ([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"SenderID"])
	{
		if (self.isChatParticipant)
		{
			[self.chatParticipant setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else
		{
			[self.chatMessage setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
	}
	else if ([elementName isEqualToString:@"Unopened"])
	{
		self.chatMessage.Unopened = self.currentElementValue.boolValue;
	}
	else
	{
		@try
		{
			if (self.isChatParticipant)
			{
				[self.chatParticipant setValue:self.currentElementValue forKey:elementName];
			}
			else
			{
				[self.chatMessage setValue:self.currentElementValue forKey:elementName];
			}
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found on Chat Message: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
