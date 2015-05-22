
local StockDataClass, stockDataUpdatedMessage = require 'YahooStockTradeInfo'
local StockViewClass = require 'SimpleStockView'

local UiView = require "UIKit.UIView"

local UIViewController = objc.UIViewController

local StockViewController = class.createClass ('StockViewController', UIViewController)

function StockViewController:init()
    self:initWithNibName_bundle(nil, nil)
end

function StockViewController:initWithNibName_bundle (nibNameOrNil --[[@type string]], nibBundleOrNil --[[@type objc.NSBundle]])
    self[UIViewController]:initWithNibName_bundle(nibNameOrNil, nibBundleOrNil)
    
    self.isCreated = true
end

function StockViewController:loadView()
    local applicationFrame = objc.UIScreen.mainScreen.applicationFrame
    local stockView = StockViewClass:newWithFrame(applicationFrame)
    stockView.autoresizingMask = UiView.Autoresizing.FlexibleHeight + UiView.Autoresizing.FlexibleWidth
    
    self.stockTradeInfo =  StockDataClass:new()
    stockView.dataSource = self.stockTradeInfo
    
    self.view = stockView
    
    self:configureStockTradeInfo()
    
    -- subscribe to the module load messages
    self:addMessageHandler ("system.did_load_module", "refresh")
    self:addMessageHandler (stockDataUpdatedMessage, "refresh")
end

function StockViewController:configureStockTradeInfo()
    getResource("AAPL-stock-info", 'public.plain-text', 
                self,
                function (self, stockInfoText)
                    self.stockTradeInfo:parseStockInfo(stockInfoText)
                    self.view:setNeedsDisplay ()
                end)
end

function StockViewController:didRotateFromInterfaceOrientation(fromInterfaceOrientation)
    self.view:setNeedsDisplay ()
end

function StockViewController:refresh (messageName, moduleName)
    if messageName == "system.did_load_module" and moduleName == "StockViewController" then
        self:configureStockTradeInfo()
    end
    self.view:setNeedsDisplay ()
end

return StockViewController