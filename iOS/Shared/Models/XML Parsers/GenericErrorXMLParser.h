//
//  GenericErrorXMLParser.h
//  TeleMed
//
//  Created by SolutionBuilt on 11/19/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenericErrorXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NSString *error;
@property (nonatomic) NSMutableString *currentElementValue;

@end
