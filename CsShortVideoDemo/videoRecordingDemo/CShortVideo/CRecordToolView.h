//
//  CRecordToolView.h
//  videoRecordingDemo
//
//  Created by apple on 2017/5/8.
//  Copyright © 2017年 . All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CRecordViewDelegate <NSObject>

/**
     单击
 */
- (void)onTap;

/**
     按住录制中向上滑动
 */
- (void)onMoveUp;

/**
     按住录制中滑动回原位
 */
- (void)onMoveBack;

/**
     长按
 */
- (void)onTouchDown;

/**
     松开或结束
 */
- (void)onTouchUp;

/**
     撤销
 */
- (void)onDismiss;

/**
     重新拍摄
 */
- (void)reMakeVideo;

/**
     完成拍摄
 */
- (void)finishTakeVideo;

@end


@interface CRecordToolView : UIView

@property (weak  , nonatomic) id<CRecordViewDelegate>delegate;


+(instancetype)creatWithDuration:(CGFloat)duration
                    InerViewColor:(UIColor *)inerViewColor
                 ProgressBarWidth:(CGFloat)progressBarWidth
                ProgressBackColor:(UIColor *)progressBackColor
                    ProgressColor:(UIColor *)progressColor;

@end
