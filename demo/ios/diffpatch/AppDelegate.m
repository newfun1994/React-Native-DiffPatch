/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"
#import "patchClass.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
  
  NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"0.1" ofType:@"jsbundle"];
  
  //读取config.plist文件
  if(![[NSUserDefaults standardUserDefaults] objectForKey:@"config"]){
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"config"];
  }
  NSDictionary *config = [[NSUserDefaults standardUserDefaults] objectForKey:@"config"];
  NSString *loadBundle = [[self getFilePath:[config objectForKey:@"nowBundle"]] stringByAppendingString:@".jsbundle"];
  if ([[config objectForKey:@"crash"] boolValue]) {
    loadBundle = [[self getFilePath:[config objectForKey:@"oldBundle"]] stringByAppendingString:@".jsbundle"];
  }
  
  
  //文件拷贝
  NSFileManager *fileManager =[NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath:loadBundle]){
    [fileManager copyItemAtPath:bundlePath toPath:loadBundle error:nil];
    bundlePath = loadBundle;
  }
  else{
    bundlePath = loadBundle;
  }
  
  NSURL *jsCodeLocation = [NSURL fileURLWithPath:bundlePath];
  
//  jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios&dev=true"];
  
  
  _rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                          moduleName:@"diffpatch"
                                   initialProperties:nil
                                       launchOptions:launchOptions];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  _rootViewController = [UIViewController new];
  _rootViewController.view = _rootView;
  self.window.rootViewController = _rootViewController;
  [self.window makeKeyAndVisible];
  
  [NSThread detachNewThreadSelector:@selector(checkUpdate) toTarget:self withObject:nil];
  return YES;
}

- (void)checkUpdate {
  patchClass *patch = [[patchClass alloc] init];
  [patch checkUpdate];
}

- (NSString*)getFilePath:(NSString*)fileName{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory =[paths objectAtIndex:0];
  NSString *filePath =[documentsDirectory stringByAppendingPathComponent:fileName];
  return filePath;
}

@end
