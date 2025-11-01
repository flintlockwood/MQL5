//+------------------------------------------------------------------+
//|                                                 BaseDetector.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "High"
#property indicator_type1  DRAW_LINE
#property indicator_color1  clrGray

#property indicator_label2  "Low"
#property indicator_type2  DRAW_LINE
#property indicator_color2  clrMediumBlue

input bool showHigh         = true;
input bool showLow          = true;

double    HighBuffer[];
double    LowBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowBuffer,INDICATOR_DATA);
//---
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
//---
   int pos = prev_calculated;
   if(pos<1) {
      for(int i=0;i<1;i++) {
         HighBuffer[i]=EMPTY_VALUE;
         LowBuffer[i]=EMPTY_VALUE;
      }
      pos = 1;
   }

   for(int i=pos;i<rates_total && !IsStopped();i++) {
      HighBuffer[i] = EMPTY_VALUE;
      LowBuffer[i] = EMPTY_VALUE;
      
      double highVar;
      if (high[i-1] != 0) {
         highVar = MathAbs(high[i]-high[i-1]);
      }
      
      double lowVar;
      if (low[i-1] != 0) {
         lowVar = MathAbs(low[i]-low[i-1]);
      }
      
      if (showHigh) {
         HighBuffer[i] = highVar;
      }
      if (showLow) {
         LowBuffer[i] = lowVar;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---

}
//+------------------------------------------------------------------+
