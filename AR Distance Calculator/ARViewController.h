//
//  ARViewController.h
//  Next Reality Viewer
//
//  Created by kkmm on 2017/10/10.
//  Copyright © 2017年 Next Reality Viewer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
typedef NS_ENUM(NSUInteger, ARType) {
	ARTypeNormal = 1, //点击添加虚拟物体
	ARTypePlane, //自动捕捉平地添加虚拟物体
	ARTypeMove, //虚拟物体跟随相机移动
	ARTypeRotation, //虚拟物体围绕相机旋转
};


@interface ARViewController : UIViewController
@property(nonatomic,assign)ARType arType;
@end
