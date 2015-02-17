local NSCalendar = require 'Foundation.NSCalendar'

local StockDailyTradeInfo = class.createClass ('StockDailyTradeInfo')

function StockDailyTradeInfo:initWithTradingInfo (date, volume, closingPrice)
    self.date = date
    self.volume = volume
    self.closingPrice = closingPrice
    return self;
end

---------------------------------------
local StockTradeInfo = class.createClass ('StockTradeInfo')

function StockTradeInfo:init()
    self._dailyTradeInfo = {} -- Sorted-by-date array of StockDailyTradeInfo
end

function StockTradeInfo:dailyTradeInfoCount()
    return #self._dailyTradeInfo
end

function StockTradeInfo:dailyTradeInfoWithIndex (dayIndex)
    return self._dailyTradeInfo [dayIndex]
end

function StockTradeInfo:enumerateDailyTradeInfo (handlerFunction, startDate, endDate)
    -- function handlerFunction (tradeInfo) (return shallStop)
    -- self._dailyTradeInfo shall be sorted by date
    local isInRange = (startDate == nil)
    
    for dayIndex, dailyTradeInfo in ipairs(self._dailyTradeInfo) do

        if not isInRange then
            isInRange = (dailyTradeInfo.date:timeIntervalSinceDate(startDate) >= 0) -- is after startDate
        end
        
        if isInRange then
            if (endDate == nil) or (dailyTradeInfo.date:timeIntervalSinceDate(endDate) <= 0) then
                -- tradeInfo.date is before endDate: call handler
                local stop = handlerFunction (dailyTradeInfo)
                if stop then break end
            else
                -- tradeInfo.date is after end date
                break
            end
        end
    end
end

function StockTradeInfo:getMonthlyTradeInfo()
    if self._monthlyTradeInfo == nil then
        self._monthlyTradeInfo = {}
        
        local calendar = objc.NSCalendar:currentCalendar()
        local yearAndMonthComponents = NSCalendar.Unit.Year + NSCalendar.Unit.Month
        
        local currentMonthTradeInfo
        self:enumerateDailyTradeInfo (function (dailyTradeInfo)
                                          if currentMonthTradeInfo == nil then
                                              currentMonthTradeInfo = { date = dailyTradeInfo.date, tradingDays = 1 }
                                          else
                                              local currentMonthDateComponents = calendar:components_fromDate (yearAndMonthComponents, currentMonthTradeInfo.date)
                                              local dailyTradeDateComponents = calendar:components_fromDate (yearAndMonthComponents, dailyTradeInfo.date)
                                              if (currentMonthDateComponents:year() == dailyTradeDateComponents:year()) and
                                                 (currentMonthDateComponents:month() == dailyTradeDateComponents:month()) then
                                                  -- still in current month
                                                  currentMonthTradeInfo.tradingDays = currentMonthTradeInfo.tradingDays + 1
                                              else
                                                  -- dailyTradeInfo is for a different month
                                                  -- add the current monthly info to self._monthlyTradeInfo
                                                  table.insert (self._monthlyTradeInfo, currentMonthTradeInfo)
                                                  -- and create a new montly info for this month
                                                  currentMonthTradeInfo = { date = dailyTradeInfo.date, tradingDays = 1 }
                                              end
                                          end
                                      end)
        
        -- add the last monthly info to self._monthlyTradeInfo
        table.insert (self._monthlyTradeInfo, currentMonthTradeInfo)
    end
    
    return self._monthlyTradeInfo
end
    
local function evaluateMinMaxOfTradeInfoFieldWithName (stockTradeInfo, fieldName, startDate, endDate)
    
    local min, max
    
    stockTradeInfo:enumerateDailyTradeInfo (function (dailyTradeInfo)
                                                local currentFiledValue = dailyTradeInfo [fieldName]
                                                if currentFiledValue ~= nil then
                                                    if (min == nil) or (min > currentFiledValue) then min = currentFiledValue end
                                                    if (max == nil) or (max < currentFiledValue) then max = currentFiledValue end
                                                end
                                            end,
                                            startDate, endDate)
                                                    
     return min, max
end

StockTradeInfo:declareGetters { tradingDaysCount = 'dailyTradeInfoCount',
                                minDailyVolume = function (self)
                                                     if self._minVolume == nil then
                                                         self._minVolume, self._maxVolume = evaluateMinMaxOfTradeInfoFieldWithName(self, 'volume')
                                                     end
                                                     return self._minVolume
                                                 end,
                                maxDailyVolume = function (self)
                                                     if self._maxVolume == nil then
                                                         self._minVolume, self._maxVolume = evaluateMinMaxOfTradeInfoFieldWithName(self, 'volume')
                                                     end
                                                     return self._maxVolume
                                                 end,
                                minClosingPrice = function (self)
                                                     if self._minClosingPrice == nil then
                                                         self._minClosingPrice, self._maxClosingPrice = evaluateMinMaxOfTradeInfoFieldWithName(self, 'closingPrice')
                                                     end
                                                     return self._minClosingPrice
                                                 end,
                                maxClosingPrice = function (self)
                                                     if self._maxClosingPrice == nil then
                                                         self._minClosingPrice, self._maxClosingPrice = evaluateMinMaxOfTradeInfoFieldWithName(self, 'closingPrice')
                                                     end
                                                     return self._maxClosingPrice
                                                 end,
                                monthlyTradeInfo = 'getMonthlyTradeInfo',
                              }

return StockTradeInfo
