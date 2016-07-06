//
//  patchClass.m
//  diffpatch
//
//  Created by newfun on 16/4/20.
//  Copyright © 2016年 Facebook. All rights reserved.
//

#import "patchClass.h"
#import "DiffPatch.h"



@implementation patchClass{
  NSMutableDictionary *config;
  NSString *nowBundleVersion;
  NSString *newestBundleVersion;
  
}

- (instancetype)init{
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)checkUpdate {
  config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] mutableCopy];
  
  nowBundleVersion = [config objectForKey:@"nowBundle"];
  NSLog(@"当前bundle版本为:%@",nowBundleVersion);
  
  NSString *urlStr = @"http://newfun1994.github.io/react-native-DiffPatch/checkUpdate.json";
  NSURL *url = [NSURL URLWithString: urlStr];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];
  [request setHTTPMethod: @"GET"];
  NSData   *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];
  if (data){
    NSDictionary *resultInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    newestBundleVersion = [resultInfo objectForKey:@"version"];
    if ([nowBundleVersion floatValue] < [newestBundleVersion floatValue]) {
      NSLog(@"检测到最新版本:%@",newestBundleVersion);
      [self downLoadFile:[resultInfo objectForKey:@"url"]];
    }
  }
}

- (void)downLoadFile:(NSString *)urlString{
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];
  [request setHTTPMethod: @"GET"];
  NSData   *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];
  
  if (data){
    NSLog(@"diff下载成功");
    NSString *pacthPath = [self getFilePath:[newestBundleVersion stringByAppendingString: @".patch"]];
    if ([data writeToFile:pacthPath atomically:YES]) {
      [self patchBundle:pacthPath];
    }
    else{
      NSLog(@"diff保存失败.");
    }
  }
  else {
    NSLog(@"diff下载失败");
  }
}

- (void)patchBundle:(NSString*)pacthPath{
  NSString *nowBundlePath = [self getFilePath:[nowBundleVersion stringByAppendingString: @".jsbundle"]];
  //  创建最新jsbundel文件
  BOOL writeBundel =   [DiffPatch beginPatch:pacthPath origin:nowBundlePath toDestination:[self getFilePath:[newestBundleVersion stringByAppendingString: @".jsbundle"]]];
  if (!writeBundel) {
    NSLog(@"bundel写入失败");
    return;
  }
  
  [config setObject:nowBundleVersion forKey:@"oldBundle"];
  [config setObject:newestBundleVersion forKey:@"nowBundle"];
  
  [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"config"];
  
  NSLog(@"更新成功");
}

- (NSString*)getFilePath:(NSString*)fileName{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory =[paths objectAtIndex:0];
  NSString *filePath =[documentsDirectory stringByAppendingPathComponent:fileName];
  return filePath;
}



@end


