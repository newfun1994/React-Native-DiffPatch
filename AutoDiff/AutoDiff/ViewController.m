//
//  ViewController.m
//  AutoDiff
//
//  Created by newfun on 16/3/23.
//  Copyright © 2016年 newfun. All rights reserved.
//

#import "ViewController.h"
#import "DiffPatch.h"

@implementation ViewController{
    NSString *patchPath;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [NSApp setDelegate:self];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication{
    return YES;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (IBAction)createDiff:(NSButtonCell *)sender {
    NSString *oldPath = self.OldBundleFile.stringValue;
    NSString *newPath = self.NewBundleFile.stringValue;
    if(![self fileExistsAtPath:oldPath]){
        self.msg.stringValue = @"massage:oldBundle不存在";
        return;
    }
    if(![self fileExistsAtPath:newPath]){
        self.msg.stringValue = @"massage:newBundle不存在";
        return;
    }
    self.msg.stringValue = @"massage:...";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString *desktopPath = [paths objectAtIndex:0];
    patchPath = [NSString stringWithFormat:@"%@%@%@%@", desktopPath, @"/", [self getTime], @".patch"];
    if ([DiffPatch beginDiff:patchPath oldBundle:oldPath newBundle:newPath]) {
        self.msg.stringValue = [NSString stringWithFormat:@"%@%@", @"创建成功 位置:",patchPath];
    }
}

- (IBAction)patch:(id)sender {
    if(![self fileExistsAtPath:patchPath]){
        self.msg.stringValue = @"massage:patch文件不存在";
        return;
    }
    NSString *director = [self.NewBundleFile.stringValue stringByDeletingLastPathComponent];
    NSString *pathExtension = [self.NewBundleFile.stringValue pathExtension];
    NSString *fileName = [NSString stringWithFormat:@"%@%@%@", director, @"/", [self getTime]];
    if (![pathExtension isEqualToString:@""]) {
        fileName = [NSString stringWithFormat:@"%@%@%@", fileName, @".", pathExtension];
    }
    if([DiffPatch beginPatch:patchPath origin:self.OldBundleFile.stringValue toDestination:fileName]){
        self.msg.stringValue = [NSString stringWithFormat:@"%@%@", @"测试成功 位置:", fileName];
    }
}

- (IBAction)selectOldBundle:(id)sender {
    self.OldBundleFile.stringValue = [self selectFile];
}
- (IBAction)selectNewBundle:(id)sender {
    self.NewBundleFile.stringValue = [self selectFile];
}

- (IBAction)exchange:(id)sender {
    NSString *string = self.OldBundleFile.stringValue;
    self.OldBundleFile.stringValue = self.NewBundleFile.stringValue;
    self.NewBundleFile.stringValue = string;
}

- (BOOL)fileExistsAtPath:(NSString*)path{
    NSFileManager *fileManage = [NSFileManager defaultManager];
    return [fileManage fileExistsAtPath: path];
}

//获取当前系统时间
- (NSString*)getTime{
    NSDate *date = [NSDate date];
    // 2013-04-07 11:14:45
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // HH是24进制，hh是12进制
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *string = [formatter stringFromDate:date];
    return  string;
}

//上传文件
- (NSString*)selectFile{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt: @"选择"];
    //    openPanel.allowedFileTypes = [NSArray arrayWithObjects: @"jsbundle", nil];
    openPanel.directoryURL = nil;
    
    if ([openPanel runModal] == NSModalResponseOK){
        NSURL *fileUrl = [[openPanel URLs] objectAtIndex:0];
        return [fileUrl path];
    }
    return nil;
}

@end
