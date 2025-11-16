//+------------------------------------------------------------------+
//|                                                         MBot.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "DvpSRStrategy.mqh"
#include "PriceHelper.mqh"

input int dvpPeriod = 60;
input int dvpNRows = 100;
input double dvpPctValueArea = 70.0;
input int scanPeriod = 300;
input double tfratio = 1;
input int srCount = 3;
input bool drawSupportResistance = true;

datetime lastbartime = 0;
datetime lastbartimeM1 = 0;
datetime lastbartimeH1 = 0;
datetime lastbartimeH4 = 0;
datetime lastbartimeD1 = 0;

double avgRangePoint = 0;
double avgSpreadPoint = 0;

int            dvp_handle;

DvpSRStrategy *strategy;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
   printf("initializing mbot");
   lastbartime = 0;
   lastbartimeM1 = 0;
   lastbartimeH1 = 0;
   lastbartimeH4 = 0;
   lastbartimeD1 = 0;
   
   dvp_handle = iCustom(_Symbol, PERIOD_CURRENT, "MR\\DVP1", dvpPeriod, dvpNRows, dvpPctValueArea, false);
   if (dvp_handle == INVALID_HANDLE) {
      printf("invalid handle");
      return (INIT_FAILED);
   }

   for (int i=0; i<2; i++) {
      string objName = "MBOT_Label_" + IntegerToString(i);
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 100);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 20+i*12);
      ObjectSetString(0, objName, OBJPROP_TEXT, "");
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
   }

   setAvgPoint();

   strategy = new DvpSRStrategy(dvpPeriod, dvpNRows, dvpPctValueArea, tfratio, scanPeriod, srCount);

   checkNewBar();
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   printf("deinit mbot");

   delete strategy;
   
   IndicatorRelease(dvp_handle);

   ObjectsDeleteAll(0, "MBOT_");
   ObjectsDeleteAll(0, "SR_");
   ChartRedraw();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   checkNewBar();
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
   printf("OnTradeTransaction comment: %s", request.comment);
   
   string symbol = request.symbol;
   if (symbol == "") {
      symbol = trans.symbol;
   }
   if (symbol != _Symbol) {
      return;
   }
   
   string arr[];
   string comment = request.comment;
   comment.Split(' ', arr);
   if (ArraySize(arr) < 2 ) {
      //if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      //   ulong ticket = trans.deal;
      //   if (ticket == 0) {
      //      ticket = trans.order;
      //   }
      //   if (ticket != 0) {
      //      string objName = StringFormat("SL_%s", IntegerToString(ticket));
      //      ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, TimeCurrent(), trans.price_sl);
      //      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrPink);
      //      objName = StringFormat("TP_%s", IntegerToString(ticket));
      //      ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, TimeCurrent(), trans.price_tp);
      //      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGreenYellow);
      //   }
      //}
   }
   else {
      string command = arr[0];
      string chatid = arr[1];
      string period = "H1";
      if (ArraySize(arr) > 2) {
         period = arr[2];
      }
   
      if (command == "/c") {
         string filepath = ScreenCaptureChart(symbol, StringToTimeFrame(period));
         printf("screen capture success: %s", filepath);
         PrivateMessage(chatid, StringFormat("/image %s", filepath));
      }
   }
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
//---

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkNewBar() {
// detecting new bar
   if (lastbartime == 0 && lastbartimeM1 == 0 && lastbartimeH1 == 0 && lastbartimeH4 == 0 && lastbartimeD1 == 0) {
      lastbartime = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
      onNewBar();
      lastbartimeM1 = SeriesInfoInteger(_Symbol, PERIOD_M1, SERIES_LASTBAR_DATE);
      onNewBarM1();
      lastbartimeH1 = SeriesInfoInteger(_Symbol, PERIOD_H1, SERIES_LASTBAR_DATE);
      onNewBarH1();
      lastbartimeH4 = SeriesInfoInteger(_Symbol, PERIOD_H4, SERIES_LASTBAR_DATE);
      onNewBarH4();
      lastbartimeD1 = SeriesInfoInteger(_Symbol, PERIOD_D1, SERIES_LASTBAR_DATE);
      onNewBarD1();
      return;
   }
   
   datetime currtime = TimeCurrent();
   if ((currtime - lastbartime) >= PeriodSeconds(PERIOD_CURRENT)) {
      lastbartime = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
      onNewBar();
   }
   if (PeriodSeconds(PERIOD_CURRENT) != PeriodSeconds(PERIOD_M1) && (currtime - lastbartimeM1) >= PeriodSeconds(PERIOD_M1)) {
      lastbartimeM1 = SeriesInfoInteger(_Symbol, PERIOD_M1, SERIES_LASTBAR_DATE);
      onNewBarM1();
   }
   if (PeriodSeconds(PERIOD_CURRENT) != PeriodSeconds(PERIOD_H1) && (currtime - lastbartimeH1) >= PeriodSeconds(PERIOD_H1)) {
      lastbartimeH1 = SeriesInfoInteger(_Symbol, PERIOD_H1, SERIES_LASTBAR_DATE);
      onNewBarH1();
   }
   if (PeriodSeconds(PERIOD_CURRENT) != PeriodSeconds(PERIOD_H4) && (currtime - lastbartimeH4) >= PeriodSeconds(PERIOD_H4)) {
      lastbartimeH4 = SeriesInfoInteger(_Symbol, PERIOD_H4, SERIES_LASTBAR_DATE);
      onNewBarH4();
   }
   if (PeriodSeconds(PERIOD_CURRENT) != PeriodSeconds(PERIOD_D1) && (currtime - lastbartimeD1) >= PeriodSeconds(PERIOD_D1)) {
      lastbartimeD1 = SeriesInfoInteger(_Symbol, PERIOD_D1, SERIES_LASTBAR_DATE);
      onNewBarD1();
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void onNewBar() {
   double poc_buffer[];
   CopyBuffer(dvp_handle, 0, 1, scanPeriod, poc_buffer);
   
   setAvgPoint();

   strategy.CheckEntry();
   drawSR();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void onNewBarM1() {
//printf("%s PERIOD_M1 new bar event", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void onNewBarH1() {
//printf("%s PERIOD_H1 new bar event", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   setAvgSpread();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void onNewBarH4() {
//printf("%s PERIOD_H4 new bar event", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void onNewBarD1() {
//printf("%s PERIOD_D1 new bar event", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawSR() {
   if (!drawSupportResistance) {
      return;
   }
   
   CArrayObj *tempSR = strategy.GetSR();
   ObjectsDeleteAll(0, "SR_");
   for(int i=0; i<tempSR.Total(); i++) {
      string objName = StringFormat("SR_%i", i);
      SRLine *line = tempSR.At(i);
      double price = line.AvgValue();
      ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price);
   }
   ChartRedraw();
   delete tempSR;
}

//+------------------------------------------------------------------+
void setAvgPoint() {
   avgRangePoint = GetAvgRangePoint(_Symbol, PERIOD_CURRENT, scanPeriod*2);
   ObjectSetString(0, "MBOT_Label_0", OBJPROP_TEXT, "Avg Range " + DoubleToString(avgRangePoint,0));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setAvgSpread() {
   avgSpreadPoint = GetAvgSpreadPoint(_Symbol, 2*60*60);
   ObjectSetString(0, "MBOT_Label_1", OBJPROP_TEXT, "Avg Spread " + DoubleToString(avgSpreadPoint,1));
}
//+------------------------------------------------------------------+
