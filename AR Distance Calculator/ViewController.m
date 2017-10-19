//
//  ViewController.m
//  ARKit自定义实现
//
//  Created by kkmm on 2017/10/10.
//  Copyright © 2017年 Next Reality Viewer. All rights reserved.
//

#import "ViewController.h"
#import "ARViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.view.backgroundColor = [UIColor whiteColor];
	UIImageView *imageView = [[UIImageView alloc]initWithFrame:self.view.frame];
	imageView.image = [UIImage imageNamed:@"tron-albedo"];
	[self.view addSubview:imageView];
	
	UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-60, self.view.frame.size.height/2-60, 120, 120)];
	btn.backgroundColor = [UIColor lightGrayColor];
	btn.layer.cornerRadius = 60;
	[btn setTitle:@"开启AR" forState:UIControlStateNormal];
	[btn addTarget:self action:@selector(openAR) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btn];
	
}
-(void)openAR{
	ARViewController *VC = [[ARViewController alloc]init];
	[self presentViewController:VC animated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end

