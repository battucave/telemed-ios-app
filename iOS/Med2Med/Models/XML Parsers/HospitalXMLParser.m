//
//  HospitalXMLParser.m
//  Med2Med
//
//  Created by Shane Goodwin on 11/29/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import "HospitalXMLParser.h"
#import "HospitalModel.h"

@interface HospitalXMLParser()

@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) HospitalModel *hospital;
@property (nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation HospitalXMLParser

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// Initialize hospitals array
	self.hospitals = [[NSMutableArray alloc] init];
	
	// Initialize number formatter
	self.numberFormatter = [[NSNumberFormatter alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"Hospital"])
	{
		// Initialize a hospital
		self.hospital = [[HospitalModel alloc] init];
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
	if ([elementName isEqualToString:@"Hospital"])
	{
		[self.hospitals addObject:self.hospital];
		
		self.hospital = nil;
	}
	else if ([elementName isEqualToString:@"ID"])
	{
		[self.hospital setValue:[self.numberFormatter numberFromString:self.currentElementValue] forKey:elementName];
	}
	else
	{
		@try
		{
			[self.hospital setValue:self.currentElementValue forKey:elementName];
		}
		@catch(NSException *exception)
		{
			NSLog(@"Key not found on Hospital: %@", elementName);
		}
	}
	
	self.currentElementValue = nil;
}

@end