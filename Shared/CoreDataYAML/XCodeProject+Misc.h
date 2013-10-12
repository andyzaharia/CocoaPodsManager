//
//  XCodeProject+Misc.h
//  CocoaPodsManager
//
//  Created by Andy on 14.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "XCodeProject.h"

@interface XCodeProject (Misc)

+(NSString *) projectPathWithRandomPath: (NSString *) fPath;
+(NSString *) podFileWithProjectPath: (NSString *) projPath;

-(BOOL) setProjectPath: (NSString *) fPath;

-(NSString *) podFilePath;
-(NSString *) workSpaceFilePath;

-(BOOL) isPodInstalledForProject;

@end
