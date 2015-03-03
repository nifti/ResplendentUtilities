//
//  RUSlideMenuNavigationController.m
//  Nifti
//
//  Created by Benjamin Maer on 12/1/14.
//  Copyright (c) 2014 Nifti. All rights reserved.
//

#import "RUSlideMenuNavigationController.h"
#import "RUProtocolOrNil.h"
#import "RUConditionalReturn.h"
#import "UIView+RUSnapshot.h"
#import "UIViewController+RUStatusBarHeight.h"





CGFloat const kRUSlideMenuNavigationController_MENU_FAST_VELOCITY_FOR_SWIPE_FOLLOW_DIRECTION = 1200.0f;
CGFloat const kRUSlideMenuNavigationController_MENU_QUICK_SLIDE_ANIMATION_DURATION = .18f;
CGFloat const kRUSlideMenuNavigationController_MENU_SLIDE_ANIMATION_DURATION = .3f;

typedef NS_ENUM(NSInteger, RUSlideMenuNavigationController_panGestureState) {
	RUSlideMenuNavigationController_panGestureState_None,
	RUSlideMenuNavigationController_panGestureState_View,
	RUSlideMenuNavigationController_panGestureState_ImageView,
};





@interface RUSlideMenuNavigationController ()

@property (nonatomic, readonly) UIView* animatableScreenShotBackgroundView;
@property (nonatomic, readonly) UIImageView* animatableScreenShotImageView;

@property (nonatomic, readonly) UIViewController* currentViewControllerForPossibleDisplayActions;
@property (nonatomic, readonly) UIViewController<RUSlideNavigationController_DisplayDelegate>* currentViewControllerForDisplayActions;
@property (nonatomic, readonly) UIView* currentViewControllerMenuView;
-(UIView *)currentViewControllerMenuViewForMenuType:(RUSlideNavigationController_MenuType)menuType;
-(UIView *)defaultMenuViewForMenuType:(RUSlideNavigationController_MenuType)menuType;

//@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
//@property (nonatomic, assign) CGPoint draggingPoint;

@property (nonatomic, readonly) CGFloat horizontalViewLocation;
@property (nonatomic, readonly) CGFloat horizontalPanLocation;
@property (nonatomic, readonly) CGFloat horizontalPanLocationWithVelocity;
@property (nonatomic, readonly) CGFloat viewOriginXOrHorizontalPanLocationOrHorizontalPanLocationWithVelocity;
-(RUSlideNavigationController_MenuType)menuTypeForHorizontalLocation:(CGFloat)horizontalLocation;
- (CGRect)initialRectForMenu:(RUSlideNavigationController_MenuType)menu;
@property (nonatomic, readonly) CGFloat horizontalSize;

@property (nonatomic, readonly) CGFloat minXForDragging;
@property (nonatomic, readonly) CGFloat maxXForDragging;
@property (nonatomic, readonly) CGFloat slideOffset;

- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer;
- (void)panDetected:(UIPanGestureRecognizer *)aPanRecognizer;

- (void)prepareMenuForReveal:(RUSlideNavigationController_MenuType)menu forcePrepare:(BOOL)forcePrepare;
- (BOOL)shouldDisplayMenu:(RUSlideNavigationController_MenuType)menu forViewController:(UIViewController *)vc;

- (void)updateMenuFrameAndTransformAccordingToOrientation;
- (void)updateMenuFrameAndTransformAccordingToOrientationWithMenu:(RUSlideNavigationController_MenuType)menu;

- (void)moveHorizontallyToLocation:(CGFloat)location animatedWithDuration:(NSTimeInterval)duration completion:(void(^)())completion;
- (void)updateTransformationForView:(UIView*)view atHorizontalLocation:(CGFloat)location;
- (void)updateMenuAnimation:(RUSlideNavigationController_MenuType)menu;
- (void)openMenu:(RUSlideNavigationController_MenuType)menu withDuration:(float)duration andCompletion:(void (^)())completion;
- (void)closeMenuWithDuration:(float)duration andCompletion:(void (^)())completion;
- (void)toggleMenu:(RUSlideNavigationController_MenuType)menu withCompletion:(void (^)())completion;

//- (void)enableTapGestureToCloseMenu:(BOOL)enable;

-(CGFloat)horizontalProgressForMenuType:(RUSlideNavigationController_MenuType)menuType;
-(CGFloat)horizontalProgressForMenuType:(RUSlideNavigationController_MenuType)menuType xLocation:(CGFloat)xLocation;

-(void)setPanRecognizerState:(RUSlideMenuNavigationController_panGestureState)panRecognizerState;

@end





@implementation RUSlideMenuNavigationController

#pragma mark - UIViewController
- (void)viewDidLoad
{
	[super viewDidLoad];

	[self setPanRecognizerState:RUSlideMenuNavigationController_panGestureState_View];
}

-(void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];

	[self updateMenuFrameAndTransformAccordingToOrientation];

	if (self.animatableScreenShotBackgroundView)
	{
		[self.animatableScreenShotBackgroundView.superview bringSubviewToFront:self.animatableScreenShotBackgroundView];
	}
}

#pragma mark - Update Content
- (void)updateMenuFrameAndTransformAccordingToOrientation
{
	[self updateMenuFrameAndTransformAccordingToOrientationWithMenu:[self menuTypeForHorizontalLocation:self.viewOriginXOrHorizontalPanLocationOrHorizontalPanLocationWithVelocity]];
}

- (void)updateMenuFrameAndTransformAccordingToOrientationWithMenu:(RUSlideNavigationController_MenuType)menu
{
	// Animate rotatation when menu is open and device rotates
	CGAffineTransform transform = self.view.transform;
	self.defaultLeftMenuView.transform = transform;
	self.defaultLeftMenuView.frame = [self initialRectForMenu:RUSlideNavigationController_MenuType_Left];

	self.defaultRightMenuView.transform = transform;
	self.defaultRightMenuView.frame = [self initialRectForMenu:RUSlideNavigationController_MenuType_Right];

	if (self.currentViewControllerMenuView)
	{
		self.currentViewControllerMenuView.transform = transform;
		self.currentViewControllerMenuView.frame = [self initialRectForMenu:menu];
	}
}

- (void)moveHorizontallyToLocation:(CGFloat)location animatedWithDuration:(NSTimeInterval)duration completion:(void(^)())completion
{
	CGRect rect = self.view.frame;
	UIInterfaceOrientation orientation = self.interfaceOrientation;
	RUSlideNavigationController_MenuType menu = [self menuTypeForHorizontalLocation:location];
	
	if (UIInterfaceOrientationIsLandscape(orientation))
	{
		rect.origin.x = 0;
		rect.origin.y = (orientation == UIInterfaceOrientationLandscapeRight) ? location : location*-1;
	}
	else
	{
		rect.origin.x = (orientation == UIInterfaceOrientationPortrait) ? location : location*-1;
		rect.origin.y = 0;
	}

	BOOL willHide = (CGRectGetMinX(rect) != 0);

	void (^animationBlock)() = ^(){
		
	};

	void (^animationCompletionBlock)() = ^(){
		if (completion)
		{
			completion();
		}
	};

	typeof(self.animatableScreenShotBackgroundView) animatableScreenShotBackgroundView_old = self.animatableScreenShotBackgroundView;
	typeof(self.animatableScreenShotImageView) animatableScreenShotImageView_old = self.animatableScreenShotImageView;

	if (willHide)
	{
		if (self.animatableScreenShotBackgroundView == nil)
		{
			_animatableScreenShotBackgroundView = [UIView new];
			[self.animatableScreenShotBackgroundView setBackgroundColor:[UIColor clearColor]];
			[self.animatableScreenShotBackgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)]];
			[self.view.window addSubview:self.animatableScreenShotBackgroundView];
		}

		if (self.animatableScreenShotImageView == nil)
		{
			NSAssert(self.animatableScreenShotBackgroundView != nil, @"unhandled");
			UIImage* snapshotImage = self.imageForCurrentSnapshot;
			_animatableScreenShotImageView = [[UIImageView alloc]initWithImage:snapshotImage];
			NSAssert(CGSizeEqualToSize(snapshotImage.size, self.view.bounds.size), @"unhandled");
			[self.animatableScreenShotImageView setUserInteractionEnabled:YES];
			[self.animatableScreenShotImageView setBackgroundColor:[UIColor redColor]];
			[self.animatableScreenShotImageView setContentMode:UIViewContentModeScaleAspectFill];
			[self.animatableScreenShotBackgroundView addSubview:self.animatableScreenShotImageView];
		}
	}
	else
	{
		if (self.animatableScreenShotBackgroundView)
		{
			__weak typeof(animatableScreenShotBackgroundView_old) weakAnimatableScreenShotBackgroundView_old = animatableScreenShotBackgroundView_old;
			animationCompletionBlock = ^{
				
				[weakAnimatableScreenShotBackgroundView_old removeFromSuperview];
				animationCompletionBlock();
				
			};
			
			_animatableScreenShotBackgroundView = nil;
		}

		if (self.animatableScreenShotImageView)
		{
			_animatableScreenShotImageView = nil;
		}
	}

	__weak typeof(self.animatableScreenShotBackgroundView) weakAnimatableScreenShotBackgroundView_forFrameSet = (willHide ? self.animatableScreenShotBackgroundView : animatableScreenShotBackgroundView_old);
	__weak typeof(self.animatableScreenShotImageView) weakAnimatableScreenShotImageView_forFrameSet = (willHide ? self.animatableScreenShotImageView : animatableScreenShotImageView_old);
	animationBlock = ^{
		[weakAnimatableScreenShotBackgroundView_forFrameSet setFrame:rect];
		[weakAnimatableScreenShotImageView_forFrameSet setFrame:(CGRect){
			.size	= rect.size,
		}];
		animationBlock();
	};

	__weak typeof(self) weakSelf = self;
	__weak typeof(animatableScreenShotImageView_old) weakAnimatableScreenShotImageView_forTransformation = (willHide ? self.animatableScreenShotImageView : animatableScreenShotImageView_old);
	if (weakAnimatableScreenShotImageView_forTransformation)
	{
		animationBlock = ^{
			[weakSelf updateTransformationForView:weakAnimatableScreenShotImageView_forTransformation atHorizontalLocation:location];
			//		[weakSelf updateCurrentViewControllerForSlideUseTransform];
			animationBlock();
		};
	}

	if (willHide)
	{
		if (self.tabBarController)
		{
			[self.tabBarController.tabBar setHidden:willHide];
		}
		
		[self.view setHidden:willHide];
	}
	else
	{
		__weak typeof(self) weakSelf = self;
		animationCompletionBlock = ^{

			if (weakSelf.tabBarController)
			{
				[weakSelf.tabBarController.tabBar setHidden:willHide];
			}
			
			[weakSelf.view setHidden:willHide];
			animationCompletionBlock();

		};
	}

	BOOL animate = (duration > 0);
	if (animate)
	{
		[UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		 
			animationBlock();
		 
		} completion:^(BOOL finished) {

			animationCompletionBlock();
			
		}];
	}
	else
	{
		animationBlock();
		animationCompletionBlock();
	}

//	[self setPanRecognizerState:(willHide ? RUSlideMenuNavigationController_panGestureState_None : RUSlideMenuNavigationController_panGestureState_View)];

//	if (self.tabBarController)
//	{
//		[self.tabBarController.tabBar setHidden:willHide];
//	}
//
//	[self.view setHidden:willHide];
//	self.view.frame = rect;

	[self updateMenuAnimation:menu];
}

- (void)updateMenuAnimation:(RUSlideNavigationController_MenuType)menu
{
	CGFloat progress = [self horizontalProgressForMenuType:menu];
	
	[self.menuAnimator animateMenu:menu withProgress:progress];
}

- (void)openMenu:(RUSlideNavigationController_MenuType)menu withDuration:(float)duration andCompletion:(void (^)())completion
{
//	[self enableTapGestureToCloseMenu:YES];
	
	[self prepareMenuForReveal:menu forcePrepare:NO];

	CGRect rect = self.view.frame;
	CGFloat width = self.horizontalSize;
	rect.origin.x = (menu == RUSlideNavigationController_MenuType_Left) ? (width - self.slideOffset) : ((width - self.slideOffset )* -1);
	[self moveHorizontallyToLocation:rect.origin.x animatedWithDuration:duration completion:completion];

//	[UIView animateWithDuration:duration
//						  delay:0
//						options:UIViewAnimationOptionCurveEaseOut
//					 animations:^{
//						 CGRect rect = self.view.frame;
//						 CGFloat width = self.horizontalSize;
//						 rect.origin.x = (menu == RUSlideNavigationController_MenuType_Left) ? (width - self.slideOffset) : ((width - self.slideOffset )* -1);
//						 [self moveHorizontallyToLocation:rect.origin.x];
//					 }
//					 completion:^(BOOL finished) {
//						 if (completion)
//							 completion();
//					 }];
}

- (void)openMenu:(RUSlideNavigationController_MenuType)menu withCompletion:(void (^)())completion
{
	[self openMenu:menu withDuration:kRUSlideMenuNavigationController_MENU_SLIDE_ANIMATION_DURATION andCompletion:completion];
}

- (void)closeMenuWithCompletion:(void (^)())completion
{
	[self closeMenuWithDuration:kRUSlideMenuNavigationController_MENU_SLIDE_ANIMATION_DURATION andCompletion:completion];
}

- (void)closeMenuWithDuration:(float)duration andCompletion:(void (^)())completion
{
	[self moveHorizontallyToLocation:0 animatedWithDuration:duration completion:^{

		[self.currentViewControllerMenuView removeFromSuperview];
		
		if (completion)
		{
			completion();
		}

	}];
//
//	[UIView animateWithDuration:duration
//						  delay:0
//						options:UIViewAnimationOptionCurveEaseOut
//					 animations:^{
//
//						 [self moveHorizontallyToLocation:0];
//
//					 }
//					 completion:^(BOOL finished) {
//
//						 [self.currentViewControllerMenuView removeFromSuperview];
//
//						 if (completion)
//							 completion();
//					 }];
}

#pragma mark - Menu
- (void)bounceMenu:(RUSlideNavigationController_MenuType)menu withCompletion:(void (^)())completion
{
	[self prepareMenuForReveal:menu forcePrepare:YES];
	double movementDirection = (menu == RUSlideNavigationController_MenuType_Left) ? 1 : -1;

	[self moveHorizontallyToLocation:30.0f * movementDirection animatedWithDuration:0.16f completion:^{
		[self moveHorizontallyToLocation:0 animatedWithDuration:0.1f completion:^{
			[self moveHorizontallyToLocation:16.0f * movementDirection animatedWithDuration:0.12f completion:^{
				[self moveHorizontallyToLocation:0 animatedWithDuration:0.08f completion:^{
					[self moveHorizontallyToLocation:6.0f * movementDirection animatedWithDuration:0.08f completion:^{
						[self moveHorizontallyToLocation:0 animatedWithDuration:0.06f completion:completion];
					}];
				}];
			}];
		}];
	}];

//	[UIView animateWithDuration:.16 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//		[self moveHorizontallyToLocation:30*movementDirection];
//	} completion:^(BOOL finished){
//		[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//			[self moveHorizontallyToLocation:0];
//		} completion:^(BOOL finished){
//			[UIView animateWithDuration:.12 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//				[self moveHorizontallyToLocation:16*movementDirection];
//			} completion:^(BOOL finished){
//				[UIView animateWithDuration:.08 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//					[self moveHorizontallyToLocation:0];
//				} completion:^(BOOL finished){
//					[UIView animateWithDuration:.08 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//						[self moveHorizontallyToLocation:6*movementDirection];
//					} completion:^(BOOL finished){
//						[UIView animateWithDuration:.06 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//							[self moveHorizontallyToLocation:0];
//						} completion:^(BOOL finished){
//							if (completion)
//								completion();
//						}];
//					}];
//				}];
//			}];
//		}];
//	}];
}

- (BOOL)isMenuOpen
{
	return (self.horizontalViewLocation == 0) ? NO : YES;
}

- (void)prepareMenuForReveal:(RUSlideNavigationController_MenuType)menu forcePrepare:(BOOL)forcePrepare
{
	UIViewController<RUSlideNavigationController_DisplayDelegate>* currentViewControllerForDisplayActions = self.currentViewControllerForDisplayActions;

	if ([self shouldDisplayMenu:menu forViewController:currentViewControllerForDisplayActions] == false)
	{
		return;
	}

	UIView *removingMenuView = [self currentViewControllerMenuViewForMenuType:RUSlideNavigationController_MenuType_Opposite(menu)];

	_currentViewControllerMenuView = ((currentViewControllerForDisplayActions &&
									   [currentViewControllerForDisplayActions respondsToSelector:@selector(ru_slideNavigationController_viewForMenuType:)]) ?
									  [currentViewControllerForDisplayActions ru_slideNavigationController_viewForMenuType:menu] :
									  nil);
	
	UIView *menuView = [self currentViewControllerMenuViewForMenuType:menu];

	if (menuView.superview == nil)
	{
		if ([currentViewControllerForDisplayActions respondsToSelector:@selector(ru_slideNavigationController_willDisplayMenuType:)])
		{
			[currentViewControllerForDisplayActions ru_slideNavigationController_willDisplayMenuType:menu];
		}
	}

	[self.view.superview insertSubview:menuView belowSubview:self.view];

	if (menuView == removingMenuView)
	{
		[self updateMenuFrameAndTransformAccordingToOrientationWithMenu:menu];
		return;
	}

	// If menu is already open don't prepare, unless forcePrepare is set to true
	if ([self isMenuOpen] && !forcePrepare)
		return;
	
	[removingMenuView removeFromSuperview];

	[self updateMenuFrameAndTransformAccordingToOrientationWithMenu:menu];
	
	[self.menuAnimator prepareMenuForAnimation:menu];
}

- (BOOL)shouldDisplayMenu:(RUSlideNavigationController_MenuType)menu forViewController:(UIViewController *)vc
{
	BOOL vc_conformsTo_RUSlideNavigationController_DisplayDelegate = [vc conformsToProtocol:@protocol(RUSlideNavigationController_DisplayDelegate)];
	if (vc_conformsTo_RUSlideNavigationController_DisplayDelegate)
	{
		if ([vc respondsToSelector:@selector(ru_slideNavigationController_shouldDisplayMenuType:)])
		{
			if ([(id<RUSlideNavigationController_DisplayDelegate>)vc ru_slideNavigationController_shouldDisplayMenuType:menu] == NO)
			{
				return NO;
			}
		}
	}

	return ((vc_conformsTo_RUSlideNavigationController_DisplayDelegate &&
			 [vc respondsToSelector:@selector(ru_slideNavigationController_viewForMenuType:)]) ?
			[(id<RUSlideNavigationController_DisplayDelegate>)vc ru_slideNavigationController_viewForMenuType:menu] :
			(menu == RUSlideNavigationController_MenuType_Left ? self.defaultLeftMenuView : self.defaultRightMenuView)) != nil;
}

- (void)toggleLeftMenu
{
	[self toggleMenu:RUSlideNavigationController_MenuType_Left withCompletion:nil];
}

- (void)toggleRightMenu
{
	[self toggleMenu:RUSlideNavigationController_MenuType_Right withCompletion:nil];
}

- (void)toggleMenu:(RUSlideNavigationController_MenuType)menu withCompletion:(void (^)())completion
{
	if ([self isMenuOpen])
		[self closeMenuWithCompletion:completion];
	else
		[self openMenu:menu withCompletion:completion];
}

#pragma mark - horizontalLocation
- (CGFloat)horizontalViewLocation
{
	CGRect rect = self.view.frame;
	UIInterfaceOrientation orientation = self.interfaceOrientation;

	
	
	if (UIInterfaceOrientationIsLandscape(orientation))
	{
		return (orientation == UIInterfaceOrientationLandscapeRight)
		? rect.origin.y
		: rect.origin.y*-1;
	}
	else
	{
		return (orientation == UIInterfaceOrientationPortrait)
		? rect.origin.x
		: rect.origin.x*-1;
	}
}

-(CGFloat)horizontalPanLocation
{
	CGPoint translation = [self.panRecognizer translationInView:self.panRecognizer.view];
	return translation.x;
}

-(CGFloat)horizontalPanLocationWithVelocity
{
	CGPoint velocity = [self.panRecognizer velocityInView:self.panRecognizer.view];

	return self.horizontalPanLocation + velocity.x;
}

-(CGFloat)viewOriginXOrHorizontalPanLocationOrHorizontalPanLocationWithVelocity
{
	CGFloat viewOriginX = CGRectGetMinX(self.view.frame);
	if (viewOriginX != 0)
	{
		return viewOriginX;
	}
	
	CGFloat horizontalPanLocation = self.horizontalPanLocation;
	if (horizontalPanLocation != 0)
	{
		return horizontalPanLocation;
	}

	return self.horizontalPanLocationWithVelocity;
}

#pragma mark - Frames
-(RUSlideNavigationController_MenuType)menuTypeForHorizontalLocation:(CGFloat)horizontalLocation
{
	return ((horizontalLocation >= 0) ?
			RUSlideNavigationController_MenuType_Left :
			RUSlideNavigationController_MenuType_Right);
}

- (CGRect)initialRectForMenu:(RUSlideNavigationController_MenuType)menu
{
	CGRect rect = self.view.frame;
	CGFloat slideOffset = self.slideOffset;
	rect.origin.x = 0;
	rect.origin.y = 0;
	
//	BOOL isIos7 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
//	CGFloat statusBarHeight = kPASlideNavigationControllerSTATUS_BAR_HEIGHT;
	CGFloat yOffset = 0;
	if (self.fitMenuViewsUnderStatusBar)
	{
		CGFloat statusBarHeight = [self ru_statusBarHeightInView];
		yOffset += statusBarHeight;
	}
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		rect.origin.x = (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) ? 0 : yOffset;
		rect.size.width = self.view.frame.size.width-yOffset;
//		if (!isIos7)
//		{
//			// For some reasons in landscape belos the status bar is considered y=0, but in portrait it's considered y=20
//			rect.origin.x = (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) ? 0 : statusBarHeight;
//			rect.size.width = self.view.frame.size.width-statusBarHeight;
//		}
	}
	else
	{
		rect.origin.y = (self.interfaceOrientation == UIInterfaceOrientationPortrait) ? yOffset : 0;
		rect.size.height = self.view.frame.size.height-yOffset;
//		if (!isIos7)
//		{
//			// For some reasons in landscape belos the status bar is considered y=0, but in portrait it's considered y=20
//			rect.origin.y = (self.interfaceOrientation == UIInterfaceOrientationPortrait) ? statusBarHeight : 0;
//			rect.size.height = self.view.frame.size.height-statusBarHeight;
//		}
	}
	
//	rect.size.width -= slideOffset;

	if (menu == RUSlideNavigationController_MenuType_Right)
	{
		rect.origin.x += slideOffset;
	}
	
	return UIEdgeInsetsInsetRect(rect, self.menuViewFrameInsets);
}

- (CGFloat)horizontalSize
{
	CGRect rect = self.view.frame;
	UIInterfaceOrientation orientation = self.interfaceOrientation;
	
	if (UIInterfaceOrientationIsLandscape(orientation))
	{
		return rect.size.height;
	}
	else
	{
		return rect.size.width;
	}
}

- (CGFloat)minXForDragging
{
	if ([self shouldDisplayMenu:RUSlideNavigationController_MenuType_Right forViewController:self.currentViewControllerForDisplayActions])
	{
		return (self.horizontalSize - self.slideOffset)  * -1;
	}
	
	return 0;
}

- (CGFloat)maxXForDragging
{
	if ([self shouldDisplayMenu:RUSlideNavigationController_MenuType_Left forViewController:self.currentViewControllerForDisplayActions])
	{
		return self.horizontalSize - self.slideOffset;
	}
	
	return 0;
}

- (CGFloat)slideOffset
{
	return (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	? self.landscapeSlideOffset
	: self.portraitSlideOffset;
}

#pragma mark - Getters
//- (UITapGestureRecognizer *)tapRecognizer
//{
//	if (_tapRecognizer == nil)
//	{
//		_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
//	}
//	
//	return _tapRecognizer;
//}

- (UIPanGestureRecognizer *)panRecognizer
{
	if (_panRecognizer == nil)
	{
		_panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
	}
	
	return _panRecognizer;
}

#pragma mark - Setters
-(void)setPanRecognizerState:(RUSlideMenuNavigationController_panGestureState)panRecognizerState
{
	UIView* view = [self viewForPanRecognizerState:panRecognizerState];
	kRUConditionalReturn(self.panRecognizer.view == view, NO);

	UIPanGestureRecognizer* panRecognizer = self.panRecognizer;
	[panRecognizer.view removeGestureRecognizer:panRecognizer];

	if (view)
	{
		[view addGestureRecognizer:panRecognizer];
	}
}

-(UIView*)viewForPanRecognizerState:(RUSlideMenuNavigationController_panGestureState)panRecognizerState
{
	switch (panRecognizerState)
	{
		case RUSlideMenuNavigationController_panGestureState_ImageView:
			return self.animatableScreenShotImageView;

		case RUSlideMenuNavigationController_panGestureState_View:
			return self.view;

		case RUSlideMenuNavigationController_panGestureState_None:
			return nil;
	}

	NSAssert(false, @"unhandled");
	return nil;
}

#pragma mark - Setters
-(BOOL)enablePanGesture
{
	return self.panRecognizer.enabled;
}

- (void)setEnablePanGesture:(BOOL)enablePanGesture
{
	kRUConditionalReturn(self.enablePanGesture == enablePanGesture, NO);

	[self.panRecognizer setEnabled:self.enablePanGesture];
}

#pragma mark - Actions
- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer
{
	[self closeMenuWithCompletion:nil];
}

- (void)panDetected:(UIPanGestureRecognizer *)aPanRecognizer
{
	CGFloat viewOriginXOrHorizontalPanLocationOrHorizontalPanLocationWithVelocity = self.viewOriginXOrHorizontalPanLocationOrHorizontalPanLocationWithVelocity;
	RUSlideNavigationController_MenuType menuFromHorizontalPanLocationWithVelocity = [self menuTypeForHorizontalLocation:viewOriginXOrHorizontalPanLocationOrHorizontalPanLocationWithVelocity];
	
	if (aPanRecognizer.state == UIGestureRecognizerStateBegan)
	{
		if (![self isMenuOpen])
			[self prepareMenuForReveal:menuFromHorizontalPanLocationWithVelocity forcePrepare:YES];
	}
	else if (aPanRecognizer.state == UIGestureRecognizerStateChanged)
	{
		// Force prepare menu when slides quickly between left and right menu
		[self prepareMenuForReveal:menuFromHorizontalPanLocationWithVelocity forcePrepare:YES];

		CGFloat horizontalPanLocation = self.horizontalPanLocation;

		if (horizontalPanLocation >= self.minXForDragging && horizontalPanLocation <= self.maxXForDragging)
		{
			[self moveHorizontallyToLocation:horizontalPanLocation animatedWithDuration:0 completion:nil];
		}
	}
	else if (aPanRecognizer.state == UIGestureRecognizerStateEnded)
	{
		CGFloat horizontalPanLocationWithVelocity = self.horizontalPanLocationWithVelocity;
		CGPoint velocity = [aPanRecognizer velocityInView:aPanRecognizer.view];

		// If the speed is high enough follow direction
		if (fabs(velocity.x) >= kRUSlideMenuNavigationController_MENU_FAST_VELOCITY_FOR_SWIPE_FOLLOW_DIRECTION)
		{
			BOOL shouldClose = ((velocity.x > 0) ?
								(horizontalPanLocationWithVelocity < 0) :
								(horizontalPanLocationWithVelocity > 0));
			if (shouldClose)
			{
				[self closeMenuWithDuration:kRUSlideMenuNavigationController_MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
			}
			else
			{
				if ([self shouldDisplayMenu:menuFromHorizontalPanLocationWithVelocity forViewController:self.currentViewControllerForPossibleDisplayActions])
				{
					[self openMenu:menuFromHorizontalPanLocationWithVelocity withCompletion:nil];
				}
			}
		}
		else
		{
			if (horizontalPanLocationWithVelocity < (self.horizontalSize - self.slideOffset)/2)
			{
				[self closeMenuWithCompletion:nil];
			}
			else
			{
				[self openMenu:menuFromHorizontalPanLocationWithVelocity withCompletion:nil];
			}
		}
	}
}

//#pragma mark - Enabling
//- (void)enableTapGestureToCloseMenu:(BOOL)enable
//{
//	if (enable)
//	{
//		self.topViewController.view.userInteractionEnabled = NO;
//		[self.view addGestureRecognizer:self.tapRecognizer];
//	}
//	else
//	{
//		self.topViewController.view.userInteractionEnabled = YES;
//		[self.view removeGestureRecognizer:self.tapRecognizer];
//	}
//}

#pragma mark - currentViewControllerForDisplayActions
-(UIViewController*)currentViewControllerForPossibleDisplayActions
{
	return self.topViewController;
}

-(UIViewController<RUSlideNavigationController_DisplayDelegate> *)currentViewControllerForDisplayActions
{
	UIViewController<RUSlideNavigationController_DisplayDelegate>* currentViewControllerForDisplayActions = (UIViewController<RUSlideNavigationController_DisplayDelegate>*)kRUProtocolOrNil(self.currentViewControllerForPossibleDisplayActions, RUSlideNavigationController_DisplayDelegate);
	return currentViewControllerForDisplayActions;
}

#pragma mark - currentViewControllerMenuView
-(UIView *)currentViewControllerMenuViewForMenuType:(RUSlideNavigationController_MenuType)menuType
{
	if (self.currentViewControllerMenuView)
	{
		return self.currentViewControllerMenuView;
	}

	return [self defaultMenuViewForMenuType:menuType];
}

#pragma mark - defaultMenuView
-(UIView *)defaultMenuViewForMenuType:(RUSlideNavigationController_MenuType)menuType
{
	switch (menuType)
	{
		case RUSlideNavigationController_MenuType_Left:
			return self.defaultLeftMenuView;
			
		case RUSlideNavigationController_MenuType_Right:
			return self.defaultRightMenuView;
	}
	
	NSAssert(false, @"unhandled");
	return nil;
}

#pragma mark - menuViewFrameInsets
-(void)setMenuViewFrameInsets:(UIEdgeInsets)menuViewFrameInsets
{
	kRUConditionalReturn(UIEdgeInsetsEqualToEdgeInsets(self.menuViewFrameInsets, menuViewFrameInsets), NO);

	_menuViewFrameInsets = menuViewFrameInsets;

	[self.view setNeedsLayout];
}

#pragma mark - Progress
-(CGFloat)horizontalProgressForMenuType:(RUSlideNavigationController_MenuType)menuType
{
	CGFloat horizontalPanLocation = self.horizontalPanLocation;
	return [self horizontalProgressForMenuType:menuType xLocation:horizontalPanLocation];
}

-(CGFloat)horizontalProgressForMenuType:(RUSlideNavigationController_MenuType)menuType xLocation:(CGFloat)xLocation
{
	CGFloat horizontalSize = self.horizontalSize;
	CGFloat slideOffset = self.slideOffset;

	return ((menuType == RUSlideNavigationController_MenuType_Left) ?
			(xLocation / (horizontalSize - slideOffset)) :
			(xLocation / ((horizontalSize - slideOffset) * -1)));
}

#pragma mark - Transformation
- (void)updateTransformationForView:(UIView*)view atHorizontalLocation:(CGFloat)location
{
	kRUConditionalReturn(view == nil, YES);
	RUSlideNavigationController_MenuType menuTypeForHorizontalLocation = [self menuTypeForHorizontalLocation:location];
	CGFloat horizontalProgress = [self horizontalProgressForMenuType:menuTypeForHorizontalLocation xLocation:location];
	RUDLog(@"horizontalProgress: %f",horizontalProgress);

	UIViewController* currentViewControllerForPossibleDisplayActions = self.currentViewControllerForPossibleDisplayActions;
	kRUConditionalReturn(currentViewControllerForPossibleDisplayActions == nil, YES);

	CGFloat const progressToXTranslateDistanceRatio = -981.0f;
	CGFloat xTranslateDistance = pow(horizontalProgress, 2.0f) * progressToXTranslateDistanceRatio;
	RUDLog(@"xTranslateDistance: %f",xTranslateDistance);
	
	CGFloat angle = -horizontalProgress * M_PI_4;
	
	CATransform3D transform = CATransform3DIdentity;
	transform.m34 = 1.0 / - 1800;
	transform = CATransform3DTranslate(transform, xTranslateDistance, 0, 0);
	transform = CATransform3DRotate(transform, angle, 0, 1.0f, 0);

	CGFloat const progressToZTranslateDistanceRatio = -1200.0f;
	CGFloat zTranslateDistance = horizontalProgress * progressToZTranslateDistanceRatio;
	RUDLog(@"zTranslateDistance: %f",zTranslateDistance);
	transform = CATransform3DTranslate(transform, 0, 0, zTranslateDistance);

	[view.layer setZPosition:ceil(CGFLOAT_MAX / 2.0f)];
	[view.layer setTransform:transform];
}

#pragma mark - imageForCurrentSnapshot
-(UIImage*)imageForCurrentSnapshot
{
	UIImage* imageForCurrentSnapshot = [self.view ruGetSnapshotFromWindow];

	return imageForCurrentSnapshot;
}

@end
