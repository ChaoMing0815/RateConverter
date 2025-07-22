//
//  ConverterViewController.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/21.
//

import Foundation
import UIKit
import SnapKit

class ConverterViewController: UIViewController {
    private let viewModel: ConverterViewModel
    
    // MARK: - UI components
    lazy var amountTextField = makeAmountTextField()
    lazy var currencyPicker = makeCurrencyPicker()
    lazy var conversionCollectionView = makeConversionCollectionView()
    lazy var activityIndicator = makeActivityIndicator()
    
    private var conversionResults: [(String, Float)] = []
    
    init(viewModel: ConverterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Actions
    @objc private func amountTextFieldDidChange() {
        viewModel.updateConversionResult(amountText: amountTextField.text ?? "")
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedCurrency = viewModel.currencyList[row]
        viewModel.setSelectedCurrency(selectedCurrency)
        amountTextFieldDidChange()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        amountTextField.resignFirstResponder()
    }
    
    private func showErorrAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// MARK: - Private helpers
extension ConverterViewController {
    private func setupBindings() {
        viewModel.convertedResultHandler = { [weak self] results in
            DispatchQueue.main.async {
                self?.conversionResults = results
                self?.conversionCollectionView.reloadData()
            }
        }
        
        viewModel.convertedAmountHandler = { [weak self] convertedAmount in
            DispatchQueue.main.async {
                self?.conversionResults = [(self?.viewModel.selectedCurrency ?? "USD", convertedAmount)]
                self?.conversionCollectionView.reloadData()
            }
        }
        
        viewModel.errorHandler = { [weak self] error in
            DispatchQueue.main.async { self?.showErorrAlert(message: error) }
        }
        
        viewModel.isLoadingHandler = { [weak self] isLoading in
            DispatchQueue.main.async {
                isLoading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
        }
        
        viewModel.currencyListUpdatedHandler = { [weak self] selectedCurrencyIndex in
            DispatchQueue.main.async {
                self?.currencyPicker.reloadAllComponents()
                self?.currencyPicker.selectRow(selectedCurrencyIndex, inComponent: 0, animated: false)
            }
        }
    }
}

// MARK: - UI setup
extension ConverterViewController {
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(amountTextField)
        view.addSubview(currencyPicker)
        view.addSubview(conversionCollectionView)
        view.addSubview(activityIndicator)
        
        
        
    }
}

// MARK: - Factory methods
extension ConverterViewController {
    private func makeAmountTextField() -> UITextField {
        let textField = UITextField()
        textField.placeholder = "Enter amount"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.textAlignment = .center
        return textField
    }
    
    private func makeCurrencyPicker() -> UIPickerView {
        return UIPickerView()
    }
    
    private func makeConversionCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 100, height: 100)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: "UICollectionViewCell"))
        return collectionView
    }
    
    private func makeActivityIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }
}
