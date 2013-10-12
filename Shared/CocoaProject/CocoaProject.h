//
//  CocoaProject.h
//  CocoaPodsManager
//
//  Created by Andy on 08.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dependency.h"
#import "XCodeProject+Misc.h"

/*
 
    A simple wrapper for the Project PodFile
 
*/

@class PodSpec;

@interface CocoaProject : NSObject

@property (nonatomic, retain) XCodeProject      *xcodeProject; // CoreData reference

@property (nonatomic, retain) NSString          *platformString;
@property (nonatomic, retain) NSString          *deploymentString;
@property (nonatomic, retain) NSMutableArray    *items;

@property (nonatomic)         BOOL              inhibit_all_warnings;

// Hooks
@property (nonatomic, retain) NSString          *pre_install;
@property (nonatomic, retain) NSString          *post_install;

-(BOOL) containsPod: (PodSpec *) pod;

-(Dependency *) dependencyForPod: (PodSpec *) pod;

-(BOOL) isSameXCodeProject: (XCodeProject *) xProj;


-(void) addPodsFromArray: (NSArray *) items;

-(id) initWithXCodeProject:(XCodeProject *) proj;

-(void) writeProjectToPodFile;

@end
