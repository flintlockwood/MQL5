//+------------------------------------------------------------------+
//|                                          IndicatorSuperTrend.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot UpTrendBuy
#property indicator_label1  "UpTrendBuy"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot DownTrendSell
#property indicator_label2  "DownTrendSell"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#include <MovingAverages.mqh>
#include "TimeSeries.mqh"

enum ENUM_SMOOTING_METHOD {
    SMA,
    RMA
};

//--- input parameters
input int                  inp_period = 10;
input double               inp_atr_multiplier = 3.1;
input ENUM_MA_METHOD       inp_smooting_method = ENUM_MA_METHOD::MODE_SMMA;
input ENUM_APPLIED_PRICE   inp_applied_price = ENUM_APPLIED_PRICE::PRICE_OPEN;

//--- buffers
double                     tr_buffer[];
double                     atr_buffer[];
double                     applied_price[];
double                     lower_band_buffer[];
double                     upper_band_buffer[];
double                     trend_buffer[];
double                     signal1_buffer[];
double                     signal2_buffer[];
double                     signal3_buffer[];

//--- Indicator buffers
double                     uptrend_buffer[];
double                     downtrend_buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
    SetIndexBuffer(0, uptrend_buffer, INDICATOR_DATA);
    SetIndexBuffer(1, downtrend_buffer, INDICATOR_DATA);
    SetIndexBuffer(2, signal1_buffer, INDICATOR_DATA);
    SetIndexBuffer(3, signal2_buffer, INDICATOR_DATA);
    SetIndexBuffer(4, signal3_buffer, INDICATOR_DATA);

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

    InitializeArray(tr_buffer, rates_total, EMPTY_VALUE);
    tr_buffer[0] = high[0] - low[0];
    for (int i=1; i<rates_total; i++) {
        tr_buffer[i] = MathMax(MathMax(high[i] - low[i], MathAbs(high[i] - close[i-1])), MathAbs(low[i] - close[i-1]));
    }

    InitializeArray(atr_buffer, rates_total, EMPTY_VALUE);
    if (inp_smooting_method == ENUM_MA_METHOD::MODE_SMA) {
        SimpleMAOnBuffer(rates_total, 0, 0, inp_period, tr_buffer, atr_buffer);
    }
    else if (inp_smooting_method== ENUM_MA_METHOD::MODE_SMMA) {
        SmoothedMAOnBuffer(rates_total, 0, 0, inp_period, tr_buffer, atr_buffer);
    }
    else if (inp_smooting_method== ENUM_MA_METHOD::MODE_EMA) {
        ExponentialMAOnBuffer(rates_total, 0, 0, inp_period, tr_buffer, atr_buffer);
    }
    else if (inp_smooting_method== ENUM_MA_METHOD::MODE_LWMA) {
        LinearWeightedMAOnBuffer(rates_total, 0, 0, inp_period, tr_buffer, atr_buffer);
    }

    InitializeArray(applied_price, rates_total, EMPTY_VALUE);
    CopyAppliedPrice(_Symbol, _Period, inp_applied_price, 0, rates_total, applied_price);

    InitializeArray(lower_band_buffer, rates_total, EMPTY_VALUE);
    InitializeArray(upper_band_buffer, rates_total, EMPTY_VALUE);
    InitializeArray(trend_buffer, rates_total, 1);
    InitializeArray(signal1_buffer, rates_total, EMPTY_VALUE);
    InitializeArray(signal2_buffer, rates_total, EMPTY_VALUE);
    InitializeArray(signal3_buffer, rates_total, EMPTY_VALUE);
    InitializeArray(uptrend_buffer, rates_total, EMPTY_VALUE);
    InitializeArray(downtrend_buffer, rates_total, EMPTY_VALUE);

    lower_band_buffer[0] = applied_price[0] - atr_buffer[0] * inp_atr_multiplier;
    upper_band_buffer[0] = applied_price[0] + atr_buffer[0] * inp_atr_multiplier;
    for (int i=1; i<rates_total; i++) {
        lower_band_buffer[i] = applied_price[i] - atr_buffer[i] * inp_atr_multiplier;
        double prev_lower_band = lower_band_buffer[i-1] == EMPTY_VALUE ? lower_band_buffer[i] : lower_band_buffer[i-1];
        lower_band_buffer[i] = close[i-1] > prev_lower_band ? MathMax(lower_band_buffer[i], prev_lower_band) : lower_band_buffer[i];
        
        upper_band_buffer[i] = applied_price[i] + atr_buffer[i] * inp_atr_multiplier;
        double prev_upper_band = upper_band_buffer[i-1] == EMPTY_VALUE ? upper_band_buffer[i] : upper_band_buffer[i-1];
        upper_band_buffer[i] = close[i-1] < prev_upper_band ? MathMin(upper_band_buffer[i], prev_upper_band) : upper_band_buffer[i];

        trend_buffer[i] = trend_buffer[i-1] == EMPTY_VALUE ? trend_buffer[i] : trend_buffer[i-1];
        trend_buffer[i] = trend_buffer[i] == -1 && close[i] > prev_upper_band ? 1 : trend_buffer[i] == 1 && close[i] < prev_lower_band ? -1 : trend_buffer[i];

        signal1_buffer[i] = trend_buffer[i] == 1 ? 1 : 0;
        signal2_buffer[i] = trend_buffer[i] == 1 && close[i] > close[i-1] ? 1 : 0;
        signal3_buffer[i] = trend_buffer[i] == 1 && trend_buffer[i-1] == -1 ? 1 : 0;

        if (trend_buffer[i] == 1) {
            uptrend_buffer[i] = lower_band_buffer[i];
        }
        else if (trend_buffer[i] == -1){
            downtrend_buffer[i] = upper_band_buffer[i];
        }
    }

//--- return value of prev_calculated for next call
    return(rates_total);
}
//+------------------------------------------------------------------+
