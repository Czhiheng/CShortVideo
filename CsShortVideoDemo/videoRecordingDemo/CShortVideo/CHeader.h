//
//  CHeader.h
//  videoRecordingDemo
//
//  Created by apple on 2017/5/6.
//  Copyright © 2017年 . All rights reserved.
//

#ifndef CHeader_h
#define CHeader_h


// 屏幕宽高
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define C_TRANSFER_FORCE(x) rintf((x) * SCREEN_WIDTH / 750)
#define C_TRANSFER(x) ((SCREEN_WIDTH>320)?((x)/2):rintf((x) * SCREEN_WIDTH / 750))

#define INIT_INER_RATE 0.7
#define TRAMSFORM_RATE 0.7


#endif /* CHeader_h */
