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

#include "Common.mqh";
#include "CSPattern.mqh";
#include "CurrencyStrength.mqh"

string alertList[];

void trendlineInit() {
   ArrayFree(alertList);
   string filename = _Symbol + "_Alert.txt";
   int fhandle = FileOpen(filename, FILE_READ|FILE_SHARE_READ|FILE_TXT|FILE_COMMON);
   if (fhandle != INVALID_HANDLE) {
      FileSeek(fhandle, 0, SEEK_SET);
      while(!FileIsEnding(fhandle))
      {
         string line = FileReadString(fhandle);
         if (StringLen(line) > 0) {
            ArrayResize(alertList, ArraySize(alertList)+1, 10);
            alertList[ArraySize(alertList)-1] = line;
         }
      }
      FileClose(fhandle);
   }
   else {
      printf("error while opening file %s", filename);
   }
}

void checkBreakout() {
   bool reload = false;
   for(int i=0; i<ArraySize(alertList); i++) {
      string arr[];
      string line = alertList[i];
      StringSplit(line, StringGetCharacter(" ", 0), arr);
      ENUM_TIMEFRAMES tf = StringToTimeframe(arr[2]);
      if (isNewBar2(tf)) {
         //Print("checking breakout..");
         MqlRates rates[];
         CopyRates(_Symbol, tf, 1, 1, rates);
         string type = arr[3];
         StringToLower(type);
         double x1 = StringToDouble(arr[4]);
         double y1 = StringToDouble(arr[5]);
         double x2 = StringToDouble(arr[6]);
         double y2 = StringToDouble(arr[7]);
         Line l;
         l.x1 = x1;
         l.y1 = y1;
         l.x2 = x2;
         l.y2 = y2;
         CHashMap<string, double> map;
         calculateCurrencyStrength(12, PERIOD_M15, map);
         string strSym = _Symbol;
         string base = StringSubstr(strSym, 0, 3);
         string quote = StringSubstr(strSym, 3, 3);
         double baseStrength;
         double quoteStrength;
         map.TryGetValue(base, baseStrength);
         map.TryGetValue(quote, quoteStrength);
         if (type == "breakout") {
            bool res1 = isBreakout(rates[0].time, rates[0].low, x1, y1, x2, y2);
            bool res2 = isBreakout2(rates[0], x1, y1, x2, y2);
            bool res3 = (baseStrength > quoteStrength && (baseStrength > 60 || quoteStrength < 40));
            if (res1 || res2) {
               string content = StringFormat("%s, #%s is breaking out trendline at timeframe:%s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, EnumToString(tf));
               if (res3) {
                  content = StringFormat("%s with BULLISH_CROSS", content);
               }
               deleteAlert(line);
               string line2 = line;
               StringReplace(line2, "breakout", "breakdown");
               addAlert(line2);
               //rename
               //ObjectSetString(0, sparam, OBJPROP_NAME, newname);
               reload = true;
               writeSignal(content);
            }
            bool res4 = isRejected(rates[0], x1, y1, x2, y2, "bearish", tf);
            bool res5 = baseStrength < quoteStrength && (baseStrength < 40 || quoteStrength > 60);
            if (res4) {
               string content = StringFormat("%s, #%s is rejected at resistence at timeframe:%s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, EnumToString(tf));
               if (res5) {
                  content = StringFormat("%s with BEARISH_CROSS", content);
               }
               writeSignal(content);
            }
         }
         else if (type == "breakdown") {
            bool res1 = isBreakdown(rates[0].time, rates[0].high, x1, y1, x2, y2);
            bool res2 = isBreakdown2(rates[0], x1, y1, x2, y2);
            if (res1 || res2) {
               string content = StringFormat("%s, #%s is breaking down trendline at timeframe:%s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, EnumToString(tf));
               if (baseStrength < quoteStrength && (baseStrength < 40 || quoteStrength > 60)) {
                  content = StringFormat("%s with BEARISH_CROSS", content);
               }
               deleteAlert(line);
               string line2 = line;
               StringReplace(line2, "breakdown", "breakout");
               addAlert(line2);
               reload = true;
               writeSignal(content);
            }
            bool res3 =  isRejected(rates[0], x1, y1, x2, y2, "bullish", tf);
            if (res3) {
               string content = StringFormat("%s, #%s is rejected at support at timeframe:%s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, EnumToString(tf));
               if (baseStrength > quoteStrength && (baseStrength > 60 || quoteStrength < 40)) {
                  content = StringFormat("%s with BULLISH_CROSS", content);
               }
               writeSignal(content);
            }
         }
         checkAllCSPattern(tf, l);
      }
   }
   if (reload) {
      trendlineInit();
   }
}

bool isBreakout(long currX, double currY, double x1, double y1, double x2, double y2) {
   double p = calculateY(currX, x1, y1, x2, y2);
   if (currY > p) {
      return true;
   }
   return false;
}

bool isBreakout2(MqlRates &rates, double x1, double y1, double x2, double y2) {
   double time = (double)rates.time;
   double p = calculateY(time, x1, y1, x2, y2);
   double mid = rates.open + ((rates.close - rates.open) / 4);
   if (mid > p) {
      return true;
   }
   return false;
}

bool isBreakdown(double currX, double currY, double x1, double y1, double x2, double y2) {
   double p = calculateY(currX, x1, y1, x2, y2);
   if (currY < p) {
      return true;
   }
   return false;
}

bool isBreakdown2(MqlRates &rates, double x1, double y1, double x2, double y2) {
   double time = (double)rates.time;
   double p = calculateY(time, x1, y1, x2, y2);
   double mid = rates.open - ((rates.open - rates.close) / 4);
   if (mid < p) {
      return true;
   }
   return false;
}

bool isRejected(MqlRates &rates, double x1, double y1, double x2, double y2, string type, ENUM_TIMEFRAMES tf) {
   StringToLower(type);
   double halfrange = (rates.high - rates.low) / 2;
   double mid = rates.low + halfrange;
   double quarter = rates.low + halfrange / 2;
   double quarter2 = rates.low + (mid * 3 / 2);
   double p = calculateY(rates.time, x1, y1, x2, y2);
   double r = getAverageRange(tf, 100) / 2 * 10 * _Point;
   if (type == "bullish") {
      if (rates.open > mid && rates.close > quarter2) {
         if (rates.high > p && rates.low >= (p - r) && rates.low <= (p + r)) {
            return true;
         }
      }
   }
   else if (type == "bearish") {
      if (rates.open < mid && rates.close < quarter) {
         if (rates.low < p && rates.high <= (p + r) && rates.high >= (p - r)) {
            return true;
         }
      }
   }
   return false;
}

//double calculateY(double x, double x1, double y1, double x2, double y2) {
//   return ((y2 - y1) / (x2 - x1) * x) - ((y2 - y1) / (x2 - x1) * x1) + y1;
//}

