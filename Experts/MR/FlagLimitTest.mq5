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

input int swingSize = 20;
input int avgRangeSize = 100;
input int lastBarSize = 500;

CIsNewBar inb;
int flcnt;

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
      flaglimit();
   }
}
//+------------------------------------------------------------------+

void flaglimit(){
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, lastBarSize, rates);

   // find swing high/low
   RatesPoint swinglist[];
   findSwings(rates, 20, "ALL", swinglist);
   
   // find flag limit zone
   RatesZone flzones[];
   for(int i=0; i<ArraySize(swinglist); i++) {
      MqlRates tempRates[];
      CopyRates(_Symbol, PERIOD_CURRENT, swinglist[i].rates.time, rates[lastBarSize-2].time, tempRates);
      
      double avgRange = getAvgRanges(rates[lastBarSize-1].time, avgRangeSize);
      double swingPrice = swinglist[i].type == "SH" ? swinglist[i].rates.high : swinglist[i].rates.low;
      string retestype = swinglist[i].type == "SH" ? "high" : "low";
      double reteslevel = swinglist[i].type == "SH" ? swingPrice+2*avgRange : swingPrice-2*avgRange;
      datetime reteststart = swinglist[i].rates.time+PeriodSeconds();
      datetime retestend = rates[lastBarSize-2].time;
      bool isnotbreak = isNotRetested(reteslevel, retestype, reteststart, retestend);
      bool ismovedfar = isMovedFar(retestype, swinglist[i].type, reteststart, retestend);
      if (isnotbreak && ismovedfar) {
         double lowerFlag1 = swingPrice;
         double upperFlag1 = swingPrice + avgRange;
         double lowerFlag2 = swingPrice - avgRange;
         double upperFlag2 = swingPrice;
         datetime startdate = 0;
         datetime enddate = 0;
         bool range1active = false;
         bool range2active = false;
         for(int j=0; j<ArraySize(tempRates)-1; j++) {
            bool isinrange1 = tempRates[j].high >= lowerFlag1 && tempRates[j].low <= upperFlag1;
            bool isinrange2 = tempRates[j].high >= lowerFlag2 && tempRates[j].low <= upperFlag2;   
            if (isinrange1 && !range2active) {
               double d1 = tempRates[j].high - upperFlag1;
               d1 = d1 < 0 ? 0 : d1;
               double d2 = lowerFlag1 - tempRates[j].low;
               d2 = d2 < 0 ? 0 : d2;
               double r1 = ((tempRates[j].high-tempRates[j].low)-(d1+d2)) / (tempRates[j].high-tempRates[j].low);
               if (r1 >= 0.9 && r1 <= 1) {
                  if (startdate == 0 && !range2active) {
                     startdate = tempRates[j].time;
                     range1active = true;
                  }
               }
               else {
                  if (range1active && startdate > 0)  {
                     enddate = tempRates[j].time;
                     break;
                  }
               }
            }
            else if (isinrange2 && !range1active) {
               double d3 = tempRates[j].high - upperFlag2;
               d3 = d3 < 0 ? 0 : d3;
               double d4 = lowerFlag2 - tempRates[j].low;
               d4 = d4 < 0 ? 0 : d4;
               double r2 = ((tempRates[j].high-tempRates[j].low)-(d3+d4)) / (tempRates[j].high-tempRates[j].low);
               if(r2 >= 0.9 && r2 <= 1) {
                  if (startdate == 0 && !range1active) {
                     startdate = tempRates[j].time;
                     range2active = true;
                  }
               }
               else {
                  if (range2active && startdate > 0)  {
                     enddate = tempRates[j].time;
                     break;
                  }
               }
            }
            else {
               if (range1active || range2active) {
                  enddate = tempRates[j].time;
                  break;
               }
            }
         }
         
         if (startdate > 0 && enddate > 0) {
            if (enddate - startdate > PeriodSeconds()) {
               string stop = "";
            }
         }
      }
      
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
         bool ismovedfar = (max - swinglist[i].rates.high) / avgRange > 3;
         if (isbreak && ismovedfar) {
            MqlRates tempRates2[];
            CopyRates(_Symbol, PERIOD_CURRENT, breaktime, rates[lastBarSize-2].time, tempRates2);
            double minrange = swinglist[i].rates.high - avgRange/5;
            double maxrange = swinglist[i].rates.high + avgRange/5;
            datetime startrange = 0;
            datetime endrange = 0;
            double maxprice = 0;
            double minprice = 999999;
            int cnt = 0;
            datetime previnrange = 0;
            for(int j=0; j<ArraySize(tempRates2); j++) {
               if (tempRates2[j].low <=  maxrange && tempRates2[j].high >= minrange) {
                  if (startrange == 0) {
                     startrange = tempRates2[j].time;
                  }
                  if (tempRates2[j].low < minprice) {
                     minprice = tempRates2[j].low;
                  }
                  if (tempRates2[j].high > maxprice) {
                     maxprice = tempRates2[j].high;
                  }
                  if (cnt == 0 || (tempRates2[j].time - previnrange) == PeriodSeconds()) {
                     cnt++;
                  }
                  previnrange = tempRates2[j].time;
               }
               else {
                  if (startrange > 0) {
                     endrange = tempRates2[j].time;
                     break;
                  }
               }
            }
            endrange = endrange - PeriodSeconds();
            if (startrange > 0 && endrange > 0 && cnt > 1) {
               ArrayResize(flzones, ArraySize(flzones)+1, 5);
               RatesZone *fl;
               fl = new RatesZone(startrange, endrange, maxprice, minprice, "Demand", swinglist[i].rates);
               flzones[ArraySize(flzones)-1] = fl;
            }
         }
      }
      else if (swinglist[i].type == "SL") {
         if (swinglist[i].rates.time == D'2022.04.14 16:00:00') {
            bool stophere = true;
         }
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
         if (breaktime == D'2022.04.14 16:00:00') {
            bool stophere = true;
            double avgRangeTemp = getAvgRanges(breaktime, 100);
         }
         bool ismovedfar = (swinglist[i].rates.low - min) / avgRange > 3;
         if (isbreak && ismovedfar) {
            MqlRates tempRates2[];
            CopyRates(_Symbol, PERIOD_CURRENT, breaktime, rates[lastBarSize-2].time, tempRates2);
            double minrange = swinglist[i].rates.low - avgRange/5;
            double maxrange = swinglist[i].rates.low + avgRange/5;
            datetime startrange = 0;
            datetime endrange = 0;
            double maxprice = 0;
            double minprice = 999999;
            int cnt = 0;
            datetime previnrange = 0;
            for(int j=0; j<ArraySize(tempRates2); j++) {
               if (tempRates2[j].low <=  maxrange && tempRates2[j].high >= minrange) {
                  if (startrange == 0) {
                     startrange = tempRates2[j].time;
                  }
                  if (tempRates2[j].low < minprice) {
                     minprice = tempRates2[j].low;
                  }
                  if (tempRates2[j].high > maxprice) {
                     maxprice = tempRates2[j].high;
                  }
                  if (cnt == 0 || (tempRates2[j].time - previnrange) == PeriodSeconds()) {
                     cnt++;
                  }
                  previnrange = tempRates2[j].time;
               }
               else {
                  if (startrange > 0) {
                     endrange = tempRates2[j].time;
                     break;
                  }
               }
            }
            endrange = endrange - PeriodSeconds();
            if (startrange > 0 && endrange > 0 && cnt > 1) {
               ArrayResize(flzones, ArraySize(flzones)+1, 5);
               RatesZone *fl;
               fl = new RatesZone(startrange, endrange, maxprice, minprice, "Supply", swinglist[i].rates);
               flzones[ArraySize(flzones)-1] = fl;
            }
         }
      }
   }
   
   // check price
   if (ArraySize(flzones) > 0) {
      double avgRange = getAvgRanges(rates[lastBarSize-2].time, 100);
      for(int i=ArraySize(flzones)-1; i>=0; i--) {
         if (flzones[i].type == "Supply") {
            if (rates[ArraySize(rates)-2].high >= flzones[i].swingReference.low - avgRange/4 && rates[ArraySize(rates)-2].high < flzones[i].maxprice) {
               bool isorderexist = false;
               string comment = TimeToString(flzones[i].startdate, TIME_DATE|TIME_MINUTES) + "-" + TimeToString(flzones[i].swingReference.time, TIME_DATE|TIME_MINUTES);
               StringReplace(comment, ".", "");
               StringReplace(comment, ":", "");
               comment = "s" + comment;
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
               double retestlevel = flzones[i].swingReference.low;
               bool notretes = isNotRetested(retestlevel, "high", flzones[i].enddate+PeriodSeconds(), rates[lastBarSize-2].time);
               if (!isorderexist && notretes) {
                  double tempLows[];
                  CopyHigh(_Symbol, PERIOD_CURRENT, flzones[i].enddate+PeriodSeconds(), rates[lastBarSize-2].time, tempLows);
                  int idx = ArrayMinimum(tempLows);
                  double avgRange = getAvgRanges(rates[lastBarSize-2].time, 100);
                  double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                  double sl = flzones[i].maxprice + avgRange/4;
                  double tp = tempLows[idx];
                  if (price-tp != 0) {
                     double rr = (sl-price) / (price-tp);
                     //if (rr < 4) {
                        sendOrder("sell", 0, sl, tp, comment);
                     //}
                  }
                  datetime linestartdate = flzones[i].swingReference.time;
                  double linestartprice = flzones[i].swingReference.low;
                  datetime lineenddate = rates[lastBarSize-1].time;
                  double lineendprice = flzones[i].swingReference.low;
                  ObjectCreate(0, "fl_line_#" + flcnt, OBJ_TREND, 0, linestartdate, linestartprice, lineenddate, lineendprice);
                  datetime rectstartdate = flzones[i].startdate - 2*PeriodSeconds();
                  double rectstartprice = flzones[i].maxprice + 100*_Point;
                  datetime rectenddate = flzones[i].enddate + PeriodSeconds();
                  double rectendprice = flzones[i].minprice - 100*_Point;
                  ObjectCreate(0, "fl_rect_#" + flcnt, OBJ_RECTANGLE, 0, rectstartdate, rectstartprice, rectenddate, rectendprice);
                  ObjectSetString(0, "fl_rect_#" + flcnt, OBJPROP_TEXT, TimeToString(rectstartdate,TIME_DATE|TIME_SECONDS) + " " + TimeToString(rectenddate,TIME_DATE|TIME_SECONDS));
                  flcnt++;
                  break;
               }
            }
         }
         else if (flzones[i].type == "Demand") {
            if (rates[ArraySize(rates)-2].low <= flzones[i].swingReference.high + avgRange/4 && rates[ArraySize(rates)-2].low > flzones[i].minprice) {
               bool isorderexist = false;
               string comment = TimeToString(flzones[i].startdate, TIME_DATE|TIME_MINUTES) + "-" + TimeToString(flzones[i].swingReference.time, TIME_DATE|TIME_MINUTES);
               StringReplace(comment, ".", "");
               StringReplace(comment, ":", "");
               comment = "b" + comment;
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
               double retestlevel = flzones[i].swingReference.high;
               bool notretes = isNotRetested(retestlevel, "low", flzones[i].enddate+PeriodSeconds(), rates[lastBarSize-2].time);
               if (!isorderexist && notretes) {
                  double tempHighs[];
                  CopyHigh(_Symbol, PERIOD_CURRENT, flzones[i].enddate+PeriodSeconds(), rates[lastBarSize-2].time, tempHighs);
                  int idx = ArrayMaximum(tempHighs);
                  double avgRange = getAvgRanges(rates[lastBarSize-2].time, 100);
                  double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                  double sl = flzones[i].minprice - avgRange/4;
                  double tp = tempHighs[idx];
                  if (price-tp != 0) {
                     double rr = (sl-price) / (price-tp);
                     //if (rr < 4) {
                        sendOrder("buy", 0, sl, tp, comment);
                     //}
                  }
                  datetime linestartdate = flzones[i].swingReference.time;
                  double linestartprice = flzones[i].swingReference.high;
                  datetime lineenddate = rates[lastBarSize-1].time;
                  double lineendprice = flzones[i].swingReference.high;
                  ObjectCreate(0, "fl_line_#" + flcnt, OBJ_TREND, 0, linestartdate, linestartprice, lineenddate, lineendprice);
                  datetime rectstartdate = flzones[i].startdate - 2*PeriodSeconds();
                  double rectstartprice = flzones[i].maxprice + 100*_Point;
                  datetime rectenddate = flzones[i].enddate + PeriodSeconds();
                  double rectendprice = flzones[i].minprice - 100*_Point;
                  ObjectCreate(0, "fl_rect_#" + flcnt, OBJ_RECTANGLE, 0, rectstartdate, rectstartprice, rectenddate, rectendprice);
                  ObjectSetString(0, "fl_rect_#" + flcnt, OBJPROP_TEXT, TimeToString(rectstartdate,TIME_DATE|TIME_SECONDS) + " " + TimeToString(rectenddate,TIME_DATE|TIME_SECONDS));
                  flcnt++;
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
   for(int i=0; i<ArraySize(rates)-1; i++) {
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

bool isMovedFar(double level, string type, datetime startdate, datetime enddate) {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, startdate, enddate, rates);
   double max = rates[0].high;
   double min = rates[0].low;
   for(int i=1; i<ArraySize(rates)-1; i++) {
      if (rates[i].high > max) {
         max = rates[i].high;
      }
      if (rates[i].low < min) {
         min = rates[i].low;
      }
   }
   double avgRange = getAvgRanges(enddate, 100);
   if (type == "SH") {
      if (level - min > 2*avgRange) {
         return true;
      }
   }
   else if (type == "SL") {
      if (max - level > 2*avgRange) {
         return true;
      }
   }
   return false;
}