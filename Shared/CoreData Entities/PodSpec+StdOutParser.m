//
//  PodSpec+StdOutParser.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 2/28/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec+StdOutParser.h"
#import "NSString+Misc.h"
#import "YAMLSerialization.h"

#import "AppConstants.h"

#define HOME_PAGE @"- Homepage:"
#define SOURCE_URL @"- Source:"
#define VERSIONS_PAGE @"- Versions:"

@implementation PodSpec (StdOutParser)

-(void) applyProperties: (NSDictionary *) properties
{
    if (properties) {
        NSString *desc = [properties valueForKey:@"description"];
        if (![desc length]) {
            desc = [properties valueForKey:@"summary"]; // Fall back to summary.
        }
        self.desc = [desc stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        
    }
}

#pragma mark -

-(NSString *) podNameFromLine: (NSString *) line{
    
    NSRange podStartRange = NSMakeRange(0, 2);
    if ([line length] > 2) {
        if ([[line substringWithRange: podStartRange] isEqualToString:@"->"]) {
            NSString *linePodName = [line stringByReplacingCharactersInRange:podStartRange withString:@""];
            linePodName = [linePodName trimWhiteSpaceAndNewline];
            
            NSRange sP = [linePodName rangeOfString:@"("];
            NSRange eP = [linePodName rangeOfString:@")"];
            if((sP.location != NSNotFound) && (eP.location != NSNotFound)){
                linePodName = [[linePodName stringByReplacingCharactersInRange:NSMakeRange(sP.location, [linePodName length] - sP.location) withString:@""]  trimWhiteSpaceAndNewline];
            }
            return linePodName;
        }
    }
    
    return @"";
}


-(NSMutableArray *) fetchYamlPropertiesWithVersion: (NSString *) version {
    TODO("Must be improved.")
    
    NSString *podSpecFilePath = [NSHomeDirectory() stringByAppendingPathComponent: [PODS_MASTER_FOLDER stringByAppendingPathComponent: self.name]];
    podSpecFilePath = [podSpecFilePath stringByAppendingPathComponent:version]; // add version to path
    podSpecFilePath = [podSpecFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.podspec", self.name]]; // add pod file to path
    
    __block NSMutableArray *yaml = nil;
    
    [CocoaPodsApp executeWithArguments:@[@"ipc", @"spec", podSpecFilePath] responseBlock:^(NSString *stdOut) {
        
        NSError *error = nil;
        
        yaml = [YAMLSerialization objectsWithYAMLString: stdOut
                                                options: kYAMLReadOptionStringScalars
                                                  error: &error];
        if (!error) {
            NSDictionary *properties = [yaml lastObject];
            [self applyProperties: properties];
        } else {
            // Fail silently.
        }
    } failBlock:^(NSError *error) {
        TODO("hanlde error");
    }];
    
    return yaml;
}

// Launched from main thread only
-(void) fetchPropertiesAsyncWithVersion: (NSString *) version
                                 onDone: (OnDoneEx) onDone
                              onFailure: (OnError) onFailure
{
    __weak PodSpec *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *podSpecFilePath = [NSHomeDirectory() stringByAppendingPathComponent: [PODS_MASTER_FOLDER stringByAppendingPathComponent: self.name]];
        podSpecFilePath = [podSpecFilePath stringByAppendingPathComponent:version]; // add version to path
        podSpecFilePath = [podSpecFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.podspec", self.name]]; // add pod file to path
        
        __block NSMutableArray *yaml = nil;
        
        [CocoaPodsApp executeWithArguments:@[@"ipc", @"spec", podSpecFilePath] responseBlock:^(NSString *stdOut) {
            
            NSError *error = nil;
            yaml = [YAMLSerialization YAMLWithData: [stdOut dataUsingEncoding:NSUTF8StringEncoding]
                                           options: kYAMLReadOptionStringScalars
                                             error: &error];
            
            NSDictionary *properties = [yaml lastObject];
            NSString *descriptionString = nil;
            if (properties) {
                NSString *desc = [properties valueForKey:@"description"];
                if (![desc length]) {
                    desc = [properties valueForKey:@"summary"]; // Fall back to summary.
                }
                
                desc = [desc stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                descriptionString = desc;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.desc = descriptionString;
                
                if (onDone) {
                    onDone(properties);
                }
            });
            
        } failBlock:^(NSError *error) {
            if (onFailure) {
                onFailure(error);
            }
        }];
    });
}

-(void) fetchPropertiesInContext: (NSManagedObjectContext *) context{
    
    // Deprecated, must be removed.
    
    
    if ([self.name length] == 0) {
        return;
    }
    
    return;
    
    // Messy, looking forward for a cleaner implementation
    [CocoaPodsApp executeWithArguments:@[@"search", self.name] responseBlock:^(NSString *output) {
        NSMutableArray *lines = [output componentsSeparatedByString:@"\n"].mutableCopy;
        BOOL ourPod = NO;
        NSInteger podDeclarationLine = -1;
        for (NSString *line in lines){
            NSString *lineT = [line trimWhiteSpace];
            
            if (ourPod) {
                
                [context performBlockAndWait:^{
                    if ([lines indexOfObject:line] == podDeclarationLine + 1) {
                        // This is the description line
                        self.desc = [line trimWhiteSpace];
                    }else{
                        
                        if ([lineT length] > [HOME_PAGE length] && [[lineT substringWithRange:NSMakeRange(0, [HOME_PAGE length])] isEqualToString: HOME_PAGE]) {
                            self.homePage = [lineT substringWithRange:NSMakeRange([HOME_PAGE length], [lineT length] - [HOME_PAGE length])];
                            self.homePage = [self.homePage trimWhiteSpace];
                        }
                        
                        if ([lineT length] > [SOURCE_URL length] && [[lineT substringWithRange:NSMakeRange(0, [SOURCE_URL length])] isEqualToString: SOURCE_URL]) {
                            self.source = [lineT substringWithRange:NSMakeRange([SOURCE_URL length], [lineT length] - [SOURCE_URL length])];
                            self.source = [self.source trimWhiteSpace];
                        }
                        
                        if ([lineT length] > [VERSIONS_PAGE length] && [[lineT substringWithRange:NSMakeRange(0, [VERSIONS_PAGE length])] isEqualToString: VERSIONS_PAGE]) {
                            self.versions = [lineT substringWithRange:NSMakeRange([VERSIONS_PAGE length], [lineT length] - [VERSIONS_PAGE length])];
                            self.versions = [self.versions trimWhiteSpace];
                        }
                    }
                    
                    self.fetchedDetails = @YES;
                }];
            }
            
            NSRange podStartRange = NSMakeRange(0, 2);
            if ([lineT length] > 2 && [[lineT substringWithRange: podStartRange] isEqualToString:@"->"]) {
                NSString *linePodName = [self podNameFromLine: lineT];
                
                if ([linePodName isEqualToString: self.name]) {
                    ourPod  = YES;
                    podDeclarationLine = [lines indexOfObject: line];
                }else {
                    break;
                }
            }
        }
        
    }failBlock:^(NSError *error) {
        NSLog(@"Failed to fetch pod properties: %@", self.name);
    }];
}

@end
