

#import "DiffPatch.h"
#import "bsdiff.h"
#import "bspatch.h"

@implementation DiffPatch

+ (BOOL)beginDiff:(NSString *)patch
        oldBundle:(NSString *)oldBundle
        newBundle:(NSString *)newBundle
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:newBundle]) {
        return NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:oldBundle]) {
        return NO;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:patch]) {
        [[NSFileManager defaultManager] removeItemAtPath:patch error:nil];
    }
    
    int err = beginDiff([oldBundle UTF8String], [newBundle UTF8String], [patch UTF8String]);
    if (err) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)beginPatch:(NSString *)patch
            origin:(NSString *)origin
     toDestination:(NSString *)destination
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:patch]) {
        return NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:origin]) {
        return NO;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
        [[NSFileManager defaultManager] removeItemAtPath:destination error:nil];
    }
    
    int err = beginPatch([origin UTF8String], [destination UTF8String], [patch UTF8String]);
    if (err) {
        return NO;
    }
    return YES;
}

@end
