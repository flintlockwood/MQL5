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

class SndSignal : public SignalBase
{
   public:
      MqlRates bar1;
      MqlRates bar2;
      MqlRates bar3;
      MqlRates bar4;
      MqlRates bar5;
      MqlRates bar6;
      MqlRates bar7;
      Line KeyLevel;
      
      SndSignal(MqlRates &rates[]) {
         bar1 = rates[0];
         bar2 = rates[1];
         bar3 = rates[2];
         bar4 = rates[3];
         bar5 = rates[4];
         bar6 = rates[5];
         bar7 = rates[6];
      }

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_SND" : "BEARISH_SND";
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
         return type == SIGNAL_TYPE_BULLISH ? bar4.low : bar4.high;
      }
      
      virtual double GetStopLoss() {
         return type == SIGNAL_TYPE_BULLISH ? GetEntry() - 100*_Point : GetEntry() + 100*_Point;
      }
      
      virtual double GetTakeProfit() {
         return type == SIGNAL_TYPE_BULLISH ? GetEntry() + 100*_Point : GetEntry() - 100*_Point;
      }
      
      virtual bool CheckSignal(ENUM_TIMEFRAMES tf) {
         bool ret = false;
         int res = checkSnd(tf, 24);
         if (res != 0) {
            time = bar4.time;
            if (res == 1) {
               type = SIGNAL_TYPE_BULLISH;
               price = bar4.low;
            }
            else if (res == -1) {
               type = SIGNAL_TYPE_BEARISH;
               price = bar4.high;
            }
            ret = true;
         }
         return ret;
      }
      
   private:
      int checkSnd(ENUM_TIMEFRAMES tf, int period) {
         int ret = 0;
         
         double bodyratio4 = MathAbs(bar4.open-bar4.close) / (bar4.high-bar4.low);
         double bodyratio5 = MathAbs(bar5.open-bar5.close) / (bar5.high-bar5.low);
         double bodyratio6 = MathAbs(bar6.open-bar6.close) / (bar6.high-bar6.low);
         double bodyratio7 = MathAbs(bar7.open-bar7.close) / (bar7.high-bar7.low);
         
         double avgrange = getAverageRange(tf, period);
         double sdrange = getSdRange(tf, period);
         bool bodylong4 = (bar4.high-bar4.low) > avgrange+sdrange && bodyratio4 >= 0.618;
         bool bodylong5 = (bar5.high-bar5.low) > avgrange+sdrange && bodyratio5 >= 0.618;
         bool bodylong6 = (bar6.high-bar6.low) > avgrange+sdrange && bodyratio6 >= 0.618;
         bool bodylong7 = (bar7.high-bar7.low) > avgrange+sdrange && bodyratio7 >= 0.618;
         
         if (bodylong4 || bodylong5 || bodylong6 || bodylong7) {
            // check for bullish engulfing
            if (bar1.low > bar2.low && bar2.low > bar3.low && bar3.low > bar4.low && bar4.low < bar5.low && bar5.low < bar6.low && bar6.low < bar7.low) {
               ret = 1;
            }
            // check for bearish engulfing
            else if (bar1.high < bar2.high && bar2.high < bar3.high && bar3.high < bar4.high && bar4.high > bar5.high && bar5.high > bar6.high && bar6.high > bar7.high) {
               ret = -1;
            }
         }
         return ret;
      }
      
      int checkSndCross(ENUM_TIMEFRAMES tf) {
         int ret = 0;
         return ret;
      }
};