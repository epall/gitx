//
//  PBEasyPipe.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBEasyPipe.h"


@implementation PBEasyPipe

+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args
{
	return [self handleForCommand:cmd withArgs:args inDir:nil];
}

+ (NSFileHandle*) handleForCommand: (NSString*) cmd withArgs: (NSArray*) args inDir: (NSString*) dir
{
	NSTask *task = [self taskForCommand:cmd withArgs:args inDir:dir];
	NSFileHandle* handle = [[task standardOutput] fileHandleForReading];
	
	[task launch];
	return handle;
}

+ (NSTask *) taskForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir
{
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:cmd];
	[task setArguments:args];
	if (dir) {
        // check if the dir exists and is really a folder
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir] && isDir) {
            [task setCurrentDirectoryPath:dir];
        }
    }
    
   /* use getenv too so we can easily use Xcodes executable environment */
	if (([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Debug Messages"]) || (getenv("PBDebugEnabled"))) 
   {
      NSLog(@"Starting command `%@ %@` in dir %@", cmd, [args componentsJoinedByString:@" "], dir);
   }
   
#ifdef CLI
	NSLog(@"Starting command `%@ %@` in dir %@", cmd, [args componentsJoinedByString:@" "], dir);
#endif
    
	NSPipe* pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	return task;
}

+ (NSString *) outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir retValue:(int *)ret {
    return [self outputForCommand:cmd withArgs:args inDir:dir byExtendingEnvironment:nil inputString:nil retValue:ret];
}

+ (NSString *) outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir inputString:(NSString *)input retValue:(int *)ret {
    return [self outputForCommand:cmd withArgs:args inDir:dir byExtendingEnvironment:nil inputString:input retValue:ret];
}

+ (NSString *) outputForCommand:(NSString *)cmd withArgs:(NSArray *)args inDir:(NSString *)dir byExtendingEnvironment:(NSDictionary *)dict inputString:(NSString *)input retValue:(int *)ret {
    NSTask * task = [self taskForCommand:cmd withArgs:args inDir:dir];

    if (dict) {
        NSMutableDictionary * env = [[[NSProcessInfo processInfo] environment] mutableCopy];
        [env addEntriesFromDictionary:dict];
        [task setEnvironment:env];
    }

    NSFileHandle * handle = [[task standardOutput] fileHandleForReading];

    if (input) {
        [task setStandardInput:[NSPipe pipe]];
        NSFileHandle * inHandle = [task.standardInput fileHandleForWriting];
        [inHandle writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
        [inHandle closeFile];
    }

    [task launch];

    NSData * data = [handle readDataToEndOfFile];
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!string)
        string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];

    // Strip trailing newline
    if ([string hasSuffix:@"\n"])
        string = [string substringToIndex:[string length] - 1];

    [task waitUntilExit];
    if (ret)
        *ret = [task terminationStatus];
    return string;
}	

// We don't use the above function because then we'd have to wait until the program was finished
// with running

+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args  inDir: (NSString*) dir
{
	NSTask *task = [self taskForCommand:cmd withArgs:args inDir:dir];
	NSFileHandle* handle = [[task standardOutput] fileHandleForReading];
	
	[task launch];
#warning This can cause a "Bad file descriptor"... when?
	NSData *data;
	@try {
		data = [handle readDataToEndOfFile];
	}
	@catch (NSException * e) {
		NSLog(@"Got a bad file descriptor in %s!", _cmd);
		if ([NSThread currentThread] != [NSThread mainThread])
			[task waitUntilExit];

		return nil;
	}
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!string)
		string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];

	if ([NSThread currentThread] != [NSThread mainThread])
		[task waitUntilExit];

	return string;
}


+ (NSString*) outputForCommand: (NSString*) cmd withArgs: (NSArray*) args
{
	return [self outputForCommand:cmd withArgs:args inDir:nil];
}

@end
