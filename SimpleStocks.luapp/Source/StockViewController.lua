
local StockDataClass = require 'SampleStockTradeInfo'
local StockViewClass = require 'SimpleStockView'

local UiView = require "UIKit.UIView"

local UIViewController = objc.UIViewController

local StockViewController = class.createClass ('StockViewController', UIViewController)

function StockViewController:loadView()
    local applicationFrame = objc.UIScreen.mainScreen.applicationFrame
    local stockView = StockViewClass:newWithFrame(applicationFrame)
    stockView.autoresizingMask = UiView.Autoresizing.FlexibleHeight + UiView.Autoresizing.FlexibleWidth
    
    local StockTradeInfo =  StockDataClass:new()
    stockView.dataSource = StockTradeInfo
    
    self.view = stockView
    
    -- subscribe to the module load messages
    self:addMessageHandler ("system.did_load_module", "refresh")
end

function StockViewController:didRotateFromInterfaceOrientation(fromInterfaceOrientation)
    self.view:setNeedsDisplay ()
end

function StockViewController:refresh ()
    self.view:setNeedsDisplay ()
end

return StockViewController