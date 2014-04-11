//
//  CPProject+Misc.m
//  CocoaPodsManager
//
//  Created by Andy on 05.11.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CPProject+Misc.h"
#import "NSString+Misc.h"
#import "PodSpec.h"
#import "CPDependency+Misc.h"
#import "CPProject+PodFileParser.h"

#define kPODFILE_LOCK               @"Podfile.lock"

@implementation CPProject (Misc)

#pragma mark -

-(id) init
{
    self = [super init];
    if (self) {
        //self.items = [NSMutableArray array];
        self.platformString = @"ios";
    }
    return self;
}

//-(id) initWithXCodeProject:(XCodeProject *) proj
//{
//    self = [self init];
//    if (self) {        
//        self.items = [NSMutableArray array];
//        [self readPodFile];
//    }
//    return self;
//}

-(void) setProjectFilePath:(NSString *)projectFilePath
{
    [self willChangeValueForKey:@"projectFilePath"];
    [self setPrimitiveValue:projectFilePath forKey:@"projectFilePath"];

    NSAlert* msgBox = [[NSAlert alloc] init];
    [msgBox setMessageText: @"Did set project file"];
    [msgBox addButtonWithTitle: @"OK"];
    [msgBox runModal];
    
    [self readPodFile];
    
    [self didChangeValueForKey:@"projectFilePath"];
}

#pragma mark - Validation

-(BOOL) podFileExistsAtCurrentPath
{
    NSString *podFilePath = [self podFilePath];
    return [[NSFileManager defaultManager] fileExistsAtPath:podFilePath isDirectory: nil];
}

#pragma mark -

-(BOOL) containsPod: (PodSpec *) pod
{
    if (!pod && [self.items count]) {
        return NO;
    }
    
    __block BOOL found = NO;
    [self.items enumerateObjectsUsingBlock:^(CPDependency *dependency, NSUInteger idx, BOOL *stop) {
        if ([dependency.pod.objectID isEqual: pod.objectID]) {
            found = YES;
            *stop = YES;
        }
    }];
    
    return found;
}

-(BOOL) isSameProject: (CPProject *) proj
{
    return [self.projectFilePath isEqualToString: proj.projectFilePath];
}

-(BOOL) setProjectPath: (NSString *) fPath{
    
    self.projectFilePath = [CPProject projectPathWithRandomPath: fPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: fPath]) {
        return YES;
    }else {
        TODO("Show Podfile not found alert.");
    }
    
    return NO;
}

-(BOOL) isPodInstalledForProject
{
    NSString *path = [[self podFilePath] stringByAppendingPathExtension:@"lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

#pragma mark -

-(CPDependency *) dependencyForPod: (PodSpec *) pod {
    
    for (CPDependency *dependency in self.items) {
        if (dependency.pod == pod) {
            return dependency;
        }
    }
    return nil;
}

#pragma mark -

-(void) addPodsFromArray: (NSArray *) items
{
    [items enumerateObjectsUsingBlock:^(PodSpec *pod, NSUInteger idx, BOOL *stop) {
        if (![self containsPod: pod]) {
            [self addPodsObject: pod];
        }
    }];
}

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
        return [CPProject findXCodeProjectInFolder: [fPath stringByDeletingLastPathComponent]];
    }else{
        NSFileManager *fManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        if ([fManager fileExistsAtPath:fPath isDirectory:&isDirectory]) {
            return [CPProject findXCodeProjectInFolder: isDirectory ? fPath : [fPath stringByDeletingLastPathComponent]];
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

-(NSString *) podFilePath{
    return [CPProject podFileWithProjectPath: self.projectFilePath];
}

-(NSString *) workSpaceFilePath{
    
    NSString *fPath = self.projectFilePath;
    fPath = [fPath stringByDeletingLastPathComponent];
    fPath = [fPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xcworkspace", self.name]];
    return fPath;
}

@end
