//
//  NSString+XML.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_XML)

- (NSString *)escapeXML;
- (NSString *)unescapeXML;

@end
