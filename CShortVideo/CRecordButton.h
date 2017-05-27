//
//  CRecordButton.h
//  videoRecordingDemo
//
//  Created by apple on 2017/5/8.
//  Copyright © 2017年 qibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CRecordToolView.h"


@interface CRecordButton : UIButton

@property (weak  , nonatomic) id<CRecordViewDelegate> delegate;


-(instancetype)initWithDuration:(CGFloat)duration
                  InerViewColor:(UIColor *)inerViewColor
               ProgressBarWidth:(CGFloat)progressBarWidth
              ProgressBackColor:(UIColor *)progressBackColor
                  ProgressColor:(UIColor *)progressColor;


/**
     进度动画开始
 */
- (void)displayLinkON;

/**
     进度动画结束
 */
- (void)displayLinkOFF;


@end
