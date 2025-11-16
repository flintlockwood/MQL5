//+------------------------------------------------------------------+
//|                                                 MufEAInclude.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
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

#include <Math\Stat\Math.mqh>
#include <MR\Dvp.mqh>
#include "Line.mqh"

enum SignalType {
   BUY_SLIPPAGE,
   SELL_SLIPPAGE,
   BUY_UNUSUAL_VOLUME,
   SELL_UNUSUAL_VOLUME,
   NEUTRAL_UNUSUAL_VOLUME,
   BUY_DOUBLE_SLIPPAGE,
   SELL_DOUBLE_SLIPPAGE,
   BUY_TRIPPLE_SLIPPAGE,
   SELL_TRIPPLE_SLIPPAGE,
   BUY_QUADRUPLE_SLIPPAGE,
   SELL_QUADRUPLE_SLIPPAGE,
   BULLISH_ENGULFING,
   BEARISH_ENGULFING
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeLineToFile(string filename, string line, bool common = true) {
   int fhandle = 0;
   if (common) {
      int fhandle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   }
   else {
      fhandle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_CSV);
   }
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, line);
   FileFlush(fhandle);
   FileClose(fhandle);
}

void writeSignal(string content) {
   int fhandle = FileOpen(_Symbol + "_Signals.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeTicksProve(string content) {
   int fhandle = FileOpen(Symbol() + "_TicksProve.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeLog(string content) {
   int fhandle = FileOpen(Symbol() + "_ticks_log.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

template<typename T>
T StringToEnum(string str,T enu) {
   for(int i=0; i<65536; i++)
      if(EnumToString(enu=(T)i)==str)
         return(enu);
   return(-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar(ENUM_TIMEFRAMES tf) {
   //--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
   //--- current time
   datetime lastbar_time = SeriesInfoInteger(Symbol(), tf, SERIES_LASTBAR_DATE);
   datetime currtime = TimeCurrent();
   //--- if it is the first call of the function
   if(last_time==0) {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
   }

   //--- if the time differs
   if(last_time!=lastbar_time) {
      //datetime dt = TimeCurrent();
      //int m = dt % (120);
      //if (m > 60 && m < 120) {
      //   //--- memorize the time and return true
      //   last_time=lastbar_time;
      //   if (lastbar_time == StringToTime("2021.01.07 12:45:00")) {
      //      string stop = "";
      //   }
      //   return true;
      //}
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
   }
   
   //--- if we passed to this line, then the bar is not new; return false
   return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar2(ENUM_TIMEFRAMES tf) {
   datetime dt = TimeCurrent();
   if (tf == PERIOD_M1) {
      return (dt-1) % 60 == 0;
   } else if (tf == PERIOD_M2) {
      return (dt-1) % (2*60) == 0;
   } else if (tf == PERIOD_M3) {
      return (dt-1) % (3*60) == 0;
   } else if (tf == PERIOD_M4) {
      return (dt-1) % (4*60) == 0;
   } else if (tf == PERIOD_M5) {
      return (dt-1) % (5*60) == 0;
   } else if (tf == PERIOD_M6) {
      return (dt-1) % (6*60) == 0;
   } else if (tf == PERIOD_M10) {
      return (dt-1) % (10*60) == 0;
   } else if (tf == PERIOD_M12) {
      return (dt-1) % (12*60) == 0;
   } else if (tf == PERIOD_M15) {
      int r = dt %(15*60);
      if (r == 0) {
         return false;
      } else if (r == 1) {
         return (dt-1) % (15*60) == 0;
      } else {
         if (r < 60) {
            return (dt-r) % (15*60) == 0;
         }
      }
   } else if (tf == PERIOD_M20) {
      return (dt-1) % (20*60) == 0;
   } else if (tf == PERIOD_M30) {
      return (dt-1) % (30*60) == 0;
   } else if (tf == PERIOD_H1) {
      return (dt-1) % (60*60) == 0;
   } else if (tf == PERIOD_H2) {
      return (dt-1) % (2*60*60) == 0;
   } else if (tf == PERIOD_H3) {
      return (dt-1) % (3*60*60) == 0;
   } else if (tf == PERIOD_H4) {
      return (dt-1) % (4*60*60) == 0;
   } else if (tf == PERIOD_H6) {
      return (dt-1) % (6*60*60) == 0;
   } else if (tf == PERIOD_H8) {
      return (dt-1) % (8*60*60) == 0;
   } else if (tf == PERIOD_H12) {
      return (dt-1) % (12*60*60) == 0;
   } else if (tf == PERIOD_D1) {
      return (dt-1) % (24*60*60) == 0;
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getCurrDVP(int period, int nrow, double vapct, MqlRates &rates[], DvpRates &dvp) {
   if (ArraySize(rates) != period) {
      return;
   }

   double prices[];
   long volumes[];
   ArrayResize(prices, period);
   ArrayResize(volumes, period);

   for(int i=0; i<period; i++) {
      prices[i] = rates[i].close;
      volumes[i] = rates[i].tick_volume;
   }

   double min = prices[ArrayMinimum(prices, 0, period)];
   double max = prices[ArrayMaximum(prices, 0, period)];
   double d=(max-min)/nrow;

   long totalVolume=0;
   long levelVolume[];
   ArrayResize(levelVolume,nrow+1);
   ArrayFill(levelVolume,0,nrow+1,0);
   for(int j=0; j<period; j++) {
      int lvl=getPriceLevel(prices[j],min,d,nrow);
      levelVolume[lvl]+=volumes[j];
      totalVolume+=volumes[j];
   }

   long pocVol=0.0;
   int pocLevel=0;
   for(int j=1; j<=nrow; j++) {
      long vol=levelVolume[j];
      if(vol>pocVol) {
         pocLevel=j;
         pocVol=vol;
      }
   }

   double valueArea=totalVolume*vapct/100;
   double val = 0.0;
   double vah = 0.0;
   long tempVol=levelVolume[pocLevel];
   for(int j=1; j<=nrow; j++) {
      long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
      long v2 = pocLevel+j <= nrow ? levelVolume[pocLevel+j] : 0;
      tempVol = tempVol + v1 + v2;
      if(tempVol>=valueArea) {
         val = v1==0 ? min : min+(pocLevel-j-1)*d;
         vah = v2==0 ? max : min+(pocLevel+j)*d;
         break;
      }
   }

   if(val==0 && vah==0) {
      val = min;
      vah = max;
   }

   dvp.Time = rates[period-1].time;
   dvp.Poc = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
   dvp.Val = NormalizeDouble(val, _Digits);
   dvp.Vah = NormalizeDouble(vah, _Digits);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getCurrentRsi(string symbol, ENUM_TIMEFRAMES tf, int period) {
   int rsiHandle = iRSI(symbol, tf, period, PRICE_CLOSE);
   if (rsiHandle != INVALID_HANDLE) {
      double rsiBuffer[];
      int res = CopyBuffer(rsiHandle,0,0,1,rsiBuffer);
      if (res == -1) {
         return 0;
      }
      else {
         return rsiBuffer[0];
      }
   } else {
      printf("invalid RSI handle for symbol: %s", symbol);
      return 0;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getCurrRange(ENUM_TIMEFRAMES tf) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, 1, rates);
   if (n == 1) {
      double range = rates[0].high - rates[0].low;
      return NormalizeDouble(range / _Point / 10, 0);
   } else {
      printf("cannot calculate getCurrRange because copyrates return: %i", n);
      return 0;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getSdRange(ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, period, rates);
   if (n == period) {
      double arr[];
      ArrayResize(arr, n);
      for(int i=0; i<period; i++) {
         arr[i] = MathAbs(rates[i].high - rates[i].low);
      }
      return MathStandardDeviation(arr);
   } else {
      printf("cannot calculate average range because copyrates return: %i", n);
      return 0;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAverageRange(ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, period, rates);
   if (n == period) {
      double sum = 0;
      for(int i=0; i<period; i++) {
         sum = sum + rates[i].high - rates[i].low;
      }
      return NormalizeDouble(sum / period, _Digits);
   } else {
      printf("cannot calculate average range because copyrates return: %i", n);
      return 0;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAverageRangeInPips(ENUM_TIMEFRAMES tf, int period) {
   return NormalizeDouble(getAverageRange(tf, period) / _Point / 10, 0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAverageBody(ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, period, rates);
   if (n == period) {
      double sum = 0;
      for(int i=0; i<period; i++) {
         sum = sum + MathAbs(rates[i].close - rates[i].open);
      }
      return NormalizeDouble(sum / period, _Digits);
   } else {
      printf("cannot calculate average range because copyrates return: %i", n);
      return 0;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES StringToTimeframe(string str) {
   StringToUpper(str);
   if (str == "PERIOD_M1") {
      return PERIOD_M1;
   } else if (str == "PERIOD_M2") {
      return PERIOD_M2;
   } else if (str == "PERIOD_M3") {
      return PERIOD_M3;
   } else if (str == "PERIOD_M4") {
      return PERIOD_M4;
   } else if (str == "PERIOD_M5") {
      return PERIOD_M5;
   } else if (str == "PERIOD_M6") {
      return PERIOD_M6;
   } else if (str == "PERIOD_M10") {
      return PERIOD_M10;
   } else if (str == "PERIOD_M12") {
      return PERIOD_M12;
   } else if (str == "PERIOD_M15") {
      return PERIOD_M15;
   } else if (str == "PERIOD_M20") {
      return PERIOD_M20;
   } else if (str == "PERIOD_M30") {
      return PERIOD_M30;
   } else if (str == "PERIOD_H1") {
      return PERIOD_H1;
   } else if (str == "PERIOD_H2") {
      return PERIOD_H2;
   } else if (str == "PERIOD_H3") {
      return PERIOD_H3;
   } else if (str == "PERIOD_H4") {
      return PERIOD_H4;
   } else if (str == "PERIOD_H6") {
      return PERIOD_H6;
   } else if (str == "PERIOD_H8") {
      return PERIOD_H8;
   } else if (str == "PERIOD_H12") {
      return PERIOD_H12;
   } else if (str == "PERIOD_D1") {
      return PERIOD_D1;
   } else if (str == "PERIOD_W1") {
      return PERIOD_W1;
   } else if (str == "PERIOD_MN1") {
      return PERIOD_MN1;
   }
   return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calculateY(double x, double x1, double y1, double x2, double y2) {
   return ((y2 - y1) / (x2 - x1) * x) - ((y2 - y1) / (x2 - x1) * x1) + y1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isInFrame(ENUM_TIMEFRAMES tf, MqlRates &rates, Line &keyLevel) {
   double currLevel = calculateY(rates.time, keyLevel.x1, keyLevel.y1, keyLevel.x2, keyLevel.y2);
   double avgRange = getAverageRange(tf, 100);
   if (rates.high >= currLevel-avgRange/4 && rates.low <= currLevel+avgRange/4) {
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isInFrame(ENUM_TIMEFRAMES tf, MqlRates &rates[], Line &keyLevel) {
   for(int i=0; i<ArraySize(rates); i++) {
      if (!isInFrame(tf, rates[i], keyLevel)) {
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addAlert(string alert) {
   int fhandle = FileOpen(Symbol() + "_Alert.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   if (fhandle != INVALID_HANDLE) {
      FileSeek(fhandle, 0, SEEK_END);
      FileWrite(fhandle, alert);
      FileFlush(fhandle);
      FileClose(fhandle);
   } else {
      Print("invalid handle");
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void updateAlert(string alert) {
   string filename = Symbol() + "_Alert.txt";
   string lines[];
   int fhandle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_COMMON);
   if (fhandle != INVALID_HANDLE) {
      while(!FileIsEnding(fhandle)) {
         string line = FileReadString(fhandle);
         if (StringLen(line) > 0) {
            string arr1[];
            StringSplit(line, StringGetCharacter(" ", 0), arr1);
            string arr2[];
            StringSplit(alert, StringGetCharacter(" ", 0), arr2);
            if (arr1[0] == arr2[0]) {
               line = alert;
            }
            ArrayResize(lines, ArraySize(lines)+1, 100);
            lines[ArraySize(lines)-1] = line;
         }
      }
      FileClose(fhandle);
   } else {
      Print("invalid handle");
   }
   int fhandle2 = FileOpen(filename, FILE_WRITE|FILE_COMMON);
   if(fhandle2 != INVALID_HANDLE) {
      FileClose(fhandle2);
   } else {
      Print("invalid handle");
   }
   int fhandle3 = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   if(fhandle3 != INVALID_HANDLE) {
      FileSeek(fhandle3, 0, SEEK_SET);
      for(int i=0; i<ArraySize(lines); i++) {
         FileWrite(fhandle3, lines[i]);
      }
      FileFlush(fhandle3);
      FileClose(fhandle3);
   } else {
      Print("invalid handle");
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deleteAlert(string alert) {
   string filename = Symbol() + "_Alert.txt";
   string lines[];
   int fhandle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_COMMON);
   if (fhandle != INVALID_HANDLE) {
      while(!FileIsEnding(fhandle)) {
         string line = FileReadString(fhandle);
         if (StringLen(line) > 0) {
            string arr1[];
            StringSplit(line, StringGetCharacter(" ", 0), arr1);
            string arr2[];
            StringSplit(alert, StringGetCharacter(" ", 0), arr2);
            if (arr1[0] == arr2[0]) {
               //printf("deleted: %s", alert);
               continue;
            } else {
               ArrayResize(lines, ArraySize(lines)+1, 100);
               lines[ArraySize(lines)-1] = line;
            }
         }
      }
      FileClose(fhandle);
   }
   int fhandle2 = FileOpen(filename, FILE_WRITE|FILE_COMMON);
   if(fhandle2 != INVALID_HANDLE) {
      FileClose(fhandle2);
   } else {
      Print("invalid handle");
   }
   if (ArraySize(lines) > 0) {
      int fhandle3 = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
      FileSeek(fhandle3, 0, SEEK_SET);
      for(int i=0; i<ArraySize(lines); i++) {
         FileWrite(fhandle3, lines[i]);
      }
      FileFlush(fhandle3);
      FileClose(fhandle3);
   }
}
//+------------------------------------------------------------------+
