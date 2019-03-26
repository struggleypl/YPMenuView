//
//  MSMenuView.h
//  MSDragTableView
//
//  Created by ypl on 2018/10/9.
//  Copyright © 2018年 ypl. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSMenuAction;
@interface MSMenuView : UIView

@property (nonatomic,assign) CGFloat cornerRaius;
@property (nonatomic,strong) UIColor *separatorColor;
@property (nonatomic,strong) UIColor *menuColor;
@property (nonatomic,assign) CGFloat menuCellHeight;
@property (nonatomic,assign) NSInteger maxDisplayCount;
@property (nonatomic,assign,getter = isShadowShowing)BOOL   isShowShadow;
@property (nonatomic,assign) BOOL dismissOnselected;
@property (nonatomic,assign) BOOL dismissOnTouchOutside;
@property (nonatomic,assign) UIFont *textFont;
@property (nonatomic,strong) UIColor *textColor;
@property (nonatomic,assign)  CGFloat offset;
@property (nonatomic,assign) BOOL isShow;

+ (instancetype)menuWithActions:(NSArray<MSMenuAction *> *)actions width:(CGFloat)width atPoint:(CGPoint)point;

// 从关联视图创建（可以是UIView和UIBarButtonItem）
+ (instancetype)menuWithActions:(NSArray<MSMenuAction *> *)actions width:(CGFloat)width relyonView:(id)view;
- (void)show;
- (void)dismiss;
@end

@interface MSMenuAction : NSObject
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic,copy, readonly) void (^handler)(MSMenuAction *action);
+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image handler:(void (^)(MSMenuAction *action))handler;
@end
