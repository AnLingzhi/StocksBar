//
//  StockDataSource.swift
//  StocksBar
//
//  Created by xu.shuifeng on 2019/4/28.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import Foundation
import Cocoa
import Alamofire
import UserNotifications

class StockDataSource: NSObject {
    
    static let shared = StockDataSource()
    
    var updatedHandler: RelayCommand?
    
    private var content: [Stock] = []
    
    private let api = SinaStocksAPI()
    
    private var currentIndex = 0
    
    private var fileURL: URL {
        let name: String
        #if DEBUG
            name = "stocks_debug.data"
        #else
            name = "stocks.data"
        #endif
        let path = NSHomeDirectory().appending("/Documents/\(name)")
        print(path)
        return URL(fileURLWithPath: path)
    }
    
    private var appDelegate: AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }
    
//    var defaultStocks:[String:Int] = ["sz300750": 700
//                                     ,"sh688356": 1000
//                                     ,"sz300496": 1500
//                                     ,"sh601888": 800
//                                     ,"sz300573": 1100
//                                     ,"sz300896": 100
//                                     ,"sh600771": 1400
//                                     ,"sh603893": 300
//                                     ,"sz300458": 300
//                                     ,"sz000876": 3500
//                                     ,"sh688613": 600
//                                     ,"sh600498": 1000
//                                     ,"sh688508": 200
//                                     ,"sz000538": 200
//                                     ,"sz000851": 1000
//                                     ,"sz002456": 600
//                                     ,"sh513550": 4200
//                                     ,"sh000001": 0
//                                     ,"sz399006": 0
//                                     ,"sh000688": 0]
//
//    var defaultStocks:[String:Int] = ["sz002409": 400,
//                                    "sz300316": 400,
//                                    "sz300496": 200,
//                                    "sz300487": 700,
//                                    "sh603501": 100,
//                                    "sh600563": 200,
//                                    "sz300747": 300,
//                                    "sh603260": 400,
//                                    "sz300751": 100,
//                                    "sz300015": 600,
//                                    "sh600315": 400,
//                                    "sh600132": 200]
//
    var defaultStocks:[String:Int] = ["sh000001": 0
                                     ,"sz399006": 0
                                     ,"sh000688": 0]
    

    var confStocks:[String:Int] = ["sh000001": 0]
    
    private override init() {
        super.init()
        if let data = try? Data(contentsOf: fileURL),
            let list = try? JSONDecoder().decode([Stock].self, from: data), list.count > 0 {
            content = list
            for stock in content {
                confStocks[stock.code] = stock.numOfPosition
            }
            updatedHandler?()
        } else {
            for (stock_code, stock_num) in defaultStocks {
                confStocks[stock_code] = stock_num
                content.append(Stock(code:stock_code))
                print(stock_code, content[content.count-1].numOfPosition)
            }
            save()
        }
        update()
    }
    
    // MARK: - Public functions
    
    func numberOfRows() -> Int {
        return content.count
    }
    
    func data(atIndex index: Int) -> Stock {
        return content[index]
    }
    
    func numOfPosition(code: String) -> Int {
        var num = confStocks[code]
        if(nil == num){
            num = 0
        }
        return num!
    }
    
    func add(stock: Stock) {
        var array = content
        if !array.contains(where: { $0.code == stock.code }) {
            array.insert(stock, at: 0)
            content = array
            confStocks[stock.code] = stock.numOfPosition
            save()
            updatedHandler?()
        }
    }
    
    func remove(stock: Stock) {
        var array = content
        if let index = array.firstIndex(where: { $0.code == stock.code }) {
            array.remove(at: index)
            content = array
            confStocks[stock.code] = 0
            save()
        }
    }
    
    func remove(at index: Int) {
        var array = content
        array.remove(at: index)
        content = array
        save()
    }
    
    func save() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            let data = try JSONEncoder().encode(content)
            try data.write(to: fileURL)
        } catch {
            print(error)
        }
    }
    
    func buy(at index: Int, num: Int) {
        let stock = content[index]
        confStocks[stock.code]! += (100 * num)
        save()
    }
    
    func sell(at index: Int, num: Int) {
        let stock = content[index]
        confStocks[stock.code]! -= (100 * num)
        save()
    }
    
    func clearance(at index: Int) {
        let stock = content[index]
        confStocks[stock.code]! = 0
        save()
    }
    
    
    func updateReminderOfStock(_ newStock: Stock) {
        if let stock = content.first(where: { $0.code == newStock.code }) {
            stock.reminder = newStock.reminder
            save()
        }
    }
    
    func contains(_ stock: Stock) -> Bool {
        return content.contains(where: { $0.code == stock.code })
    }
    
    func move(from index: Int, to row: Int) {
//        var array = content
//        array.insert(array.remove(at: index), at: row)
//        content = array
//        save()
//        updatedHandler?()
    }
    
    func onSort(s1:Stock, s2:Stock) -> Bool{
        let a = Float(s1.numOfPosition) * s1.current
        let b = Float(s2.numOfPosition) * s2.current
        return a > b
    }
    
    func sortStocks() {
        var array = content
        array.sort(by: onSort)
        content = array
        save()
        updatedHandler?()
    }
    
    func search(suggestion: String, completion: @escaping StocksAPICompletion) {
        api.suggestion(key: suggestion, completion: completion)
    }
    
    // MARK: - Private functions
    
    @objc private func update() {
        if content.count == 0 {
            return
        }
        
        let codes = content.map { return $0.code }
        api.request(codes: codes) { (stocks, error) in
            if let error = error {
                print(error)
            } else {
                self.updateStocks(stocks)
                self.updatedHandler?()
                self.updateStatusBar()
            }
            let time = AppPreferences.shared.refreshInterval
            self.perform(#selector(self.update), with: nil, afterDelay: TimeInterval(time), inModes: [.default])
        }
    }
    
    private func updateStocks(_ newStocks: [Stock]) {
        for stock in content {
            if let n = newStocks.first(where: { $0.code == stock.code }) {
                stock.update(with: n)
            }
            checkRemind(stock: stock)
        }
        self.sortStocks()
    }
    
    private func checkRemind(stock: Stock) {
        if stock.reminder.checkRemind(percent: stock.percent, price: stock.current) {
            stock.reminder.toasted = true
            stock.reminder.toastDate = Date()
            save()
            
            let price = String(format: "%.2f", stock.current)
            
            let notification = NSUserNotification()
            notification.title = "股价提醒"
            notification.subtitle = "你关注的\(stock.symbol) 达到\(price)"
            notification.informativeText = stock.reminder.remindText(percent: stock.percent, price: stock.current)
            notification.deliveryDate = Date(timeInterval: 0.5, since: Date())
            NSUserNotificationCenter.default.scheduleNotification(notification)
        }
    }
    
    private func updateStatusBar() {
//        if AppPreferences.shared.loopDisplayStocks {
//            currentIndex = currentIndex % content.count
//            appDelegate?.update(stock: content[currentIndex])
//            currentIndex += 1
//        } else {
//            appDelegate?.update(stock: content.first)
//        }
//        
//        for (stock_code, stock_num) in defaultStocks {
//            print(stock_code, stock_num, content[])
//        }

        var sum:Float = 0
        var sum_lst:Float = 0
        for stock in content {
            let numOfPosition = confStocks[stock.code]
            if numOfPosition != nil{
                sum += (stock.current * Float(numOfPosition!))
                sum_lst += (stock.lastClosedPrice * Float(numOfPosition!))
            }
        }
        let chg = sum-sum_lst
        let chgP = 100 * chg / sum_lst
        var face1:String = "🈵️"
        var face2:String = "❤️‍🔥"
        var face3:String = "😄"
        if(chgP > 2){
            face1 = "🈵️"
            face2 = "❤️‍🔥"
            face3 = "😍"
        }
        else if(chgP>1){
            face1 = "🈵️"
            face2 = "💖"
            face3 = "🥰"
        }
        else if(chgP>0){
            face1 = "🈵️"
            face2 = "❤️"
            face3 = "😘"
        }
        else if(chgP>(-1)){
            face1 = "💰"
            face2 = "💔"
            face3 = "🥺"
        }
        else if(chgP>(-2)){
            face1 = "💰"
            face2 = "💔"
            face3 = "😰"
        }
        else{
            face1 = "💊"
            face2 = "💔"
            face3 = "😱"
        }
        
        let title_str = String(format: "%@:%.2f %@:%.2f %@:%.2f%%", face1, sum, face2, chg, face3, chgP)
        appDelegate?.update_title(title: title_str)
    }
}
