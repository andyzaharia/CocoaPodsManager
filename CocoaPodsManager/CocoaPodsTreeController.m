//
//  CocoaPodsTreeController.m
//  CocoaPodsManager
//
//  Created by Andy on 28.02.2013.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "CocoaPodsTreeController.h"

@interface CocoaPodsTreeController (Private)

- (void)updateSortOrderOfModelObjects;

@end

@implementation CocoaPodsTreeController (Private)

- (void)updateSortOrderOfModelObjects{

//	for (NSTreeNode *node in [self flattenedNodes])
//		[[node representedObject] setValue:[NSNumber numberWithInt:[[node indexPath] lastIndex]] forKey:@"sortIndex"];
}

@end


@implementation CocoaPodsTreeController

- (void)insertObject:(id)object atArrangedObjectIndexPath:(NSIndexPath *)indexPath{
    
	[super insertObject:object atArrangedObjectIndexPath:indexPath];
	[self updateSortOrderOfModelObjects];
}

- (void)insertObjects:(NSArray *)objects atArrangedObjectIndexPaths:(NSArray *)indexPaths{
    
	[super insertObjects:objects atArrangedObjectIndexPaths:indexPaths];
	[self updateSortOrderOfModelObjects];
}

- (void)removeObjectAtArrangedObjectIndexPath:(NSIndexPath *)indexPath{

	[super removeObjectAtArrangedObjectIndexPath:indexPath];
	[self updateSortOrderOfModelObjects];
}

- (void)removeObjectsAtArrangedObjectIndexPaths:(NSArray *)indexPaths{

	[super removeObjectsAtArrangedObjectIndexPaths:indexPaths];
	[self updateSortOrderOfModelObjects];
}

- (void)moveNode:(NSTreeNode *)node toIndexPath:(NSIndexPath *)indexPath{

	[super moveNode:node toIndexPath:indexPath];
	[self updateSortOrderOfModelObjects];
}

- (void)moveNodes:(NSArray *)nodes toIndexPath:(NSIndexPath *)indexPath{

	[super moveNodes:nodes toIndexPath:indexPath];
	[self updateSortOrderOfModelObjects];
}

@end
