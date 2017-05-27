# CShortVideo
A short video recording of the project, imitate WeChat small video.


Simple to use, you need to _#import “CRecordViewController.h”_ _first，and next：


```
CRecordViewController * vc = [CRecordViewController recordWithDuration:10
                                                                     TargetSize:nil
                                                                  InerViewColor:nil
                                                               ProgressBarWidth:5
                                                              ProgressBackColor:[UIColor colorWithWhite:1.0 alpha:0.6]
                                                                  ProgressColor:nil
                                                                  LandscapeMode:NO];
        vc.finishBlock = ^(NSString * filePath){
            NSLog(@"upload!, path is ： %@",filePath);
        };
        [self presentViewController:vc animated:YES completion:nil];
```
Or you can use the default style, just like this：


```
CRecordViewController * vc = [[CRecordViewController alloc]init];
        [self presentViewController:vc animated:YES completion:nil];
```

Maybe you have any questions, you need to ask me or find bug. You can send me a brief letter from Jane. Thank you very much.
Jane address : http://www.jianshu.com/u/bd29a2cb4b4d
