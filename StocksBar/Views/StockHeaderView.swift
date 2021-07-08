//
//  StockHeaderView.swift
//  StocksBar
//
//  Created by xu.shuifeng on 2019/4/28.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import Cocoa

class StockHeaderView: NSView {

    var headerCommand: RelayCommand?
    
    var searchField: NSSearchField!
    
    var titleField: NSTextField!
    
    private var listButton: NSButton!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    private func commonInit() {
        
        titleField = NSTextField()
        titleField.isBordered = false
//        titleField.backgroundColor = .clear
        titleField.isEditable = false
        titleField.alignment = .left
        titleField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        titleField.stringValue = "代码                 市值                           当日盈亏              股价         涨跌幅"
        titleField.textColor = NSColor.systemBrown
        addSubview(titleField)
        titleField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(50)
            make.trailing.equalToSuperview().offset(-50)
        }

        
//        searchField = NSSearchField()
//        searchField.focusRingType = .none
//        searchField.placeholderString = "Search Stock"
//        searchField.refusesFirstResponder = true
//        addSubview(searchField)
//        searchField.snp.makeConstraints { make in
//            make.centerY.equalToSuperview()
//            make.leading.equalToSuperview().offset(10)
//            make.height.equalTo(28)
//            make.trailing.equalToSuperview().offset(-40)
//        }
//
//        listButton = NSButton(image: NSImage(named: "icon_list")!, target: self, action: #selector(handleTapListButton(_:)))
//        listButton.isBordered = false
//
//        listButton.setButtonType(.momentaryPushIn)
//        listButton.refusesFirstResponder = true
//        addSubview(listButton)
//        listButton.snp.makeConstraints { make in
//            make.height.width.equalTo(20)
//            make.centerY.equalToSuperview()
//            make.trailing.equalToSuperview().offset(-12)
//        }
//
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 1, alpha: 0.6).cgColor
    }
    
    @objc private func handleTapListButton(_ sender: Any) {
        headerCommand?()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
