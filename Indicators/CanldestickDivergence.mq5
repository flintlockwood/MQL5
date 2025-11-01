//+------------------------------------------------------------------+
//|                                        CanldestickDivergence.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   2
//--- plot Bullish divergence
#property indicator_label1  "BullishDivergence"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- plot Bearish divergence
#property indicator_label1  "BearishDivergence"
#property indicator_type1   DRAW_ARROW
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- Buffers
double         BullishDivergenceBuffer[];
double         BearishDivergenceBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
    SetIndexBuffer(0,BullishDivergenceBuffer,INDICATOR_DATA);
    SetIndexBuffer(1,BearishDivergenceBuffer,INDICATOR_DATA);

    PlotIndexSetInteger(0,PLOT_ARROW,233);
    PlotIndexSetInteger(1,PLOT_ARROW,234);

//--- setting shift
    PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,10);
    PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);

//---
    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int32_t rates_total,
                const int32_t prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int32_t &spread[]) {
//---
    for (int i=prev_calculated; i<rates_total; i++) {
        if (i < 2) {
            return i;
        }
        // bullish divergence candlestick
        bool condition1 = open[i-2] < close[i-2] && open[i-1] < close[i-1] && open[i] > close[i];
        bool condition2 = low[i-2] < low[i-1] && low[i] < low[i-1];
        if (condition1 && condition2) {
            BullishDivergenceBuffer[i] = low[i];
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
