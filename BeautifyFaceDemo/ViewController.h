//
//  ViewController.h
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/27.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(atomic,assign) CVPixelBufferRef imagePixelBuffer;
@property (atomic, readonly) BOOL started;
@end

