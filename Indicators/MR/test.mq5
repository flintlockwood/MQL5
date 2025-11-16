//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

int handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
    handle = iCustom(_Symbol, PERIOD_CURRENT, "Market\\KT Price Border MT5");
    if (handle == INVALID_HANDLE) {
        printf("can not initialize KT Price Border indicator %d", GetLastError());
        return INIT_FAILED;
    }
//---
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    IndicatorRelease(handle);
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
    double buff0[], buff1[], buff2[], buff3[], buff4[];
    CopyBuffer(handle, 0, 0, 1, buff0);
    CopyBuffer(handle, 1, 0, 1, buff1);
    CopyBuffer(handle, 2, 0, 1, buff2);
    CopyBuffer(handle, 3, 0, 1, buff3);
    CopyBuffer(handle, 4, 0, 1, buff4);

    printf("%s onCalculate", TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS));
//--- return value of prev_calculated for next call
    return prev_calculated;
}
//+------------------------------------------------------------------+
