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
#include <Math\Stat\Normal.mqh>

#define MUF_MAGIC 141592

input int swingSize = 20;
input int avgRangeSize = 100;
input int lastBarSize = 500;

class SwingPoint {
 public:
   datetime          date;
   double            price;
   string            type;
   int               flag;
   MqlRates          rates;

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
   //swing_handle = iCustom(_Symbol, PERIOD_CURRENT, "MR\\Swing.ex5", swingSize);
   swing_handle = iCustom(_Symbol, PERIOD_CURRENT, "MR\\Pole.ex5", 50);
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
      if (OrdersTotal() == 0) {
         ftb();
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
//|                                                                  |
//+------------------------------------------------------------------+
double getAvgRanges(datetime startTime, int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startTime, period, rates);
   double avgRanges = 0;
   for(int i=0; i<period; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getCurrentAvgBody(int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, period, rates);
   double avgBody = 0;
   for(int i=0; i<period; i++) {
      avgBody += MathAbs(rates[i].close - rates[i].open);
   }
   return avgBody /= period;
}

//+------------------------------------------------------------------+
void sendOrder(string orderType, double price, double sl, double tp, string comment = NULL, datetime expiration = 0) {
   //if (PositionsTotal() > 0) {
   //   return;
   //}
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol   = Symbol();
   request.volume   = 0.1;
   request.deviation= 5;
   request.magic    = MUF_MAGIC;
   if (expiration != 0) {
      request.type_time = ORDER_TIME_SPECIFIED;
      request.expiration = expiration;
   }
//--- set the price and order type depending on the position type
   double pip = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(orderType == "buy") {
      if (price == 0) {
         request.price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         request.type = ORDER_TYPE_BUY;
         request.action   = TRADE_ACTION_DEAL;
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
         request.action   = TRADE_ACTION_DEAL;
      } else {
         request.price = price;
         double currprice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         if (price > currprice) {
            request.type = ORDER_TYPE_SELL_LIMIT;
         } else if (price < currprice) {
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
   if (comment != NULL) {
      request.comment = comment;
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
void getSwings2(MqlRates &rates[], int swingBars, string type, SwingPoint &outSwings[]) {
   for(int i=2*swingBars; i<ArraySize(rates); i++) {
      MqlRates tempRates[];
      ArrayCopy(tempRates, rates, 0, i-(2*swingBars), 2*swingBars+1);
      if (isSwingHigh(tempRates)) {
         if (type == "SH" || type == "ALL") {
            ArrayResize(outSwings, ArraySize(outSwings)+1, 5);
            SwingPoint point;
            point.rates = rates[i-swingBars];
            point.type = "SH";
            outSwings[ArraySize(outSwings)-1] = point;
         }
      } else if(isSwingLow(tempRates)) {
         if (type == "SL" || type == "ALL") {
            ArrayResize(outSwings, ArraySize(outSwings)+1, 5);
            SwingPoint point;
            point.rates = rates[i-swingBars];
            point.type = "SL";
            outSwings[ArraySize(outSwings)-1] = point;
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

bool isSLNotTested(double level, datetime startdate, datetime enddate) {
   double lows[];
   CopyHigh(_Symbol, PERIOD_CURRENT, startdate, enddate, lows);
   for(int i=1; i<ArraySize(lows)-1; i++) {
      if (lows[i] < level) {
         return false;
      }
   }
   return true;
}

bool isNotRetested(double level, string type, datetime startdate, datetime enddate) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startdate, enddate, rates);
   for(int i=1; i<ArraySize(rates)-1; i++) {
      if (type == "high") {
         if (rates[i].high > level) {
            return false;
         }
      }
      else if (type == "low") {
         if (rates[i].low < level) {
            return false;
         }
      }
   }
   return true;
}
//+------------------------------------------------------------------+
bool isSHNotBreaked(double level, datetime startdate, datetime enddate) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startdate, enddate, rates);
   for(int i=1; i<ArraySize(rates)-1; i++) {
      if ((rates[i].close+rates[i].open)/2 > level) {
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doubleTopBreakout() {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 1, lastBarSize, rates);
   MqlRates swing[];
   getSwings(rates, swingSize, "SH", swing);

   if (rates[lastBarSize-1].time == D'2021.04.19 08:00') {
      int breaks = 0;
   }

// find double top
   double doubleTopPrice = 0;
   datetime doubleTopTime = 0;
   for(int i=ArraySize(swing)-1; i>0; i--) {
      double s1 = swing[i].high;
      double s2 = swing[i-1].high;
      double avgRanges = getAvgRanges(swing[i].time, avgRangeSize);
      if (MathAbs(s1-s1) < avgRanges/10) {
         doubleTopPrice = (s1+s2)/2;
         doubleTopTime = swing[i].time;
         break;
      }
   }

   bool notbreaked = isSHNotBreaked(doubleTopPrice, doubleTopTime, rates[lastBarSize-2].time);
   bool isbreak = (rates[lastBarSize-1].close + rates[lastBarSize-1].open) / 2 > doubleTopPrice;
   bool isbreak2 = rates[lastBarSize-1].low > doubleTopPrice;

   if (doubleTopPrice > 0 && notbreaked && (isbreak || isbreak2)) {
      double avgRanges = getCurrentAvgRanges(avgRangeSize);
      double askPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      sendOrder("buy", 0, doubleTopPrice-avgRanges, askPrice+4*avgRanges);
   }
   return;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void swingBreakout() {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 1, lastBarSize, rates);
   MqlRates swing[];
   getSwings(rates, swingSize, "SH", swing);

   int n = ArraySize(rates)-2;
   for(int i=ArraySize(swing)-1; i>=0; i--) {
      double avgRanges = getCurrentAvgRanges(100);

      // reject
      bool isgreen1 = rates[n-1].close > rates[n-1].open;
      bool isred0 = rates[n].close < rates[n].open;
      //bool iscross1 = rates[n-1].high >= swing[i].high && rates[n-1].low < swing[i].high;
      //bool isreject0 = rates[n].close < swing[i].high && ((swing[i].high - rates[n].low) / (rates[n].high - rates[n].low) > 0.5);
      bool isNotTested = isSHNotTested(swing[i].high, swing[i].time, rates[n-2].time);
      bool notFar = MathAbs(swing[i].high - rates[n].high) <= avgRanges/2;
      //if (isgreen1 && isred0 && isNotTested && notFar) {
      //   double bidPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      //   sendOrder("sell", 0, swing[i].high+avgRanges/2, bidPrice-avgRanges);
      //   break;
      //}

      // breakout
      bool isbreakout = rates[n].close > swing[i].high && rates[n].low > swing[i].high;
      bool isLongBody = MathAbs(rates[n].close - rates[n].open) > getCurrentAvgBody(12);
      if (isbreakout && isLongBody && isNotTested) {
         double avgRanges = getCurrentAvgRanges(100);
         double askPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         sendOrder("buy", 0, askPrice-avgRanges, askPrice+avgRanges);
         break;
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void trendBreakout() {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 1, lastBarSize, rates);
   SwingPoint swing[];
   getSwings2(rates, swingSize, "SH", swing);
   int nswing = ArraySize(swing);

   bool isuptrend = false;
   bool isdowntrend = false;
   //if (swing[nswing])
}
//+------------------------------------------------------------------+
void ftb() {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 1, lastBarSize, rates);
   // find supply/demand
   SwingPoint snd[];
   findSupplies(rates, 50, snd);
   // find ftr zone
   MqlRates ftrzones[];
   for(int i=1; i<ArraySize(snd); i++) {
      if (snd[i-1].type == snd[i].type && snd[i].type == "demand") {
         if (snd[i].rates.low > snd[i-1].rates.low+(snd[i-1].rates.high-snd[i-1].rates.low)/2) {
            MqlRates tempRates[];
            CopyRates(_Symbol, PERIOD_CURRENT, snd[i-1].rates.time, snd[i].rates.time, tempRates);
            if (ArraySize(tempRates) == 3 && tempRates[1].open > tempRates[1].close) {
               ArrayResize(ftrzones, ArraySize(ftrzones)+1, 5);
               ftrzones[ArraySize(ftrzones)-1] = tempRates[1];
            }
         }
      }
      else if (snd[i-1].type == snd[i].type && snd[i].type == "supply") {
         if (snd[i].rates.high < snd[i-1].rates.high-(snd[i-1].rates.high-snd[i-1].rates.low)/2) {
            MqlRates tempRates[];
            CopyRates(_Symbol, PERIOD_CURRENT, snd[i-1].rates.time, snd[i].rates.time, tempRates);
            if (ArraySize(tempRates) == 3 && tempRates[1].open < tempRates[1].close) {
               ArrayResize(ftrzones, ArraySize(ftrzones)+1, 5);
               ftrzones[ArraySize(ftrzones)-1] = tempRates[1];
            }
         }
      }
   }
   // check price
   if (rates[ArraySize(rates)-1].time == D'2021.05.10 23:00:00') {
      int j=0;
   }
   if (ArraySize(ftrzones) > 0) {
      for(int i=0; i<ArraySize(ftrzones); i++) {
         bool isorderexist = false;
         for(int i=OrdersTotal()-1;i>=0;i--) {
            if(OrderGetTicket(i)>0) {
               double orderPrice;
               OrderGetDouble(ORDER_PRICE_OPEN, orderPrice);
               long orderType;
               OrderGetInteger(ORDER_TYPE, orderType);
               if (ftrzones[i].close > ftrzones[i].open) {
                  double orderPriceTemp = ftrzones[i].low - 5*_Point;
                  long orderTypeTemp = ORDER_TYPE_SELL_LIMIT;
                  if (orderPrice == orderPriceTemp && orderType == orderTypeTemp) {
                     isorderexist = true;
                  }
               }
               else if (ftrzones[i].close < ftrzones[i].open) {
                  double orderPriceTemp = ftrzones[i].high + 5*_Point;
                  long orderTypeTemp = ORDER_TYPE_BUY_LIMIT;
                  if (orderPrice == orderPriceTemp && orderType == orderTypeTemp) {
                     isorderexist = true;
                  }
               }
            }
         }
         if (!isorderexist) {
            if (ftrzones[i].close > ftrzones[i].open) {
               if (isNotRetested(ftrzones[i].low, "low", ftrzones[i].time, rates[ArraySize(rates)-1].time)) {
                  double orderPriceTemp = ftrzones[i].low - 5*_Point;
                  long orderTypeTemp = ORDER_TYPE_SELL_LIMIT;
                  double sl = ftrzones[i].high + 10*_Point;
                  double tp = orderPriceTemp - (ftrzones[i].high-ftrzones[i].low);
                  datetime expiration = ftrzones[i].time + PeriodSeconds()*lastBarSize;
                  sendOrder("sell", orderPriceTemp, sl, tp, "ftr " + TimeToString(ftrzones[i].time, TIME_DATE|TIME_MINUTES), expiration);
               }
            }
            else if (ftrzones[i].close < ftrzones[i].open) {
               if (isNotRetested(ftrzones[i].high, "high", ftrzones[i].time, rates[ArraySize(rates)-1].time)) {
                  double orderPriceTemp = ftrzones[i].high + 5*_Point;
                  long orderTypeTemp = ORDER_TYPE_BUY_LIMIT;
                  double sl = ftrzones[i].low - 10*_Point;
                  double tp = orderPriceTemp + (ftrzones[i].high-ftrzones[i].low);
                  datetime expiration = ftrzones[i].time + PeriodSeconds()*lastBarSize;
                  sendOrder("buy", orderPriceTemp, sl, tp, "ftr " + TimeToString(ftrzones[i].time, TIME_DATE|TIME_MINUTES), expiration);
               }
            }
         }
      }
   }
   // calculate sl tp
   // send order
}

void findSupplies(MqlRates &rates[], int inpPeriod, SwingPoint &snd[]) {
   for(int i=0; i<ArraySize(rates); i++)
   {
      if (i-inpPeriod < 0) {
         continue;
      }
      MqlRates arr[];
      ArrayCopy(arr, rates, 0, i-inpPeriod, inpPeriod);
      
      if (rates[i].time == D'2022.05.17 11:00:00') {
         int j=0;
      }
      
      double ranges[];
      ArrayResize(ranges, inpPeriod);
      for (int j=0; j<inpPeriod; j++) {
         ranges[j] = arr[j].high - arr[j].low;
      }
      double rangeAvg = MathMean(ranges);
      double rangeSd = MathStandardDeviation(ranges);
      
      double ratio = 0;
      if (rates[i].high-rates[i].low != 0) {
         ratio = MathAbs(rates[i].close-rates[i].open) / (rates[i].high-rates[i].low);
      }
      
      if (rates[i].close>rates[i].open && (rates[i].high-rates[i].low)>=(rangeAvg+rangeSd) && ratio>=0.618) {
         SwingPoint sp;
         sp.rates = rates[i];
         sp.type = "demand";
         ArrayResize(snd, ArraySize(snd)+1, 5);
         snd[ArraySize(snd)-1] = sp;
      }
      
      if (rates[i].close<rates[i].open && (rates[i].high-rates[i].low)>=(rangeAvg+rangeSd) && ratio>=0.618) {
         SwingPoint sp;
         sp.rates = rates[i];
         sp.type = "supply";
         ArrayResize(snd, ArraySize(snd)+1, 5);
         snd[ArraySize(snd)-1] = sp;
      }
   }
}