//
//  NSString+XML.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "NSString+XML.h"
#import "NSMutableString+XML.h"

@implementation NSString (NSString_XML)

- (NSString *)escapeXML
{
	NSMutableString *escapeString = [NSMutableString stringWithString:self];

	return [NSString stringWithString:[escapeString escapeMutableXML]];
}

- (NSString *)unescapeXML
{
	NSMutableString *unescapeString = [NSMutableString stringWithString:self];

	return [NSString stringWithString:[unescapeString unescapeMutableXML]];
}

@end
