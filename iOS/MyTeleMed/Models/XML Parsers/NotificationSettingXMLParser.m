//
//  NotificationSettingXMLParser.m
//  MyTeleMed
//
//  Created by SolutionBuilt on 8/16/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "NotificationSettingXMLParser.h"
#import "NotificationSettingModel.h"

@interface NotificationSettingXMLParser()

@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation NotificationSettingXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize the array
	self.notificationSettings = [[NSMutableArray alloc] init];
	
	// Initialize the number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:@"NotificationSettings"])
	{
		// Initialize the Notification Setting (Only when retrieving ALL Notification Settings. When retrieving a single Notification Setting, this will already be initialized)
		if( ! self.notificationSetting)
		{
			self.notificationSetting = [[NotificationSettingModel alloc] init];
		}
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
	if([elementName isEqualToString:@"NotificationSettings"])
	{
		[self.notificationSettings addObject:self.notificationSetting];
		
		self.notificationSetting = nil;
	}
	else if([elementName isEqualToString:@"Enabled"])
	{
		self.notificationSetting.Enabled = [self.currentElementValue boolValue];
	}
	else if([elementName isEqualToString:@"Interval"])
	{
		[self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		
		self.notificationSetting.Interval = [self.numberFormatter numberFromString:self.currentElementValue];
	}
	else
	{
		@try
		{
			[self.notificationSetting setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
