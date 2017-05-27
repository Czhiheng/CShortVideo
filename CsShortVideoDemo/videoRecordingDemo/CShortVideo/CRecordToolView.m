//
//  CRecordToolView.m
//  videoRecordingDemo
//
//  Created by apple on 2017/5/8.
//  Copyright © 2017年 . All rights reserved.
//

#import "CRecordToolView.h"
#import "CRecordButton.h"

static NSString *defaultTip = @"长按录制小视频";
static NSString *upTip = @"上滑取消";
static NSString *downTip = @"向下继续";
static NSString *tapTip = @"请不要松手";


@interface CRecordToolView ()<CRecordViewDelegate>

@property (strong, nonatomic) UILabel *tipLabel;

@property (strong, nonatomic) CRecordButton * recordButton; // 中间圆录制按钮

@property (strong, nonatomic) UIButton *dismissButton;//取消拍摄
@property (strong, nonatomic) UIButton *reMakeButton;//重新拍摄
@property (strong, nonatomic) UIButton *doneButton;//完成拍摄

@property (assign, nonatomic) BOOL cancelHidden;//取消tip隐藏
@property (assign, nonatomic) BOOL isCancel;// 手指是否上移了

@end

@implementation CRecordToolView
-(void)showTip:(NSString *)tip
{
    _tipLabel.hidden = NO;
    _tipLabel.text = tip;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _tipLabel.hidden = YES;
    });
}

+(instancetype)creatWithDuration:(CGFloat)duration
                      InerViewColor:(UIColor *)inerViewColor
                   ProgressBarWidth:(CGFloat)progressBarWidth
                  ProgressBackColor:(UIColor *)progressBackColor
                      ProgressColor:(UIColor *)progressColor

{
    return [[self alloc]initWithDuration:(CGFloat)duration
                           InerViewColor:(UIColor *)inerViewColor
                        ProgressBarWidth:(CGFloat)progressBarWidth
                       ProgressBackColor:(UIColor *)progressBackColor
                           ProgressColor:(UIColor *)progressColor];
}

- (instancetype)initWithDuration:(CGFloat)duration
                   InerViewColor:(UIColor *)inerViewColor
                ProgressBarWidth:(CGFloat)progressBarWidth
               ProgressBackColor:(UIColor *)progressBackColor
                   ProgressColor:(UIColor *)progressColor
{
    
    self = [super initWithFrame:
            CGRectMake(0,
                       SCREEN_HEIGHT - C_TRANSFER(310),
                       SCREEN_WIDTH,
                       C_TRANSFER(310))];

    if (self) {
        _tipLabel = [[UILabel alloc] initWithFrame:
                     CGRectMake(0, 0, SCREEN_WIDTH, C_TRANSFER(30))];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont systemFontOfSize:C_TRANSFER(24)];
        _tipLabel.text = defaultTip;
        [self addSubview:_tipLabel];
        
        _recordButton = [[CRecordButton alloc]initWithDuration:duration
                                                 InerViewColor:inerViewColor
                                              ProgressBarWidth:progressBarWidth
                                             ProgressBackColor:progressBackColor
                                                 ProgressColor:progressColor];
        _recordButton.delegate = self;
        [self addSubview:_recordButton];
        
        _dismissButton = [[UIButton alloc] initWithFrame:
                          CGRectMake(((SCREEN_WIDTH-C_TRANSFER(160))/2 - C_TRANSFER(80))/2,
                                     _recordButton.center.y - C_TRANSFER(80)/2,
                                     C_TRANSFER(80),
                                     C_TRANSFER(80))];
        [_dismissButton setImage:[UIImage imageNamed:@"下箭头"]
                        forState:UIControlStateNormal];
        _dismissButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_dismissButton addTarget:self
                           action:@selector(onDismiss)
                 forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_dismissButton];
        
        [self showTip:defaultTip];

    }
    return self;
}

#pragma mark - 结束录制，弹出两侧按钮
- (void)onActionDone {
    _recordButton.hidden = YES;
    _dismissButton.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        _tipLabel.hidden = YES;
        self.reMakeButton.alpha = 1;
        self.reMakeButton.center = CGPointMake(SCREEN_WIDTH/4, _recordButton.center.y);
        
        self.doneButton.alpha = 1;
        self.doneButton.center = CGPointMake(SCREEN_WIDTH*3/4, _recordButton.center.y);
    } completion:^(BOOL finished) {
        
    }];
}

#pragma amrk - 撤销操作
- (void)reMakeButtonClicked:(UIButton *)sender {
    [self reMakeVideo];
    _recordButton.hidden = NO;
    _dismissButton.hidden = NO;
    _reMakeButton.alpha = 0;
    _reMakeButton.center = _recordButton.center;
    _doneButton.alpha = 0;
    _doneButton.center = _recordButton.center;
    _doneButton.userInteractionEnabled = YES;
}

- (void)doneButtonClicked:(UIButton *)sender {
    [self finishTakeVideo];
    _doneButton.userInteractionEnabled = NO;
}

#pragma mark -- property
- (UIButton *)reMakeButton {
    if (!_reMakeButton) {
        _reMakeButton = [[UIButton alloc] initWithFrame:
                         CGRectMake(_recordButton.center.x - C_TRANSFER(130)/2,
                                    _recordButton.center.y - C_TRANSFER(130)/2,
                                    C_TRANSFER(130),
                                    C_TRANSFER(130))];
        [_reMakeButton setBackgroundImage:[UIImage imageNamed:@"重新拍摄"]
                                 forState:UIControlStateNormal];
        _reMakeButton.alpha = 0;
        [_reMakeButton addTarget:self
                          action:@selector(reMakeButtonClicked:)
                forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_reMakeButton];
    }
    return _reMakeButton;
}

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [[UIButton alloc] initWithFrame:
                       CGRectMake(_recordButton.center.x - C_TRANSFER(130)/2,
                                  _recordButton.center.y - C_TRANSFER(130)/2,
                                  C_TRANSFER(130),
                                  C_TRANSFER(130))];
        [_doneButton setBackgroundImage:[UIImage imageNamed:@"完成"]
                               forState:UIControlStateNormal];
        _doneButton.center = _recordButton.center;
        _doneButton.alpha = 0;
        [_doneButton addTarget:self
                        action:@selector(doneButtonClicked:)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_doneButton];
    }
    return _doneButton;
}

#pragma mark -- QFShortVideoTakeButtonDelegate
- (void)onTap {//点击事件
    if ([self.delegate respondsToSelector:@selector(onTap)]) {
        [self.delegate onTap];
    }

    [self showTip:tapTip];
}

- (void)onMoveUp {//向上移动
    if ([self.delegate respondsToSelector:@selector(onMoveUp)]) {
        [self.delegate onMoveUp];
    }
    self.isCancel = YES;
    static BOOL isShowed;
    if (!isShowed) {
        isShowed = YES;
        static BOOL isShowed;
        if (!isShowed) {
            isShowed = YES;
            [self showTip:downTip];
        }
    }
}

// 移动回来
- (void)onMoveBack {
    if ([self.delegate respondsToSelector:@selector(onMoveBack)]) {
        [self.delegate onMoveBack];
    }
    self.isCancel = NO;
}

// 长按
- (void)onTouchDown {
    if ([self.delegate respondsToSelector:@selector(onTouchDown)]) {
        [self.delegate onTouchDown];
    }
    self.isCancel = NO;
    static BOOL isShowed;
    if (!isShowed) {
        isShowed = YES;
        [self showTip:upTip];
    }
}

//结束按下
- (void)onTouchUp {
    if ([self.delegate respondsToSelector:@selector(onTouchUp)]) {
        [self.delegate onTouchUp];
    }
    
    if (!_isCancel) {
        [self onActionDone];
    }
    
}

//取消拍摄
- (void)onDismiss {
    if ([self.delegate respondsToSelector:@selector(onDismiss)]) {
        [self.delegate onDismiss];
    }
}

//重新拍摄
- (void)reMakeVideo {
    if ([self.delegate respondsToSelector:@selector(reMakeVideo)]) {
        [self.delegate reMakeVideo];
    }
}

//完成拍摄
- (void)finishTakeVideo {
    if ([self.delegate respondsToSelector:@selector(finishTakeVideo)]) {
        [self.delegate finishTakeVideo];
    }
}

@end
