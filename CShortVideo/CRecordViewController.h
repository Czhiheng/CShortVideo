//
//  CRecordViewController.h
//  videoRecordingDemo
//
//  Created by apple on 2017/5/6.
//  Copyright © 2017年 qibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CRecordViewController : UIViewController


/**
 Factory creation method

 @param duration video duration，default is 15s
 @param targetSize  Target resolution for video files (video output used)，default is 640*480，
 You can choose ：   AVAssetExportPreset640x480
                     AVAssetExportPreset960x540
                     AVAssetExportPreset1280x720
                     AVAssetExportPreset1920x1080
                     AVAssetExportPreset3840x2160
 
 @param inerViewColor record iner View color，default is red
 @param progressBarWidth progress bar Width，default is 5
 @param progressBackColor progress bar background color，default is white
 @param progressColor Progress completed color，default is green
 @param landscapeMode Horizontal screen ， default is NO
 @return Controller instance
 
 */
+(instancetype)recordWithDuration:(CGFloat)duration
                       TargetSize:(NSString *)targetSize
                    InerViewColor:(UIColor *)inerViewColor
                 ProgressBarWidth:(CGFloat)progressBarWidth
                ProgressBackColor:(UIColor *)progressBackColor
                    ProgressColor:(UIColor *)progressColor
                    LandscapeMode:(BOOL)landscapeMode;


/**
 recording finished callback
 */
@property (nonatomic, copy)  void(^finishBlock) (NSString*);
@end
