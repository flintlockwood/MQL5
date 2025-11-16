//+------------------------------------------------------------------+
//|                                                     SRZigZag.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

// Zigzag inputs
input int      InpDepth       =  12;         // Depth
input int      InpDeviation   =  5;          // Deviation
input int      InpBackstep    =  3;          // Backstep

// Peak analysis inputs
input int      InpGapPoints   =  100;        // Minimum gap between peaks in points
input int      InpSensitivity =  2;          // Peak sensitivity
input int      InpLookback    =  50;         // Lookback

// Drawing inputs
input string   InpPrefix      =  "SRLevel_"; // Object name prefix
input color    InpLineColour  =  clrYellow;  // Line colour
input int      InpLineWeight  =  2;          // Line weight

// For the levels
double   SRLevels[];

// For the MT5 ZigZag indicator
double   Buffer[];
int      Handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
// Init the zz indicator
   Handle   =  iCustom(Symbol(), Period(), "Examples\\ZigZag", InpDepth, InpDeviation, InpBackstep);
   if (Handle==INVALID_HANDLE) {
      Print("Could not create a handle to zigzag indicator");
      return(INIT_FAILED);
   }
   ArraySetAsSeries(Buffer, true);

// Clean up any sr levels left from earlier indicators
   ObjectsDeleteAll(0, InpPrefix, 0, OBJ_HLINE);
   ChartRedraw(0);
   ArrayResize(SRLevels, InpLookback);
//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   IndicatorRelease(Handle);
   ObjectsDeleteAll(0, InpPrefix, 0, OBJ_HLINE);
   ChartRedraw(0);
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
// One time convert points to a price gap
   static double  levelGap = InpGapPoints*SymbolInfoDouble(Symbol(), SYMBOL_POINT);
// Only do this on a new bar
   if (rates_total==prev_calculated)   return(rates_total);
// Get the most recent <lookback> peaks
   double   zz       =  0;
   double   zzPeaks[];
   int      zzCount  =  0;
   ArrayResize(zzPeaks, InpLookback);
   ArrayInitialize(zzPeaks, 0.0);

   int      count    =  CopyBuffer(Handle, 0, 0, rates_total, Buffer);
   if (count < 0) {
      int err=GetLastError();
      return(0);
   }
   for (int i=1; i< rates_total && zzCount< InpLookback; i++) {
      zz =  Buffer[i];
      if (zz!=0 && zz!=EMPTY_VALUE) {
         zzPeaks[zzCount] = zz;
         zzCount++;
      }
   }
   ArraySort(zzPeaks);

// Search for groupings and set levels
   int      srCounter   =  0;
   double   price       =  0;
   int      priceCount  =  0;
   ArrayInitialize(SRLevels, 0.0);
   for (int i=InpLookback-1; i>=0; i--) {
      if (zzPeaks[i]> 0) {
         price += zzPeaks[i];
         priceCount++;
      }
      if (i==0 || (zzPeaks[i]-zzPeaks[i-1])> levelGap) {
         if (priceCount>=InpSensitivity) {
            price = price/priceCount;
            SRLevels[srCounter] = price;
            srCounter++;
         }
         price       =  0;
         priceCount  =  0;
      }
   }
   DrawLevels();
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

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  DrawLevels() {
   for (int i=0; i< InpLookback; i++) {
      string name = InpPrefix + IntegerToString(i);
      if (SRLevels[i]==0) {
         ObjectDelete(0, name);
         continue;
      }
      if (ObjectFind(0, name)< 0) {
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, SRLevels[i]);
         ObjectSetInteger(0, name, OBJPROP_COLOR, InpLineColour);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLineWeight);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      } else {
         ObjectSetDouble(0, name, OBJPROP_PRICE, SRLevels[i]);
      }
   }
   ChartRedraw(0);
} // end DrawLevels
//+------------------------------------------------------------------+
