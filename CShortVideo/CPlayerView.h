//
//  CPlayerView.h
//  videoRecordingDemo
//
//  Created by apple on 2017/5/11.
//  Copyright © 2017年 qibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface CPlayerView : UIView


- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@property (nonatomic,copy)NSString *URLString;//视频播放地址
@property (nonatomic,copy)NSString *fileURLString;//本地文件地址
@property (nonatomic,copy)NSURL *URL;//url
@property (nonatomic,assign,getter=isMuted) BOOL muted;//静音 default is NO;
@property (nonatomic,assign) BOOL repeat;//default is YES


- (void)play;//播放视频
- (void)pause;//暂停播放


+ (UIImage *)thumbnailImageWithURLString:(NSString *)URLString;
+ (UIImage *)thumbnailImageWithFileURLString:(NSString *)fileURLString;
+ (UIImage *)thumbnailImageWithURL:(NSURL *)URL;


@end
