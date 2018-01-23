//
//  HospitalXMLParser.h
//  MedToMed
//
//  Created by Shane Goodwin on 11/29/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HospitalXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) NSMutableArray *hospitals;

@end
