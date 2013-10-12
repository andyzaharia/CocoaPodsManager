//
//  XCodeProject+Misc.m
//  CocoaPodsManager
//
//  Created by Andy on 14.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "XCodeProject+Misc.h"

@implementation XCodeProject (Misc)

+(NSString *) findXCodeProjectInFolder: (NSString *) projectFolder{
    
    NSFileManager *fManager = [NSFileManager defaultManager];
    NSArray *items = [fManager contentsOfDirectoryAtPath:projectFolder error: nil];
    for (NSString *itemPath in items) {
        if ([[itemPath pathExtension] isEqualToString: XCODE_PROJECT_EXTENSION]) {
            return [projectFolder stringByAppendingPathComponent: itemPath];
        }
    }
    return nil;
}

+(NSString *) projectPathWithRandomPath: (NSString *) fPath{
    
    if ([[[fPath pathExtension] lowercaseString] isEqualToString: XCODE_PROJECT_EXTENSION]) {
        return fPath;
    }else if ([[[fPath pathExtension] lowercaseString] isEqualToString: XCODE_WORKSPACE_EXTENSION]) {
        return [XCodeProject findXCodeProjectInFolder: [fPath stringByDeletingLastPathComponent]];
    }else{
        NSFileManager *fManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        if ([fManager fileExistsAtPath:fPath isDirectory:&isDirectory]) {
            return [XCodeProject findXCodeProjectInFolder: isDirectory ? fPath : [fPath stringByDeletingLastPathComponent]];
        }
    }
    
    return nil;
}

+(NSString *) podFileWithProjectPath: (NSString *) projPath {
    
    NSString *fPath = projPath;
    if ([[[fPath pathExtension] lowercaseString] isEqualToString:@"xcodeproj"]) {
        NSString *folder = [fPath stringByDeletingLastPathComponent];
        fPath = [folder stringByAppendingPathComponent:@"Podfile"];
        if (![[NSFileManager defaultManager] fileExistsAtPath: fPath]) {
            // This might be deprecated...
            return [folder stringByAppendingPathComponent:@"Podfile"];
        }
        
        return fPath;
    }
    
    return nil;
}

#pragma mark -

-(BOOL) setProjectPath: (NSString *) fPath{
    
    self.projectFilePath = [XCodeProject projectPathWithRandomPath: fPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: fPath]) {
        return YES;
    }else {
        TODO("Show Podfile not found alert.");
    }
    
    return NO;
}

-(NSString *) podFilePath{
    return [XCodeProject podFileWithProjectPath: self.projectFilePath];
}

-(NSString *) workSpaceFilePath{
    
    NSString *fPath = self.projectFilePath;
    fPath = [fPath stringByDeletingLastPathComponent];
    fPath = [fPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcworkspace", self.name]];
    return fPath;
}

-(BOOL) isPodInstalledForProject
{
    NSString *path = [[self podFilePath] stringByAppendingPathExtension:@"lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

@end
