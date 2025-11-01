//+------------------------------------------------------------------+
//|                                                        Swing.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot SwingHigh
#property indicator_label1  "SwingHigh"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot SwingLow
#property indicator_label2  "SwingLow"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

input int inpSwingBarCount = 10;

double    SwingHighBuffer[];
double    SwingLowBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,SwingHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SwingLowBuffer,INDICATOR_DATA);

//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,234);
   PlotIndexSetInteger(1,PLOT_ARROW,233);

//--- setting shift
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,10);

//--- initialize buffer value to empty_value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
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
   if(prev_calculated<inpSwingBarCount) {
      ArrayInitialize(SwingHighBuffer,EMPTY_VALUE);
      ArrayInitialize(SwingLowBuffer,EMPTY_VALUE);
   }
   for(int i=prev_calculated; i<rates_total-1; i++) {
      if (i>=2*inpSwingBarCount) {
         MqlRates rates[];
         for(int j=2*inpSwingBarCount; j>=0; j--) {
            MqlRates rate;
            rate.open = open[i-j];
            rate.high = high[i-j];
            rate.low = low[i-j];
            rate.close = close[i-j];
            rate.time = time[i-j];
            ArrayResize(rates, ArraySize(rates)+1, 5);
            rates[ArraySize(rates)-1] = rate;
         }
         int mid = inpSwingBarCount;
         if (isSwingHigh(rates)) {
            SwingHighBuffer[i-mid] = high[i-mid];
         }
         else if (isSwingLow(rates)) {
            SwingLowBuffer[i-mid] = low[i-mid];
         }
         else {
            SwingHighBuffer[i-mid] = EMPTY_VALUE;
            SwingLowBuffer[i-mid] = EMPTY_VALUE;
         }
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
   bool ret = false;
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
