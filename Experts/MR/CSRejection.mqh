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

class RejectionSignal : public SignalBase {
 public:
   MqlRates bar;
   Line KeyLevel;

   RejectionSignal(MqlRates &rate, Line &keyLevel) {
      bar = rate;
      KeyLevel = keyLevel;
   }

   virtual string Name() {
      return type == SIGNAL_TYPE_BULLISH ? "BULLISH_REJECTION" : "BEARISH_REJECTION";
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
         int res = checkRejectionCross(tf);
         if (res != 0) {
            time = bar.time;
            price = bar.close;
            if (res == 1) {
               type = SIGNAL_TYPE_BULLISH;
            } else if (res == -1) {
               type = SIGNAL_TYPE_BEARISH;
            }
            ret = true;
         }
      } else {
         int res = checkRejection();
         if (res != 0) {
            time = bar.time;
            price = bar.close;
            if (res == 1) {
               type = SIGNAL_TYPE_BULLISH;
            } else if (res == -1) {
               type = SIGNAL_TYPE_BEARISH;
            }
            ret = true;
         }
      }
      return ret;
   }

 private:
   int checkRejection() {
      int ret = 0;
      double range = bar.high - bar.low;
      double lwick = bar.close < bar.open ? bar.close - bar.low : bar.open - bar.low;
      double hwick = bar.close < bar.open ? bar.high - bar.open : bar.high - bar.close;

      if (range > 0) {
         if (lwick / range >= 0.6) {
            ret = 1;
         }
         if (hwick / range >= 0.6) {
            ret = -1;
         }
      }
      return ret;
   }

   int checkRejectionCross(ENUM_TIMEFRAMES tf) {
      int ret = 0;
      if (isInFrame(tf, bar, KeyLevel)) {
         int flag = checkRejection();
         if (flag != 0) {
            double currLevel = calculateY(bar.time, KeyLevel.x1, KeyLevel.y1, KeyLevel.x2, KeyLevel.y2);
            double avgRange = getAverageRange(tf, 100);
            if (flag == 1) {
               if (bar.low <= currLevel+avgRange/4 && bar.high >= currLevel+avgRange/4) {
                  ret = 1;
               }
            } else if (flag == -1) {
               if (bar.high >= currLevel-avgRange/4 && bar.low <= currLevel-avgRange/4) {
                  ret = -1;
               }
            }
         }
      }
      return ret;
   }
};
//+------------------------------------------------------------------+
