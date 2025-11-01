//+------------------------------------------------------------------+
//|                                                   SimpleLine.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//--- input parameters
input int      BarsBack=20;
input bool     ShowMin=true;
input bool     ShowMax=true;

//--- global variable
string objPrefix = "SimpL_";
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
    //--- Delete old objects
    ObjectsDeleteAll(0, objPrefix);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //--- Delete old objects
    ObjectsDeleteAll(0, objPrefix);
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
    // Ensure we have enough candles
    if(rates_total <= BarsBack) return(prev_calculated);

    // Check if new bar formed
    if(time[0] != lastBarTime) {
        lastBarTime = time[0];
        
        // first delete old objects
        ObjectsDeleteAll(0, objPrefix);
        
        ArraySetAsSeries(time, true);
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        
        int index = BarsBack;               // 20th bar back
        datetime barTime = time[index];     // its time
        int high_index   = iHighest(NULL, 0, MODE_HIGH, BarsBack, 0); 
        printf("high_index %i", high_index);
        double barHigh   = high[high_index];     // its high
        printf("high_value %dd", barHigh);
        int low_index    = iLowest(NULL, 0, MODE_LOW, BarsBack, 0);
        printf("low_index %i", low_index);
        double barLow    = low[low_index];      // its low
        printf("bar_low %i", barLow);
      
        // draw vertical line
        ObjectCreate(0, objPrefix + "vert_line", OBJ_VLINE, 0, barTime, 0);
        
        // draw horizontal lowest line
        if (ShowMin) {
            ObjectCreate(0, objPrefix + "low_line", OBJ_TREND, 0, time[low_index+2], barLow, time[low_index-3], barLow);
        }
        
        // draw horizontal highest line
        if (ShowMax) {
            ObjectCreate(0, objPrefix + "high_line", OBJ_TREND, 0, time[high_index+2], barHigh, time[high_index-3], barHigh);
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
    
