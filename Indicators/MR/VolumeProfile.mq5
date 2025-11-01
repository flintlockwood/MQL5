//+------------------------------------------------------------------+
//|                                                VolumeProfile.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping

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
    datetime fromdt = time[ArraySize(time)-1] - 16 * PeriodSeconds(PERIOD_CURRENT);
    datetime todt = time[ArraySize(time)-1] + PeriodSeconds(PERIOD_CURRENT);
    MqlTick ticks[];
    CopyTicksRange(_Symbol, ticks, COPY_TICKS_ALL, fromdt, todt);
    for (int i=0; i<ArraySize(ticks); i++) {
        
    }
//--- return value of prev_calculated for next call
    return(rates_total);
}
//+------------------------------------------------------------------+
