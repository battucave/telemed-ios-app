//
//  TimeZoneXMLParser.h
//  Med2Med
//
//  Created by Shane Goodwin on 7/13/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeZoneXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NSMutableArray *timeZones;

@end
