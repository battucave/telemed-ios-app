//
//  NSMutableString+XML.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 1/16/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableString (NSMutableString_XML)

- (NSMutableString *)escapeMutableXML;
- (NSMutableString *)unescapeMutableXML;

@end
