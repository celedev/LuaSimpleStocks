# Simple Stocks

SimpleStock defines a custom view and draws a complex stock history graphics in this View using CoreGraphics. 

![SimpleStock screen capture](readme-image1.png)

Points of interest of this sample app include:

- It illustrates how straightforward it is to call C-based APIs like CoreGraphics from Lua in CodeFlow (see Lua module *SimpleStockView*). Comment / uncomment various calls in method `drawRect` of this class to quickly experiment in real time what each one of them do!
- The application's data model (the stocks info) is stored in a Lua table and the generation of this table is a mix of Lua standard functions and iOS SDK calls (the data model is defined in Lua Modules *StockTradeInfo* and *YahooStockTradeInfo*).
- The data model and the display are updated automatically if the stock information changes, but also if the code of specific modules is changed. Have a look at *StockViewController* and *YahooStockTradeInfo* to see how this is done.
- Running SimpleStocks on multiple devices with various screen sizes (e.g. an iPhone and an iPad), or in different orientations is a good way to experience the benefits of multi-devices live coding with CodeFlow.
- On the Objective-C side, note that the creation of the application's root view controller is simply done by creating an instance of the Lua class returned when loading Lua module *StockViewController*. This is an example of how easy it is to use a Lua class from Objective-C.

## Configuration required

A Mac with Celedev CodeFlow version 0.9.18 or later.  
You can download CodeFlow from <https://www.celedev.com/en/support/#downloads> (registration required).

Works on iPhone or iPad, running iOS 7 or later.

## How to use this code sample

1. Open the CodeFlow project for this sample application.  
  This will automatically update the associated Xcode project, so that paths and other build settings are correctly set for your environment.

2. Open the associated Xcode project. You can do this in CodeFlow with the menu command `Program -> Open Xcode Project`.

3. Run the application on a device or in the simulator.

4. In CodeFlow, select the application in the `Target` popup menu in the project window toolbar. The app stops on a breakpoint at the first line of the Lua program.

5. Click on the `Continue` button in the toolbar (or use the CodeFlow debugger for stepping in the program) 

6. Enjoy the power of live coding with CodeFlow

## Troubleshooting

- **Some libraries / header files in the sample app Xcode project are missing**

  **⇒ Fix**: open the corresponding CodeFlow project, and CodeFlow will update the associated Xcode project, so that paths and libraries are correctly set.

- **Link errors (missing symbols) occur when I compile the Xcode project**

  **Most probable cause**: if you are using Xcode 5 (and thus iOS 7.1 SDK), these errors occur because the sample app is configured for the iOS 8 SDK.

  **⇒ Fix**: In the CodeFlow project, use the bindings library for the iOS 7.1 SDK in replacement of the one for the iOS 8 SDK
	- Download [CodeFlow bindings for iOS 7.1 SDK](https://www.celedev.com/en/support/#downloads), and double-click on the .luabindings library file to install it in codeFlow; 
	- If needed, select the iOS 7.1 SDK library in CodeFlow project (menu `Program -> Select SDK Library -> iOS 7.1 SDK` or using the contextual menu on the current iOS External Lib);
	- CodeFlow will then update the associated Xcode project so that it links with the iOS 7.1 SDK bindings libraries.

## License

This application is provided under the MIT License (MIT)

Copyright (c) 2014-2015 Celedev.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
