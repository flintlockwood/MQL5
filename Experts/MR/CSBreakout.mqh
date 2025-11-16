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

class BreakoutSignal : public SignalBase
{
   public:
      MqlRates bar;
      Line KeyLevel;
      
      BreakoutSignal(MqlRates &rate, Line &keyLevel) {
         bar = rate;
         KeyLevel = keyLevel;
      }

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_BREAKOUT" : "BEARISH_BREAKOUT";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
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
            int res = checkBreakoutCross(tf);
            if (res != 0) {
               time = bar.time;
               price = bar.close;
               timeframe = tf;
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
      int checkBreakoutCross(ENUM_TIMEFRAMES tf) {
         int ret = 0;
         if (isInFrame(tf, bar, KeyLevel)) {
            double midBody = MathAbs(bar.close - bar.open) / 2;
            double lowerBody = bar.close < bar.open ? bar.close : bar.open;
            double midBodyLevel = lowerBody + midBody;
            double currLevel = calculateY(bar.time, KeyLevel.x1, KeyLevel.y1, KeyLevel.x2, KeyLevel.y2);
            if (KeyLevel.type == SOR_SUPPORT) {
               if (midBodyLevel <= currLevel && bar.high >= currLevel) {
                  ret = -1;
               }
            }
            else if (KeyLevel.type == SOR_RESISTANCE) {
               if (midBodyLevel >= currLevel && bar.low <= currLevel) {
                  ret = 1;
               }
            }
         }
         return ret;
      }
};