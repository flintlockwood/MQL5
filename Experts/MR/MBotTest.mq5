//+------------------------------------------------------------------+
//|                                                     MBotTest.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

long lastbartime = 0;

int dvpltfHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
   EventSetTimer(60);

   dvpltfHandle = iCustom(_Symbol, PERIOD_M30, "MR\\DVPLowerTf", 60, 100, 70, true);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();

   IndicatorRelease(dvpltfHandle);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   checkNewBar();
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---

}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
//---

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
void checkNewBar() {
   // detecting new bar
   if (lastbartime == 0) {
      lastbartime = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
      //printf("lastbartime: %s", TimeToString(lastbartime, TIME_DATE|TIME_SECONDS));
      onNewBar();
   }
   datetime currtime = TimeCurrent();
   
   if ((currtime - lastbartime) >= PeriodSeconds(PERIOD_CURRENT)) {
      //printf("new bar is formed");
      //printf("lastbartime: %s currtime: %s", TimeToString(lastbartime, TIME_DATE|TIME_SECONDS), TimeToString(currtime, TIME_DATE|TIME_SECONDS));
      lastbartime = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
      onNewBar();
   }
}

void onNewBar() {
   int n = 500;
   double vahBuffer[];
   CopyBuffer(dvpltfHandle, 0, 0, n, vahBuffer);
   double valBuffer[];
   CopyBuffer(dvpltfHandle, 1, 0, n, valBuffer);
   double pocBuffer[];
   CopyBuffer(dvpltfHandle, 2, 0, n, pocBuffer);
   if (pocBuffer[ArraySize(pocBuffer)-1] != 0) {
      string check = "";
      printf("currdatetime: %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
      double vah = vahBuffer[ArraySize(vahBuffer)-1];
      double val = valBuffer[ArraySize(valBuffer)-1];
      double poc = pocBuffer[ArraySize(pocBuffer)-1];
   }
}