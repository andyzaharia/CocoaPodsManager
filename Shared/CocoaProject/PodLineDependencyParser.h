//
//  PodFileParser.h
//  CocoaPodsManager
//
//  Created by Andy on 01.03.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dependency.h"

@interface PodLineDependencyParser : NSObject

+(Dependency *) dependencyFromString: (NSString *) podLine;

@end
