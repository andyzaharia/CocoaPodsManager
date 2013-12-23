//
//  CPDependency+Misc.h
//  CocoaPodsManager
//
//  Created by Andy on 19.12.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CPDependency.h"

@interface CPDependency (Misc)

+(CPDependency *) dependencyWithPod: (PodSpec *) pod;

-(NSString *) podLineRepresentation;

@end
