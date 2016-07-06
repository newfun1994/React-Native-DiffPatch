/*
 ***************************************************************************
 * Copyright (C) 2012-2016 PingAnFu. All Rights Reserved
 * File			: PafRNDiffPatch.m
 *
 * Description	: 文件差异对比与合并
 *
 * Creation		: 2016/04/26
 * Author       : newfun
 * History		: Creation, 2016/04/26, newfun, Create the file
 ***************************************************************************
 **/

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
