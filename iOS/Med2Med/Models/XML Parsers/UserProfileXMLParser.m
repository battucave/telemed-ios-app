//
//  UserProfileXMLParser.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "UserProfileXMLParser.h"
#import "TimeZoneModel.h"
#import "UserProfileModel.h"

@interface UserProfileXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation UserProfileXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"MyTimeZone"])
	{
		// Initialize a time zone
		self.userProfile.MyTimeZone = [[TimeZoneModel alloc] init];
		
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
	if ([elementName isEqualToString:@"MyTimeZone"])
	{
		self.currentModel = nil;
	}
	else if (! [elementName isEqualToString:@"UserProfile"])
	{
		if ([self.currentModel isEqualToString:@"TimeZoneModel"])
		{
			if ([elementName isEqualToString:@"ID"])
			{
				[self.userProfile.MyTimeZone setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
			}
			else
			{
				@try
				{
					[self.userProfile.MyTimeZone setValue:self.currentElementValue forKey:elementName];
				}
				@catch(NSException *exception)
				{
					NSLog(@"Key not found on Time Zone: %@", elementName);
				}
			}
		}
		else
		{
			if ([elementName isEqualToString:@"ID"] || [elementName isEqualToString:@"TimeoutPeriodMins"])
			{
				[self.userProfile setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
			}
			else if ([elementName isEqualToString:@"MayDisableTimeout"])
			{
				self.userProfile.MayDisableTimeout = self.currentElementValue.boolValue;
			}
			else
			{
				@try
				{
					[self.userProfile setValue:self.currentElementValue forKey:elementName];
				}
				@catch(NSException *exception)
				{
					NSLog(@"Key not found on User Profile: %@", elementName);
				}
			}
		}
	}
	
	self.currentElementValue = nil;
}

@end
