//
//  ConversionCell.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/22.
//

import UIKit
import SnapKit

class ConversionCell: UICollectionViewCell {
    private let currencyLabel = UILabel()
    private let amountLabel = UILabel()
    
    override init(frame: CGRect) {
        super .init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(currencyLabel)
        contentView.addSubview(amountLabel)
        
        currencyLabel.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        
        amountLabel.snp.makeConstraints { make in
            make.top.equalTo(currencyLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
        }
    }
    
    func configure(currency: String, amount: Float) {
        currencyLabel.text = currency
        amountLabel.text = String(format: "%.2f", amount)
    }
}
