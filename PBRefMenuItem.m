//
//  PBRefMenuItem.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefMenuItem.h"


@implementation PBRefMenuItem
@synthesize ref, commit;

+ (PBRefMenuItem *)addRemoteMethod:(BOOL)hasRemote title:(NSString *)title action:(SEL)selector
{
	PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""];
	[item setEnabled:hasRemote];
	return item;
}

+ (NSArray *)defaultMenuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit target:(id)target
{
	NSMutableArray *array = [NSMutableArray array];
	NSString *type = [ref type];
	if ([type isEqualToString:@"remote"])
		type = @"remote branch";
	else if ([type isEqualToString:@"head"])
		type = @"branch";
    
    NSString *targetRef = [ref shortName];
	NSString *remote = [commit.repository remoteForRefName:targetRef];
	BOOL hasRemote = (remote ? YES : NO); 
    
	if ([type isEqualToString:@"branch"]) {
        if (hasRemote) {        
            PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Remote: %@", remote] action:nil keyEquivalent:@""];
            [item setEnabled:NO];
            [array addObject:item];
            PBRefMenuItem *sepItem = [PBRefMenuItem separatorItem];
            [array addObject:sepItem];
        }
        
        [array addObject:[self addRemoteMethod:hasRemote title:[NSString stringWithFormat:@"Push %@ to remote", targetRef] action:@selector(pushRef:)]];
		[array addObject:[self addRemoteMethod:hasRemote title:[NSString stringWithFormat:@"Pull down latest"] action:@selector(pullRef:)]];
		[array addObject:[self addRemoteMethod:hasRemote title:[NSString stringWithFormat:@"Rebase local changes with latest"] action:@selector(rebaseRef:)]];
		
        PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:[@"Checkout " stringByAppendingString:targetRef]
                                                            action:@selector(checkoutRef:)
                                                     keyEquivalent: @""];
        if ([targetRef isEqualToString:[[[commit repository] headRef] description]])
            [item setEnabled:NO];
        
		[array addObject:item];
    }

	[array addObject:[[PBRefMenuItem alloc] initWithTitle:[@"Delete " stringByAppendingString:targetRef]
												   action:@selector(removeRef:)
											keyEquivalent: @""]];
    if ([type isEqualToString:@"tag"])
		[array addObject:[[PBRefMenuItem alloc] initWithTitle:@"View tag info"
													   action:@selector(tagInfo:)
												keyEquivalent: @""]];    

	for (PBRefMenuItem *item in array)
	{
		[item setTarget: target];
		[item setRef: ref];
		[item setCommit:commit];
	}

	return array;
}

+ (NSArray *) defaultMenuItemsForCommit:(PBGitCommit *)commit target:(id)target
{
    NSMutableArray *items = [NSMutableArray array];
    
    NSMenuItem *copySHAItem = [[PBRefMenuItem alloc] initWithTitle:@"Copy SHA" action:@selector(copySHA:) keyEquivalent:@""];
    [items addObject:copySHAItem];
    
    NSMenuItem *copyPatchItem = [[PBRefMenuItem alloc] initWithTitle:@"Copy Patch" action:@selector(copyPatch:) keyEquivalent:@""];
    [items addObject:copyPatchItem];
    
	for (PBRefMenuItem *item in items)
	{
		[item setTarget: target];
		[item setCommit:commit];
	}
    
	return items;
}

+ (PBRefMenuItem *)separatorItem {
    PBRefMenuItem * item = (PBRefMenuItem *) [super separatorItem];
    return item;
}

@end
