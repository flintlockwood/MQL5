//+------------------------------------------------------------------+
//|                                                FlagLimitTest.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "CIsNewBar.mqh";

#define MUF_MAGIC 141592

input int swingSize = 30;
input int avgRangeSize = 100;
input int lastBarSize = 300;

CIsNewBar inb;
int srflipline;

class RatesPoint {
 public:
   datetime          date;
   double            price;
   string            type;
   int               flag;
   MqlRates          rates;

   RatesPoint() {
   }

   RatesPoint(const RatesPoint &old) {
      date = old.date;
      price = old.price;
      type = old.type;
      flag = old.flag;
   }
   
   RatesPoint(MqlRates &pRates, string pType) {
      rates = pRates;
      date = pRates.time;
      price = pRates.close;
      type = pType;
   }
};

class RatesZone {
 public:
   datetime          startdate;
   datetime          enddate;
   double            maxprice;
   double            minprice;
   string            type; // supply / demand
   MqlRates          swingReference;

   RatesZone() {
   }

   RatesZone(const RatesZone &old) {
      startdate = old.startdate;
      enddate = old.enddate;
      maxprice = old.maxprice;
      minprice = old.minprice;
      type = old.type;
   }
   
   RatesZone(datetime pStartdate, datetime pEnddate, double pMaxprice, double pMinprice, string pType, MqlRates &ref) {
      startdate = pStartdate;
      enddate = pEnddate;
      maxprice = pMaxprice;
      minprice = pMinprice;
      type = pType;
      swingReference = ref;
   }
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
   EventSetTimer(5);
   inb.SetPeriod(PERIOD_CURRENT);
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
      srFlip();
   }
}
//+------------------------------------------------------------------+

void srFlip(){
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, lastBarSize, rates);

   // find swing high/low
   RatesPoint swinglist[];
   findSwings(rates, 20, "ALL", swinglist);
   
   // find SR Flip / Check Price
   RatesZone flzones[];
   for(int i=ArraySize(swinglist)-1; i>=0; i--) {
      MqlRates tempRates[];
      CopyRates(_Symbol, PERIOD_CURRENT, swinglist[i].rates.time, rates[lastBarSize-2].time, tempRates);
      
      if (swinglist[i].type == "SH") {
         double avgRange = getAvgRanges(swinglist[i].rates.time, 100);
         double max = tempRates[0].high;
         datetime maxtime = tempRates[0].time;
         double min = tempRates[0].low;
         datetime mintime = tempRates[0].time;
         bool isbreak = false;
         datetime breaktime = 0;
         for(int j=0; j<ArraySize(tempRates); j++) {
            if (tempRates[j].high > max) {
               max = tempRates[j].high;
               maxtime = tempRates[j].time;
               isbreak = true;
               if (breaktime == 0) {
                  breaktime = tempRates[j].time;
               }
            }
            if (tempRates[j].low < min) {
               min = tempRates[j].low;
               mintime = tempRates[j].time;
            }
         }
         bool ismovedfar = (max - swinglist[i].rates.high) / avgRange > 4;
         bool istimeskip = rates[lastBarSize-2].time - breaktime > 5*PeriodSeconds();
         if (isbreak && ismovedfar && istimeskip) {
            // check price
            double retestlevel = swinglist[i].rates.high;
            bool notretes = isNotRetested(retestlevel, "high", breaktime+PeriodSeconds(), rates[lastBarSize-2].time);
            if (notretes && rates[ArraySize(rates)-2].low <= swinglist[i].rates.high + avgRange/4) {
               bool isorderexist = false;
               string comment = "buy " + TimeToString(swinglist[i].rates.time, TIME_DATE|TIME_MINUTES);
               for(int j=PositionsTotal()-1;j>=0;j--) {
                  if(PositionGetTicket(j)>0) {
                     string orderComment= PositionGetString(POSITION_COMMENT);
                     if (orderComment == comment) {
                        isorderexist = true;
                     }
                  }
               }
               HistorySelect(rates[lastBarSize-1].time - 500*PeriodSeconds(), rates[lastBarSize-1].time);
               for(int j=HistoryDealsTotal()-1;j>=0;j--) {
                  ulong dealticket = HistoryDealGetTicket(j);
                  if(dealticket > 0) {
                     string orderComment= HistoryDealGetString(dealticket, DEAL_COMMENT);
                     if (orderComment == comment) {
                        isorderexist = true;
                     }
                  }
               }
               if (!isorderexist) {
                  double sl = 0;
                  MqlRates tempRatesSL[];
                  CopyRates(_Symbol, PERIOD_CURRENT, swinglist[i].rates.time-300*PeriodSeconds(), swinglist[i].rates.time, tempRatesSL);
                  for(int j=ArraySize(tempRatesSL)-1; j>=0; j--) {
                     MqlRates temp[];
                     ArrayCopy(temp, tempRatesSL, 0, j-4, 5);
                     if (isSwingLow(temp)) {
                        sl = temp[2].low;
                        break;
                     }
                  }
                  MqlRates tempRatesTP[];
                  CopyRates(_Symbol, PERIOD_CURRENT, swinglist[i].rates.time, rates[lastBarSize-1].time, tempRatesTP);
                  double bodyhighs[];
                  for(int j=ArraySize(tempRatesTP)-1; j>=0; j--) {
                     double bodyhigh = tempRatesTP[j].close > tempRatesTP[j].open ? tempRatesTP[j].close : tempRatesTP[j].open;
                     ArrayResize(bodyhighs, ArraySize(bodyhighs)+1, 5);
                     bodyhighs[ArraySize(bodyhighs)-1] = bodyhigh;
                  }
                  int idx = ArrayMaximum(bodyhighs);
                  double tp = bodyhighs[idx];
                  
                  if (sl != 0 && tp != 0) {
                     //double rr = (sl-price) / (price-tp);
                     //if (rr < 4) {
                        sendOrder("buy", 0, sl, tp, comment);
                     //}
                  }
                  datetime linestartdate = swinglist[i].rates.time;
                  double linestartprice = swinglist[i].rates.low;
                  datetime lineenddate = rates[lastBarSize-1].time;
                  double lineendprice = swinglist[i].rates.low;
                  ObjectCreate(0, "srflip_line_#" + srflipline, OBJ_TREND, 0, linestartdate, linestartprice, lineenddate, lineendprice);
                  srflipline++;
                  break;
               }
            }
         }
      }
      else if (swinglist[i].type == "SL") {
         double avgRange = getAvgRanges(swinglist[i].rates.time, 100);
         double max = tempRates[0].high;
         datetime maxtime = tempRates[0].time;
         double min = tempRates[0].low;
         datetime mintime = tempRates[0].time;
         bool isbreak = false;
         datetime breaktime = 0;
         for(int j=0; j<ArraySize(tempRates); j++) {
            if (tempRates[j].high > max) {
               max = tempRates[j].high;
               maxtime = tempRates[j].time;
            }
            if (tempRates[j].low < min) {
               min = tempRates[j].low;
               mintime = tempRates[j].time;
               isbreak = true;
               if (breaktime == 0) {
                  breaktime = tempRates[j].time;
               }
            }
         }
         bool ismovedfar = (swinglist[i].rates.low - min) / avgRange > 4;
         bool istimeskip = rates[lastBarSize-2].time - breaktime > 5*PeriodSeconds();
         if (isbreak && ismovedfar && istimeskip) {
            // check price
            double retestlevel = swinglist[i].rates.low;
            bool notretes = isNotRetested(retestlevel, "low", breaktime+PeriodSeconds(), rates[lastBarSize-2].time);
            if (notretes && rates[ArraySize(rates)-2].high >= swinglist[i].rates.low - avgRange/4) {
               bool isorderexist = false;
               string comment = "sell " + TimeToString(swinglist[i].rates.time, TIME_DATE|TIME_MINUTES);
               for(int j=PositionsTotal()-1;j>=0;j--) {
                  if(PositionGetTicket(j)>0) {
                     string orderComment= PositionGetString(POSITION_COMMENT);
                     if (orderComment == comment) {
                        isorderexist = true;
                     }
                  }
               }
               HistorySelect(rates[lastBarSize-1].time - 500*PeriodSeconds(), rates[lastBarSize-1].time);
               for(int j=HistoryDealsTotal()-1;j>=0;j--) {
                  ulong dealticket = HistoryDealGetTicket(j);
                  if(dealticket > 0) {
                     string orderComment= HistoryDealGetString(dealticket, DEAL_COMMENT);
                     if (orderComment == comment) {
                        isorderexist = true;
                     }
                  }
               }
               if (!isorderexist) {
                  double sl = 0;
                  MqlRates tempRatesSL[];
                  CopyRates(_Symbol, PERIOD_CURRENT, swinglist[i].rates.time-300*PeriodSeconds(), swinglist[i].rates.time, tempRatesSL);
                  for(int j=ArraySize(tempRatesSL)-1; j>=0; j--) {
                     MqlRates temp[];
                     ArrayCopy(temp, tempRatesSL, 0, j-4, 5);
                     if (isSwingHigh(temp)) {
                        sl = temp[2].high;
                        break;
                     }
                  }
                  MqlRates tempRatesTP[];
                  CopyRates(_Symbol, PERIOD_CURRENT, swinglist[i].rates.time, rates[lastBarSize-1].time, tempRatesTP);
                  double bodylows[];
                  for(int j=ArraySize(tempRatesTP)-1; j>=0; j--) {
                     double bodylow = tempRatesTP[j].close > tempRatesTP[j].open ? tempRatesTP[j].open : tempRatesTP[j].close;
                     ArrayResize(bodylows, ArraySize(bodylows)+1, 5);
                     bodylows[ArraySize(bodylows)-1] = bodylow;
                  }
                  int idx = ArrayMinimum(bodylows);
                  double tp = bodylows[idx];
                  
                  if (sl != 0 && tp!= 0) {
                     //double rr = (sl-price) / (price-tp);
                     //if (rr < 4) {
                        sendOrder("sell", 0, sl, tp, comment);
                     //}
                  }
                  datetime linestartdate = swinglist[i].rates.time;
                  double linestartprice = swinglist[i].rates.high;
                  datetime lineenddate = rates[lastBarSize-1].time;
                  double lineendprice = swinglist[i].rates.high;
                  ObjectCreate(0, "srflip_line_#" + srflipline, OBJ_TREND, 0, linestartdate, linestartprice, lineenddate, lineendprice);
                  srflipline++;
                  break;
               }
            }
         }
      }
   }
}

void findSwings(MqlRates &rates[], int inpPeriod, string type, RatesPoint &list[]) {
   for(int i=2*inpPeriod; i<ArraySize(rates); i++) {
      MqlRates tempRates[];
      ArrayCopy(tempRates, rates, 0, i-(2*inpPeriod), 2*inpPeriod+1);
      if (isSwingHigh(tempRates)) {
         if (type == "SH" || type == "ALL") {
            ArrayResize(list, ArraySize(list)+1, 5);
            RatesPoint point;
            point.rates = rates[i-inpPeriod];
            point.type = "SH";
            list[ArraySize(list)-1] = point;
         }
      } else if(isSwingLow(tempRates)) {
         if (type == "SL" || type == "ALL") {
            ArrayResize(list, ArraySize(list)+1, 5);
            RatesPoint point;
            point.rates = rates[i-inpPeriod];
            point.type = "SL";
            list[ArraySize(list)-1] = point;
         }
      }
   }
}

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

double getAvgRanges(datetime startTime, int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startTime, period, rates);
   double avgRanges = 0;
   for(int i=0; i<period; i++) {
      avgRanges += rates[i].high - rates[i].low;
   }
   return avgRanges /= period;
}

double getCurrentAvgBody(int period) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, period, rates);
   double avgBody = 0;
   for(int i=0; i<period; i++) {
      avgBody += MathAbs(rates[i].close - rates[i].open);
   }
   return avgBody /= period;
}

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