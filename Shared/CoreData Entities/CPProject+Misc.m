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
#import "PodLineDependencyParser.h"
#import "CPDependency+Misc.h"

#define kPODFILE_LOCK               @"Podfile.lock"
#define kPLATFORM                   @"platform"
#define kPOD                        @"pod"
#define kPOD_VERSION                @"~>"

#define kPOD_INHIBIT_ALL_WARNINGS   @"inhibit_all_warnings!"

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

    [self readPodFile];
    
    [self didChangeValueForKey:@"projectFilePath"];
}

#pragma mark - PodFile  Parser

-(BOOL) readPlatformFromLine: (NSString *) platformStr
{
    if ([platformStr length] > [kPLATFORM length]) {
        if ([[[platformStr lowercaseString] substringWithRange:NSMakeRange(0, [kPLATFORM length])] isEqualToString:[kPLATFORM lowercaseString]]) {
            
            NSString *platformContent = [platformStr substringWithRange: NSMakeRange([kPLATFORM length], [platformStr length] - [kPLATFORM length])];
            platformContent = [platformContent trimWhiteSpace];
            
            NSArray *components = [platformContent componentsSeparatedByString:@","];
            for (NSString *component in components) {
                if ([components indexOfObject: component] == 0) {
                    self.platformString = [component trimWhiteSpace];
                    self.platformString = [self.platformString stringByReplacingOccurrencesOfString:@":" withString:@""];
                }
                else
                    if ([components indexOfObject: component] == 1) {
                        self.deploymentString = [component trimWhiteSpace];
                        self.deploymentString = [self.deploymentString stringByReplacingOccurrencesOfString:@"'" withString:@""];
                        self.deploymentString = [self.deploymentString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    }
            }
            return YES;
        }
    }
    return NO;
}

-(void) readPodFile
{
    // Really this parser needs some better code
    
    NSString *podFilePath = [self podFilePath];
    if ([podFilePath length]) {
        NSURL *fileURL = [NSURL fileURLWithPath: podFilePath];
        NSString *fileContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error: nil];
        
        fileContent = [fileContent trimWhiteSpaceAndNewline];
        NSMutableArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]].mutableCopy;
        if ([lines count] > 0) {
            if ([self readPlatformFromLine:[lines objectAtIndex:0]]) {
                [lines removeObjectAtIndex: 0];
            }
            
            while ([lines count] > 0) {
                NSString *line = [lines objectAtIndex: 0];
                line = [line trimWhiteSpace];
                if (![[line leftSubstringWithLength:1] isEqualToString:@"#"]) {
                    if ([line length] > 0) {
                        if ([line isSameLeftSideWithCaseInsensitive: kPOD]) {
                            CPDependency *dependency = [PodLineDependencyParser dependencyFromString: line];
                            if (dependency) {
                                dependency.project = self;
                            } else {
                                NSLog(@"Failed to parse line:\n%@", line);
                            }
                        } else
                            if ([line isSameLeftSideWithCaseInsensitive: kPOD_INHIBIT_ALL_WARNINGS]) {
                                self.inhibit_all_warnings = @(YES);
                            }
                    }
                }
                [lines removeObjectAtIndex: 0];
            }
        }
    }
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

-(void) writeProjectToPodFile
{
    NSMutableString *podString = [NSMutableString string];
    NSString *platformStr = [NSString stringWithFormat:@"platform :%@", [self.platformString lowercaseString]];
    if ([self.deploymentString length] > 0) {
        platformStr = [platformStr stringByAppendingFormat:@", '%@'", self.deploymentString];
    }
    
    [podString appendFormat:@"%@\n\n", platformStr];
    
    if (self.inhibit_all_warnings) {
        [podString appendFormat:@"%@\n\n", kPOD_INHIBIT_ALL_WARNINGS];
    }
    
    for (CPDependency *dependency in self.items) {
        [podString appendFormat:@"%@\n", [dependency podLineRepresentation]];
    }
    
    NSString *podFilePath = [self podFilePath];
    [podString writeToFile:podFilePath atomically:YES encoding:NSUTF8StringEncoding error: nil];
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

#pragma mark - Work around, most likely an Apple Bug

//- (void)addItemsObject:(CPDependency *)value {    
//    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey: @"items"]];
//    NSUInteger idx = [tmpOrderedSet count];
//    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:idx];
//    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey: @"items"];
//    [tmpOrderedSet addObject:value];
//    [self setPrimitiveValue:tmpOrderedSet forKey: @"items"];
//    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey: @"items"];
//}

@end
