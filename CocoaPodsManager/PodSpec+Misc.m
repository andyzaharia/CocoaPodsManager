//
//  Pod+Misc.m
//  CocoaPodsManager
//
//  Created by Andy on 07.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "PodSpec+Misc.h"
#import "AppConstants.h"

@implementation PodSpec (Misc)

#pragma mark -

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    [self configureTransientValues];
}

-(void) configureTransientValues
{
    self.childDescription = [NSString stringWithFormat: @"Description: %@", ([self.desc length]) ? self.desc : @""];
    self.childHomePage = [NSString stringWithFormat: @"Homepage: %@",  ([self.homePage length]) ? self.homePage : @""];
    self.childSourcePage = [NSString stringWithFormat: @"Source: %@",  ([self.source length]) ? self.source : @""];
    self.childVersions = [NSString stringWithFormat: @"Versions: %@",  ([self.versions length]) ? self.versions : @""];
}

#pragma mark -
#pragma mark NSPasteboardWriting support

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    
    static NSArray *writableTypes = nil;
    
    if (!writableTypes) {
        if (!writableTypes) {
            writableTypes = [[NSArray alloc] initWithObjects: NSPasteboardTypeString, nil];
        }
    }
    return writableTypes;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return self.name;
    }
    return nil;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return NSPasteboardReadingAsString;
    }
    return 0;
}

#pragma mark -
#pragma mark  NSPasteboardReading support

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    // We allow creation from folder and image URLs only, but there is no way to specify just file URLs that contain images
    return [NSArray arrayWithObjects:(id)kUTTypeUTF8PlainText, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return NSPasteboardReadingAsString;
    } else {
        return NSPasteboardReadingAsData;
    }
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    
    self = (PodSpec *)[[PodSpec findAllWithPredicate:[NSPredicate predicateWithFormat:@"name == %@", propertyList]] lastObject];
    
    // We may return nil
    return self;
}

#pragma mark -

-(NSMutableArray *) versionsArray
{    
    NSString *podPath =  [[NSHomeDirectory() stringByAppendingPathComponent: PODS_MASTER_FOLDER] stringByAppendingPathComponent: self.name];
    NSError *error = nil;
    NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:podPath error: &error];
    __block NSMutableArray *versions = [NSMutableArray array];
    if ([items count]) {
        [items enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx, BOOL *stop) {
            BOOL isDir;
            NSString *fullPath = [podPath stringByAppendingPathComponent: item];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] &&isDir) {
                if(isDir) {
                    [versions addObject: item];
                }
            }
        }];
    }
    
//    NSString *versionsStr = [self.versions stringByReplacingOccurrencesOfString:@"[master repo]" withString:@""];
//    versionsStr = [versionsStr stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSMutableArray *items = [versionsStr componentsSeparatedByString:@","].mutableCopy;
    return versions;
}

-(NSMutableArray *) lastVersionYAML
{
    // Well, theoretically last version.
    NSArray *versions = [self versionsArray];
    versions = [versions sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *lastVersion = [versions lastObject];
    if ([lastVersion length]) {
        return [self fetchPropertiesInContext:self.managedObjectContext withVersion: lastVersion];
    } else return nil;
}

@end
