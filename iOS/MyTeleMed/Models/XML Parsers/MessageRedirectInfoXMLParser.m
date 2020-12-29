//
//  MessageRedirectInfoXMLParser.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/09/18.
//  Copyright (c) 2018 SolutionBuilt. All rights reserved.
//

#import "MessageRedirectInfoXMLParser.h"
#import "MessageRecipientModel.h"
#import "OnCallSlotModel.h"

@interface MessageRedirectInfoXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;
@property (nonatomic) MessageRecipientModel *messageRecipient;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) OnCallSlotModel *onCallSlot;
@property (nonatomic) NSMutableArray *recipients;
@property (nonatomic) NSMutableArray *slots;

@end

@implementation MessageRedirectInfoXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"EscalationSlot"] || [elementName isEqualToString:@"OnCallSlot"])
	{
		// Initialize an on call slot
		self.onCallSlot = [[OnCallSlotModel alloc] init];
		
		self.currentModel = @"OnCallSlotModel";
	}
	else if ([elementName isEqualToString:@"ForwardRecipients"] || [elementName isEqualToString:@"RedirectRecipients"])
	{
		// Initialize recipients array
		self.recipients = [[NSMutableArray alloc] init];
	}
	else if ([elementName isEqualToString:@"MsgRecip"])
	{
		// Initialize a message recipient
		self.messageRecipient = [[MessageRecipientModel alloc] init];
		
		self.currentModel = @"MessageRecipientModel";
	}
	else if ([elementName isEqualToString:@"RedirectionSlots"])
	{
		// Initialize slots array
		self.slots = [[NSMutableArray alloc] init];
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
	if ([elementName isEqualToString:@"EscalationSlot"])
	{
		// Escalation slot may be present, but null so verify that it has an id
		if (self.onCallSlot.ID)
		{
			self.messageRedirectInfo.EscalationSlot = self.onCallSlot;
		}
		
		self.currentModel = nil;
		self.onCallSlot = nil;
	}
	else if ([elementName isEqualToString:@"ForwardRecipients"] || [elementName isEqualToString:@"RedirectRecipients"])
	{
		[self.messageRedirectInfo setValue:self.recipients forKey:elementName];
		
		self.recipients = nil;
	}
	else if ([elementName isEqualToString:@"RedirectionSlots"])
	{
		self.messageRedirectInfo.RedirectSlots = self.slots;
		self.slots = nil;
	}
	else if ([elementName isEqualToString:@"MsgRecip"])
	{
		[self.recipients addObject:self.messageRecipient];
		
		self.messageRecipient = nil;
	}
	else if ([elementName isEqualToString:@"OnCallSlot"])
	{
		[self.slots addObject:self.onCallSlot];
		
		self.onCallSlot = nil;
	}
	// Replicate MessageRecipientXMLParser parsing
	else if ([self.currentModel isEqualToString:@"MessageRecipientModel"])
	{
		if ([elementName isEqualToString:@"ID"])
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
			// Most Med2Med names are of the following format: FirstName LastName
			else if ([self.currentElementValue rangeOfString:@" "].location != NSNotFound)
			{
				NSMutableArray *nameComponents = [[self.currentElementValue componentsSeparatedByString:@" "] mutableCopy];
				NSString *firstName = [nameComponents objectAtIndex:0];
				
				// If first name is a prefix, then adjust name components
				if ([nameComponents count] > 2 && ([firstName hasPrefix:@"Dr"] || [firstName hasPrefix:@"Mr"] || [firstName hasPrefix:@"MD"]))
				{
					[nameComponents removeObjectAtIndex:0];
				}
				
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
				NSLog(@"Key not found on Message Recipient: %@", elementName);
			}
		}
	}
	// Replicate OnCallSlotXMLParser parsing
	else if ([self.currentModel isEqualToString:@"OnCallSlotModel"])
	{
		if ([elementName isEqualToString:@"ID"])
		{
			[self.onCallSlot setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
		}
		else if ([elementName isEqualToString:@"IsEscalationSlot"])
		{
			self.onCallSlot.IsEscalationSlot = self.currentElementValue.boolValue;
		}
		else if ([elementName isEqualToString:@"SelectRecipient"])
		{
			self.onCallSlot.SelectRecipient = self.currentElementValue.boolValue;
		}
		else
		{
			@try
			{
				[self.onCallSlot setValue:self.currentElementValue forKey:elementName];
			}
			@catch(NSException *exception)
			{
				NSLog(@"Key not found on On Call Slot: %@", elementName);
			}
		}
	}
	else if ([elementName isEqualToString:@"ID"])
	{
		[self.messageRedirectInfo setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else
	{
		@try
		{
			[self.messageRedirectInfo setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found on Message Redirect Info: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
