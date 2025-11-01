//+------------------------------------------------------------------+
//|                                                    SwingTest.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MR\Dictionary.mqh>
#include "CIsNewBar.mqh";
#include <Trade\Trade.mqh>

#define MUF_MAGIC 141592

class SwingPoint {
 public:
   datetime date;
   double price;
   string type;
   int flag;

   SwingPoint() {
   }

   SwingPoint(const SwingPoint &old) {
      date = old.date;
      price = old.price;
      type = old.type;
      flag = old.flag;
   }
};

CIsNewBar inb;
Dictionary<datetime, SwingPoint> swings;
int    swing_handle;
double sh_buffer[];
double sl_buffer[];
CTrade m_trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
   EventSetTimer(5);
   inb.SetPeriod(PERIOD_CURRENT);
   swing_handle = iCustom(_Symbol, PERIOD_CURRENT, "MR\\Swing.ex5", 10);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---
   if (inb.isNewBar()>0) {
      MqlRates rates[];
      CopyRates(_Symbol, PERIOD_CURRENT, 0, 250, rates);
      MqlRates swing[];
      getSwings(rates, 10, "SH", swing);

      //int copy1=CopyBuffer(swing_handle, 0, 0, 2000, sh_buffer);
      //int copy2=CopyBuffer(swing_handle, 1, 0, 2000, sl_buffer);

      if (OrdersTotal() == 0) {
         int n = ArraySize(rates)-2;
         // reject
         double avgRanges = getCurrentAvgRanges(100);
         bool isgreen1 = rates[n-1].close > rates[n-1].open;
         bool isred0 = rates[n].close < rates[n].open;
         //bool iscross1 = rates[n-1].high >= swing[i].high && rates[n-1].low < swing[i].high;
         double highest = rates[n].high > rates[n-1].high ? rates[n].high : rates[n-1].high;
         bool isreject0 = (rates[n-1].high > rates[n].low) && ((rates[n-1].high - rates[n].low) / (rates[n].high - rates[n].low) > 0.5);
         //bool isNotTested = isSHNotTested(swing[i].high, swing[i].time, rates[n-2].time);
         //bool notFar = MathAbs(swing[i].high - rates[n].high) <= avgRanges/2;
         double sl = (rates[n].high > rates[n-1].high ? rates[n].high : rates[n-1].high) + avgRanges/2;
         if (isgreen1 && isred0 && isreject0) {
            double bidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
            sendOrder("sell", 0, sl, bidPrice-avgRanges);
         }
         // breakout
         //else if (rates[n].close > swing[i] && rates[n].open > swing[i] && rates[n].low < swing[i]) {
         //   double avgRanges = getCurrentAvgRanges(100);
         //   double askPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         //   sendOrder("buy", 0, askPrice-avgRanges, askPrice+avgRanges);
         //   break;
         //}
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getCurrentAvgRanges(int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, period, rates);
   double avgRanges = 0;
   for(int i=0; i<period; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}

//+------------------------------------------------------------------+
void sendOrder(string orderType, double price, double sl, double tp) {
   if (PositionsTotal() > 0) {
      return;
   }
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol   = Symbol();
   request.volume   = 0.1;
   request.deviation= 5;
   request.magic    = MUF_MAGIC;
   request.action   = TRADE_ACTION_DEAL;
   //--- set the price and order type depending on the position type
   double pip = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(orderType == "buy") {
      if (price == 0) {
         request.price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         request.type = ORDER_TYPE_BUY;
      } else {
         request.price = price;
         double currprice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         if (price < currprice) {
            request.type = ORDER_TYPE_BUY_LIMIT;
         } else if (price > currprice) {
            request.type = ORDER_TYPE_BUY_STOP;
         }
         request.action   = TRADE_ACTION_PENDING;
      }

      if (sl != 0) {
         request.sl = sl;
      }
      if (tp != 0) {
         request.tp = tp;
      }
   } else {
      if (price == 0) {
         request.price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
         request.type = ORDER_TYPE_SELL;
      } else {
         request.price = price;
         double currprice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         if (price > currprice) {
            request.type = ORDER_TYPE_SELL_LIMIT;
         } else if (price > currprice) {
            request.type = ORDER_TYPE_SELL_STOP;
         }
         request.action   = TRADE_ACTION_PENDING;
      }

      if (sl != 0) {
         request.sl = sl;
      }
      if (tp != 0) {
         request.tp = tp;
      }
   }
   MqlTradeCheckResult checkresult;
   bool valid = OrderCheck(request, checkresult);
   if (valid) {
      MqlTradeResult result;
      bool res = OrderSend(request, result);
      if (!res) {
         printf("Order fail: %s", result.comment);
      }
   } else {
      Print("Order invlalid");
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeOrder(ulong position) {
   bool res = m_trade.PositionClose(position);
   if (!res) {
      printf("fail to close position: %s", m_trade.ResultComment());
   }
}
//+------------------------------------------------------------------+
void getSwings(MqlRates &rates[], int swingBars, string type, MqlRates &outSwings[]) {
   for(int i=2*swingBars; i<ArraySize(rates); i++) {
      MqlRates tempRates[];
      ArrayCopy(tempRates, rates, 0, i-(2*swingBars), 2*swingBars+1);
      if (isSwingHigh(tempRates)) {
         if (type == "SH" || type == "ALL") {
            ArrayResize(outSwings, ArraySize(outSwings)+1, 5);
            outSwings[ArraySize(outSwings)-1] = rates[i-swingBars];
         }
      } else if(isSwingLow(tempRates)) {
         if (type == "SL" || type == "ALL") {
            ArrayResize(outSwings, ArraySize(outSwings)+1, 5);
            outSwings[ArraySize(outSwings)-1] = rates[i-swingBars];
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingHigh(MqlRates &rates[]) {
   bool ret = false;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double maxPrice = rates[0].high;
      int maxIndex = 0;
      for(int i=1; i<n; i++) {
         if (rates[i].high > maxPrice) {
            maxPrice = rates[i].high;
            maxIndex = i;
         }
      }
      ret = maxIndex == mid;
   }
   return ret;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSwingLow(MqlRates &rates[]) {
   bool ret = true;
   int n = ArraySize(rates);
   if (n % 2 == 1) {
      int mid = (n - 1) / 2;
      double minPrice = rates[0].low;
      int minIndex = 0;
      for(int i=1; i<n; i++) {
         if (rates[i].low < minPrice) {
            minPrice = rates[i].low;
            minIndex = i;
         }
      }
      ret = minIndex == mid;
   }
   return ret;
}
//+------------------------------------------------------------------+
bool isSHNotTested(double level, datetime startdate, datetime enddate) {
   double highs[];
   CopyHigh(_Symbol, PERIOD_CURRENT, startdate, enddate, highs);
   for(int i=1; i<ArraySize(highs)-1; i++) {
      if (highs[i] > level) {
         return false;
      }
   }
   return true;
}