//+------------------------------------------------------------------+
//|                                                         DVP1.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <StringUtils.mqh>

//--- input parameters


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   EventSetTimer(60);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
void OnTimer() {
   EventKillTimer();
   
   update();
   
   EventSetTimer(60);
}

void update() {
   // find all rectangle object
   int n = ObjectsTotal(0, 0, OBJ_RECTANGLE);
   for(int i=0; i<n; i++) {
      string name = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if (StringStartsWith(name, "#FVP")) {
         double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
         datetime t1 = ObjectGetInteger(0, name, OBJPROP_TIME, 0);
         double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
         datetime t2 = ObjectGetInteger(0, name, OBJPROP_TIME, 1);
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getPriceLevel(double price, double min, double d, int nrow) {
   return MathMin(MathFloor((price - min) / d) + 1, nrow);
}
//+------------------------------------------------------------------+

void drawHistogram(datetime dateFrom, datetime dateTo, long &volumes[]) {
}