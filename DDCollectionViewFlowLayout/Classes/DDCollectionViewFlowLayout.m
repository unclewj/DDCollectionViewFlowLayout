//
//  DDCollectionViewFlowLayout.m
//  DDCollectionViewFlowLayout
//
//  Created by Diaoshu on 15-2-12.
//  Copyright (c) 2015年 DDKit. All rights reserved.
//

#import "DDCollectionViewFlowLayout.h"

@interface DDCollectionViewFlowLayout(){
    NSMutableArray			*sectionRects;
    NSMutableArray			*columnRectsInSection;
    
    NSMutableArray			*layoutItemAttributes;
    NSDictionary            *headerFooterItemAttributes;
}

@end

@implementation DDCollectionViewFlowLayout

- (CGSize)collectionViewContentSize {
    [super collectionViewContentSize];
    
    DDLog(@"super collectionViewContentSize = %@",[NSValue valueWithCGSize:[super collectionViewContentSize]]);
    
    CGRect lastSectionRect = [[sectionRects lastObject] CGRectValue];
    CGSize lastSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds),CGRectGetMaxY(lastSectionRect));
    DDLog(@"lastSize = %@",[NSValue valueWithCGSize:lastSize]);
    return lastSize;
}

- (void)prepareLayout{
    NSUInteger numberOfSections = self.collectionView.numberOfSections;
    sectionRects = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    columnRectsInSection = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    layoutItemAttributes = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    headerFooterItemAttributes = @{UICollectionElementKindSectionHeader:[NSMutableDictionary dictionary], UICollectionElementKindSectionFooter:[NSMutableDictionary dictionary]};
    
    for (NSUInteger section = 0; section < numberOfSections; ++section) {
        NSUInteger itemsInSection = [self.collectionView numberOfItemsInSection:section];
        [layoutItemAttributes addObject:[NSMutableArray array]];
        [self prepareSectionLayout:section withNumberOfItems:itemsInSection];
    }
}

- (void)prepareSectionLayout:(NSUInteger)section withNumberOfItems:(NSUInteger)numberOfItems{
    UICollectionView *cView = self.collectionView;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    
    //# hanlde the section header
    CGFloat headerHeight = 0.0f;
    
    CGRect previousSectionRect = [self rectForSectionAtIndex:indexPath.section - 1];
    
    CGRect sectionRect;
    sectionRect.origin.y = CGRectGetHeight(previousSectionRect) + CGRectGetMinY(previousSectionRect);
    
    DDLog(@"section = %d previousSectionRect = %@ origin.y = %d",(int)section,[NSValue valueWithCGRect:previousSectionRect],(int)CGRectGetHeight(previousSectionRect));
    
    if([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]){
        
        // #2: Define the rect of the header
        CGRect headerFrame;
        headerFrame.origin.x = 0.0f;
        headerFrame.origin.y = sectionRect.origin.y;

        CGSize headerSize = [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:indexPath.section];
        headerFrame.size.height = headerSize.height;
        headerFrame.size.width = headerSize.width;
        
        UICollectionViewLayoutAttributes *headerAttributes =
        [UICollectionViewLayoutAttributes
         layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
         withIndexPath:indexPath];
        headerAttributes.frame = headerFrame;
        
        DDLog(@"section = %d, headerFrame = %@",(int)section,[NSValue valueWithCGRect:headerFrame]);
        
        headerHeight = headerFrame.size.height;
        [headerFooterItemAttributes[UICollectionElementKindSectionHeader] setObject:headerAttributes forKey:[NSString stringWithFormat:@"section%d",(int)section]];
        
        [layoutItemAttributes[section] addObject:headerAttributes];
    }

    //# get the insets of section
    UIEdgeInsets sectionInsets = UIEdgeInsetsZero;
    
    if([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]){
        sectionInsets = [self.delegate collectionView:cView layout:self insetForSectionAtIndex:section];
    }
    
    CGRect itemsContentRect;
    
    //# the the lineSpacing & interitemSpacing default values
    CGFloat lineSpacing = 0.0f;
    CGFloat interitemSpacing = 0.0f;

    if([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]){
        interitemSpacing = [self.delegate collectionView:cView layout:self minimumInteritemSpacingForSectionAtIndex:section];
    }
    
    if([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]){
        lineSpacing = [self.delegate collectionView:cView layout:self minimumLineSpacingForSectionAtIndex:section];
    }
    
    itemsContentRect.origin.x = sectionInsets.left;
    itemsContentRect.origin.y = headerHeight + sectionInsets.top;
    
    NSUInteger numberOfColumns = [self.delegate collectionView:cView layout:self numberOfColumnsInSection:section];
    itemsContentRect.size.width = CGRectGetWidth(cView.frame) - (sectionInsets.left + sectionInsets.right);
    
    CGFloat columnSpace = itemsContentRect.size.width - (interitemSpacing * (numberOfColumns-1));
    CGFloat columnWidth = (columnSpace/numberOfColumns);
    
    // store space for each column
    [columnRectsInSection addObject:[NSMutableArray arrayWithCapacity:numberOfColumns]];
    for (NSUInteger colIdx = 0; colIdx < numberOfColumns; ++colIdx)
        [columnRectsInSection[section] addObject:[NSMutableArray array]];
    
    // #3: Define the rect of the of each item
    for (NSInteger itemIdx = 0; itemIdx < numberOfItems; ++itemIdx) {
        NSIndexPath *itemPath = [NSIndexPath indexPathForItem:itemIdx inSection:section];
        CGSize itemSize = [self.delegate collectionView:cView layout:self sizeForItemAtIndexPath:itemPath];
        
        NSInteger destColumnIdx = [self preferredColumnIndexInSection:section];
        NSInteger destRowInColumn = [self numberOfItemsInColumn:destColumnIdx ofSection:section];
        CGFloat lastItemInColumnOffset = [self lastItemOffsetInColumn:destColumnIdx inSection:section];
        
        if(destRowInColumn == 0){
            lastItemInColumnOffset += sectionRect.origin.y;
        }
        
        CGRect itemRect;
        itemRect.origin.x = itemsContentRect.origin.x + destColumnIdx * (interitemSpacing + columnWidth);
        itemRect.origin.y = lastItemInColumnOffset + (destRowInColumn > 0 ? lineSpacing: sectionInsets.top);
        itemRect.size.width = columnWidth;
        itemRect.size.height = itemSize.height;
        
        itemRect = CGRectIntegral(itemRect);
        
        UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemPath];
        itemAttributes.frame = itemRect;
        [layoutItemAttributes[section] addObject:itemAttributes];
        [columnRectsInSection[section][destColumnIdx] addObject:[NSValue valueWithCGRect:itemRect]];
    }
    
    itemsContentRect.size.height = [self heightOfItemsInSection:indexPath.section] + sectionInsets.bottom;
    
    DDLog(@"section = %d itemContentRect = %@", (int)section, [NSValue valueWithCGRect:itemsContentRect]);
    CGFloat footerHeight = 0.0f;
    
    if([self.delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]){
        CGRect footerFrame;
        footerFrame.origin.x = 0;
        footerFrame.origin.y = itemsContentRect.size.height;
        
        CGSize footerSize = [self.delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:indexPath.section];
        footerFrame.size.height = footerSize.height;
        footerFrame.size.width = footerSize.width;
        
        DDLog(@"section = %d footerFrame = %@", (int)section, [NSValue valueWithCGRect:footerFrame]);

        UICollectionViewLayoutAttributes *footerAttributes = [UICollectionViewLayoutAttributes
                                                              layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                              withIndexPath:indexPath];
        footerAttributes.frame = footerFrame;
        
        footerHeight = footerFrame.size.height;
        
        [headerFooterItemAttributes[UICollectionElementKindSectionFooter] setObject:footerAttributes forKey:[NSString stringWithFormat:@"section%d",(int)section]];
        
        [layoutItemAttributes[section] addObject:footerAttributes];
    }
    
    if(section > 0){
        itemsContentRect.size.height -= sectionRect.origin.y;
    }

    sectionRect.size.height = itemsContentRect.size.height + footerHeight;
    
    sectionRect.origin.x = 0;
    sectionRect.size.width = cView.bounds.size.width;
    
    DDLog(@"section = %d sectionRect = %@", (int)section, [NSValue valueWithCGRect:sectionRect]);
    [sectionRects addObject:[NSValue valueWithCGRect:sectionRect]];
}

- (CGFloat)heightOfItemsInSection:(NSUInteger)sectionIdx {
    CGFloat maxHeightBetweenColumns = 0.0f;
    NSArray *columnsInSection = columnRectsInSection[sectionIdx];
    for (NSUInteger columnIdx = 0; columnIdx < columnsInSection.count; ++columnIdx) {
        CGFloat heightOfColumn = [self lastItemOffsetInColumn:columnIdx inSection:sectionIdx];
        maxHeightBetweenColumns = MAX(maxHeightBetweenColumns, heightOfColumn);
    }
    NSLog(@"section = %d, maxHeight = %f",(int)sectionIdx, maxHeightBetweenColumns);
    return maxHeightBetweenColumns;
}

- (NSInteger)numberOfItemsInColumn:(NSInteger)columnIdx ofSection:(NSInteger)sectionIdx {
    return [columnRectsInSection[sectionIdx][columnIdx] count];
}

- (CGFloat)lastItemOffsetInColumn:(NSInteger)columnIdx inSection:(NSInteger)sectionIdx {
    NSArray *itemsInColumn = columnRectsInSection[sectionIdx][columnIdx];
    if (itemsInColumn.count == 0) {
        if(headerFooterItemAttributes[UICollectionElementKindSectionHeader][[NSString stringWithFormat:@"section%d",(int)sectionIdx]]){
            CGRect headerFrame = [headerFooterItemAttributes[UICollectionElementKindSectionHeader][[NSString stringWithFormat:@"section%d",(int)sectionIdx]] frame];
            DDLog(@"section = %d, origin y = %f", (int)sectionIdx,headerFrame.size.height);
            return headerFrame.size.height;
        }
        return 0.0f;
    } else {
        CGRect lastItemRect = [[itemsInColumn lastObject] CGRectValue];
        return CGRectGetMaxY(lastItemRect);
    }
}

- (NSInteger)preferredColumnIndexInSection:(NSInteger)sectionIdx {
    NSUInteger shortestColumnIdx = 0;
    CGFloat heightOfShortestColumn = CGFLOAT_MAX;
    for (NSUInteger columnIdx = 0; columnIdx < [columnRectsInSection[sectionIdx] count]; ++columnIdx) {
        CGFloat columnHeight = [self lastItemOffsetInColumn:columnIdx inSection:sectionIdx];
        if (columnHeight < heightOfShortestColumn) {
            shortestColumnIdx = columnIdx;
            heightOfShortestColumn = columnHeight;
        }
    }
    return shortestColumnIdx;
}

- (CGRect)rectForSectionAtIndex:(NSInteger)sectionIdx {
    if (sectionIdx < 0 || sectionIdx >= sectionRects.count)
        return CGRectZero;
    return [sectionRects[sectionIdx] CGRectValue];
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
//    DDLog(@"headerFooterItemAttributes = %@", headerFooterItemAttributes);
    if(headerFooterItemAttributes[kind][[NSString stringWithFormat:@"section%d",(int)indexPath.section]]){
        return headerFooterItemAttributes[kind][[NSString stringWithFormat:@"section%d",(int)indexPath.section]];
    }
    return nil;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    return layoutItemAttributes[indexPath.section][indexPath.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [self searchVisibleLayoutAttributesInRect:rect];
}

- (NSArray *)searchVisibleLayoutAttributesInRect:(CGRect)rect {
    NSMutableArray *itemAttrs = [[NSMutableArray alloc] init];
    NSIndexSet *visibleSections = [self sectionIndexesInRect:rect];
    [visibleSections enumerateIndexesUsingBlock:^(NSUInteger sectionIdx, BOOL *stop) {
        for (UICollectionViewLayoutAttributes *itemAttr in layoutItemAttributes[sectionIdx]) {
            CGRect itemRect = itemAttr.frame;
            BOOL isVisible = CGRectIntersectsRect(rect, itemRect);
            if (isVisible)
                [itemAttrs addObject:itemAttr];
        }
    }];
    return itemAttrs;
}

- (NSIndexSet *)sectionIndexesInRect:(CGRect)rect {
    CGRect theRect = rect;
    NSMutableIndexSet *visibleIndexes = [[NSMutableIndexSet alloc] init];
    NSUInteger numberOfSections = self.collectionView.numberOfSections;
    for (NSUInteger sectionIdx = 0; sectionIdx < numberOfSections; ++sectionIdx) {
        CGRect sectionRect = [sectionRects[sectionIdx] CGRectValue];
        BOOL isVisible = CGRectIntersectsRect(theRect, sectionRect);
        if (isVisible)
            [visibleIndexes addIndex:sectionIdx];
    }
    return visibleIndexes;
}

@end
