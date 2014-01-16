//
//  CPProject+Misc.h
//  CocoaPodsManager
//
//  Created by Andy on 05.11.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CPProject.h"
#import "CPDependency.h"

@interface CPProject (Misc)

+(NSString *) projectPathWithRandomPath: (NSString *) fPath;
+(NSString *) podFileWithProjectPath: (NSString *) projPath;

-(BOOL) containsPod: (PodSpec *) pod;
-(BOOL) isSameProject: (CPProject *) xProj;
-(BOOL) setProjectPath: (NSString *) fPath;
-(BOOL) isPodInstalledForProject;

// Returns NO if the PodFile cant be located at the current Project Path location
-(BOOL) podFileExistsAtCurrentPath;

-(CPDependency *) dependencyForPod: (PodSpec *) pod;

-(void) addPodsFromArray: (NSArray *) items;

//-(id) initWithXCodeProject:(XCodeProject *) proj;

-(void) writeProjectToPodFile;

-(NSString *) podFilePath;
-(NSString *) workSpaceFilePath;

@end