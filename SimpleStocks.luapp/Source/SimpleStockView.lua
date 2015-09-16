local CgContext = require 'CoreGraphics.CGContext'
local CgPath = require 'CoreGraphics.CGPath'
local CgGradient = require 'CoreGraphics.CGGradient'
local CgColorSpace = require 'CoreGraphics.CGColorSpace'
local UiGraphics = require 'UIKit.UIGraphics'

require 'StockTradeInfo'

local UIView = objc.UIView
local UIColor = objc.UIColor
local whiteColor = UIColor.whiteColor
local CGRect = struct.CGRect

local floor = math.floor

local SimpleStockView = class.createClass ("SimpleStockView", UIView) 

local UIBezierPath = objc.UIBezierPath

function SimpleStockView:topClipPathFromDataInRect (rect)
    
    local path = UIBezierPath:bezierPath()
    path:appendPath (self:pathForPriceDataInRect(rect))
    local rectMaxX = rect:getMaxX()
    local rectMinX = rect:getMinX()
    local rectMinY = rect:getMinY()
    path:addLineToPoint { x = rectMaxX, y = path.currentPoint.y }
    path:addLineToPoint { x = rectMaxX, y = rectMinY }
    path:addLineToPoint { x = rectMinX, y = rectMinY }
    path:addLineToPoint { x = rectMinX, y = self.initialDataPoint.y }
    path:addLineToPoint (self.initialDataPoint)
    path:closePath()
    
    return path
end

function SimpleStockView:bottomClipPathFromDataInRect (rect)
    
    local path = UIBezierPath:bezierPath()
    path:appendPath (self:pathForPriceDataInRect(rect))
    local rectMaxX = rect:getMaxX()
    local rectMinX = rect:getMinX()
    local rectMaxY = rect:getMaxY()
    path:addLineToPoint { x = rectMaxX, y = path.currentPoint.y }
    path:addLineToPoint { x = rectMaxX, y = rectMaxY }
    path:addLineToPoint { x = rectMinX, y = rectMaxY }
    path:addLineToPoint { x = rectMinX, y = self.initialDataPoint.y }
    path:addLineToPoint (self.initialDataPoint)
    path:closePath()
    
    return path
end

-- Draw closing data
local priceLineWidth = 1.0

--The path for the closing data, this is used to draw the graph, and as part of the top and bottom clip paths
function SimpleStockView:pathForPriceDataInRect(rect)
    
    local tradingDays = self.dataSource.tradingDaysCount
    local maxClosePrice = self.dataSource.maxClosingPrice
    local minClosePrice = self.dataSource.minClosingPrice
    
    --[[ local priceLineWidth = priceLineWidth
    if math.min(rect.size.width, rect.size.height) < 500 then
        priceLineWidth = math.floor(priceLineWidth * 0.6)
    end]]
    
    local path = UIBezierPath:bezierPath()
    path:setLineWidth(priceLineWidth)
    path:setLineJoinStyle(CgPath.CGLineJoin.Round)
    path:setLineCapStyle(CgPath.CGLineCap.Round)
    
    rect = rect:inset(priceLineWidth / 2, priceLineWidth) -- Inset so the path does not ever go beyond the frame of the graph.
    
    local rectMinX = rect:getMinX()
    local rectMaxY = rect:getMaxY()
    local horizontalSpacing = rect.size.width / tradingDays
    local verticalScale = rect.size.height / (maxClosePrice - minClosePrice)

    local closingPrice = self.dataSource:dailyTradeInfoWithIndex(1).closingPrice
    self.initialDataPoint = { x = rectMinX, y = rectMaxY - (closingPrice - minClosePrice) * verticalScale }
    path:moveToPoint(self.initialDataPoint)
    
    for dayIndex = 2, tradingDays-1 do 
        closingPrice = self.dataSource:dailyTradeInfoWithIndex(dayIndex).closingPrice
        path:addLineToPoint { x = rectMinX + dayIndex * horizontalSpacing, y = rectMaxY - (closingPrice - minClosePrice) * verticalScale }
    end
    
    closingPrice = self.dataSource:dailyTradeInfoWithIndex(tradingDays).closingPrice
    path:addLineToPoint { x = rect:getMaxX(), y = rectMaxY - (closingPrice - minClosePrice) * verticalScale }
    
    return path;
end

function SimpleStockView:drawPriceDataInRect(rect)
    whiteColor:setStroke()
    local path = self:pathForPriceDataInRect(rect)
    path:stroke()
end

local underPricePatternLineStep = 4
local underPricePatternLineWidth = 2
local underPricePatternCellSize = 64

function SimpleStockView:drawLinePatterUnderPriceData(rect, shouldCLip)
    
    local ctx = UiGraphics.GetCurrentContext()
    
    if shouldCLip then
        CgContext.SaveGState(ctx)
        local clipPath = self:bottomClipPathFromDataInRect(rect)
        clipPath:addClip()
    end
    
    local alphaMax = 0.8
    local alphaMin = 0.1
    
    local rectMinX = rect:getMinX()
    local rectMaxX = rect:getMaxX()
    local rectMinY = rect:getMinY()
    local rectMaxY = rect:getMaxY()

    local path = UIBezierPath:bezierPath()
    path:setLineWidth(underPricePatternLineWidth)
    path:moveToPoint { x = 0.0, y = rectMinY + 0.5 }
    path:addLineToPoint { x = rectMaxX, y = rectMinY + 0.5}
    
    local translationStep = underPricePatternLineWidth * underPricePatternLineStep
    local alphaStep = (alphaMax - alphaMin) / (rect.size.height / translationStep)
    
    local alpha = alphaMax
    local lineColor = UIColor:colorWithWhite_alpha (0.7, alpha)
    
    CgContext.SaveGState(ctx)
    local translation = rectMinY
    while translation < rectMaxY do
        lineColor:setStroke()
        path:stroke()
        CgContext.TranslateCTM (ctx, 0.0, translationStep)
        translation = translation + translationStep
        alpha = alpha - alphaStep
        lineColor = lineColor:colorWithAlphaComponent(alpha)
    end
    CgContext.RestoreGState(ctx)
    
    if shouldCLip then
        CgContext.RestoreGState(ctx)
    end
end

local function createGradientInRGBSpaceWithColorComponents (gradientColorComponents, locations)
    local colorSpace = CgColorSpace.CreateDeviceRGB()
    local gradient = CgGradient.CreateWithColorComponents(colorSpace, gradientColorComponents, locations, #locations)
    CgColorSpace.Release(colorSpace)
    return gradient
end

 -- This is the blue gradient used behind the 'programmer art' pattern
local blueBlendGradient = createGradientInRGBSpaceWithColorComponents ({ 38.0 / 255.0, 61.0 / 255.0, 114.0 / 255.0, 1.0,
                                                                         10.0 / 255.0, 23.0 / 255.0, 94.0 / 255.0, 1.0 },
                                                                       { 0.10, 
                                                                         0.90 })

local function drawLine (startPoint, endPoint, lineWidth)
    local path = UIBezierPath:bezierPath()
    if lineWidth then
        path:setLineWidth(lineWidth)
    end
    path:moveToPoint (startPoint)
    path:addLineToPoint (endPoint)
    path:stroke()
end

local function drawRadialGradient (gradient, size, center)
    local ctx = UiGraphics.GetCurrentContext()
    local startRadius = 0.0
    local endRadius = 0.85 * (size.width^2 + size.height^2)^0.5 / 2
    CgContext.DrawRadialGradient(ctx, gradient, center, startRadius, center, endRadius, CgGradient.Draws.AfterEndLocation)
end

local function underPriceDataPatternImage (patternSize)
    
    UiGraphics.BeginImageContextWithOptions (patternSize, true, 0.0)
    
    drawRadialGradient (blueBlendGradient, patternSize, { x = floor(patternSize.width / 2), y = floor (patternSize.height / 2) })
    
    local lineWidth = 2
    local lineColor = UIColor:colorWithRed_green_blue_alpha (211.0 / 255.0, 218.0 / 255.0, 182.0 / 255.0, 1.0)
    lineColor:setStroke();
    drawLine ( { x = 0.0, y = 0.0 }, { x = floor(patternSize.width), y = floor (patternSize.height) }, lineWidth)
    drawLine ( { x = 0.0, y = floor (patternSize.height) }, { x = floor(patternSize.width), y = 0.0}, lineWidth)
    
    local patternImage = UiGraphics.GetImageFromCurrentImageContext()
    
    UiGraphics.EndImageContext()
    
    return patternImage
end

function SimpleStockView:drawArtPatternUnderPriceData (rect, underPricePatternCellSize)
    
    local fillPattern = UIColor:colorWithPatternImage (underPriceDataPatternImage { width = underPricePatternCellSize, height = underPricePatternCellSize })
    fillPattern:setFill()
    
    local pathToFill = self:bottomClipPathFromDataInRect(rect)
    pathToFill:fill()
end

function SimpleStockView:drawImageUnderPriceData (rect, imageResourceName)
    local ctx = UiGraphics.GetCurrentContext()
    CgContext.SaveGState(ctx)
    local clipPath = self:bottomClipPathFromDataInRect(rect)
    clipPath:addClip()
    local resourceImage = getResource (imageResourceName, 'public.image', function () self:setNeedsDisplay() end)
    if (resourceImage) then 
        resourceImage:drawInRect (rect)
    end
    CgContext.RestoreGState(ctx)
end

local gridColor = UIColor:colorWithRed_green_blue_alpha (154.0 / 255.0, 156.0 / 255.0, 216.0 / 255.0, 1.0)

-- Draw the horizontal grid clipped by the price data
function SimpleStockView:drawHorizontalGridInRect (rect)
    local ctx = UiGraphics.GetCurrentContext()
    CgContext.SaveGState(ctx)
    local clipPath = self:topClipPathFromDataInRect(rect)
    clipPath:addClip()
    
    local gridLines = 5
    
    local path = UIBezierPath:bezierPath()
    path:setLineWidth (1.0)
    path:moveToPoint { x =  rect:getMinX(), y = floor(rect:getMinY() + 0.5) }
    path:addLineToPoint {x =  rect:getMaxX(), y = floor(rect:getMinY() + 0.5) }
    path:setLineDash_count_phase ({5.0, 5.0}, 2, 0.0)
    gridColor:setStroke()
    
    path:stroke()
    for i = 1, gridLines do
        CgContext.TranslateCTM (ctx, 0.0, floor(rect.size.height / gridLines + 0.5))
        path:stroke()
    end
    
    CgContext.RestoreGState(ctx)
end

-- Draw the vertical grid by month
function SimpleStockView:drawVerticalGridInRect (pricesRect, volumeRectHeight)
    
    local dataCount = self.dataSource.tradingDaysCount
    local monthlyTradeInfo = self.dataSource.monthlyTradeInfo

    local rectMinX = pricesRect:getMinX()
    
    local gridLine = UIBezierPath:bezierPath()
    gridLine:setLineWidth (2.0)
    gridLine:moveToPoint    { x = rectMinX, y = pricesRect:getMinY()  }
    gridLine:addLineToPoint { x = rectMinX, y = pricesRect:getMaxY() + volumeRectHeight }
    
    gridColor:setStroke()
    -- gridLine:stroke()
        
    local ctx = UiGraphics.GetCurrentContext()
    CgContext.SaveGState(ctx)
    
    local horizontalDaySpacing = pricesRect.size.width / dataCount
    
    for monthIndex = 1, #monthlyTradeInfo - 1 do
        local lineOffset = floor(horizontalDaySpacing * monthlyTradeInfo[monthIndex].tradingDays)
        CgContext.TranslateCTM (ctx, lineOffset, 0.0)
        gridLine:stroke()
    end
    
    CgContext.RestoreGState(ctx)
    
    --[[ -- Stroke last vertical line
    CgContext.SaveGState(ctx)
    CgContext.TranslateCTM (ctx, pricesRect:getMaxX(), 0.0)
    gridLine:stroke()
    CgContext.RestoreGState(ctx)]]
end

local backgroundGradient = createGradientInRGBSpaceWithColorComponents 
                           ({ 148.0 / 255.0, 161.0 / 255.0, 214.0 / 255.0, 1.0,
                              33.0 / 255.0, 47.0 / 255.0, 113.0 / 255.0, 1.0,
                              20.0 / 255.0, 33.0 / 255.0, 104.0 / 255.0, 1.0,
                              120.0 / 255.0, 33.0 / 255.0, 104.0 / 255.0, 1.0 },
                            {0.0, 0.5, 0.5, 1.0})

function SimpleStockView:drawBackgroundGradient()
    local ctx = UiGraphics.GetCurrentContext()
    local startPoint = { x = 0.0, y = 0.0 }
    local endPoint   = { x = 0.0, y = self:bounds().size.height }
    CgContext.DrawLinearGradient (ctx, backgroundGradient, startPoint, endPoint, 0)
end

local volumeLineWidthRatio = 0.4

function SimpleStockView:drawVolumeDataInRect(volumeRect)

    local tradingDays = self.dataSource.tradingDaysCount

    local minVolume = 0--self.dataSource.minDailyVolume
    local maxVolume = self.dataSource.maxDailyVolume
    
    local rectMinX = volumeRect:getMinX()
    local rectMaxY = volumeRect:getMaxY()
    local horizontalSpacing = volumeRect.size.width / tradingDays
    local verticalScale = volumeRect.size.height / (maxVolume - minVolume)
    
    local volumeLineWidth =  horizontalSpacing * volumeLineWidthRatio
    
    local ctx = UiGraphics.GetCurrentContext()
    CgContext.SaveGState(ctx)
    
    whiteColor:setStroke()
    
    for dayIndex = 1, tradingDays do 
        local path = UIBezierPath:bezierPath()
        path:setLineWidth(volumeLineWidth)
        local tradingVolume = self.dataSource:dailyTradeInfoWithIndex(dayIndex).volume
        local dayVolumeX = rectMinX + volumeLineWidth / 2 + (dayIndex - 1) * horizontalSpacing
        path:moveToPoint { x = dayVolumeX, y = rectMaxY }
        path:addLineToPoint { x = dayVolumeX, y = rectMaxY - (tradingVolume - minVolume) * verticalScale }
        path:stroke()
    end
    
    CgContext.RestoreGState(ctx)
end

-- Draw Month Names

local calendar = objc.NSCalendar:currentCalendar()
local dateFormatter = objc.NSDateFormatter:new()
dateFormatter:setDateFormat (objc.NSDateFormatter:dateFormatFromTemplate_options_locale ('MMMM', 0, objc.NSLocale:currentLocale()))

local shadowHeight = 2.0

local pi = math.pi
function SimpleStockView:drawMonthNamesTextUnderVolumeRect(volumeRect, monthNamesHeight)
    
    local dataCount = self.dataSource.tradingDaysCount
    local monthlyTradeInfo = self.dataSource.monthlyTradeInfo
    
    local monthAverageWidth = volumeRect.size.width / #monthlyTradeInfo
    local monthNameFontSize
    local monthNameRotationAngle
    if monthAverageWidth > 5 * monthNamesHeight then
        monthNameFontSize = monthNamesHeight * 0.8
    else
        monthNameFontSize = monthAverageWidth / 6
        
        if monthNameFontSize < 10 then
            monthNameFontSize = 10
            monthNameRotationAngle = -pi / 12
        end
    end
    local monthNameFont = objc.UIFont:boldSystemFontOfSize (monthNameFontSize)
    
    whiteColor:setFill()
    
    local ctx = UiGraphics.GetCurrentContext()
    CgContext.SaveGState(ctx)
    CgContext.TranslateCTM(ctx, volumeRect.origin.x, volumeRect:getMaxY())
    
    CgContext.SetShadowWithColor(ctx, { width = 1.0, height = -shadowHeight}, 0.0, UIColor:darkGrayColor().CGColor)
    
    local tradingDaySpacing = volumeRect.size.width / dataCount
    
    for monthIndex = 1, #monthlyTradeInfo do
        
        if monthIndex > 1 then
            -- Move to the end of the previous month
            local linePosition = floor(tradingDaySpacing * monthlyTradeInfo[monthIndex - 1].tradingDays)
            CgContext.TranslateCTM(ctx, linePosition, 0.0)
        end
        
        if monthNameRotationAngle then
            CgContext.SaveGState(ctx)
            CgContext.TranslateCTM(ctx, 0, monthNamesHeight / 2)
            CgContext.RotateCTM(ctx, monthNameRotationAngle)
        end
        
        local monthGraphWidth = tradingDaySpacing * monthlyTradeInfo[monthIndex].tradingDays
        local date = monthlyTradeInfo[monthIndex].date
        local monthName = dateFormatter:stringFromDate(date)
        local monthSize = monthName:sizeWithFont(monthNameFont)
        if monthNameRotationAngle or (monthSize.width <= monthGraphWidth) then
            local monthRect = CGRect((monthGraphWidth - monthSize.width) / 2, 0, monthSize.width, monthSize.height)
            monthName:drawInRect_withFont(monthRect, monthNameFont)
        end
        
        if monthNameRotationAngle then
            CgContext.RestoreGState(ctx)
        end
    end
    
    CgContext.RestoreGState(ctx)
end

local graphMargin = 0
local volumeGraphicTopMargin = 15
local volumeGraphicHeightRatio = 0.14
local artPatternCellsHCount = 7

priceLineWidth = 3.0

function CGRect:translate (dx, dy)
    self.origin.x = self.origin.x + dx
    self.origin.y = self.origin.y + dy
end

local min = math.min
local max = math.max

function SimpleStockView:drawRect (rect)
    
    local bounds = self.bounds
    bounds = bounds:inset (graphMargin, graphMargin)
    
    print ("In drawRect", bounds)
    
    local topReservedHeight = 0.08 * bounds.size.height
    local volumeGraphicHeight = volumeGraphicHeightRatio * bounds.size.height
    local monthNamesHeight = min (max (0.3 * volumeGraphicHeight, 0), 100)
    
    local pricesRect = CGRect (bounds.origin.x, bounds.origin.y + topReservedHeight, 
                               bounds.size.width, 
                               bounds.size.height - (topReservedHeight + volumeGraphicTopMargin + 
                                                     volumeGraphicHeight + monthNamesHeight))
    local volumeRect = CGRect (pricesRect:getMinX(), pricesRect:getMaxY() + volumeGraphicTopMargin,
                               pricesRect.size.width, volumeGraphicHeight)
    
    -- Background and grid
    self:drawBackgroundGradient ()
    self:drawVerticalGridInRect (pricesRect, volumeGraphicHeight + volumeGraphicTopMargin)
    self:drawHorizontalGridInRect (pricesRect)
    
    -- Prices Graph and background
    local patternCellSize = math.min (bounds.size.width, bounds.size.height) / artPatternCellsHCount
    -- self:drawArtPatternUnderPriceData (pricesRect, patternCellSize)
    -- self:drawImageUnderPriceData (pricesRect, 'Background-image')
    self:drawLinePatterUnderPriceData (pricesRect, true)
    self:drawPriceDataInRect (pricesRect)
    
    -- Volumes and Months names
    self:drawVolumeDataInRect (volumeRect)
    self:drawMonthNamesTextUnderVolumeRect (volumeRect, monthNamesHeight)
end

return SimpleStockView