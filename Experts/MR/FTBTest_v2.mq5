//+------------------------------------------------------------------+
//|                                                    SwingTest.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MR\ArrayListClass.mqh>
#include <MR\Dictionary.mqh>
#include "CIsNewBar.mqh";
#include <Trade\Trade.mqh>
#include <Math\Stat\Normal.mqh>

#define MUF_MAGIC 141592

input int swingSize = 20;
input int avgRangeSize = 100;
input int lastBarSize = 500;

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
   
   RatesPoint(MqlRates &pRates, string pType, double pPrice) {
      rates = pRates;
      date = pRates.time;
      price = pPrice;
      type = pType;
   }
};

class FtrZone {
 public:
   datetime          startdate;
   datetime          enddate;
   double            maxprice;
   double            minprice;
   string            type; // supply / demand

   FtrZone() {
   }

   FtrZone(const FtrZone &old) {
      startdate = old.startdate;
      enddate = old.enddate;
      maxprice = old.maxprice;
      minprice = old.minprice;
      type = old.type;
   }
   
   FtrZone(datetime pStartdate, datetime pEnddate, double pMaxprice, double pMinprice, string pType) {
      startdate = pStartdate;
      enddate = pEnddate;
      maxprice = pMaxprice;
      minprice = pMinprice;
      type = pType;
   }
};

class RatesPointSortByPrice: public ICompare<RatesPoint*> {
 public:
   int Compare(RatesPoint* &el1, RatesPoint* &el2) {
      if (  el1.price < el2.price) return -1;
      if (  el1.price > el2.price) return 1;
      return 0;
   }
};

class SRLevel {
 public:
   double            level;
   datetime          startdate;
   datetime          enddate;
   RatesPoint*       points[];

   SRLevel() {
   }

   SRLevel(const SRLevel &old) {
      level = old.level;
      startdate = old.startdate;
      enddate = old.enddate;
      ArrayResize(points, ArraySize(old.points));
      for(int i=0; i<ArraySize(old.points)-1; i++) {
         points[i] = new RatesPoint(old.points[i]);
      }
      calculateAverage();
   }

   SRLevel(double pLevel) {
      level = pLevel;
   }

   void AddPoint(RatesPoint *point) {
      ArrayResize(points, ArraySize(points)+1, 10);
      points[ArraySize(points)-1] = new RatesPoint(point);
      calculateAverage();
   }

   ~SRLevel() {
   }

 private:
   void calculateAverage() {
      double avg;
      startdate = points[0].rates.time;
      enddate = points[0].rates.time;
      for(int i=0; i<ArraySize(points); i++) {
         double price = points[i].type == "SH" ? points[i].rates.high : points[i].rates.low;
         avg += price;
         if (points[i].rates.time < startdate) {
            startdate = points[i].rates.time;
         }
         if (points[i].rates.time > enddate) {
            enddate = points[i].rates.time;
         }
      }
      avg /= ArraySize(points);
      level = avg;
   }
};

CIsNewBar inb;
Dictionary<datetime, RatesPoint> swings;
int    swing_handle;
double sh_buffer[];
double sl_buffer[];
CTrade m_trade;
FtrZone ftrZoneList[];
int ftrcnt = 1;
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
      ftb();
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
void ftb() {
   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, 0, lastBarSize, rates);
   if (ArraySize(rates) != lastBarSize) {
      return;
   }
   
   // find swings
   double swings[];
   findSwings(rates, 10, swings);
   // find poles/supply/demand
   RatesPoint snd[];
   findPoles(rates, 100, snd);
   // find ftr zone
   FtrZone ftrzones[];
   for(int i=1; i<ArraySize(snd); i++) {
      MqlRates tempRates[];
      CopyRates(_Symbol, PERIOD_CURRENT, snd[i-1].rates.time, snd[i].rates.time, tempRates);
      if (ArraySize(tempRates) > 2 && ArraySize(tempRates) <= 10) {
         double avgRange = getAvgRanges(snd[i-1].rates.time, 100);
         bool isInRange = true;
         for(int j=0; j<ArraySize(tempRates); j++) {
            if (tempRates[j].high - tempRates[j].low > avgRange) {
               isInRange = false;
               break;
            }
         }
         if (isInRange) {
            datetime startdate = tempRates[1].time; 
            datetime enddate = tempRates[ArraySize(tempRates)-1].time;
            double minprice = 999999;
            double maxprice = 0;
            for (int j=1; j<ArraySize(tempRates)-1; j++) {
               if (tempRates[j].high > maxprice) {
                  maxprice = tempRates[j].high;
               }
               if (tempRates[j].low < minprice) {
                  minprice = tempRates[j].low;
               }
            }
            
            string type = "";
            if (snd[i-1].type == "rally" && snd[i].type == "rally") {
               type = "demand";
            }
            else if (snd[i-1].type == "drop" && snd[i].type == "drop") {
               type = "supply";
            }
            else if (snd[i-1].type == "rally" && snd[i].type == "drop") {
               type = "supply";
            }
            else if (snd[i-1].type == "drop" && snd[i].type == "rally") {
               type = "demand";
            }
            ArrayResize(ftrzones, ArraySize(ftrzones)+1, 5);
            FtrZone *ftr;
            ftr = new FtrZone(startdate, enddate, maxprice, minprice, type);
            ftrzones[ArraySize(ftrzones)-1] = ftr;
         }
      }   
   }
   // check price
   if (ArraySize(ftrzones) > 0) {
      for(int i=ArraySize(ftrzones)-1; i>=0; i--) {
         //if (!isFtrExist(ftrZoneList, ftrzones[i])) {
         //   ArrayResize(ftrZoneList, ArraySize(ftrZoneList)+1, 5);
         //   ftrZoneList[ArraySize(ftrZoneList)-1] = ftrzones[i];
         //   datetime rectstartdate = ftrzones[i].startdate - 2*PeriodSeconds();
         //   double rectstartprice = ftrzones[i].maxprice + 100*_Point;
         //   datetime rectenddate = ftrzones[i].enddate + PeriodSeconds();
         //   double rectendprice = ftrzones[i].minprice - 100*_Point;
         //   ObjectCreate(0, "ftr #" + ftrcnt, OBJ_RECTANGLE, 0, rectstartdate, rectstartprice, rectenddate, rectendprice);
         //   ObjectSetString(0, "ftr #" + ftrcnt, OBJPROP_TEXT, TimeToString(rectstartdate,TIME_DATE|TIME_SECONDS) + " " + TimeToString(rectenddate,TIME_DATE|TIME_SECONDS));
         //   ftrcnt++;
         //}
         double avgRange = getCurrentAvgRanges(100);
         if (ftrzones[i].type == "supply") {
            MqlRates tempRates2[];
            datetime startcopy = ftrzones[i].enddate + PeriodSeconds();
            datetime endcopy = rates[ArraySize(rates)-3].time;
            //if (endcopy > startcopy) {
               CopyRates(_Symbol, PERIOD_CURRENT, startcopy, endcopy, tempRates2);
               double swinglow = tempRates2[0].low;
               bool hasretested = false;
               for(int j=0; j<ArraySize(tempRates2); j++) {
                  if (tempRates2[j].low < swinglow) {
                     swinglow = tempRates2[j].low;
                  }
                  if (j>0 && tempRates2[j].high >= ftrzones[i].minprice - avgRange/4) {
                     hasretested = true;
                  }
               }
               bool hasmovedfar = (ftrzones[i].minprice - swinglow) > 0.5*(ftrzones[i].maxprice - ftrzones[i].minprice);
               if (!hasretested && hasmovedfar) {
                  //double bodyhigh = rates[ArraySize(rates)-2].open > rates[ArraySize(rates)-2].close ? rates[ArraySize(rates)-2].open : rates[ArraySize(rates)-2].close;
                  //double bodylow = rates[ArraySize(rates)-2].open < rates[ArraySize(rates)-2].close ? rates[ArraySize(rates)-2].open : rates[ArraySize(rates)-2].close;
                  //bool reject = (rates[ArraySize(rates)-2].high - bodyhigh) / (bodylow - rates[ArraySize(rates)-2].low) > 0.618;
                  if (rates[ArraySize(rates)-2].high >= ftrzones[i].minprice - avgRange/4 && rates[ArraySize(rates)-2].high <= ftrzones[i].maxprice) {
                     bool isorderexist = false;
                     string comment = "sell ftr " + TimeToString(ftrzones[i].startdate, TIME_DATE|TIME_MINUTES);
                     for(int j=PositionsTotal()-1;j>=0;j--) {
                        if(PositionGetTicket(j)>0) {
                           string orderComment= PositionGetString(POSITION_COMMENT);
                           if (orderComment == comment) {
                              isorderexist = true;
                           }
                        }
                     }
                     if (!isorderexist) {
                        double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                        double sl = ftrzones[i].maxprice + avgRange/4;
                        //double tp = ftrzones[i].minprice - (ftrzones[i].maxprice - ftrzones[i].minprice)*1.5;
                        double tp = swinglow;
                        if (price - tp < avgRange) {
                           for(int j=lastBarSize-1; j>=0; j--) {
                              MqlRates temp[];
                              ArrayCopy(temp, rates, 0, j-4, 5);
                              if (isSwingLow(temp) && temp[2].low < swinglow) {
                                 tp = temp[2].low;
                                 break;
                              }
                           }
                        }
                        MqlDateTime currtime;
                        TimeCurrent(currtime);
                        if (currtime.hour < 7) {
                           Print("Order is rejected because hour < 7");
                        }
                        if (price-tp != 0 && price > tp && price < sl) {
                           double rr = (sl-price) / (price-tp);
                           //if (rr < 4) {
                              sendOrder("sell", 0, sl, tp, comment);
                           //}
                           datetime linestartdate = ftrzones[i].startdate;
                           double linestartprice = price;
                           datetime lineenddate = rates[lastBarSize-1].time;
                           double lineendprice = price;
                           ObjectCreate(0, "ftr_line_#" + ftrcnt, OBJ_TREND, 0, linestartdate, linestartprice, lineenddate, lineendprice);
                           datetime rectstartdate = ftrzones[i].startdate - 2*PeriodSeconds();
                           double rectstartprice = ftrzones[i].maxprice + 100*_Point;
                           datetime rectenddate = ftrzones[i].enddate + PeriodSeconds();
                           double rectendprice = ftrzones[i].minprice - 100*_Point;
                           ObjectCreate(0, "ftr_rect_#" + ftrcnt, OBJ_RECTANGLE, 0, rectstartdate, rectstartprice, rectenddate, rectendprice);
                           ObjectSetString(0, "ftr_rect_#" + ftrcnt, OBJPROP_TEXT, TimeToString(rectstartdate,TIME_DATE|TIME_SECONDS) + " " + TimeToString(rectenddate,TIME_DATE|TIME_SECONDS));
                           ftrcnt++;
                        }
                     }
                  }
               }
            //}
         }
         else if(ftrzones[i].type == "demand") {
            MqlRates tempRates2[];
            datetime startcopy = ftrzones[i].enddate + PeriodSeconds();
            datetime endcopy = rates[ArraySize(rates)-3].time;
            //if (endcopy > startcopy) {
               CopyRates(_Symbol, PERIOD_CURRENT, startcopy, endcopy, tempRates2);
               double swinghigh = tempRates2[0].high;
               bool hasretested = false;
               for(int j=0; j<ArraySize(tempRates2); j++) {
                  if (tempRates2[j].high > swinghigh) {
                     swinghigh = tempRates2[j].high;
                  }
                  if (j>0 && tempRates2[j].low <= ftrzones[i].maxprice + avgRange/4) {
                     hasretested = true;
                  }
               }
               bool hasmovedfar = (swinghigh - ftrzones[i].maxprice) > 0.5*(ftrzones[i].maxprice - ftrzones[i].minprice);
               if (!hasretested && hasmovedfar) {
                  //double bodyhigh = rates[ArraySize(rates)-2].open > rates[ArraySize(rates)-2].close ? rates[ArraySize(rates)-2].open : rates[ArraySize(rates)-2].close;
                  //double bodylow = rates[ArraySize(rates)-2].open < rates[ArraySize(rates)-2].close ? rates[ArraySize(rates)-2].open : rates[ArraySize(rates)-2].close;
                  //bool reject = (bodylow - rates[ArraySize(rates)-2].low) / (rates[ArraySize(rates)-2].high - bodyhigh) > 0.618;
                  if (rates[ArraySize(rates)-2].low <= ftrzones[i].maxprice + avgRange/4 && rates[ArraySize(rates)-2].low >= ftrzones[i].minprice) {
                     bool isorderexist = false;
                     string comment = "buy ftr " + TimeToString(ftrzones[i].startdate, TIME_DATE|TIME_MINUTES);
                     for(int j=PositionsTotal()-1;j>=0;j--) {
                        if(PositionGetTicket(j)>0) {
                           string orderComment = PositionGetString(POSITION_COMMENT);
                           if (orderComment == comment) {
                              isorderexist = true;
                           }
                        }
                     }
                     if (!isorderexist) {
                        double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                        double sl = ftrzones[i].minprice - avgRange/4;
                        //double tp = ftrzones[i].maxprice + (ftrzones[i].maxprice - ftrzones[i].minprice)*1.5;
                        double tp = swinghigh;
                        if (tp - price < avgRange) {
                           for(int j=lastBarSize-1; j>=0; j--) {
                              MqlRates temp[];
                              ArrayCopy(temp, rates, 0, j-4, 5);
                              if (isSwingHigh(temp) && temp[2].high > swinghigh) {
                                 tp = temp[2].high;
                                 break;
                              }
                           }
                        }
                        MqlDateTime currtime;
                        TimeCurrent(currtime);
                        if (currtime.hour < 7) {
                           Print("Order is rejected because hour < 7");
                        }
                        if (tp-price != 0 && price < tp && price > sl) {
                           double rr = (price-sl) / (tp-price);
                           //if (rr < 4) {
                              sendOrder("buy", 0, sl, tp, comment);
                           //}
                           datetime linestartdate = ftrzones[i].startdate;
                           double linestartprice = price;
                           datetime lineenddate = rates[lastBarSize-1].time;
                           double lineendprice = price;
                           ObjectCreate(0, "ftr_line_#" + ftrcnt, OBJ_TREND, 0, linestartdate, linestartprice, lineenddate, lineendprice);
                           datetime rectstartdate = ftrzones[i].startdate - 2*PeriodSeconds();
                           double rectstartprice = ftrzones[i].maxprice + 100*_Point;
                           datetime rectenddate = ftrzones[i].enddate + PeriodSeconds();
                           double rectendprice = ftrzones[i].minprice - 100*_Point;
                           ObjectCreate(0, "ftr_rect_#" + ftrcnt, OBJ_RECTANGLE, 0, rectstartdate, rectstartprice, rectenddate, rectendprice);
                           ObjectSetString(0, "ftr_rect_#" + ftrcnt, OBJPROP_TEXT, TimeToString(rectstartdate,TIME_DATE|TIME_SECONDS) + " " + TimeToString(rectenddate,TIME_DATE|TIME_SECONDS));
                           ftrcnt++;
                        }
                     }
                  }
               }
            //}
         }
      }
   }
   // calculate sl tp
   // send order
}

void findPoles(MqlRates &rates[], int inpPeriod, RatesPoint &snd[]) {
   for(int i=0; i<ArraySize(rates)-1; i++)
   {
      if (i-inpPeriod < 0) {
         continue;
      }
      MqlRates arr[];
      ArrayCopy(arr, rates, 0, i-inpPeriod, inpPeriod);
      
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
         RatesPoint *rp;
         rp = new RatesPoint(rates[i], "rally", rates[i].high);
         ArrayResize(snd, ArraySize(snd)+1, 5);
         snd[ArraySize(snd)-1] = rp;
      }
      
      if (rates[i].close<rates[i].open && (rates[i].high-rates[i].low)>=(rangeAvg+rangeSd) && ratio>=0.618) {
         RatesPoint *rp;
         rp = new RatesPoint(rates[i], "drop", rates[i].low);
         ArrayResize(snd, ArraySize(snd)+1, 5);
         snd[ArraySize(snd)-1] = rp;
      }
   }
}

bool isFtrExist(FtrZone &list[], FtrZone &ftr) {
   for(int i=0; i<ArraySize(list); i++) {
      if (list[i].startdate == ftr.startdate && list[i].enddate == ftr.enddate) {
         return true;
      }
   }
   return false;
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

void findSupportResistance(MqlRates &rates[], int swingBarCount, int senstivity, CArrayListClass<SRLevel>* levels) {
   CArrayListClass<RatesPoint>* swingList = new CArrayListClass<RatesPoint>();
   for(int i=0; i<ArraySize(rates)-1; i++)
   {
      if (i < 2*swingBarCount) {
         continue;
      }
      
      MqlRates temprates[];
      ArrayCopy(temprates, rates, 0, i-2*swingBarCount, i);
      int mid = swingBarCount;
      if (isSwingHigh(temprates)) {
         swingList.add(new RatesPoint(rates[i-mid], "SH", rates[i-mid].high));
      }
      else if (isSwingLow(temprates)) {
         swingList.add(new RatesPoint(rates[i-mid], "SL", rates[i-mid].low));
      }
   }
   ICompare<RatesPoint*>* rpsortbyprice = new RatesPointSortByPrice();
   swingList.SortBy(rpsortbyprice);
   
   int price = 0;
   int priceCount = 0;
   double levelGap = 0.5*getAvgRanges(rates[ArraySize(rates)-1].time, 100);
   int srCounter = 0;
   double SRLevels[];
   for (int i=swingList.size()-1; i>=0; i--) {
      price += swingList[i].price;
      priceCount++;
      if (i==0 || (swingList[i].price-swingList[i-1].price) > levelGap) {
         if (priceCount>=senstivity) {
            price = price/priceCount;
            
            SRLevels[srCounter] = price;
            srCounter++;
         }
         price       =  0;
         priceCount  =  0;
      }
   }
}

void findSwings(MqlRates &rates[], int swingBarCount, double &swings[]) {
   for(int i=0; i<ArraySize(rates)-1; i++)
   {
      if (i < 2*swingBarCount) {
         continue;
      }
      
      MqlRates temprates[];
      ArrayCopy(temprates, rates, 0, i-2*swingBarCount, i);
      int mid = swingBarCount;
      if (isSwingHigh(temprates)) {
         ArrayResize(swings, ArraySize(swings)+1, 50);
         swings[ArraySize(swings)-1] = rates[i-mid].high;
      }
      else if (isSwingLow(temprates)) {
         ArrayResize(swings, ArraySize(swings)+1, 50);
         swings[ArraySize(swings)-1] = rates[i-mid].low;
      }
   }
}
