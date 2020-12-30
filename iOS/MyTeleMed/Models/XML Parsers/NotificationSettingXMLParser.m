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

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NotificationSettingModel *notificationSetting;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation NotificationSettingXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize notification settings array
	self.notificationSettings = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"NotificationSetting"])
	{
		// Initialize a notification setting
		self.notificationSetting = [[NotificationSettingModel alloc] init];
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
	if ([elementName isEqualToString:@"NotificationSetting"])
	{
		[self.notificationSettings addObject:self.notificationSetting];
		
		self.notificationSetting = nil;
	}
	else if ([elementName isEqualToString:@"Enabled"])
	{
		self.notificationSetting.Enabled = self.currentElementValue.boolValue;
	}
	else if ([elementName isEqualToString:@"Interval"])
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
			NSLog(@"Key not found on Notification Setting: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end
