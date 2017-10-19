//
//  ViewController.m
//  Next Reality Viewer
//
//  Created by kkmm on 2017/10/10.
//  Copyright © 2017年 Next Reality Viewer. All rights reserved.
//

#import "ARViewController.h"

@interface ARViewController () <ARSCNViewDelegate,ARSessionDelegate,SCNSceneRendererDelegate>{
	UIView *redPointView;
	CGFloat screenCenterX;
	CGFloat screenCenterZ;
	UIView *redPoint;
	matrix_float4x4 _transform;
	NSInteger cubeNumber;
	
	UILabel *distanceLab;
	UILabel *totalDistanceLab;
	
	UITapGestureRecognizer *tapGesture;
	
	NSTimer *timer;

}

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) ARWorldTrackingConfiguration *arConfiguration;
@property (nonatomic, strong) UILabel *remindView;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) ARHitTestResult *hitResult;
@property (nonatomic, strong) SCNNode *zeroNode;
@property (nonatomic, assign) BOOL *zeroNodeGeted;

@property (nonatomic, strong) SCNNode *calculateNode;
@property (nonatomic, strong) SCNScene *scene;

@property (nonatomic) ARTrackingState currentTrackingState;

@property (nonatomic, strong) NSString *currentMessage;
@property (nonatomic, strong) NSString *nextMessage;


@end


@implementation ARViewController

- (void)queueMessage: (NSString *)message {
	// If we are currently showing a message, queue the next message. We will show
	// it once the previous message has disappeared. If multiple messages come in
	// we only care about showing the last one
	if (self.currentMessage) {
		self.nextMessage = message;
		return;
	}
	
	self.nextMessage = message;
	[self showNextMessage];
}

- (void)showNextMessage {
	self.currentMessage = self.nextMessage;
	self.nextMessage = nil;
	
	if (!_remindView) {
		_remindView = [[UILabel alloc]initWithFrame:CGRectMake(10, 20, self.view.frame.size.width-20, 50)];
		_remindView.backgroundColor = [UIColor clearColor];
		_remindView.textAlignment = NSTextAlignmentCenter;
		//	_remindView.alpha = 0;
		//	_remindView.text = @"加载中。。。";
		[self.view addSubview:_remindView];
		[self.view bringSubviewToFront:_remindView];
		_remindView.alpha = 0.3;
	}

	if (self.currentMessage == nil) {
		[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
			_remindView.alpha = 0;
		} completion:^(BOOL finished) {
		}];
		return;
	}
	
	_remindView.text = self.currentMessage;
	
	[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
		_remindView.alpha = 1.0;
	} completion:^(BOOL finished) {
		// Wait 5 seconds
		timer = [NSTimer scheduledTimerWithTimeInterval:4 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self showNextMessage];
		}];
	}];

}


- (void)viewDidLoad {
	[super viewDidLoad];
	cubeNumber = 0;
	self.sceneView = [[ARSCNView alloc]initWithFrame:self.view.bounds];
	[self.view addSubview:self.sceneView];
	// Set the view's delegate
	self.sceneView.delegate = self;
	self.sceneView.session.delegate = self;
	self.sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;//debug模式，显示追踪到的点位
//	self.sceneView.showsStatistics = YES;
//	self.sceneView.allowsCameraControl = YES;
//	Show statistics such as fps and timing information
	self.sceneView.showsStatistics = YES;
	SCNNode *lightNode = [SCNNode node];
	lightNode.light = [SCNLight light];
	lightNode.light.type = SCNLightTypeOmni;
	lightNode.position = SCNVector3Make(0, 10, 10);
	[self.sceneView.scene.rootNode addChildNode:lightNode];
	self.sceneView.rendersContinuously = YES;

	UIButton *backbutton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-40, self.view.frame.size.height-100, 80, 40)];
	backbutton.backgroundColor = [UIColor lightGrayColor];
	backbutton.alpha = 0.5;
	[backbutton setTitle:@"返回" forState:UIControlStateNormal];
	[backbutton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:backbutton];
	[self.view bringSubviewToFront:backbutton];
	// Create a new scene

	
	UIView *greenX = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-10, self.view.frame.size.height/2-1, 20, 2)];
	greenX.layer.cornerRadius = 1;
	greenX.backgroundColor = [UIColor greenColor];
	[self.view addSubview:greenX];
	[self.view bringSubviewToFront:greenX];
	
	UIView *greenY = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-1, self.view.frame.size.height/2-10, 2, 20)];
	greenY.layer.cornerRadius = 1;
	greenY.backgroundColor = [UIColor greenColor];
	[self.view addSubview:greenY];
	[self.view bringSubviewToFront:greenY];
	
	redPoint = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-2, self.view.frame.size.height/2-2, 4, 4)];
	redPoint.layer.cornerRadius = 2;
	redPoint.backgroundColor = [UIColor redColor];
	[self.view addSubview:redPoint];
	[self.view bringSubviewToFront:redPoint];

	distanceLab = [[UILabel alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-100, 90, 200, 40)];
	[self.view addSubview:distanceLab];
	[self.view bringSubviewToFront:distanceLab];
	distanceLab.backgroundColor = [UIColor colorWithRed:96 green:96 blue:96 alpha:0.4];
	distanceLab.textAlignment = NSTextAlignmentCenter;
//	distanceLab.alpha = 0.3;
	
	tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	NSMutableArray *gestureRecognizers = [NSMutableArray array];
	[gestureRecognizers addObject:tapGesture];
	[gestureRecognizers addObjectsFromArray:self.sceneView.gestureRecognizers];
	self.sceneView.gestureRecognizers = gestureRecognizers;

}



- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	//	 创建世界追踪配置会话配置，需要A9芯片支持
//	[self showRemind:@"正在加载"];
	_arConfiguration = [ARWorldTrackingConfiguration new];
	//	设置追踪方向（
	_arConfiguration.planeDetection = ARPlaneDetectionHorizontal;
	_arConfiguration.lightEstimationEnabled = YES;
	// Run the view's session
	[self.sceneView.session runWithConfiguration:_arConfiguration];
	
//	[self hiddenRemind:@"加载完成"];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	// Pause the view's session
	[self.sceneView.session pause];
}

-(void)back{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMessage:(NSString *)message {
	[self queueMessage:message];
}

#pragma mark - handleTap
- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
	CGPoint tapPoint = CGPointMake(redPoint.center.x, redPoint.center.y);
	NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlane];
	
	if (result.count == 0) {
		return;
	}
	// If there are multiple hits, just pick the closest plane
	ARHitTestResult * hitResult = [result firstObject];
	
	SCNTube *calculareTube = [SCNTube tubeWithInnerRadius:0 outerRadius:0.01 height:1];
	calculareTube.firstMaterial.diffuse.contents = [UIColor colorWithRed:0 green:255 blue:0 alpha:0.6];
	_calculateNode = [SCNNode nodeWithGeometry:calculareTube ];
	//	设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
	_calculateNode.position =  SCNVector3Make(
											  hitResult.worldTransform.columns[3].x,
											  hitResult.worldTransform.columns[3].y+0.5,
											  hitResult.worldTransform.columns[3].z
											  );
	[self.sceneView.scene.rootNode addChildNode:_calculateNode];
	if (cubeNumber > 0) {
		SCNNode *previousNode;
		previousNode = self.sceneView.scene.rootNode.childNodes[self.sceneView.scene.rootNode.childNodes.count-2];
		previousNode.geometry.firstMaterial.diffuse.contents = [UIColor greenColor];
		if (cubeNumber>1) {
			SCNNode *currentNode;
			currentNode = self.sceneView.scene.rootNode.childNodes[self.sceneView.scene.rootNode.childNodes.count-3];
			currentNode.geometry.firstMaterial.diffuse.contents = [UIColor redColor];
			if (cubeNumber>2) {
				SCNNode *oldNode;
				oldNode = self.sceneView.scene.rootNode.childNodes[self.sceneView.scene.rootNode.childNodes.count-4];
				oldNode.geometry.firstMaterial.diffuse.contents = [UIColor whiteColor];
			}
			[self calculateDistance];
		}
	}
	
	
	cubeNumber += 1;
}

-(void)calculateDistance{
	CGFloat distance;
	SCNNode *previousNode;
	previousNode = self.sceneView.scene.rootNode.childNodes[self.sceneView.scene.rootNode.childNodes.count-3];
	SCNNode *currentNode;
	currentNode = self.sceneView.scene.rootNode.childNodes[self.sceneView.scene.rootNode.childNodes.count-2];

	distance = sqrt((previousNode.position.x-currentNode.position.x)*(previousNode.position.x-currentNode.position.x)+(previousNode.position.z-currentNode.position.z)*(previousNode.position.z-currentNode.position.z));
	distanceLab.text = [NSString stringWithFormat:@"上两点距离：%f 米",distance];
}



#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame
{
	if (cubeNumber == 0) {
		return;
	}
	CGPoint tapPoint = CGPointMake(redPoint.center.x, redPoint.center.y);
	NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlane];

	if (result.count == 0) {
		return;
	}
	// If there are multiple hits, just pick the closest plane
	ARHitTestResult * hitResult = [result firstObject];
	SCNNode *currentNode;
	currentNode = [self.sceneView.scene.rootNode.childNodes lastObject];

	//	设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
	currentNode.position =  SCNVector3Make(
											  hitResult.worldTransform.columns[3].x,
											  hitResult.worldTransform.columns[3].y+0.5,
											  hitResult.worldTransform.columns[3].z
											  );
}
#pragma mark - ARSCNViewDelegate
//添加节点时候调用（当开启平地捕捉模式之后，如果捕捉到平地，ARKit会自动添加一个平地节点）
-(void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
	if ([anchor isMemberOfClass:[ARAnchor class]]) {
		NSLog(@"平地捕捉");
	}
//	添加一个3D平面模型，ARKit只有捕捉能力，锚点只是一个空间位置，要想更加清楚看到这个空间，我们需要给空间添加一个平地的3D模型来渲染他
	
	ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;

	SCNBox *plane = [SCNBox boxWithWidth:planeAnchor.extent.x height:0.001 length:planeAnchor.extent.z chamferRadius:0];
	SCNMaterial *transparentMaterial = [SCNMaterial new];
	transparentMaterial = [self materialNamed:@"tron"];
	plane.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial];
	SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
	planeNode.position =SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
	[node addChildNode:planeNode];

	SCNTube *tubey = [SCNTube tubeWithInnerRadius:0 outerRadius:0.001 height:5];
	tubey.firstMaterial.diffuse.contents = [UIColor blackColor];
	SCNNode *tubeNodey = [SCNNode nodeWithGeometry:tubey];
	tubeNodey.position = SCNVector3Make(0, 2.5, 0);
	[node addChildNode:tubeNodey];
	
	SCNTube *tubex = [SCNTube tubeWithInnerRadius:0 outerRadius:0.001 height:5];
	tubex.firstMaterial.diffuse.contents = [UIColor whiteColor];
	SCNNode *tubeNodex = [SCNNode nodeWithGeometry:tubex];
	tubeNodex.position =  SCNVector3Make(0, 0, 0);
	tubeNodex.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
	[node addChildNode:tubeNodex];
	
	SCNTube *tubez = [SCNTube tubeWithInnerRadius:0 outerRadius:0.001 height:5];
	tubez.firstMaterial.diffuse.contents = [UIColor grayColor];
	SCNNode *tubeNodez = [SCNNode nodeWithGeometry:tubez];
	tubeNodez.position =  SCNVector3Make(0, 0, 0);
	tubeNodez.rotation = SCNVector4Make(0, 0, 1, M_PI/2);
	[node addChildNode:tubeNodez];
	
	_zeroNode = [[SCNNode alloc]init];
	_zeroNode = node;
	self.arConfiguration.planeDetection = ARPlaneDetectionNone;
	
	[self.sceneView.session runWithConfiguration:self.arConfiguration];
	[self handleTap:tapGesture];
//	[self insertGeometry];
}
- (SCNMaterial *)materialNamed:(NSString *)name {
	NSMutableDictionary *materials = [NSMutableDictionary new];
	SCNMaterial *mat = materials[name];
	if (mat) {
		return mat;
	}
	
	mat = [SCNMaterial new];
	mat.lightingModelName = SCNLightingModelPhysicallyBased;
	mat.diffuse.contents = [UIImage imageNamed:@"tron-albedo"];
	mat.roughness.contents = [UIImage imageNamed:@"tron-albedo"];
	mat.metalness.contents = [UIImage imageNamed:@"tron-albedo"];
	mat.normal.contents = [UIImage imageNamed:@"tron-albedo"];
	mat.diffuse.wrapS = SCNWrapModeRepeat;
	mat.diffuse.wrapT = SCNWrapModeRepeat;
	mat.roughness.wrapS = SCNWrapModeRepeat;
	mat.roughness.wrapT = SCNWrapModeRepeat;
	mat.metalness.wrapS = SCNWrapModeRepeat;
	mat.metalness.wrapT = SCNWrapModeRepeat;
	mat.normal.wrapS = SCNWrapModeRepeat;
	mat.normal.wrapT = SCNWrapModeRepeat;
	
	materials[name] = mat;
	return mat;
}
//- (void)insertGeometry{
//
//	CGPoint tapPoint = CGPointMake(redPoint.center.x, redPoint.center.y);
//	NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlane];
//
//	if (result.count == 0) {
//		return;
//	}
////	// If there are multiple hits, just pick the closest plane
//	ARHitTestResult * hitResult = [result firstObject];
////
//	SCNTube *calculareTube = [SCNTube tubeWithInnerRadius:0 outerRadius:0.01 height:1];
//	calculareTube.firstMaterial.diffuse.contents = [UIColor greenColor];
//	_calculateNode = [SCNNode nodeWithGeometry:calculareTube ];
//	_calculateNode.position =  SCNVector3Make(
//											  hitResult.worldTransform.columns[3].x,
//											  hitResult.worldTransform.columns[3].y+0.5,
//											  hitResult.worldTransform.columns[3].z
//											  );
//	[self.sceneView.scene.rootNode addChildNode:_calculateNode];
////
//	SCNTube *tubex = [SCNTube tubeWithInnerRadius:0 outerRadius:0.001 height:5];
//	tubex.firstMaterial.diffuse.contents = [UIColor whiteColor];
//	SCNNode *tubeNodex = [SCNNode nodeWithGeometry:tubex];
//	tubeNodex.position = SCNVector3Make(
//										hitResult.worldTransform.columns[3].x,
//										hitResult.worldTransform.columns[3].y,
//										hitResult.worldTransform.columns[3].z
//										);;
//	tubeNodex.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
//	[self.sceneView.scene.rootNode addChildNode:tubeNodex];
//
//	SCNTube *tubez = [SCNTube tubeWithInnerRadius:0 outerRadius:0.001 height:5];
//	tubez.firstMaterial.diffuse.contents = [UIColor grayColor];
//	SCNNode *tubeNodez = [SCNNode nodeWithGeometry:tubez];
//	tubeNodez.position = SCNVector3Make(
//										hitResult.worldTransform.columns[3].x,
//										hitResult.worldTransform.columns[3].y,
//										hitResult.worldTransform.columns[3].z
//										);;
//	tubeNodez.rotation = SCNVector4Make(0, 0, 1, M_PI/2);
//	[self.sceneView.scene.rootNode addChildNode:tubeNodez];
	
	//	node1.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
//}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate
- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
	ARTrackingState trackingState = camera.trackingState;
	if (self.currentTrackingState == trackingState) {
		return;
	}
	self.currentTrackingState = trackingState;
	
	switch(trackingState) {
		case ARTrackingStateNotAvailable:
			[self showMessage:@"Camera tracking is not available on this device"];
			break;
			
		case ARTrackingStateLimited:
			switch(camera.trackingStateReason) {
				case ARTrackingStateReasonExcessiveMotion:
					[self showMessage:@"Limited tracking: slow down the movement of the device"];
					break;
					
				case ARTrackingStateReasonInsufficientFeatures:
					[self showMessage:@"Limited tracking: too few feature points, view areas with more textures"];
					break;
					
				case ARTrackingStateReasonNone:
					NSLog(@"Tracking limited none");
					break;
			}
			break;
			
		case ARTrackingStateNormal:
			[self showMessage:@"Tracking is back to normal"];
			break;
	}
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
	// Present an error message to the user
	[self showMessage:@"session error"];
}


- (void)sessionWasInterrupted:(ARSession *)session {
	// Inform the user that the session has been interrupted, for example, by presenting an overlay
	
}

- (void)sessionInterruptionEnded:(ARSession *)session {
	// Reset tracking and/or remove existing anchors if consistent tracking is required
	
}

@end

