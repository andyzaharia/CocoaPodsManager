//
//  CPProject.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 12/23/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CPDependency, PodSpec;

@interface CPProject : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * deploymentString;
@property (nonatomic, retain) NSNumber * inhibit_all_warnings;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * platformString;
@property (nonatomic, retain) NSString * post_install;
@property (nonatomic, retain) NSString * pre_install;
@property (nonatomic, retain) NSString * projectFilePath;
@property (nonatomic, retain) NSOrderedSet *items;
@property (nonatomic, retain) NSOrderedSet *pods;
@end

@interface CPProject (CoreDataGeneratedAccessors)

- (void)insertObject:(CPDependency *)value inItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromItemsAtIndex:(NSUInteger)idx;
- (void)insertItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInItemsAtIndex:(NSUInteger)idx withObject:(CPDependency *)value;
- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withItems:(NSArray *)values;
- (void)addItemsObject:(CPDependency *)value;
- (void)removeItemsObject:(CPDependency *)value;
- (void)addItems:(NSOrderedSet *)values;
- (void)removeItems:(NSOrderedSet *)values;
- (void)insertObject:(PodSpec *)value inPodsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPodsAtIndex:(NSUInteger)idx;
- (void)insertPods:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePodsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPodsAtIndex:(NSUInteger)idx withObject:(PodSpec *)value;
- (void)replacePodsAtIndexes:(NSIndexSet *)indexes withPods:(NSArray *)values;
- (void)addPodsObject:(PodSpec *)value;
- (void)removePodsObject:(PodSpec *)value;
- (void)addPods:(NSOrderedSet *)values;
- (void)removePods:(NSOrderedSet *)values;
@end
