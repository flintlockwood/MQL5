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

#include "Common.mqh"
#include "Line.mqh"

void checkAlert() {
   MqlDateTime timecur;
   TimeCurrent(timecur);
   if (timecur.hour >= 3 && timecur.hour <= 17) {
      for(int i=0; i<ObjectsTotal(0, 0, OBJ_TREND); i++) {
         string name = ObjectName(0, i, 0, OBJ_TREND);
         double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
         datetime t1 = ObjectGetInteger(0, name, OBJPROP_TIME, 0);
         double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
         datetime t2 = ObjectGetInteger(0, name, OBJPROP_TIME, 1);
         datetime x = TimeCurrent();
         Line l;
         l.x1 = t1;
         l.y1 = p1;
         l.x2 = t2;
         l.y2 = p2;
         MqlRates rates[];
         int n = 5;
         CopyRates(_Symbol, PERIOD_M15, 1, n, rates);
         //checkCross(rates, l);
         checkBullishCross(rates, l);
         checkBearishCross(rates, l);
      }
   }
}

void checkCross(MqlRates &rates[], Line &line) {
   int n = ArraySize(rates);
   double x = rates[n-1].time;
   double y = calculateY(x, line.x1, line.y1, line.x2, line.y2);
   if (y >= rates[n-1].low && y <= rates[n-1].high) {
      //printf("price alert");
      //Alert("price alert");
      double currprice;
      SymbolInfoDouble(_Symbol, SYMBOL_BID, currprice);
      string content = StringFormat("%s, PRICE_ALERT, #%s, PERIOD_M15, %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, DoubleToString(currprice, _Digits));
      writeSignal(content);
   }
}

void checkBullishCross(MqlRates &rates[], Line &line) {
   int n = ArraySize(rates);
   double x = rates[n-1].time;
   double y = calculateY(x, line.x1, line.y1, line.x2, line.y2);
   if(y >= rates[n-2].low && y <= rates[n-2].high && rates[n-1].close > rates[n-2].high) {   
      double currprice;
      SymbolInfoDouble(_Symbol, SYMBOL_BID, currprice);
      string content = StringFormat("%s, BULLISH_PRICE_ALERT, #%s, PERIOD_M15, %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, DoubleToString(currprice, _Digits));
      writeSignal(content);
   }
}

void checkBearishCross(MqlRates &rates[], Line &line) {
   int n = ArraySize(rates);
   double x = rates[n-1].time;
   double y = calculateY(x, line.x1, line.y1, line.x2, line.y2);
   if(y >= rates[n-2].low && y <= rates[n-2].high && rates[n-1].close < rates[n-2].low) {   
      double currprice;
      SymbolInfoDouble(_Symbol, SYMBOL_BID, currprice);
      string content = StringFormat("%s, BEARISH_PRICE_ALERT, #%s, PERIOD_M15, %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, DoubleToString(currprice, _Digits));
      writeSignal(content);
   }
}

void checkBullishEngulfing(MqlRates &rates[], Line &line) {
   int n = ArraySize(rates);
   double x = rates[n-1].time;
   double y = calculateY(x, line.x1, line.y1, line.x2, line.y2);
   if(y >= rates[n-2].low && y <= rates[n-2].high && rates[n-1].close > rates[n-2].high) {   
      double currprice;
      SymbolInfoDouble(_Symbol, SYMBOL_BID, currprice);
      string content = StringFormat("%s, BULLISH_PRICE_ALERT, #%s, PERIOD_M15, %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, DoubleToString(currprice, _Digits));
      writeSignal(content);
   }
}

void checkBearishEngulfing(MqlRates &rates[], Line &line) {
}