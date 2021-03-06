//
//  MSMenuView.m
//  MSDragTableView
//
//  Created by ypl on 2018/10/9.
//  Copyright © 2018年 ypl. All rights reserved.
//

#import "MSMenuView.h"
#define kColorHexValue(rgbValue)               (kColorHexValueA(rgbValue,1))
#define kColorHexValueA(rgbValue,alphaValue)   [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alphaValue]
#define kScreenWidth               [UIScreen mainScreen].bounds.size.width
#define kScreenHeight              [UIScreen mainScreen].bounds.size.height
#define kMainWindow                [UIApplication sharedApplication].keyWindow

#define kArrowWidth          15
#define kArrowHeight         8
#define kDefaultMargin       10
#define kAnimationTime       0.15

@class MSMenuAction;
@interface UIView (MSFrame)
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGPoint origin;

@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGSize  size;
@end

@implementation UIView (MSFrame)
- (CGFloat)x
{
    return self.frame.origin.x;
}
- (void)setX:(CGFloat)value
{
    CGRect frame = self.frame;
    frame.origin.x = value;
    self.frame = frame;
}
- (CGFloat)y
{
    return self.frame.origin.y;
}
- (void)setY:(CGFloat)value
{
    CGRect frame = self.frame;
    frame.origin.y = value;
    self.frame = frame;
}
- (CGPoint)origin
{
    return self.frame.origin;
}
- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}
- (CGFloat)centerX
{
    return self.center.x;
}
- (void)setCenterX:(CGFloat)centerX
{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}
- (CGFloat)centerY
{
    return self.center.y;
}
- (void)setCenterY:(CGFloat)centerY
{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}
- (CGFloat)width
{
    return self.frame.size.width;
}
- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}
- (CGFloat)height
{
    return self.frame.size.height;
}
- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}
- (CGSize)size
{
    return self.frame.size;
}
- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}
@end

@interface MSMenuCell : UICollectionViewCell
@property (nonatomic,assign) BOOL         isShowSeparator;
@property (nonatomic,strong) UIColor     *separatorColor;
@property (nonatomic,strong) MSMenuAction *menuAction;
@end
@implementation MSMenuCell
- (instancetype)init {
    if (self = [super init]) {
        _isShowSeparator = YES;
        _separatorColor = [UIColor clearColor];
    }
    return self;
}

-(void)setMenuAction:(MSMenuAction *)menuAction {
    _menuAction = menuAction;
    if (menuAction) {
        self.backgroundColor = kColorHexValue(0x333333);
        UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(14, 5, 24, 24)];
        img.backgroundColor = [UIColor clearColor];
        img.centerY = CGRectGetMidY(self.bounds);
        img.image = menuAction.image;
        [self.contentView addSubview:img];
        
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(img.frame)+5, 5, 30, 30)];
        lab.font = [UIFont systemFontOfSize:14.0f];
        lab.textColor = [UIColor whiteColor];
        lab.text = menuAction.title;
        lab.centerY = CGRectGetMidY(self.bounds);
        [self.contentView addSubview:lab];
    }
}

- (void)setSeparatorColor:(UIColor *)separatorColor{
    _separatorColor = separatorColor;
    [self setNeedsDisplay];
}
- (void)setIsShowSeparator:(BOOL)isShowSeparator{
    _isShowSeparator = isShowSeparator;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect{
    if (!_isShowSeparator)return;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, rect.size.height - 0.5, rect.size.width, 0.5)];
    [_separatorColor setFill];
    [path fillWithBlendMode:kCGBlendModeNormal alpha:1.0f];
    [path closePath];
}
@end


@interface MSMenuAction()
@property (nonatomic) NSString      *title;
@property (nonatomic) UIImage       *image;
@property (copy, nonatomic)void (^handler)(MSMenuAction *);
@end
@implementation MSMenuAction
+ (instancetype)actionWithTitle:(NSString *)title image:(UIImage *)image handler:(void (^)(MSMenuAction *))handler{
    MSMenuAction *action = [[MSMenuAction alloc] initWithTitle:title image:image handler:handler];
    return action;
}
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image handler:(void (^)(MSMenuAction *))handler{
    if (self = [super init]) {
        _title = title;
        _image = image;
        _handler = [handler copy];
    }
    return self;
}
@end


@interface MSMenuView()<UICollectionViewDelegate,UICollectionViewDataSource>
{
    CGPoint          _refPoint;
    UIView          *_refView;
    CGFloat          _menuWidth;
    
    CGFloat         _arrowPosition; // 三角底部的起始点x
    CGFloat         _topMargin;
    BOOL            _isReverse; // 是否反向
    BOOL            _needReload; //是否需要刷新
}
@property(nonatomic,copy) NSArray<MSMenuAction *>   *actions;
@property(nonatomic,strong)UICollectionView         *collectionView;
@property(nonatomic,strong)UIView                   *contentView;
@property(nonatomic,strong)UIView                   *bgView;

@end

static NSString *const menuCellID = @"MSMenuCell";
@implementation MSMenuView

+ (instancetype)menuWithActions:(NSArray<MSMenuAction *> *)actions width:(CGFloat)width atPoint:(CGPoint)point{
    if (width>0.0f) {
        MSMenuView *menu = [[MSMenuView alloc] initWithActions:actions width:width atPoint:point];
        return menu;
    }
    return nil;
}
+ (instancetype)menuWithActions:(NSArray<MSMenuAction *> *)actions width:(CGFloat)width relyonView:(id)view{
    if (width>0.0f&&([view isKindOfClass:[UIView class]]||[view isKindOfClass:[UIBarButtonItem class]])) {
        MSMenuView *menu = [[MSMenuView alloc] initWithActions:actions width:width relyonView:view];
        return menu;
    }
    return nil;
}

- (instancetype)initWithActions:(NSArray<MSMenuAction *> *)actions width:(CGFloat)width atPoint:(CGPoint)point{
    if (self = [super init]) {
        _actions = [actions copy];
        _refPoint = point;
        _menuWidth = width;
        _isShow = NO;
        [self defaultConfiguration];
        [self setupSubView];
    }
    return self;
}

- (instancetype)initWithActions:(NSArray<MSMenuAction *> *)actions width:(CGFloat)width relyonView:(id)view{
    if (self = [super init]) {
        // 针对UIBarButtonItem做的处理
        if ([view isKindOfClass:[UIBarButtonItem class]]) {
            UIView *bgView = [view valueForKey:@"_view"];
            _refView = bgView;
        }else{
            _refView = view;
        }
        _actions = [actions copy];
        _menuWidth = width;
        [self defaultConfiguration];
        [self setupSubView];
    }
    return self;
}

- (void)defaultConfiguration{
    self.alpha = 0.0f;
    [self setDefaultShadow];
    
    _cornerRaius = 6.0f;
    _separatorColor = [UIColor blackColor];
    _menuColor = kColorHexValue(0x333333);
    _menuCellHeight = 34.0f;
    _maxDisplayCount = 5;
    _isShowShadow = YES;
    _dismissOnselected = YES;
    _dismissOnTouchOutside = YES;
    
    _textColor = [UIColor blackColor];
    _textFont = [UIFont systemFontOfSize:15.0f];
    _offset = 0.0f;
}

- (void)setupSubView{
    [self calculateArrowAndFrame];
    [self setupMaskLayer];
    [self addSubview:self.contentView];
}

- (void)reloadData{
    [self.contentView removeFromSuperview];
    [self.collectionView removeFromSuperview];
    self.contentView = nil;
    self.collectionView = nil;
    [self setupSubView];
}

- (CGPoint)getRefPoint{
    CGRect absoluteRect = [_refView convertRect:_refView.bounds toView:kMainWindow];
    CGPoint refPoint;
    if (absoluteRect.origin.y + absoluteRect.size.height + _actions.count * _menuCellHeight > kScreenHeight - 10) {
        refPoint = CGPointMake(absoluteRect.origin.x + absoluteRect.size.width / 2, absoluteRect.origin.y);
        _isReverse = YES;
    }else{
        refPoint = CGPointMake(absoluteRect.origin.x + absoluteRect.size.width / 2, absoluteRect.origin.y + absoluteRect.size.height);
        _isReverse = NO;
    }
    return refPoint;
}

- (void)show{
    _isShow = YES;
    // 自定义设置统一在这边刷新一次
    if (_needReload) [self reloadData];
    
    [kMainWindow addSubview: self.bgView];
    [kMainWindow addSubview: self];
    self.layer.affineTransform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration: kAnimationTime animations:^{
        self.layer.affineTransform = CGAffineTransformMakeScale(1.0, 1.0);
        self.alpha = 1.0f;
        self.bgView.alpha = 1.0f;
    }];
}

- (void)dismiss{
    _isShow = NO;
    if (!_dismissOnTouchOutside) return;
    [UIView animateWithDuration: kAnimationTime animations:^{
        self.layer.affineTransform = CGAffineTransformMakeScale(0.1, 0.1);
        self.alpha = 0.0f;
        self.bgView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.bgView removeFromSuperview];
        self.actions = nil;
    }];
}

#pragma mark - Private
- (void)setupMaskLayer{
    CAShapeLayer *layer = [self drawMaskLayer];
    self.contentView.layer.mask = layer;
}

- (void)calculateArrowAndFrame{
    if (_refView) {
        _refPoint = [self getRefPoint];
    }
    
    CGFloat originX;
    CGFloat originY;
    CGFloat width;
    CGFloat height;
    
    width = _menuWidth;
    height = _menuCellHeight+20;
    // 默认在中间
    _arrowPosition = 0.5 * width - 0.5 * kArrowWidth;
    
    // 设置出menu的x和y（默认情况）
    originX = _refPoint.x - _arrowPosition - 0.5 * kArrowWidth;
    originY = _refPoint.y;
    
    // 考虑向左右展示不全的情况，需要反向展示
    if (originX + width > kScreenWidth - 10) {
        originX = kScreenWidth - kDefaultMargin - width;
    }else if (originX < 10) {
        //向上的情况间距也至少是kDefaultMargin
        originX = kDefaultMargin;
    }
    
    //设置三角形的起始点
    if ((_refPoint.x <= originX + width - _cornerRaius) && (_refPoint.x >= originX + _cornerRaius)) {
        _arrowPosition = _refPoint.x - originX - 0.5 * kArrowWidth;
    }else if (_refPoint.x < originX + _cornerRaius) {
        _arrowPosition = _cornerRaius;
    }else {
        _arrowPosition = width - _cornerRaius - kArrowWidth;
    }
    
    //如果不是根据关联视图，得算一次是否反向
    if (!_refView) {
        _isReverse = (originY + height > kScreenHeight - kDefaultMargin)?YES:NO;
    }
    
    CGPoint  anchorPoint;
    if (_isReverse) {
        originY = _refPoint.y - height;
        anchorPoint = CGPointMake(fabs(_arrowPosition) / width, 1);
        _topMargin = 0;
    }else{
        anchorPoint = CGPointMake(fabs(_arrowPosition) / width, 0);
        _topMargin = kArrowHeight;
    }
    originY += originY >= _refPoint.y ? _offset : -_offset;
    
    //保存原来的frame，防止设置锚点后偏移
    self.layer.anchorPoint = anchorPoint;
    self.frame = CGRectMake(originX, originY, width, height);
}

- (CAShapeLayer *)drawMaskLayer{
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    CGFloat bottomMargin = !_isReverse?0 :kArrowHeight;
    
    // 定出四个转角点
    CGPoint topRightArcCenter = CGPointMake(self.width - _cornerRaius, _topMargin + _cornerRaius);
    CGPoint topLeftArcCenter = CGPointMake(_cornerRaius, _topMargin + _cornerRaius);
    CGPoint bottomRightArcCenter = CGPointMake(self.width - _cornerRaius, self.height - bottomMargin - _cornerRaius);
    CGPoint bottomLeftArcCenter = CGPointMake(_cornerRaius, self.height - bottomMargin - _cornerRaius);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    // 从左上倒角的下边开始画
    [path moveToPoint: CGPointMake(0, _topMargin + _cornerRaius)];
    [path addLineToPoint: CGPointMake(0, bottomLeftArcCenter.y)];
    [path addArcWithCenter: bottomLeftArcCenter radius: _cornerRaius startAngle: -M_PI endAngle: -M_PI-M_PI_2 clockwise: NO];
    
    if (_isReverse) {
        [path addLineToPoint: CGPointMake(_arrowPosition, self.height - kArrowHeight)];
        [path addLineToPoint: CGPointMake(_arrowPosition + 0.5*kArrowWidth, self.height)];
        [path addLineToPoint: CGPointMake(_arrowPosition + kArrowWidth, self.height - kArrowHeight)];
    }
    [path addLineToPoint: CGPointMake(self.width - _cornerRaius, self.height - bottomMargin)];
    [path addArcWithCenter: bottomRightArcCenter radius: _cornerRaius startAngle: -M_PI-M_PI_2 endAngle: -M_PI*2 clockwise: NO];
    [path addLineToPoint: CGPointMake(self.width, self.height - bottomMargin + _cornerRaius)];
    [path addArcWithCenter: topRightArcCenter radius: _cornerRaius startAngle: 0 endAngle: -M_PI_2 clockwise: NO];
    
    if (!_isReverse) {
        [path addLineToPoint: CGPointMake(_arrowPosition + kArrowWidth, _topMargin)];
        [path addLineToPoint: CGPointMake(_arrowPosition + 0.5 * kArrowWidth, 0)];
        [path addLineToPoint: CGPointMake(_arrowPosition, _topMargin)];
    }
    
    [path addLineToPoint: CGPointMake(_cornerRaius, _topMargin)];
    [path addArcWithCenter: topLeftArcCenter radius: _cornerRaius startAngle: -M_PI_2 endAngle: -M_PI clockwise: NO];
    [path closePath];
    
    maskLayer.path = path.CGPath;
    return maskLayer;
}
- (void)setDefaultShadow{
//    self.layer.shadowOpacity = 0.5;
//    self.layer.shadowOffset = CGSizeMake(0, 0);
//    self.layer.shadowRadius = 5.0;
}

#pragma mark - UICollectionViewFlowLayout
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.actions.count>0?(self.bounds.size.width/self.actions.count):100, collectionView.size.height);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.actions.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    MSMenuCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MSMenuCell" forIndexPath:indexPath];
    MSMenuAction *action = _actions[indexPath.row];
    cell.menuAction = action;
    cell.separatorColor = _separatorColor;
    if (indexPath.row == _actions.count - 1) {
        cell.isShowSeparator = NO;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_dismissOnselected) [self dismiss];
    MSMenuAction *action = _actions[indexPath.row];
    if (action.handler) {
        action.handler(action);
    }
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout * flowLayout = [UICollectionViewFlowLayout new];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, _topMargin, self.width, self.bounds.size.height-kArrowHeight) collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[MSMenuCell class] forCellWithReuseIdentifier:@"MSMenuCell"];
        _collectionView.pagingEnabled = true;
        _collectionView.showsVerticalScrollIndicator = false;
        _collectionView.showsHorizontalScrollIndicator = false;
    }
    return _collectionView;
}

- (UIView *)bgView{
    if (!_bgView) {
//        _bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
////        _bgView.backgroundColor = [UIColor clearColor];
//        _bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
//        _bgView.alpha = 0.0f;
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
//        [_bgView addGestureRecognizer:tap];
    }
    return _bgView;
}

- (UIView *)contentView{
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        _contentView.backgroundColor = _menuColor;
        _contentView.layer.masksToBounds = YES;
        [_contentView addSubview:self.collectionView];
    }
    return _contentView;
}
#pragma mark - 设置属性
- (void)setCornerRaius:(CGFloat)cornerRaius{
    if (_cornerRaius == cornerRaius)return;
    _cornerRaius = cornerRaius;
    self.contentView.layer.mask = [self drawMaskLayer];
}
- (void)setMenuColor:(UIColor *)menuColor{
    if ([_menuColor isEqual:menuColor]) return;
    _menuColor = menuColor;
    self.contentView.backgroundColor = menuColor;
}
- (void)setBackgroundColor:(UIColor *)backgroundColor{
    if ([_menuColor isEqual:backgroundColor]) return;
    _menuColor = backgroundColor;
    self.contentView.backgroundColor = _menuColor;
}
- (void)setSeparatorColor:(UIColor *)separatorColor{
    if ([_separatorColor isEqual:separatorColor]) return;
    _separatorColor = separatorColor;
    [self.collectionView reloadData];
}
- (void)setMenuCellHeight:(CGFloat)menuCellHeight{
    if (_menuCellHeight == menuCellHeight)return;
    _menuCellHeight = menuCellHeight;
    _needReload = YES;
}
- (void)setMaxDisplayCount:(NSInteger)maxDisplayCount{
    if (_maxDisplayCount == maxDisplayCount)return;
    _maxDisplayCount = maxDisplayCount;
    _needReload = YES;
}
- (void)setIsShowShadow:(BOOL)isShowShadow{
    if (_isShowShadow == isShowShadow)return;
    _isShowShadow = isShowShadow;
    if (!_isShowShadow) {
        self.layer.shadowOpacity = 0.0;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 0.0;
    }else{
        [self setDefaultShadow];
    }
}
- (void)setTextFont:(UIFont *)textFont{
    if ([_textFont isEqual:textFont]) return;
    _textFont = textFont;
    [self.collectionView reloadData];
}
- (void)setTextColor:(UIColor *)textColor{
    if ([_textColor isEqual:textColor]) return;
    _textColor = textColor;
    [self.collectionView reloadData];
}
- (void)setOffset:(CGFloat)offset{
    if (offset == offset) return;
    _offset = offset;
    if (offset < 0.0f) {
        offset = 0.0f;
    }
    self.y += self.y >= _refPoint.y ? offset : -offset;
}

@end
