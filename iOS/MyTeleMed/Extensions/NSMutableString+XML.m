//
//  NSMutableString+XML.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import "NSMutableString+XML.h"

@implementation NSMutableString (NSMutableString_XML)

- (NSMutableString *)escapeMutableXML
{
	[self replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"'"  withString:@"&#x27;" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [self length])];

	return self;
}

- (NSMutableString *)unescapeMutableXML
{
	[self replaceOccurrencesOfString:@"&amp;"  withString:@"&"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x27;" withString:@"'"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x39;" withString:@"'"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x92;" withString:@"'"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&#x96;" withString:@"'"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&gt;"   withString:@">"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	[self replaceOccurrencesOfString:@"&lt;"   withString:@"<"  options:NSLiteralSearch range:NSMakeRange(0, [self length])];

	return self;
}

@end
