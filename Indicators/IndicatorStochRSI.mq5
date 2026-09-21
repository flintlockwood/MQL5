//+------------------------------------------------------------------+
//|                                            IndicatorStochRSI.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot %k
#property indicator_label1  "%K"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot %d
#property indicator_label2  "%D"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#include <MovingAverages.mqh>
#include "Helper.mqh"

//--- input parameters
input int                  inp_rsi_period = 22;
input int                  inp_stoch_length = 2;
input int                  inp_k = 19;
input int                  inp_d = 2;
input ENUM_APPLIED_PRICE   inp_rsi_source = PRICE_HIGH;
input string               inp_kd_operator = ">";

//--- buffers
double                     rsi_buffer[];

//--- Indicator buffers
double                     k_buffer[];
double                     d_buffer[];

//--- Indicator handles
int                        rsi_handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
    SetIndexBuffer(0, k_buffer, INDICATOR_DATA);
    SetIndexBuffer(1, d_buffer, INDICATOR_DATA);

//--- initialize rsi
    rsi_handle = iRSI(_Symbol, _Period, inp_rsi_period, inp_rsi_source);
    if (rsi_handle == INVALID_HANDLE) {
        printf("RSI initialization failed");
        return(INIT_FAILED);
    }

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
    InitializeArray(rsi_buffer, rates_total, EMPTY_VALUE);
    CopyBuffer(rsi_handle, 0, 0, rates_total, rsi_buffer);

    double stoch_buffer[];
    InitializeArray(stoch_buffer, rates_total, EMPTY_VALUE);
    for (int i=0; i<rates_total; i++) {
        if (i < MathMax(inp_rsi_period, inp_stoch_length) * 2) {
            continue;
        }
        double max = rsi_buffer[ArrayMaximum(rsi_buffer, i-1, inp_stoch_length)];
        double min = rsi_buffer[ArrayMinimum(rsi_buffer, i-1, inp_stoch_length)];
        double diff = max - min;
        if (diff == 0) {
            stoch_buffer[i] = 0;
        }
        else {
            //printf("i %s rsi %s max %s min %s", IntegerToString(i), DoubleToString(rsi_buffer[i], 2), DoubleToString(max, 2), DoubleToString(min, 2));
            stoch_buffer[i] = 100 * (rsi_buffer[i] - min) / diff;
        }
    }
    InitializeArray(k_buffer, rates_total, EMPTY_VALUE);
    SimpleMAOnBuffer(rates_total, 0, MathMax(MathMax(inp_rsi_period, inp_stoch_length),inp_k)*2, inp_k, stoch_buffer, k_buffer);
    InitializeArray(d_buffer, rates_total, EMPTY_VALUE);
    SimpleMAOnBuffer(rates_total, 0, MathMax(MathMax(inp_rsi_period, inp_stoch_length),inp_d)*2, inp_d, k_buffer, d_buffer);

//--- return value of prev_calculated for next call
    return(rates_total);
}
//+------------------------------------------------------------------+
