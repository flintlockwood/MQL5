//+------------------------------------------------------------------+
//|                                                  PriceHelper.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>

double GetAvgBody(string symbol, ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int copied = CopyRates(symbol, tf, 1, period, rates);
   if (copied != period) {
      return 0;
   }
   double avgBody = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      double body = MathAbs(rates[i].close - rates[i].open);
      avgBody += body;
   }
   avgBody /= ArraySize(rates);
   return avgBody;
}

double GetAvgRange(string symbol, ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int copied = CopyRates(symbol, tf, 1, period, rates);
   if (copied != period) {
      return 0;
   }
   double avgRange = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      double ranges = rates[i].high - rates[i].low;
      avgRange += ranges;
   }
   avgRange /= ArraySize(rates);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return avgRange;
}

double GetAvgRange(MqlRates &rates[]) {
   double avgRange = 0;
   for(int i=0; i<ArraySize(rates); i++) {
      double ranges = rates[i].high - rates[i].low;
      avgRange += ranges;
   }
   avgRange /= ArraySize(rates);
   return avgRange;
}

double GetAvgRangePoint(string symbol, ENUM_TIMEFRAMES tf, int period) {
   double avgRange = GetAvgRange(symbol, tf, period);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return avgRange / point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAvgSpreadPoint(string symbol, int period) {
   MqlTick ticks[];
   ResetLastError();
   int copied = CopyTicks(symbol, ticks, COPY_TICKS_ALL);
   if (copied == -1) {
      int errorcode = GetLastError();
      printf("error copyticks: %s", IntegerToString(errorcode));
      return 0;
   }
   double avgSpread = 0;
   double bid = 0;
   double ask = 0;
   double prevBid = 0;
   double prevAsk = 0;
   double total = 0;
   for (int i=0; i<ArraySize(ticks); i++) {
      bid = ticks[i].bid;
      if (bid == 0) {
         bid = prevBid;
      }
      ask = ticks[i].ask;
      if (ask == 0) {
         ask = prevAsk;
      }
      if (bid == 0 || ask == 0) {
         continue;
      }
      
      avgSpread += ask - bid;
      prevBid = bid;
      prevAsk = ask;
      total += 1;
   }
   avgSpread /= total;
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return avgSpread / point;
}

ENUM_TIMEFRAMES StringToTimeFrame(string str) {
   StringReplace(str, "PERIOD_", "");
   if (str == "M1") {
      return PERIOD_M1;
   } else if(str == "M2") {
      return PERIOD_M2;
   } else if(str == "M3") {
      return PERIOD_M3;
   } else if(str == "M4") {
      return PERIOD_M4;
   } else if(str == "M5") {
      return PERIOD_M5;
   } else if(str == "M6") {
      return PERIOD_M6;
   } else if(str == "M10") {
      return PERIOD_M10;
   } else if(str == "M12") {
      return PERIOD_M12;
   } else if(str == "M15") {
      return PERIOD_M15;
   } else if(str == "M20") {
      return PERIOD_M20;
   } else if(str == "M30") {
      return PERIOD_M30;
   } else if(str == "H1") {
      return PERIOD_H1;
   } else if(str == "H2") {
      return PERIOD_H2;
   } else if(str == "H3") {
      return PERIOD_H3;
   } else if(str == "H4") {
      return PERIOD_H4;
   } else if(str == "H6") {
      return PERIOD_H6;
   } else if(str == "H8") {
      return PERIOD_H8;
   } else if(str == "M12") {
      return PERIOD_H12;
   } else if(str == "D1") {
      return PERIOD_D1;
   } else if(str == "W1") {
      return PERIOD_W1;
   } else if(str == "MN1") {
      return PERIOD_MN1;
   }
   return PERIOD_CURRENT;
}

string TimeFrameToString(ENUM_TIMEFRAMES tf) {
   if (PeriodSeconds(tf) == PeriodSeconds(PERIOD_M1)) {
      return "PERIOD_M1";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M2)) {
      return "PERIOD_M2";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M3)) {
      return "PERIOD_M3";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M4)) {
      return "PERIOD_M4";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M5)) {
      return "PERIOD_M5";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M6)) {
      return "PERIOD_M6";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M10)) {
      return "PERIOD_M10";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M12)) {
      return "PERIOD_M12";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M15)) {
      return "PERIOD_M15";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M20)) {
      return "PERIOD_M20";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_M30)) {
      return "PERIOD_M30";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H1)) {
      return "PERIOD_H1";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H2)) {
      return "PERIOD_H2";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H3)) {
      return "PERIOD_H3";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H4)) {
      return "PERIOD_H4";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H6)) {
      return "PERIOD_H6";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H8)) {
      return "PERIOD_H8";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_H12)) {
      return "PERIOD_H12";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_D1)) {
      return "PERIOD_D1";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_W1)) {
      return "PERIOD_W1";
   } else if(PeriodSeconds(tf) == PeriodSeconds(PERIOD_MN1)) {
      return "PERIOD_MN1";
   }
   return "PERIOD_CURRENT";
}

int TotalPendingTrade(string symbol) {
   int total = OrdersTotal();
   int totalsymbol = 0;
   COrderInfo *order = new COrderInfo();
   for(int i=0; i<total; i++) {
      order.SelectByIndex(i);
      if (order.Symbol() == symbol) {
         totalsymbol++;
      }
   }
   delete order;
   return totalsymbol;
}

int TotalOpenTrade(string symbol) {
   int total = PositionsTotal();
   int totalsymbol = 0;
   for(int i=0; i<total; i++) {
      CPositionInfo *order = new CPositionInfo();
      order.SelectByIndex(i);
      if (order.Symbol() == symbol) {
         totalsymbol++;
      }
   }
   return totalsymbol;
}
