//
//  NSManagedObject+CoreData.h
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/17/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (CoreData)

+ (id) findFirstWithPredicate: (NSPredicate *) predicate;
+ (id) findFirstByAttribute:(NSString *) attribute withValue: (id) value;

+ (NSArray *) findAll;
+ (NSArray *) findAllWithPredicate: (NSPredicate *) predicate;
+ (NSArray *) findAllSortedBy:(NSString *) param ascending: (BOOL) ascending;

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate;

+ (id) createEntityInContext: (NSManagedObjectContext *) context;
+ (id) createEntity;

@end
