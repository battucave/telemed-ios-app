//
//  GenericErrorXMLParser.m
//  TeleMed
//
//  Created by SolutionBuilt on 11/19/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import "GenericErrorXMLParser.h"

@implementation GenericErrorXMLParser

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
	if ([elementName isEqualToString:@"body"] || [elementName isEqualToString:@"Message"])
	{
		self.error = self.currentElementValue;
	}
	
	self.currentElementValue = nil;
}

@end
