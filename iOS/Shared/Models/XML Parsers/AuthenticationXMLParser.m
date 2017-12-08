//
//  AuthenticationXMLParser.m
//  TeleMed
//
//  Created by Shane Goodwin on 5/29/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "AuthenticationXMLParser.h"

@implementation AuthenticationXMLParser

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
	if ([elementName isEqualToString:@"AccessToken"])
	{
		[self.authentication setAccessToken:self.currentElementValue];
	}
	else if ([elementName isEqualToString:@"RefreshToken"])
	{
		[self.authentication setRefreshToken:self.currentElementValue];
	}
	else if ([elementName isEqualToString:@"Message"])
	{
		[self.authentication setError:self.currentElementValue];
	}
	
	self.currentElementValue = nil;
}

@end
