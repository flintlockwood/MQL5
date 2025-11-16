//+------------------------------------------------------------------+
//|                                                    CSPattern.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

#include "SignalBase.mqh"
#include "Common.mqh"

class TweezerSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      DvpRates dvp;
      Line KeyLevel;
      
      TweezerSignal(MqlRates &rates[], Line &keyLevel) {
         firstBar = rates[0];
         secondBar = rates[1];
         KeyLevel = keyLevel;
      }

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_TWEEZER" : "BEARISH_TWEEZER";
      }
      
      virtual string ToString() {
         return StringFormat("%s, #%s, %s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             _Symbol,
                             Name(),
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
      
      virtual bool CheckSignal(ENUM_TIMEFRAMES tf) {
         bool ret = false;
         if (KeyLevel.x1 > 0 && KeyLevel.x2 > 0 && KeyLevel.x2 > KeyLevel.x1) {
            int res = checkTweezerCross(tf);
            if (res != 0) {
               time = secondBar.time;
               price = secondBar.close;
               if (res == 1) {
                  type = SIGNAL_TYPE_BULLISH;
               }
               else if (res == -1) {
                  type = SIGNAL_TYPE_BEARISH;
               }
               ret = true;
            }
         }
         else {
            int res = checkTweezer();
            if (res != 0) {
               time = secondBar.time;
               price = secondBar.close;
               if (res == 1) {
                  type = SIGNAL_TYPE_BULLISH;
               }
               else if (res == -1) {
                  type = SIGNAL_TYPE_BEARISH;
               }
               ret = true;
            }
         }
         return ret;
      }
      
   private:
      int checkTweezer() {
         int ret = 0;
         double b1 = firstBar.close - firstBar.open;
         double b2 = secondBar.close - secondBar.open;
         double range = MathAbs(secondBar.high - secondBar.low);
         double ratio = 0;
         if (range != 0) {
            ratio = MathAbs(b2) / range;
         }
         double r = NormalizeDouble(0.01 * range, _Digits);
         
         if (secondBar.low >= firstBar.low && secondBar.low <= (firstBar.low+r)) {
            ret = 1;
         }
         else if (secondBar.high <= firstBar.high && secondBar.high >= (firstBar.high-r)) {
            ret = -1;
         }
         return ret;
      }
      
      int checkTweezerCross(ENUM_TIMEFRAMES tf) {
         int ret = 0;
         if (isInFrame(tf, firstBar, KeyLevel) || isInFrame(tf, secondBar, KeyLevel)) {
            int flag = checkTweezer();
            if (flag != 0) {
               double firstMidBody = MathAbs(firstBar.close - firstBar.open) / 2;
               double secondMidBody = MathAbs(secondBar.close - secondBar.open) / 2;
               double firstLowerBody = firstBar.close < firstBar.open ? firstBar.close : firstBar.open;
               double secondLowerBody = secondBar.close < secondBar.open ? secondBar.close : secondBar.open;
               double firstMidLevel = firstLowerBody + firstMidBody;
               double secondMidLevel = secondLowerBody + secondMidBody;
               double currLevel = calculateY(secondBar.time, KeyLevel.x1, KeyLevel.y1, KeyLevel.x2, KeyLevel.y2);
               if ((firstMidLevel >= currLevel || secondMidLevel >= currLevel) && flag == 1) {
                  ret = 1;
               }
               else if ((firstMidLevel <= currLevel || secondMidLevel <= currLevel) && flag == -1) {
                  ret = -1;
               }
            }
         }
         return ret;
      }
};