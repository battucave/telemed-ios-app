//
//  HospitalXMLParser.h
//  MedToMed
//
//  Created by Shane Goodwin on 11/29/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HospitalModel.h"

@interface HospitalXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) HospitalModel *hospital;
@property (nonatomic) NSMutableArray *hospitals;
@property (nonatomic) NSMutableString *currentElementValue;

@end
