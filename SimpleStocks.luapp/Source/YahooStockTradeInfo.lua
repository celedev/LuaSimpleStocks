
local NsString = require "Foundation.NSString"
local NsNumberFormatter = require 'Foundation.NSNumberFormatter'

local StockTradeInfo = require 'StockTradeInfo'

------------------------------------
--[[ Stock info on yahoo can be obtained using a URL like: 
http://real-chart.finance.yahoo.com/table.csv?s=AAPL&a=08&b=1&c=2014&d=01&e=19&f=2015&g=d&ignore=.csv
where:
s= stock code
a= start month number - 1
b= start day number
c= start year
d= end month number - 1
e= end day number
f= end year
]]


local YahooStockTradeInfo = class.createClass ('YahooStockTradeInfo', StockTradeInfo)

local updateMessage = "YahooStockTradeInfo code updated"
local stockInfoUpdatedMessage = "stockInfoUpdatedMessage"

function YahooStockTradeInfo:init()
    
    self[StockTradeInfo]:init () -- call super
    
    self:addMessageHandler(updateMessage, 'handleCodeUpdate')
    
    local sampleLocale = objc.NSLocale:newWithIdentifier ("en_US_POSIX")
    
    local dateFormatter = objc.NSDateFormatter:new()
    dateFormatter:setLocale(sampleLocale)
    dateFormatter:setDateFormat("yyyy-MM-dd")
    self.dateFormatter = dateFormatter
    
    local priceFormatter = objc.NSNumberFormatter:new()
    priceFormatter:setLocale(sampleLocale)
    priceFormatter:setNumberStyle(NsNumberFormatter.Style.DecimalStyle)
    self.priceFormatter = priceFormatter
    
    local volumeFormatter= objc.NSNumberFormatter:new()
    volumeFormatter:setLocale(sampleLocale)
    volumeFormatter:setNumberStyle(NsNumberFormatter.Style.DecimalStyle)
    self.volumeFormatter = volumeFormatter
end

local sampleStockDateIndex = 1
local sampleStockClosePriceIndex = 5
local sampleStockVolumeIndex = 6

function YahooStockTradeInfo:parseStockInfo(stockInfoText)
    
    if stockInfoText then
        self.stockInfoText = stockInfoText
    else
        stockInfoText = self.stockInfoText
    end
    
    if stockInfoText then
        -- reset the data info
        self:clearData()
        
        local unsortedDaylyInfo = {}
        local textRange = struct.NSRange(0, #stockInfoText)
        
        stockInfoText:enumerateSubstringsInRange_options_usingBlock (textRange, NsString.Enumeration.ByLines,
                   function (lineString)
                       local lineTokens = lineString:componentsSeparatedByString(',')
                       
                       local tradingDate = self.dateFormatter:dateFromString(lineTokens[sampleStockDateIndex])
                       local closingPrice = self.priceFormatter:numberFromString (lineTokens[sampleStockClosePriceIndex])
                       local tradingVolume = self.volumeFormatter:numberFromString (lineTokens[sampleStockVolumeIndex])
                       
                       local dailyTradingInfo = class.StockDailyTradeInfo:newWithTradingInfo (tradingDate, tradingVolume, closingPrice)
                       if (dailyTradingInfo ~= nil) and (dailyTradingInfo.volume > 0) then
                           table.insert (unsortedDaylyInfo, dailyTradingInfo)
                       end

                   end)
        
        -- unsortedDaylyInfo is sorted in reverse order, with most recent day first
        local dayInfoCount = #unsortedDaylyInfo
        for dayIndex = 1, dayInfoCount do
            self._dailyTradeInfo [dayIndex] = unsortedDaylyInfo [dayInfoCount + 1 - dayIndex]
        end
        
        message.post(stockInfoUpdatedMessage, self)
    end
end

function YahooStockTradeInfo:handleCodeUpdate()
    self:parseStockInfo()
end

message.post(updateMessage)

return YahooStockTradeInfo, stockInfoUpdatedMessage