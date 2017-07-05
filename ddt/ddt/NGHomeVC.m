//
//  NGHomeVC.m
//  ddt
//
//  Created by gener on 15/7/26.
//  Copyright (c) 2015年 Light. All rights reserved.
//

#import "NGHomeVC.h"
#import "NGCollectionViewCell.h"
#import "NGXMLReader.h"
#import "NGItemsDetailVC.h"
#import "NGSearchCitiesVC.h"
#import "NGSecondVC.h"
#import "NGSearchBar.h"
#import <PgyUpdate/PgyUpdateManager.h>

#define ScrollViewHeight    100
#define CollectionHeaderViewHight 140
#define FootRecordData @"FootRecordData"
#define TapStr @"最近访问的类别会出现在这里"

static NSString *NGCollectionHeaderReuseID = @"NGCollectionHeaderReuseID";
static NSString *showItemDetailIdentifier = @"showItemDetailIdentifier";//item 详情页Id

static NSString *showSecondVCID     = @"showSecondVCID";//附近同行、接单、求职招聘
static NSString *showFeedBackVCID   = @"showFeedBackVCID";//意见反馈
static NSString *showTHContactID    = @"showTHContactID";//同行交流
static NSString *showShuaiDanID     = @"showShuaiDanID";//甩单
static NSString *showCarPriceVCID   = @"showCarPriceVCID";//车价评估

//#import "BaiDuLocationManger.h"

@interface NGHomeVC ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UITextFieldDelegate,UMSocialUIDelegate>

@end

@implementation NGHomeVC
{
    UIButton *leftBtn ;
    UIPageControl *_pageCtr;
    UIScrollView *_topScrollView;
    UICollectionView *_collectionView;
    NSTimer *_timer;
    
    NSArray *_itemArray;//item元素项
    NSDictionary *_selectItemDic;//选中cell的数据项
    NSString *_option_info;//item附件信息，表明企业OR个人
    NSInteger _selectIndex;//选中cell索引,section =1用到
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path= [[NSBundle mainBundle]pathForResource:@"menuItem" ofType:@"plist"];
    _itemArray = [[NSArray alloc]initWithContentsOfFile:path];
    _selectIndex = 0;
    
    [self initCollectionView];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    //获取位置信息
//    [SVProgressHUD showWithStatus:@"正在获取位置"];
    [[LocationManger shareManger]getLocationWithSuccessBlock:^(NSString *str) {
        [SVProgressHUD dismiss];
        NSLog(@"current location : %@",str);
        [[NSUserDefaults standardUserDefaults]setObject:@"上海市" forKey:CURRENT_LOCATION_CITY];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        if (str) {
             [leftBtn setTitle:str forState:UIControlStateNormal];
        }
        else
        {
            [leftBtn setTitle:@"定位失败" forState:UIControlStateNormal];
        }

        //...上传位置信息<+31.19302052,+121.68571511>
        NSString *tel = [[MySharetools shared]getPhoneNumber];
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:tel,@"username", tel,@"mobile",@"121.68571511,31.19302052",@"distance",nil];
        
        NSDictionary *_d = [MySharetools getParmsForPostWith:dic];
        
        RequestTaskHandle *_task = [RequestTaskHandle taskWithUrl:NSLocalizedString(@"url_upLocation", @"") parms:_d andSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        } faileBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
        
        [HttpRequestManager doPostOperationWithTask:_task];
        
    } andFailBlock:^(NSError *error) {
        [SVProgressHUD showInfoWithStatus:@"获取位置信息失败"];
    }];
    
    //...test检查版本更新
    [[PgyUpdateManager sharedPgyManager]checkUpdate];
  /*
    [[BaiDuLocationManger share]getLocationWithSuccessBlock:^(CLLocation *loaction) {
//        CLGeocoder *geo = [[CLGeocoder alloc]init];
//        [geo reverseGeocodeLocation:loaction completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
//            for (CLPlacemark *_p in placemarks) {
//                NSLog(@"...%@",_p);
//            }
//        }];
        CLGeocoder *geo = [[CLGeocoder alloc]init];
        [geo reverseGeocodeLocation:loaction completionHandler:^(NSArray *placemarks, NSError *error) {
            for (CLPlacemark *place in placemarks) {
                //            NSLog(@"name,%@",place.name);                       // 位置名
                //            NSLog(@"thoroughfare,%@",place.thoroughfare);       // 街道
                //            NSLog(@"subThoroughfare,%@",place.subThoroughfare); // 子街道
                //            NSLog(@"locality,%@",place.locality);               // 市
                //            NSLog(@"subLocality,%@",place.subLocality);         // 区
                //            NSLog(@"country,%@",place.country);                 // 国家
//                cityname = place.locality;
            }}];
    } andFailBlock:^(NSError *error) {
        
    }];*/
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_timer setFireDate:[NSDate distantPast]];
    [_collectionView reloadData];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_timer setFireDate:[NSDate distantFuture]];
}
-(void)awakeFromNib
{
    [self initTopView];
    
    UIBarButtonItem *backitem = [[UIBarButtonItem alloc]init];
//    backitem.image = [UIImage imageNamed:@"leftArrow"];
    backitem.title = @"";
    self.navigationItem.backBarButtonItem =backitem ;
}

#pragma mark-init subview
-(void)initTopView
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(0, 0, 60, 40);
    [leftBtn setImage:[UIImage imageNamed:@"bar_down_icon"] forState:UIControlStateNormal];
    [leftBtn setTitle:@"定位中" forState:UIControlStateNormal];
    leftBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    leftBtn.titleLabel.textAlignment  = NSTextAlignmentLeft;
    [leftBtn setTitleEdgeInsets:UIEdgeInsetsMake(3, -20, 3, -5)];
    [leftBtn setImageEdgeInsets:UIEdgeInsetsMake(5, -15, 5, 52)];
    [leftBtn addTarget:self action:@selector(locationBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.frame = CGRectMake(0, 0, 60, 40);
    [rightBtn setImage:[UIImage imageNamed:@"bar_qiandao_icon"] forState:UIControlStateNormal];
    [rightBtn setTitle:@"签到" forState:UIControlStateNormal];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [rightBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -5, 0, -35)];
    [rightBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 22, 0, -10)];
    [rightBtn addTarget:self action:@selector(siginBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    
    //搜索栏初始化
    UIView *searchView = [[UIView alloc]initWithFrame:CGRectMake(leftBtn.right+5, 0, CurrentScreenWidth -leftBtn.width-rightBtn.width-30, 25)];
    UITextField *searchField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, searchView.width, searchView.height)];
    searchField.backgroundColor = [UIColor whiteColor];
    searchField.font = [UIFont systemFontOfSize:12];
    searchField.placeholder = @" 输入搜索关键字";
    searchField.layer.masksToBounds = YES;
    searchField.layer.cornerRadius = 3;
    [searchView addSubview:searchField];
    searchField.delegate = self;
    
    UIButton *_btn = [UIButton buttonWithType:UIButtonTypeCustom];
    _btn.frame = CGRectMake(0, 0, 35, 15);
    [_btn setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
    [_btn setImage:[UIImage imageNamed:@"search_icon"] forState:UIControlStateNormal];
    searchField.rightView =_btn ;
    searchField.rightViewMode = UITextFieldViewModeAlways;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, searchView.width, 20);
    [btn addTarget:self action:@selector(jumpTosearch) forControlEvents:UIControlEventTouchUpInside];
    [searchView addSubview:btn];
    self.navigationItem.titleView = searchView;

    _pageCtr = [[UIPageControl alloc]initWithFrame:CGRectMake((CurrentScreenWidth - 100)/2.0, ScrollViewHeight - 20, 100, 20)];
    _pageCtr.numberOfPages  = 4;
    _pageCtr.currentPageIndicatorTintColor =[UIColor colorWithRed:0.345 green:0.678 blue:0.910 alpha:1];
    _pageCtr.pageIndicatorTintColor = [UIColor lightGrayColor];
    _topScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, CurrentScreenWidth, ScrollViewHeight)];
    _topScrollView.backgroundColor = [UIColor lightGrayColor];
    _topScrollView.contentSize = CGSizeMake(CurrentScreenWidth * 4, ScrollViewHeight);
    _topScrollView.contentInset = UIEdgeInsetsZero;
    //[self.view addSubview:_topScrollView];
    _topScrollView.delegate  =self;
    _topScrollView.pagingEnabled = YES;
    _topScrollView.showsHorizontalScrollIndicator = NO;
    
    //...test
    for (int i=0; i < 4; i++) {
        UIImageView *imgv = [[UIImageView alloc]init];
        imgv.frame = CGRectMake(CurrentScreenWidth * i, 0, CurrentScreenWidth, ScrollViewHeight);
        imgv.image = [UIImage imageNamed:[NSString stringWithFormat:@"image%d.png",i]];
        [_topScrollView addSubview:imgv];
    }
    [_topScrollView addSubview:_pageCtr];
}

-(void)initCollectionView
{
    float _w = (CurrentScreenWidth -20 -3) / 4.0;
    UICollectionViewFlowLayout *_layout = [[UICollectionViewFlowLayout alloc]init];
    _layout.itemSize =CGSizeMake(_w, 80);
    _layout.minimumLineSpacing = 10;
    _layout.minimumInteritemSpacing = 1;
    _layout.sectionInset = UIEdgeInsetsMake(5, 10, 10, 10);
    _layout.headerReferenceSize = CGSizeMake(0, CollectionHeaderViewHight);//_topScrollView.frame.origin.y+ScrollViewHeight
    
    _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 64, CurrentScreenWidth, CurrentScreenHeight -64-44) collectionViewLayout:_layout];
    _collectionView.backgroundColor = [UIColor whiteColor];
//    _collectionView.bounces = NO;
    [self.view addSubview:_collectionView];
    _collectionView.delegate = self;
    _collectionView.dataSource  = self;
    [_collectionView registerNib:[UINib nibWithNibName:@"NGCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"NGCollectionViewCellID"];
    [_collectionView registerNib:[UINib nibWithNibName:@"NGCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NGCollectionHeaderReuseID];
}

#pragma mark -timer action
-(void)timerAction
{
    CGPoint currentPoint = _topScrollView.contentOffset;
    currentPoint.x += CurrentScreenWidth;
    if (currentPoint.x > 3 * CurrentScreenWidth) {
        currentPoint = CGPointZero;
        _topScrollView.contentOffset = CGPointMake(0, 0);
    }
    
    [UIView animateWithDuration:.2 animations:^{
        _topScrollView.contentOffset = currentPoint;
    } completion:^(BOOL finished) {
        _pageCtr.currentPage = currentPoint.x / CurrentScreenWidth;
        _pageCtr.frame = CGRectMake(currentPoint.x + (CurrentScreenWidth - 100)/2.0, ScrollViewHeight - 20, 100, 20);
    }];
}

#pragma mark -选择城市
-(void)locationBtnAction :(UIButton*)btn
{
    [self performSegueWithIdentifier:@"searchCityIdentifier" sender:nil];
}

//签到
-(void)siginBtnAction :(UIButton*)btn
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *tel = [[MySharetools shared]getPhoneNumber];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:tel,@"username", tel,@"mobile",@"5",@"fee",dateString,@"bz",@"1",@"type",nil];//type 1:签到积分 ; 2 : 分享
    NSDictionary *_d = [MySharetools getParmsForPostWith:dic];
    [SVProgressHUD showWithStatus:@"签到中"];
    RequestTaskHandle *_task = [RequestTaskHandle taskWithUrl:NSLocalizedString(@"url_qiandao", @"") parms:_d andSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            if (![[responseObject objectForKey:@"result"]boolValue]) {
                [SVProgressHUD showSuccessWithStatus:@"签到成功,积分+5"];
                //...发送通知签到成功
                [[NSNotificationCenter defaultCenter]postNotificationName:QIAN_DAO_SUCCESS_NOTI object:@"5"];
            }
            else if ([[responseObject objectForKey:@"result"]integerValue]==1)
            {
                [SVProgressHUD showInfoWithStatus:[responseObject objectForKey:@"message"]];
            }
            else
                [SVProgressHUD showInfoWithStatus:@"签到失败,请稍后重试"];
        }
    } faileBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD showInfoWithStatus:@"签到失败,请稍后重试"];
    }];
    
    [HttpRequestManager doPostOperationWithTask:_task];
}

#pragma mark -UITextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    
    return NO;
}

#pragma mark -UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == _topScrollView) {
        NSInteger index = scrollView.contentOffset.x / CurrentScreenWidth;
        if (index != _pageCtr.currentPage) {
            _pageCtr.currentPage = scrollView.contentOffset.x / CurrentScreenWidth;
            _pageCtr.frame = CGRectMake(scrollView.contentOffset.x + (CurrentScreenWidth - 100)/2.0, ScrollViewHeight - 20, 100, 20);
        }
    }
}

//记录访问足迹
-(NSString *)footerRecord:(NSString*)str
{
    NSMutableString *_des = [[NSMutableString alloc]init];
    NSArray *_arr =  [[NSUserDefaults standardUserDefaults] objectForKey:FootRecordData];
    if (str) {
        if (_arr) {
            NSMutableArray *_tmp = [NSMutableArray arrayWithArray:_arr];
            if ([_tmp containsObject:str]) {
                [_tmp removeObject:str];
            }
            [_tmp insertObject:str atIndex:0];
            if (_tmp.count > 3) {
                [_tmp removeLastObject];
            }
            [[NSUserDefaults standardUserDefaults]setObject:_tmp forKey:FootRecordData];
        }
        else
        {
            [[NSUserDefaults standardUserDefaults]setObject:@[str] forKey:FootRecordData];
        }
    }
    else
    {
        if (_arr) {
            for (int i =0; i < _arr.count; i++) {
                [_des appendString:[NSString stringWithFormat:@" %@",_arr[i]]];
            }
            return _des;
        }
    }

    return TapStr;
}

#pragma mark -UICollectionViewDelegate
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return _itemArray?_itemArray.count:0;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (_itemArray && _itemArray.count > 0) {
        NSArray *_arr = [_itemArray objectAtIndex:section];
        return _arr?_arr.count:0;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *_arr = [_itemArray objectAtIndex:indexPath.section];
    NSDictionary *dic = [_arr objectAtIndex:indexPath.row];
    NGCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NGCollectionViewCellID" forIndexPath:indexPath];
    cell.image.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@",[dic objectForKey:@"imagename"]]];
    cell.title.text = [NSString stringWithFormat:@"%@",[dic objectForKey:@"title"]];
    return cell;
}
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return nil;
    }
    UICollectionReusableView *reuseView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NGCollectionHeaderReuseID forIndexPath:indexPath];
    for (id _s in reuseView.subviews) {
        [_s removeFromSuperview];
    }
    
    UILabel *_line = [[UILabel alloc]init];
    [reuseView addSubview:_line];
    _line.backgroundColor = [UIColor lightGrayColor];
    
    if (indexPath.section ==0) {
        [reuseView addSubview:_topScrollView];
        
        UIImageView *_igv = [[UIImageView alloc]initWithFrame:CGRectMake(0,ScrollViewHeight+ (CollectionHeaderViewHight - 20 - ScrollViewHeight)/2.0, 20, 20)];
        _igv.image = [UIImage imageNamed:@"footer"];
        [reuseView addSubview:_igv];
        UILabel*_footLab = [[UILabel alloc]initWithFrame:CGRectMake(_igv.frame.origin.x + 20, ScrollViewHeight+(CollectionHeaderViewHight - 20 -ScrollViewHeight)/2.0, 250, 20)];
        _footLab.font = [UIFont systemFontOfSize:13];
        [reuseView addSubview:_footLab];
        NSString *_ss = [self footerRecord:nil];
        _footLab.text =[NSString stringWithFormat:@"足迹:%@",_ss] ;//...
        //        _footLab.backgroundColor = [UIColor lightGrayColor];
        _footLab.textColor =[UIColor colorWithRed:0.624 green:0.624 blue:0.624 alpha:1];
        
        UIButton *_shareBtn =[UIButton buttonWithType:UIButtonTypeCustom];
        _shareBtn.frame = CGRectMake(CurrentScreenWidth -80,ScrollViewHeight+ 0, 80, CollectionHeaderViewHight -ScrollViewHeight);
        [reuseView addSubview:_shareBtn];
        [_shareBtn setTitle:@"分享赚积分" forState:UIControlStateNormal];
        [_shareBtn setImage:[UIImage imageNamed:@"share_icon"] forState:UIControlStateNormal];
        [_shareBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 0, 5, 60)];
        [_shareBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -8, 0, -5)];
        [_shareBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        _shareBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_shareBtn addTarget:self action:@selector(shareBtnAction) forControlEvents:UIControlEventTouchUpInside];
        
        _line.frame = CGRectMake(0,  CollectionHeaderViewHight - 1, CurrentScreenWidth, 1);
    }
    else if (indexPath.section ==1)
    {
        _line.frame = CGRectMake(0, 1, CurrentScreenWidth, 1);
    }
    return reuseView;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //key,title
    _option_info =nil;
    _selectItemDic =[[_itemArray objectAtIndex:indexPath.section ] objectAtIndex:indexPath.row];
    [self footerRecord:[_selectItemDic objectForKey:@"title"]];
    if (indexPath.section == 0) {
        _option_info = indexPath.row < 4 ? @"个人":(indexPath.row < 8 ?@"企业":@"");
        [self performSegueWithIdentifier:showItemDetailIdentifier sender:nil];

    }
    else if (indexPath.section == 1)
    {
        switch (indexPath.row) {
            case 0://附近同行
            {
                _selectIndex = 3;
                [self performSegueWithIdentifier:showSecondVCID sender:nil];
            }break;
                
            case 1:
            {
                [self performSegueWithIdentifier:showTHContactID sender:nil];
            }break;
                
            case 2:
            {
                [self performSegueWithIdentifier:showCarPriceVCID sender:nil];
            }break;
                
            case 3:
            {
                [self performSegueWithIdentifier:showFeedBackVCID sender:nil];
            }break;
                
            case 4:
            {
                _selectIndex = 4;
                [self performSegueWithIdentifier:showSecondVCID sender:nil];
            }break;
                
            case 5:
            {
                [self performSegueWithIdentifier:showShuaiDanID sender:nil];
            }break;
                
            case 6:
            {
                _selectIndex = 5;
                [self performSegueWithIdentifier:showSecondVCID sender:nil];
            }break;
            case 7:
            {
                _selectIndex = 6;
                [self performSegueWithIdentifier:showSecondVCID sender:nil];
            }break;
            default:
                break;
        }

    }
}

#pragma mark --UICollectionViewDelegateFlowLayout
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return CGSizeZero;
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return section?CGSizeMake(0, 2): CGSizeMake(0, CollectionHeaderViewHight);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -shareBtn Action
-(void)shareBtnAction
{
    [UMSocialSnsService presentSnsIconSheetView:self
                                         appKey:umengkey
                                      shareText:@"贷易通-你身边的贷款专家,http://www.123dyt.com"
                                     shareImage:[UIImage imageNamed:@"wx108x108"]
                                shareToSnsNames:[NSArray arrayWithObjects:UMShareToSina,UMShareToTencent,UMShareToQQ,UMShareToQzone,UMShareToWechatSession,UMShareToWechatTimeline,UMShareToWechatFavorite,UMShareToSms,nil]
                                       delegate:self];
}

-(void)didSelectSocialPlatform:(NSString *)platformName withSocialData:(UMSocialData *)socialData
{
    NSLog(@"...%@",platformName);
    if ([platformName isEqualToString:@"wxsession"]) {
      [UMSocialData defaultData].extConfig.wechatSessionData.title = @"";
    }
    else if ([platformName isEqualToString:@"qq"])
    {
        [UMSocialData defaultData].extConfig.qqData.title = @"贷易通";
    }//sina
    
}

//实现回调方法（可选）
-(void)didFinishGetUMSocialDataInViewController:(UMSocialResponseEntity *)response
{
    //根据`responseCode`得到发送结果,如果分享成功
    if(response.responseCode == UMSResponseCodeSuccess)
    {
        //得到分享到的微博平台名
        NSLog(@"share to sns name is %@",[[response.data allKeys] objectAtIndex:0]);
    }
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:showItemDetailIdentifier]) {//item详情页
        NGItemsDetailVC *_vc = [segue destinationViewController];
        _vc.superdic = _selectItemDic;
        _vc.optional_info = _option_info;
    }
    else if ([segue.identifier isEqualToString:showSecondVCID])
    {
        NGSecondVC *_vc = [segue destinationViewController];
        _vc.hidesBottomBarWhenPushed = YES;
        _vc.title = @"test";
        _vc.vcType = _selectIndex;
    }
    else if ([segue.identifier isEqualToString:@"searchCityIdentifier"])
    {
        NGSearchCitiesVC *vc = (NGSearchCitiesVC *)[((NGBaseNavigationVC*)[segue destinationViewController]) topViewController];
        
        vc.popViewBackBlock = ^(id obj){
            NSDictionary *_d = (NSDictionary*)obj;
            [leftBtn setNormalTitle:[_d objectForKey:@"NAME"] andID:[_d objectForKey:@"ID"]];
            [[NSUserDefaults standardUserDefaults]setObject:[_d objectForKey:@"NAME"] forKey:CURRENT_LOCATION_CITY];
            [[NSUserDefaults standardUserDefaults]synchronize];
        };
    }
}


#pragma mark -- 点击搜索在此跳转
-(void)jumpTosearch{
    [self performSegueWithIdentifier:@"showUserSearchId" sender:nil];
}




@end




