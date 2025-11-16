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

class FtrSignal : public SignalBase
{
   public:
      MqlRates bar1;
      MqlRates bar2;
      MqlRates bar3;
      MqlRates bar4;
      MqlRates bar5;
      DvpRates dvp;
      Line KeyLevel;
      ulong ticket;
      
      FtrSignal(MqlRates &rates[]) {
         if (ArraySize(rates) >= 2) {
            bar1 = rates[0];
            bar2 = rates[1];
            patterType = "P2";
         }
         if (ArraySize(rates) >= 4) {
            bar3 = rates[2];
            bar4 = rates[3];
            patterType = "P4";
         }
         if (ArraySize(rates) == 5) {
            bar5 = rates[4];
            patterType = "P5";
         }
         //KeyLevel = keyLevel;
      }

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_FTR" : "BEARISH_FTR";
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
         return patterType == "P4" ? bar4.close : bar5.close;
      }
      
      virtual double GetStopLoss() {
         if (patterType == "P4") {
            return type == SIGNAL_TYPE_BULLISH ? bar3.low-15*_Point : bar3.high+15*_Point;
         }
         else if (patterType == "P5") {
            return type == SIGNAL_TYPE_BULLISH ? bar3.low-15*_Point : bar3.high+15*_Point;
         }
         else if (patterType == "P2") {
            return type == SIGNAL_TYPE_BULLISH ? bar1.low-15*_Point : bar1.high+15*_Point;
         }
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return type == SIGNAL_TYPE_BULLISH ? GetEntry()+100*_Point : GetEntry()-100*_Point;
      }
      
      ulong GetTicket() {
         return ticket;
      }
      
      virtual bool CheckSignal(ENUM_TIMEFRAMES tf) {
         if (PositionsTotal() > 0) {
            return false;
         }
         
         bool ret = false;
         int res = checkFtr(tf, 24);
         if (res != 0) {
            time = bar4.time;
            price = bar4.close;
            if (res == 1) {
               type = SIGNAL_TYPE_BULLISH;
            }
            else if (res == -1) {
               type = SIGNAL_TYPE_BEARISH;
            }
            ret = true;
         }
         return ret;
      }
      
      bool CheckForClose() {
         int tot = PositionsTotal();
         if (tot == 1) {
            MqlRates rates[];
            CopyRates(_Symbol, timeframe, 1, 2, rates);
            
            ulong  position_ticket=PositionGetTicket(0);
            string position_symbol=PositionGetString(POSITION_SYMBOL);
            int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);
            ulong  magic=PositionGetInteger(POSITION_MAGIC);
            double volume=PositionGetDouble(POSITION_VOLUME);
            double sl=PositionGetDouble(POSITION_SL);
            double tp=PositionGetDouble(POSITION_TP);
            ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); 
            
            if (type == POSITION_TYPE_BUY) {
               if (rates[0].close-rates[0].open < 0 && rates[1].close-rates[1].open < 0) {
                  ticket = position_ticket;
                  return true;
               }
            }
            else if (type == POSITION_TYPE_SELL) {
               if (rates[0].close-rates[0].open > 0 && rates[1].close-rates[1].open > 0) {
                  ticket = position_ticket;
                  return true;
               }
            }
         }
         return false;
      }
      
   private:
      string patterType;
      
      int checkFtr(ENUM_TIMEFRAMES tf, int period) {
         if (patterType == "P4") {
            return checkFtrP4(tf, period);
         }
         else if (patterType == "P5") {
            return checkFtrP5(tf, period);
         }
         else if (patterType == "P2") {
            return checkFtrP2(tf, period);
         }
         else {
            return 0;
         }
          
         //if ((bodyratio0 >= 0.618) && bodyWhite0 && bodyWhite1 && !bodyWhite2 && bodyWhite3) {
         //   bool rt1 = (bar1.high - bar2.low) / (bar1.high - bar1.low) <= 0.618;
         //   bool rt2 = bar3.low > bar2.low;
         //   bool rt3 = bar4.close > bar3.high;
         //   if(rt1 && rt2 && rt3) {
         //      price = bar4.low;
         //      time = bar4.time;
         //      type = SIGNAL_TYPE_BULLISH;
         //      ret = 1;
         //   }
         //}
         //else if ((bodyratio0 >= 0.618) && !bodyWhite0 && !bodyWhite1 && bodyWhite2 && !bodyWhite3) {
         //   bool rt1 = (bar2.high - bar1.low) / (bar1.high - bar1.low) <= 0.618;
         //   bool rt2 = bar3.high < bar2.high;
         //   bool rt3 = bar4.close < bar3.low;
         //   if (rt1 && rt2 && rt3) {
         //      price = bar4.high;
         //      time = bar4.time;
         //      type = SIGNAL_TYPE_BEARISH;
         //      ret = -1;
         //   }
         //}        
         
         //if (bodyratio0 >= 0.5 && bodyratio1 >= 0.5 && bodyratio2 >= 0.5) {
         //   if (bodyWhite0 && bodyWhite1 && bodyWhite2 && !bodyWhite3 && bodyWhite4) {
         //      double level = bar3.high - (bar3.high-bar3.low)*0.618;
         //      if(bar4.low > bar3.open && bar5.low >= level && bar5.close > bar4.high) {
         //         price = bar5.low;
         //         time = bar5.time;
         //         type = SIGNAL_TYPE_BULLISH;
         //         ret = 1;
         //      }
         //   }
         //   else if (!bodyWhite0 && !bodyWhite1 && !bodyWhite2 && bodyWhite3 && !bodyWhite4) {
         //      double level = bar3.low + (bar3.high-bar3.low)*0.618;
         //      if (bar4.high < bar3.open && bar5.high <= level && bar5.close < bar4.low) {
         //         price = bar5.high;
         //         time = bar5.time;
         //         type = SIGNAL_TYPE_BEARISH;
         //         ret = -1;
         //      }
         //   }
         //}
         //return ret;
      }
      
      int checkFtrP4(ENUM_TIMEFRAMES tf, int period) {
         if (bar1.high-bar1.low == 0 || bar2.high-bar2.low == 0) {
            return 0;
         }
                  
         int ret = 0;
         bool bodyWhite0 = bar1.close > bar1.open;
         bool bodyWhite1 = bar2.close > bar2.open;
         bool bodyWhite2 = bar3.close > bar3.open;
         bool bodyWhite3 = bar4.close > bar4.open;
         
         double bodyratio0 = MathAbs(bar1.open-bar1.close) / (bar1.high-bar1.low);
         double bodyratio1 = MathAbs(bar2.open-bar2.close) / (bar2.high-bar2.low);
         
         double avgrange = getAverageRange(tf, period);
         double sdrange = getSdRange(tf, period);
         bool bodylong0 = (bar1.high-bar1.low) > avgrange+sdrange && bodyratio0 >= 0.618;
         bool bodylong1 = (bar2.high-bar2.low) > avgrange+sdrange && bodyratio1 >= 0.618;
         
         if ((bodylong0 && !bodylong1) || (!bodylong0 && bodylong1)) {
         //if (bodylong0 || bodylong1) {
            if (bodyWhite0 && bodyWhite1 && !bodyWhite2 && bodyWhite3) {
               if(bar3.low > bar2.low && bar4.close > bar2.high && bar4.close > bar3.high) {
                  int handle = iMA(_Symbol, PERIOD_D1, 100, 0, MODE_SMA, PRICE_CLOSE);
                  if (handle != INVALID_HANDLE) {
                     double maBuffer[];
                     double ma = 0;
                     int res = CopyBuffer(handle,0,0,1,maBuffer);
                     if (res != -1) {
                        ma = maBuffer[0];
                        if (bar4.close > ma) {
                           price = bar4.close;
                           time = bar4.time;
                           type = SIGNAL_TYPE_BULLISH;
                           ret = 1;
                        }
                     }
                  }
               }
            }
            else if (!bodyWhite0 && !bodyWhite1 && bodyWhite2 && !bodyWhite3) {
               if (bar3.high < bar2.high && bar4.close < bar2.low && bar4.close < bar3.low) {
                  int handle = iMA(_Symbol, PERIOD_D1, 100, 0, MODE_SMA, PRICE_CLOSE);
                  if (handle != INVALID_HANDLE) {
                     double maBuffer[];
                     double ma = 0;
                     int res = CopyBuffer(handle,0,0,1,maBuffer);
                     if (res != -1) {
                        ma = maBuffer[0];
                        if (bar4.close < ma) {
                           price = bar4.close;
                           time = bar4.time;
                           type = SIGNAL_TYPE_BEARISH;
                           ret = -1;
                        }
                     }
                  }
               }
            }      
         }
         return ret;
      }
      
      int checkFtrP5(ENUM_TIMEFRAMES tf, int period) {
         if (bar1.high-bar1.low == 0 || bar2.high-bar2.low == 0) {
            return 0;
         }
                  
         int ret = 0;
         bool bodyWhite0 = bar1.close > bar1.open;
         bool bodyWhite1 = bar2.close > bar2.open;
         bool bodyWhite2 = bar3.close > bar3.open;
         bool bodyWhite3 = bar4.close > bar4.open;
         
         double bodyratio0 = MathAbs(bar1.open-bar1.close) / (bar1.high-bar1.low);
         double bodyratio1 = MathAbs(bar2.open-bar2.close) / (bar2.high-bar2.low);
         
         double avgrange = getAverageRange(tf, period);
         double sdrange = getSdRange(tf, period);
         bool bodylong0 = (bar1.high-bar1.low) > avgrange+sdrange && bodyratio0 >= 0.618;
         bool bodylong1 = (bar2.high-bar2.low) > avgrange+sdrange && bodyratio1 >= 0.618;
         
         if ((bodylong0 && !bodylong1) || (!bodylong0 && bodylong1)) {
         //if (bodylong0 || bodylong1) {
            if (bodyWhite0 && bodyWhite1 && !bodyWhite2 && bodyWhite3) {
               if(bar3.high < bar2.high && bar4.high < bar3.high && bar5.close > bar3.high && bar5.close > bar4.high) {
                  price = bar4.close;
                  time = bar4.time;
                  type = SIGNAL_TYPE_BULLISH;
                  ret = 1;
               }
            }
            else if (!bodyWhite0 && !bodyWhite1 && bodyWhite2 && !bodyWhite3) {
               if (bar3.low > bar2.low && bar4.low > bar3.low && bar5.close < bar2.low && bar5.close < bar3.low) {
                  price = bar4.close;
                  time = bar4.time;
                  type = SIGNAL_TYPE_BEARISH;
                  ret = -1;
               }
            }      
         }
         return ret;
      }
      
      int checkFtrP2(ENUM_TIMEFRAMES tf, int period) {
         if (bar1.high-bar1.low == 0 || bar2.high-bar2.low == 0) {
            return 0;
         }
                  
         int ret = 0;
         bool bodyWhite0 = bar1.close > bar1.open;
         bool bodyWhite1 = bar2.close > bar2.open;
         
         double bodyratio0 = MathAbs(bar1.open-bar1.close) / (bar1.high-bar1.low);
         double bodyratio1 = MathAbs(bar2.open-bar2.close) / (bar2.high-bar2.low);
         
         double avgrange = getAverageRange(tf, period);
         double sdrange = getSdRange(tf, period);
         bool bodylong0 = (bar1.high-bar1.low) > avgrange+sdrange && bodyratio0 >= 0.618;
         bool bodylong1 = (bar2.high-bar2.low) > avgrange+sdrange && bodyratio1 >= 0.618;
         
         if (bodylong0) {
            if (bodyWhite0 && !bodyWhite1) {
               double range = bar1.high-bar1.low;
               double retraceLevel1 = bar1.high - range*0.318;
               double retraceLevel2 = bar1.high - range*0.618;
               if (bar2.close <= retraceLevel1 && bar2.close >= retraceLevel2) {
                  price = bar4.close;
                  time = bar4.time;
                  type = SIGNAL_TYPE_BULLISH;
                  ret = 1;
               }
            }
            else if (!bodyWhite0 && bodyWhite1) {
               double range = bar1.high-bar1.low;
               double retraceLevel1 = bar1.low + range*0.318;
               double retraceLevel2 = bar1.low + range*0.618;
               if (bar2.close >= retraceLevel1 && bar2.close <= retraceLevel2) {
                  price = bar4.close;
                  time = bar4.time;
                  type = SIGNAL_TYPE_BEARISH;
                  ret = -1;
               }
            }      
         }
         return ret;
      }
      
      int checkFtrCross(ENUM_TIMEFRAMES tf) {
         return 0;
      }
};