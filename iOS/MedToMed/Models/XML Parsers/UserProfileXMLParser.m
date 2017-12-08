//
//  UserProfileXMLParser.m
//  MedToMed
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "UserProfileXMLParser.h"
#import "UserProfileModel.h"

@interface UserProfileXMLParser()

@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation UserProfileXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	NSLog(@"Parse UserProfile");
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"MyTimeZone"])
	{
		self.timeZone = [[NSMutableDictionary alloc] init];
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
	if ([elementName isEqualToString:@"Description"] || [elementName isEqualToString:@"Offset"])
	{
		[self.timeZone setValue:self.currentElementValue forKey:elementName];
	}
	else if ([elementName isEqualToString:@"MyTimeZone"])
	{
		self.userProfile.MyTimeZone = self.timeZone;
		self.timeZone = nil;
	}
	else if ( ! [elementName isEqualToString:@"UserProfile"])
	{
		@try
		{
			if ([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"TimeoutPeriodMins"])
			{
				[self.userProfile setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
			}
			else if ([elementName isEqualToString:@"MayDisableTimeout"])
			{
				self.userProfile.MayDisableTimeout = [self.currentElementValue boolValue];
			}
			else
			{
				[self.userProfile setValue:self.currentElementValue forKey:elementName];
			}
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found on My Profile: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
