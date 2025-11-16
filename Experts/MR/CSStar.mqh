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

class StarSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      MqlRates thirdBar;
      DvpRates dvp;
      Line KeyLevel;
      
      StarSignal(MqlRates &rates[], Line &keyLevel) {
         firstBar = rates[0];
         secondBar = rates[1];
         thirdBar = rates[2];
         KeyLevel = keyLevel;
      }

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_STAR" : "BEARISH_STAR";
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
            int res = checkStarCross(tf);
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
            int res = checkStar();
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
      int checkStar() {
         int ret = 0;
   
         bool bodyWhite0 = firstBar.close > firstBar.open;
         bool bodyWhite1 = secondBar.close > secondBar.open;
         bool bodyWhite2 = thirdBar.close > thirdBar.open;
         double bodyMax0 = firstBar.close > firstBar.open ? firstBar.close : firstBar.open;
         double bodyMin0 = firstBar.close < firstBar.open ? firstBar.close : firstBar.open;
         double bodyMax1 = secondBar.close > secondBar.open ? secondBar.close : secondBar.open;
         double bodyMin1 = secondBar.close < secondBar.open ? secondBar.close : secondBar.open;
         double bodyMax2 = thirdBar.close > thirdBar.open ? thirdBar.close : thirdBar.open;
         double bodyMin2 = thirdBar.close < thirdBar.open ? thirdBar.close : thirdBar.open;
         double body0 = MathAbs(firstBar.close - firstBar.open);
         double body1 = MathAbs(secondBar.close - secondBar.open);
         double body2 = MathAbs(thirdBar.close - thirdBar.open);
         double range0 = MathAbs(firstBar.high - firstBar.low);
         double range1 = MathAbs(secondBar.high - secondBar.low);
         double range2 = MathAbs(thirdBar.high - thirdBar.low);
         double ratio0 = 0;
         if (range0 != 0) {
            ratio0 = body0 / range0;
         }
         double ratio1 = 0;
         if (range1 != 0) {
            ratio1 = body1 / range1;
         }
         double ratio2 = 0;
         if (range2 != 0) {
            ratio2 = body2 / range2;
         }
         
         if (ratio0 >= 0.8 && ratio1 <= 0.2) {
            // check for bullish morning star
            if (!bodyWhite0 && bodyWhite2 && bodyMax1 < bodyMin0 && bodyMax1 < bodyMin2 && thirdBar.close > (firstBar.close+0.5*body0)) {
               price = thirdBar.low;
               time = thirdBar.time;
               type = SIGNAL_TYPE_BULLISH;
               ret = 1;
            }
            // check for bearish evening star
            else if (bodyWhite0 && !bodyWhite2 && bodyMin1 > bodyMax0 && bodyMin1 > bodyMax2 && thirdBar.close < (firstBar.close-0.5*body0)) {
               price = thirdBar.high;
               time = thirdBar.time;
               type = SIGNAL_TYPE_BEARISH;
               ret = -1;
            }
         }
         return ret;
      }
      
      int checkStarCross(ENUM_TIMEFRAMES tf) {
         int ret = 0;
         if (isInFrame(tf, firstBar, KeyLevel) || isInFrame(tf, secondBar, KeyLevel)) {
            int flag = checkStar();
            if (flag != 0) {
               double midBody = MathAbs(secondBar.close - secondBar.open) / 2;
               double lowerBody = secondBar.close < secondBar.open ? secondBar.close : secondBar.open;
               double midLevel = lowerBody + midBody;
               double currLevel = calculateY(secondBar.time, KeyLevel.x1, KeyLevel.y1, KeyLevel.x2, KeyLevel.y2);
               double avgRange = getAverageRange(tf, 100);
               if (thirdBar.low >= currLevel-avgRange/4 && thirdBar.open <= currLevel+avgRange/4 && flag == 1) {
                  ret = 1;
               }
               else if (thirdBar.high >= currLevel-avgRange/4 && thirdBar.open <= currLevel+avgRange/4 && flag == -1) {
                  ret = -1;
               }
            }
         }
         return ret;
      }
};