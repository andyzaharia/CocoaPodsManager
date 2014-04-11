//
//  CPTarget.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 1/17/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import "CPTarget.h"
#import "CPDependency.h"
#import "CPProject.h"


@implementation CPTarget

@dynamic deploymentString;
@dynamic inhibit_all_warnings;
@dynamic name;
@dynamic platformString;
@dynamic xcodeproj;
@dynamic dependencies;
@dynamic project;

@end
