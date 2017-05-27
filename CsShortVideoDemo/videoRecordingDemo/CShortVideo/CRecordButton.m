//
//  CRecordButton.m
//  videoRecordingDemo
//
//  Created by apple on 2017/5/8.
//  Copyright © 2017年 . All rights reserved.
//

#import "CRecordButton.h"



@interface CRecordButton ()
@property (assign, nonatomic) NSTimeInterval delayTime; /**< 长按和点击区别延迟，默认 1.0 */
@property (assign, nonatomic) NSTimeInterval totalTime; /**< 录制最大时长，默认 15 */
@property (strong, nonatomic) UIColor * inerViewColor; /**< 中间圆颜色 */
@property (strong, nonatomic) UIColor * progressBackColor; /**< 进度条背景色 */
@property (strong, nonatomic) UIColor * progressColor; /**< 进度颜色 */
@property (assign, nonatomic) CGFloat progressBarWidth; /**< 进度条宽度 */
@property (assign, nonatomic) NSTimeInterval refreshRate; //肉眼能识别的刷新率
@property (assign, nonatomic) NSTimeInterval currentTime;
@property (assign, nonatomic) NSTimeInterval timeLeft;//init is totalTime * refreshRate
@property (strong, nonatomic) NSDate *startTime; // 按下录制按钮的时间
@property (weak  , nonatomic) CADisplayLink *displayLink; // 和屏幕刷新率相同的频率将内容画到屏幕上的定时器
@property (strong, nonatomic) UIView *inerView; // 中间实心圆
@property (assign, nonatomic) BOOL isTap;
@end

@implementation CRecordButton

- (void)dealloc {
    [self displayLinkOFF];
}

- (instancetype)initWithDuration:(CGFloat)duration
                   InerViewColor:(UIColor *)inerViewColor
                ProgressBarWidth:(CGFloat)progressBarWidth
               ProgressBackColor:(UIColor *)progressBackColor
                   ProgressColor:(UIColor *)progressColor {
    
    _totalTime = duration;
    _inerViewColor = inerViewColor;
    _progressBarWidth = progressBarWidth;
    _progressBackColor = progressBackColor;
    _progressColor = progressColor;
    
    CGRect frame = CGRectMake((SCREEN_WIDTH-C_TRANSFER(180))/2,
                              C_TRANSFER(60),
                              C_TRANSFER(180),
                              C_TRANSFER(180));
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        
        _inerView = [[UIView alloc] initWithFrame:
                     CGRectMake((1-INIT_INER_RATE)/2*frame.size.width,
                                (1-INIT_INER_RATE)/2*frame.size.height,
                                frame.size.width * INIT_INER_RATE,
                                frame.size.height * INIT_INER_RATE)];
        _inerView.backgroundColor = _inerViewColor;
         _inerView.layer.cornerRadius = _inerView.frame.size.height/2;
        _inerView.userInteractionEnabled = NO;
        [self addSubview:_inerView];
        
        _delayTime = 0.5; //长按延迟时间
        _refreshRate = 30.0f; //肉眼能识别的刷新率
        _totalTime = duration + 0.5;
        _timeLeft = _refreshRate * _totalTime;
        
        [self addTarget:self
                 action:@selector(touchDown)
       forControlEvents:UIControlEventTouchDown];
        [self addTarget:self
                 action:@selector(touchUp)
       forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self
                 action:@selector(touchUp)
       forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self
                 action:@selector(touchWithSender:event:)
       forControlEvents:UIControlEventAllTouchEvents];
    }
    return self;
}


- (void)touchDown{
    _isTap = NO;
    _startTime = [NSDate date];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_isTap) {
            [self displayLinkON];
            [UIView animateWithDuration:0.25 animations:^{
                _inerView.transform = CGAffineTransformMakeScale(TRAMSFORM_RATE, TRAMSFORM_RATE);
            } completion:^(BOOL finished) {
                
            }];
            if ([self.delegate respondsToSelector:@selector(onTouchDown)]) {
                [self.delegate onTouchDown];
            }
        }
    });
}

#pragma 松开或者到最大时间 执行
- (void)touchUp{
    
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:_startTime];
    if (duration < _delayTime) {
        _isTap = YES;
        if ([self.delegate respondsToSelector:@selector(onTap)]) { // 点击
            [self.delegate onTap];
        }
    } else if ([self.delegate respondsToSelector:@selector(onTouchUp)]){ // 长按,会在长按事件结束时调用 onTouchUp 事件
        
        [self displayLinkOFF];
        [UIView animateWithDuration:0.25 animations:^{
            _inerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
        _timeLeft = _refreshRate * _totalTime;
        [self setNeedsDisplay];
        [self.delegate onTouchUp];
    }
}


#pragma mark - 移动回来响应
- (void)touchDragDown{
    
    if ([self.delegate respondsToSelector:@selector(onMoveBack)]) {
        [self.delegate onMoveBack];
    }
}

#pragma mark - 上移响应
- (void)touchDragUp{
   
    if ([self.delegate respondsToSelector:@selector(onMoveUp)]) {
        [self.delegate onMoveUp];
    }
}

#pragma mark - 录制中上下移动手指监听
- (void)touchWithSender:(UIButton *)sender event:(UIEvent *)event{
    
    if (![event isKindOfClass:[UIEvent class]]) {
        return;
    }
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:sender];
    CGPoint previewLocation = [touch previousLocationInView:sender];
    
    if (location.y > 0 && previewLocation.y <= 0) {
        [self touchDragDown];
    } else if (location.y <= 0 && previewLocation.y > 0) {
        [self touchDragUp];
    }
}

#pragma mark - 重绘 rect
- (void)drawRect:(CGRect)rect {
    static CGFloat startAngle = -0.5 * M_PI;
    CGFloat endAngle = (1 - _timeLeft / (_refreshRate*_totalTime)) * 2 * M_PI + startAngle;
    
    // 进度圆圈
    UIBezierPath *circle = [UIBezierPath bezierPath];
    [circle addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                      radius:self.frame.size.width/2 - _progressBarWidth/2 - 0.5
                  startAngle:0
                    endAngle:2 * M_PI
                   clockwise:YES];
    circle.lineWidth = _progressBarWidth;
    [_progressBackColor set];
    [circle stroke];
    
    // 进度圆圈内的进度
    UIBezierPath *progress = [UIBezierPath bezierPath];
    [progress addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                        radius:self.frame.size.width/2 - _progressBarWidth/2 - 0.5
                    startAngle:startAngle
                      endAngle:endAngle
                     clockwise:YES];
    progress.lineWidth = _progressBarWidth;
    [_progressColor set];
    [progress stroke];
}

#pragma mark - 进度动画开始
- (void)displayLinkON {
    if (self.displayLink) {
        return;
    }
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self
                                                             selector:@selector(displayLinkAction)];
    displayLink.frameInterval = rintf(60/_refreshRate);
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                      forMode:NSRunLoopCommonModes];
    self.displayLink = displayLink;
}

#pragma mark - 进度动画关闭
- (void)displayLinkOFF {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

#pragma mark - 进度动画进行中
- (void)displayLinkAction {
    _timeLeft -= 1;
    [self setNeedsDisplay];
    if (_timeLeft <= 0) {
        [self touchUp];
    }
}



@end
