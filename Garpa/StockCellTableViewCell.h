//
//  StockCellTableViewCell.h
//  Garpa
//
//  Created by Rodrigo Ramele on 22/03/2019.
//  Copyright © 2019 Baufest. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StockCellTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *qty;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *price;

@end

NS_ASSUME_NONNULL_END
