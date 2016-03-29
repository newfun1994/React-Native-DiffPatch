/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <DiffMatchPatch/DiffMatchPatch.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSURL *jsCodeLocation;
  
  //  jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios&dev=true"];
  
  NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"oldmain" ofType:@"jsbundle"];
  
  
  //文件拷贝
  NSString *newBundlePath = [self getFilePath:@"oldmain.jsbundle"];
  NSFileManager *fileManager =[NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath:newBundlePath]){
    [fileManager copyItemAtPath:bundlePath toPath:newBundlePath error:nil];
    bundlePath = newBundlePath;
  }
  else{
    bundlePath = newBundlePath;
  }
  
  jsCodeLocation = [NSURL fileURLWithPath:bundlePath];
  
  _rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"diffpatch"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  _rootViewController = [UIViewController new];
  _rootViewController.view = _rootView;
  self.window.rootViewController = _rootViewController;
  [self.window makeKeyAndVisible];
  [self checkUpdate];

  return YES;
}

- (NSString*)getFilePath:(NSString*)fileName{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory =[paths objectAtIndex:0];
  NSString *filePath =[documentsDirectory stringByAppendingPathComponent:fileName];
  return filePath;
}

- (void)checkUpdate{
  __block NSDictionary *resultInfo;
  NSString *urlStr = @"http://newfun1994.github.io/react-native-DiffPatch/update.json";
  NSURL *url = [NSURL URLWithString: urlStr];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];
  [request setHTTPMethod: @"GET"];
  NSData   *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];
  if (data){
    resultInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if ([[resultInfo objectForKey:@"isUpdate"] isEqualToString:@"1"]){
      [self alertView:[resultInfo objectForKey:@"patchUrl"]];
    }
  }
}

- (void)alertView:(NSString*)urlString{
  NSString *title = @"更新";
  NSString *message = @"检测到有的升级包，是否更新";
  NSString *okButtonTitle = @"是";
  NSString *cancleButtonTitle = @"否";
  
  
  //  __block
  // 初始化
  UIAlertController *alertDialog = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
  
  // 创建操作
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:okButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self downLoadFile:urlString];

  }];
  
  UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:cancleButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSLog(@"取消更新");
  }];
  
  // 添加操作
  [alertDialog addAction:okAction];
  [alertDialog addAction:cancleAction];
  // 呈现警告视图
    [self.window.rootViewController presentViewController:alertDialog animated:YES completion:nil];
  
}

- (void)downLoadFile:(NSString *)urlString{
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];
  [request setHTTPMethod: @"GET"];
  NSData   *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];
  
  if (data){
    NSLog(@"下载成功");
    NSString *pacthPath = [self getFilePath:@"diff.patch"];
    if ([data writeToFile:pacthPath atomically:YES]) {
      [self patchBundle];
      NSLog(@"保存成功.");
    }
    else{
      NSLog(@"保存失败.");
    }
  }
  else {
    NSLog(@"下载失败");
  }
}

- (void)patchBundle{
  DiffMatchPatch *dmp = [[DiffMatchPatch alloc]init];
  
  NSString *pacthPath = [self getFilePath:@"diff.patch"];
  
  NSData * patchData =[NSData dataWithContentsOfFile:pacthPath];
  
  //  NSString *patchString = [[NSString alloc] initWithData:patchData encoding:NSUTF8StringEncoding];
  NSArray *Patch = [NSKeyedUnarchiver unarchiveObjectWithData:patchData];
  
  NSString *oldPath = [self getFilePath:@"oldmain.jsbundle"];
  NSData * oldData =[NSData dataWithContentsOfFile:oldPath];
  NSString *oldString = [[NSString alloc] initWithData:oldData encoding:NSUTF8StringEncoding];
  
  NSArray *oString = [dmp patch_apply:Patch toString:oldString];
  
  NSString *content=oString[0];
  BOOL res=[content writeToFile:oldPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
  if (res) {
    NSLog(@"更新成功");
    
    _rootView = nil;
    _rootViewController = nil;
    
    NSURL *jsCodeLocation;

    jsCodeLocation = [NSURL fileURLWithPath:oldPath];
    
    RCTRootView *rotView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                        moduleName:@"diffpatch"
                                                 initialProperties:nil
                                                     launchOptions:nil];
    UIViewController *rotViewController = [UIViewController new];
    rotViewController.view = rotView;
    self.window.rootViewController = rotViewController;
  }else
    NSLog(@"更新失败");
  
  
}

@end
