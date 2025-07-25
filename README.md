

# RateConverter
### 摘要
RateConverter 是一款簡易匯率換算 App，採用 **Clean Architecture** 與 **MVVM 架構**，提供線上即時匯率查詢，並以 Actor 為基礎的快取模組支援離線模式。

### 架構圖
![RateConverter Architecture](https://github.com/ChaoMing0815/RateConverter/blob/main/RateConverter.drawio.png)

### 功能特色
- 使用 Open Exchange Rates API 即時匯率轉換
- 內建 30 分鐘有效期的本地快取（支援離線）
- 支援所有主要幣別
- UIKit + SnapKit 簡潔介面設計
- 使用 async/await 處理非同步請求

### 架構設計
- **Domain 層**
  - Domain models: `Rate`
  - `GetCurrenciesUseCase` 如何取得匯率資料
  - `ConvertCurrenciesUseCase` 匯率轉換邏輯
- **Data 層**
  - `RemoteCurrenciesRepository` 處理遠端資料請求 
  - `StoreCurrenciesRepository` 本地資料存取
  - 資料轉換結構 `RateDTO`
- **Presentation 層**
  - `ConverterViewModel` UI 資料管理
  - `ConverterViewController` UI 呈現與互動事件處理
- **Configuration**
  - API 設定與快取參數
- **LocalCache**
  - Actor 架構的本地快取模組
- **Network 模組**
  - `URLSessionHTTPClient` 以 `URLSession` 為基礎的自定義網路請求模組  

### 安裝方式
```bash
git clone https://github.com/your-username/RateConverter.git
cd RateConverter
open RateConverter.xcodeproj
```

### 使用範例
```swift
// 初始化 RateConverter
let viewModel = ConverterViewModel(
    getCurrenciesUseCase: getCurrenciesUseCase,
    convertCurrenciesUseCase: convertCurrenciesUseCase
)

// 貨幣匯率轉換
await viewModel.doConvertProcess(
    fromCurrency: "USD",
    toCurrency: "EUR",
    amount: 200.0
)
```

### 錯誤處理
```swift
enum ConverterViewModelError: Error {
    case unableToConvert(fromCurrency: String, toCurrency: String)
    case failedToFetchRates
    case unknownError
}
```

### App 設定
```swift
enum AppConfig {
    static let baseURL = URL(string: "https://openexchangerates.org/api/")!
    static let appID = "your_app_id"
    static let currenciesCacheFileName = "currencies_cache.json"
    static let expiryDuration: TimeInterval = 1800 // 30分鐘
}
```

### 單元測試
- 網路模組單元測試

