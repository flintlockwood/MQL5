//+------------------------------------------------------------------+
//|                                                DvpSRStrategy.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\Trade.mqh>
#include "Dvp.mqh"
#include "SRLine.mqh"
#include "PriceHelper.mqh"
#include "WebHelper.mqh"
#include "TradeHelper.mqh"

class DvpSRStrategy {
 private:
   int               dvpPeriod;
   int               dvpNRows;
   double            dvpPctValueArea;
   double            tfratio;
   int               scanPeriod;
   int               srCount;
   double            avgBody;
   double            avgRange;
   double            avgSpread;

   Dvp               *dvp;
   CArrayDouble      *distinctPocList;
   CArrayObj         *srList;
   CArrayObj         *topSrList;
   
   void              calculateSRByPOC() {
      CArrayObj *pocList = dvp.GetPocList(_Symbol, PERIOD_CURRENT, 0, scanPeriod);
      if (pocList == NULL) {
         return;
      }

      for(int i=0; i<pocList.Total(); i++) {
         PriceTime *pt = pocList.At(i);
         double price = pt.price;
         distinctPocList.Add(price);
         bool find = false;
         if(i == 299) {
            string stop = "";
         }
         for(int j=0; j<srList.Total(); j++) {
            SRLine *srline = srList.At(j);
            if (MathAbs(srline.AvgValue() - price) <= avgRange/2) {
               srline.AddPoint(pt);
               find = true;
               break;
            }
         }
         if (!find) {
            SRLine *newline = new SRLine();
            newline.AddPoint(pt);
            srList.Add(newline);
         }
      }
      
      pocList.Clear();
      delete pocList;
      
      // sorting and remove duplicate poc
      distinctPocList.Sort();
      CArrayDouble *tempDistinctPoc = new CArrayDouble();
      double prevPoc = 0;
      for(int i=0; i<distinctPocList.Total(); i++) {
         double currPoc = distinctPocList.At(i);
         if (currPoc != prevPoc) {
            tempDistinctPoc.Add(currPoc);
         }
         prevPoc = currPoc;
      }
      delete distinctPocList;
      distinctPocList = tempDistinctPoc;
      distinctPocList.Sort();

      int count = srCount;
      if (count > srList.Total()) {
         count = srList.Total();
      }
      srList.Sort(SORT_BY_STRENGTH);
      int srTotal = srList.Total();
      for(int i=0; i<count; i++) {
         SRLine *templine = srList.At(srTotal-1-i);
         SRLine *tempClone = templine.Clone();
         topSrList.Add(tempClone);
         //templine.ClearPoints();
         //delete tempClone;
      }
   }
   
   double getSL(string orderType, double entryPrice) {
      StringToLower(orderType);
      double sl1 = 0;
      double sl2 = 0;
      double sl = 0;
      if (orderType == "buy") {
         //sl = getNearestPoc(entryPrice, "<");
         sl1 = getLocalSwingLow(entryPrice, scanPeriod).low;
         //double support2 = getNearestTopPoc(entryPrice, "<");
         //if (support2 == 0) {
         //   sl1 = 0;
         //}
         //else if (sl1 < support2) {
         //   sl1 = support2;
         //}
         sl2 = getNearestPoc(entryPrice, "<");
         //sl = MathMax(sl1, sl2);
         sl = sl1;
         if (sl == 0) {
            sl = entryPrice - avgRange;
         }
         sl = sl - avgRange/10 - 2*avgSpread;
      }
      else if (orderType == "sell") {
         //sl = getNearestPoc(entryPrice, ">");
         sl1 = getLocalSwingHigh(entryPrice, scanPeriod).high;
         //double resistance2 = getNearestTopPoc(entryPrice, ">");
         //if (resistance2 == 0) {
         //   sl1 = 0;
         //}
         //else if(sl1 > resistance2) {
         //   sl1 = resistance2;
         //}
         sl2 = getNearestPoc(entryPrice, "<");
         //sl = MathMin(sl1, sl2);
         sl = sl1;
         if (sl == 0) {
            sl = entryPrice + avgRange;   
         }
         sl = sl + avgRange/10 + 2*avgSpread;
      }
      return sl;
   }
   
   double getTP(string orderType, double entryPrice) {
      StringToLower(orderType);
      double tp = 0;
      double tp1 = 0;
      double tp2 = 0;
      if (orderType == "buy") {
         tp1 = getNearestTopPoc(entryPrice, ">");
         if (tp1 != 0) {
            tp2 = getNearestTopPoc(tp1, ">");
            tp = tp2;
         }
         if (tp - entryPrice < avgRange) {
            tp = getNearestPoc(entryPrice + avgRange, ">");
         }
         if (tp == 0) {
            tp = entryPrice + 2*avgRange;
         }
         tp = tp - 2*avgSpread;
      }
      else if (orderType == "sell") {
         tp1 = getNearestTopPoc(entryPrice, "<");
         tp2 = getNearestTopPoc(tp1, "<");
         tp = tp2;
         if (entryPrice - tp < avgRange) {
            tp = getNearestPoc(entryPrice - avgRange, "<");
         }
         if (tp == 0) {
            tp = entryPrice - 2*avgRange;
         }
         tp = tp + 2*avgSpread;
      }
      return tp;
   }
   
   bool isNotTested(string symbol, ENUM_TIMEFRAMES tf, datetime fromTime) {
      MqlRates rates[];
      CopyRates(symbol, tf, fromTime, scanPeriod, rates);
      for(int i=0; i<ArraySize(rates); i++) {
         
      }
      return false;
   }
   
   bool isBullishBreakout(double currPrice, MqlRates &rates[]) {
      if (ArraySize(rates) < 2) {
         return false;
      }
      MqlRates currRate = rates[2];
      MqlRates prevRate = rates[1];
      MqlRates prev2Rate = rates[0];
      bool greencandle = currRate.close > currRate.open;
      bool trendup = currRate.close > prevRate.close && prevRate.close > prev2Rate.close;
      bool currcross = (currRate.high >= currPrice && currRate.low <= currPrice);
      bool longbody = MathAbs(currRate.close - currRate.open) > avgBody;
      bool breakout = MathAbs(currRate.close - currPrice) / MathAbs(currRate.close - currRate.open) >= 0.5;
      bool prevcross = (prevRate.high >= currPrice && prevRate.low <= currPrice);
      
      if (currRate.close > currRate.open // green candle
            && (currRate.high >= currPrice && currRate.low <= currPrice) // cross the line
            && MathAbs(currRate.close - currRate.open) > avgBody // long body
            && MathAbs(currRate.close - currPrice) / MathAbs(currRate.close - currRate.open) >= 0.5) { // breakout body more than 50%
         return true;
      } else if (currRate.close > currRate.open // green candle
                 && (prevRate.high >= currPrice && prevRate.low <= currPrice) // prev candle cross the line
                 && (currRate.close > prevRate.close)
                 && (currRate.close > currPrice)
                 && MathAbs(currRate.close - currPrice) / MathAbs(currRate.close - currRate.open) >= 0.5
                 && (currRate.low > currPrice )) { // curr candle above the line
         return true;
      }
      else {
         return false;
      }
   }
   
   bool isBearishBreakout() {
      return false;
   }
   
   MqlRates getLocalSwingHigh(double price, int period, datetime fromdate = 0) {
      MqlRates rates[];
      if (fromdate == 0) {
         CopyRates(_Symbol, PERIOD_CURRENT, 1, period, rates);
      }
      else {
         CopyRates(_Symbol, PERIOD_CURRENT, fromdate, period, rates);
      }
      int cnt = ArraySize(rates);
      for(int i=0; i<cnt; i++) {
         if (cnt-3-i < 0) {
            break;
         }
         MqlRates currRate = rates[cnt-1-i];
         MqlRates prevRate = rates[cnt-2-i];
         MqlRates prev2Rate = rates[cnt-3-i];
         if (prevRate.high > price && prevRate.high > currRate.high && prevRate.high > prev2Rate.high) {
            //return prevRate.high;
            return prevRate;
         }
      }
      MqlRates zerorates;
      ZeroMemory(zerorates);
      return zerorates;
   }
   
   MqlRates getLocalSwingLow(double price, int period, datetime fromdate = 0) {
      MqlRates rates[];
      if (fromdate == 0) {
         CopyRates(_Symbol, PERIOD_CURRENT, 1, period, rates);
      }
      else {
         CopyRates(_Symbol, PERIOD_CURRENT, fromdate, period, rates);
      }
      int cnt = ArraySize(rates);
      for(int i=0; i<cnt; i++) {
         if (cnt-3-i < 0) {
            break;
         }
         MqlRates currRate = rates[cnt-1-i];
         MqlRates prevRate = rates[cnt-2-i];
         MqlRates prev2Rate = rates[cnt-3-i];
         if (prevRate.low < price && prevRate.low < currRate.low && prevRate.low < prev2Rate.low) {
            //return prevRate.low;
            return prevRate;
         }
      }
      MqlRates zerorates;
      ZeroMemory(zerorates);
      return zerorates;
   }
   
   double getNearestPoc(double price, string sign) {
      if(!srList.IsSorted(SORT_BY_VALUE)) {
         srList.Sort(SORT_BY_VALUE);
      }
      
      if (sign == "<") {
         for(int i=srList.Total()-1; i>=0; i--) {
            SRLine *tempLine = srList.At(i);
            double avgValue = tempLine.AvgValue();
            if (avgValue < price) {
               return avgValue;
            }
         }
      }
      else if (sign == ">") {
         for(int i=0; i<srList.Total(); i++) {
            SRLine *tempLine = srList.At(i);
            double avgValue = tempLine.AvgValue();
            if (avgValue > price) {
               return avgValue;
            }
         }
      }
      return 0;
   }
   
   double getNearestTopPoc(double price, string sign) {
      if(!topSrList.IsSorted(SORT_BY_VALUE)) {
         topSrList.Sort(SORT_BY_VALUE);
      }
      
      if (sign == "<") {
         for(int i=topSrList.Total()-1; i>=0; i--) {
            SRLine *tempLine = topSrList.At(i);
            double avgValue = tempLine.AvgValue();
            if (avgValue < price) {
               return avgValue;
            }
         }
      }
      else if (sign == ">") {
         for(int i=0; i<topSrList.Total(); i++) {
            SRLine *tempLine = topSrList.At(i);
            double avgValue = tempLine.AvgValue();
            if (avgValue > price) {
               return avgValue;
            }
         }
      }
      return 0;
   }
   
   void checkPendingOrders(double currPrice) {
      COrderInfo *order = new COrderInfo();
      CTrade *ct = new CTrade();
      for(int i=0; i<OrdersTotal(); i++) {
         order.SelectByIndex(i);
         if (order.OrderType() == ORDER_TYPE_BUY_STOP) {
            if (currPrice < order.StopLoss()) {
               ct.OrderDelete(order.Ticket());
            }
         }
         else if (order.OrderType() == ORDER_TYPE_SELL_STOP) {
            if (currPrice > order.StopLoss()) {
               ct.OrderDelete(order.Ticket());
            }
         }
      }
      delete ct;
      delete order;
   }
   
   SRLine* getCurrentSupport(double currPrice) {
      if (!topSrList.IsSorted(SORT_BY_VALUE)) {
         topSrList.Sort(SORT_BY_VALUE);
      }
      for(int i=topSrList.Total()-1; i>=0; i--) {
         SRLine *tempSrLine = topSrList.At(i);
         double currSrLinePrice = tempSrLine.AvgValue();
         if (currSrLinePrice < currPrice) {
            return tempSrLine;
         }
      }
      return NULL;
   }
   
   SRLine* getCurrentResistance(double currPrice) {
      if (!topSrList.IsSorted(SORT_BY_VALUE)) {
         topSrList.Sort(SORT_BY_VALUE);
      }
      for(int i=0; i<topSrList.Total(); i++) {
         SRLine *tempSrLine = topSrList.At(i);
         double currSrLinePrice = tempSrLine.AvgValue();
         if (currSrLinePrice > currPrice) {
            return tempSrLine;
         }
      }
      return NULL;
   }
   
   double getLastRedCandle(double price, int period) {
      MqlRates rates[];
      CopyRates(_Symbol, PERIOD_CURRENT, 1, period, rates);
      int cnt = ArraySize(rates);
      for(int i=0; i<cnt; i++) {
         if (rates[i].close < rates[i].open && rates[i].high > price) {
            return rates[i].high;
         }
      }
      return 0;
   }
   
   double getLastGreenCandle(double price, int period) {
      MqlRates rates[];
      CopyRates(_Symbol, PERIOD_CURRENT, 1, period, rates);
      int cnt = ArraySize(rates);
      for(int i=0; i<cnt; i++) {
         if (rates[i].close > rates[i].open && rates[i].low < price) {
            return rates[i].low;
         }
      }
      return 0;
   }
   
   void drawSR() {
      ObjectsDeleteAll(0, "MBOT_SR_");
      for(int i=0; i<topSrList.Total(); i++) {
         string objName = StringFormat("MBOT_SR_%i", i);
         SRLine *line = topSrList.At(i);
         double price = line.AvgValue();
         ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, TimeCurrent(), price);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, clrBlueViolet);
      }
      ChartRedraw();
   }

 public:
                     DvpSRStrategy(int pDvpPeriod = 60, int pDvpNRows = 100, double pValueAreaPct = 70.0, double pTfRatio = 12.0, int pScanPeriod = 300, int pSRCount = 6) {
      this.dvpPeriod = pDvpPeriod;
      this.dvpNRows = pDvpNRows;
      this.dvpPctValueArea = pValueAreaPct;
      this.tfratio = pTfRatio;
      this.scanPeriod = pScanPeriod;
      this.srCount = pSRCount;

      dvp = new Dvp(this.dvpPeriod, this.dvpNRows, this.dvpPctValueArea, this.tfratio);
      distinctPocList = new CArrayDouble();
      srList = new CArrayObj();
      topSrList = new CArrayObj();
   }

                    ~DvpSRStrategy() {
      delete dvp;
      delete distinctPocList;
      delete srList;
      delete topSrList;
   }

   void              CheckEntry() {
      delete distinctPocList;
      delete srList;
      delete topSrList;
      
      distinctPocList = new CArrayDouble();
      srList = new CArrayObj();
      topSrList = new CArrayObj();
      
      avgBody = GetAvgBody(_Symbol, _Period, scanPeriod);
      avgRange = GetAvgRange(_Symbol, _Period, scanPeriod);
      avgSpread = GetAvgSpreadPoint(_Symbol, PERIOD_CURRENT) * _Point;
      calculateSRByPOC();
      if (srList.Total() == 0 || topSrList.Total() == 0) {
         return;
      }

      MqlRates rates[];
      int copied = CopyRates(_Symbol, PERIOD_CURRENT, 1, 3, rates);
      if (copied != 3) {
         return;
      }
      MqlRates currRate = rates[2];
      MqlRates prevRate = rates[1];
      MqlRates prev2Rate = rates[0];
      
      if (currRate.time == D'2016.06.24 09:00') {
         string stop = "";
      }
      
      double currPrice = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
      if (currPrice == 0) {
         currPrice = (SymbolInfoDouble(_Symbol, SYMBOL_BID) + SymbolInfoDouble(_Symbol, SYMBOL_ASK))/2;
      }
      checkPendingOrders(currPrice);
      
      if (TotalPendingTrade(_Symbol) > 0 || TotalOpenTrade(_Symbol) > 0) {
         return;
      }
      
      bool trendup = currRate.close > prevRate.close && prevRate.close > prev2Rate.close;
      bool trenddown = currRate.close < prevRate.close && prevRate.close < prev2Rate.close;
      
      SRLine *support = getCurrentSupport(currPrice);
      double supportPrice = 0;
      if (support != NULL) {
         supportPrice = support.AvgValue();
      }
      double support2 = getNearestTopPoc(supportPrice, "<");
      SRLine *resistance = getCurrentResistance(currPrice);
      double resistancePrice = 0;
      if (resistance != NULL) {
         resistancePrice = resistance.AvgValue();
      }
      double resistance2 = getNearestTopPoc(resistancePrice, ">");
      
      if (resistancePrice != 0 && trendup && resistancePrice > currPrice && resistancePrice > currRate.high) {
         MqlRates swing = getLocalSwingHigh(resistancePrice, scanPeriod);
         if (resistance2 != 0 && swing.high > resistance2) {
            swing = getLocalSwingHigh(resistancePrice, scanPeriod, swing.time);
            if (swing.high > resistance2) {
               return;
            }
         }
         double lastred = getLastRedCandle(resistancePrice, scanPeriod);
         double lastres = resistance.MaxValue();
         double openPrice = MathMin(swing.high, lastred);
         if (openPrice > 0) {
            double openPrice = openPrice + 2*avgSpread;
            double sl = getSL("buy", resistance.MinValue());
            double tp = getTP("buy", openPrice); 
            double rrr = (tp - openPrice) / (openPrice - sl);
            //if (rrr < 0.5) {
            //   return;
            //}
            if (sl > 0 && tp > 0) {
               Buy(_Symbol, openPrice, sl, tp, 0.01, 5, "dvpsr");
               string message = StringFormat("BUY_STOP at: %s sl: %s tp: %s",
                  DoubleToString(openPrice,5), 
                  DoubleToString(sl,5), 
                  DoubleToString(tp,5));
               BroadcastMessage(_Symbol, PERIOD_CURRENT, message);
            }
         }
      }
      else if (supportPrice != 0 && trenddown && supportPrice < currPrice && supportPrice < currRate.low) {
         MqlRates swing = getLocalSwingLow(supportPrice, scanPeriod);
         if (support2 != 0 && swing.low < support2) {
            swing = getLocalSwingLow(supportPrice, scanPeriod, swing.time);
            if (swing.low < support2) {
               return;
            }
         }
         double lastgreen = getLastGreenCandle(supportPrice, scanPeriod);
         double openPrice = MathMax(swing.low, lastgreen);
         if (openPrice > 0) {
            openPrice = openPrice - 2*avgSpread;
            double sl = getSL("sell", support.MaxValue());
            double tp = getTP("sell", openPrice);
            double rrr = (openPrice - tp) / (sl - openPrice);
            //if (rrr < 0.5) {
            //   return;
            //}
            if (sl > 0 && tp > 0) {
               Sell(_Symbol, openPrice, sl, tp, 0.01, 5, "dvpsr");
               string message = StringFormat("SELL_STOP at: %s sl: %s tp: %s",
                  DoubleToString(openPrice,5), 
                  DoubleToString(sl,5), 
                  DoubleToString(tp,5));
               BroadcastMessage(_Symbol, PERIOD_CURRENT, message);            
            }
         }
      }
   }

   void              CheckExit() {
   }

   CArrayObj*        GetSR() {
      CArrayObj *retList = new CArrayObj();
      for(int i=0; i<topSrList.Total(); i++) {
         SRLine *tempSR = topSrList.At(i);
         retList.Add(tempSR.Clone());
      }
      retList.Sort(SORT_BY_STRENGTH);
      return retList;
   }
};
//+------------------------------------------------------------------+
