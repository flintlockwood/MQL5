//+------------------------------------------------------------------+
//|                                             MACD Screener EA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

/*
requirements
Ma on Macd Module is the Module i want you to optimise and enhance
New Requirements (ma on macd)
1. 4 timeframe filter (ma on macd histogram same direction crossing)
2. Entry and exit determined by ma on macd histogram crossing.
3. TP,SL and Trailing SL
4. Opening of Morethan one trade at time

1. 4 timeframes filter
If crossing happens from the higher time frame down to the lower timeframe EA should buy or sell
using it's different operational time frame (operational timeframe is the timeframe EA is seating
on different from the 4 timeframes filter
2. Entry and Exit (buy or sell is determine by the operational timeframe after all conditions are
met on the 4tf filters)
3. Take profit, Stop loss and Trailing stop loss
4. EA should be able to open morethan 1 number of trade (meaning for one instrument eg GDpUSd EA
can have 1-50 opening depending on traders apartite of risk also don't forget lot size option.

Buy is triggered when the MA white line crosses the Red line while selling is triggered when the
red line ma crosses the white
Don't forget the MAs are on the same window with the macd

T1. is 1d crosses down EA will start looking for sell
T2. Is 4h crosses down
T3. Is 1h down
T4. 5m or 1m also down
Then the EA is sitting on 15m if all conditions are met EA will sell

If reverse is the case EA will buy

Now since the EA is on 15m after a brief movement the market decided to change direction on that 15m
if there is opposite crossing ea will immediately close the trade and wait for another opportunity or
conditions to be met before taken another trade

EA will only trade 1 instrument at a time

If i want it on another instrument i will set it up

Trailing based on percentage will be better which maybe i can set manually

What i mean by opening morethan 1 trade is for 1 instrument let's say Goldusd i can have 0.1 10 times
or more there should be textfield

*/

#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   5
#property indicator_label1  "MACD"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrPurple
#property indicator_width1  2
#property indicator_label2  "Signal1"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhite
#property indicator_width2  1
#property indicator_label3  "Signal2"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_width3  1
#property indicator_label4  "BuySignal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label5  "SellSignal"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrYellow
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
#property indicator_label6  "Time"
#property indicator_type6   DRAW_NONE

#define MUF_MAGIC 141592

//--- input parameters
input int                InpFastEMA=35;               // Fast EMA period
input int                InpSlowEMA=40;               // Slow EMA period
input int                InpMAPeriod1=1;              // Signal SMA period
input int                InpMAPeriod2=3;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price

input ENUM_TIMEFRAMES T1Timeframe = PERIOD_D1;
input ENUM_TIMEFRAMES T2Timeframe = PERIOD_H4;
input ENUM_TIMEFRAMES T3Timeframe = PERIOD_H1;
input ENUM_TIMEFRAMES T4Timeframe = PERIOD_M30;

//--- indicator buffers
double T0MacdBuffer[];
double T0Signal1Buffer[];
double T0Signal2Buffer[];
double BuySignalBuffer[];
double SellSignalBuffer[];
double TimeBuffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
    SetIndexBuffer(0,T0MacdBuffer,INDICATOR_DATA);
    SetIndexBuffer(1,T0Signal1Buffer,INDICATOR_DATA);
    SetIndexBuffer(2,T0Signal2Buffer,INDICATOR_DATA);
    SetIndexBuffer(3,BuySignalBuffer,INDICATOR_DATA);
    SetIndexBuffer(4,SellSignalBuffer,INDICATOR_DATA);
    SetIndexBuffer(5,TimeBuffer,INDICATOR_CALCULATIONS);

    PlotIndexSetInteger(3,PLOT_ARROW,233);
    PlotIndexSetInteger(4,PLOT_ARROW,234);

    PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,10);
    PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-10);

    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- name for indicator subwindow label
    string short_name=StringFormat("MACD(%d,%d,%d,%d)",InpFastEMA,InpSlowEMA,InpMAPeriod1,InpMAPeriod2);
    IndicatorSetString(INDICATOR_SHORTNAME,short_name);

    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
}
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
                const int &spread[]) {   // value array for handling
//    double temp[];
//    CopyClose(_Symbol, PERIOD_D1, 0, 10, temp);
//    double temp2[];
//    CopyClose(_Symbol, PERIOD_D1, D'2024.09.30', 5, temp2);
//
//    double price[];
//    getPriceData(InpAppliedPrice, _Symbol, T1Timeframe, 0, 10, price);
//    double price2[];
//    datetime dt = D'30.09.2024';
//    getPriceData(InpAppliedPrice, _Symbol, T1Timeframe, dt, 100, price2);
//    double sma[];
//    calculateSMA(_Symbol, T1Timeframe, 0, 2, 12, sma);
//    double ema[];
//    calculateEMA(_Symbol, T1Timeframe, 0, 2, 12, ema);
//    double macd[];
//    double signal[];
//    calculateMACD(_Symbol, T1Timeframe, 0, 2, 12, 26, 9, macd, signal);

// Only do this on a new bar
    if (rates_total==prev_calculated) {
        return(rates_total);
    }

// can not do calculation because available bar is less than InpSignalSMA
    if(rates_total<InpMAPeriod1 || rates_total<InpMAPeriod2)
        return(0);

    double price[];
    double fastEma[];
    double slowEma[];
    ArrayResize(fastEma, rates_total);
    ArrayResize(slowEma, rates_total);
    getPriceData(InpAppliedPrice, _Symbol, PERIOD_CURRENT, 0, rates_total, price);
    ExponentialMAOnBuffer(rates_total, 0, 0, InpFastEMA, price, fastEma);
    ExponentialMAOnBuffer(rates_total, 0, 0, InpSlowEMA, price, slowEma);

    for(int i=0; i<rates_total; i++) {
        T0MacdBuffer[i] = fastEma[i] - slowEma[i];
    }

    for(int i=0; i<rates_total; i++) {
        if (i < InpMAPeriod1-1) {
            T0Signal1Buffer[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-InpMAPeriod1+1; j<=i; j++) {
                temp = temp + T0MacdBuffer[j];
            }
            temp = temp / InpMAPeriod1;
            T0Signal1Buffer[i] = temp;
        }

        if (i < InpMAPeriod2-1) {
            T0Signal2Buffer[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-InpMAPeriod2+1; j<=i; j++) {
                temp = temp + T0MacdBuffer[j];
            }
            temp = temp / InpMAPeriod2;
            T0Signal2Buffer[i] = temp;
        }
    }

    ArrayResize(BuySignalBuffer, rates_total);
    ArrayResize(SellSignalBuffer, rates_total);
    ArrayInitialize(BuySignalBuffer, EMPTY_VALUE);
    ArrayInitialize(SellSignalBuffer, EMPTY_VALUE);
    double emptyvalue = EMPTY_VALUE;

    for(int i=0; i<rates_total-1; i++) {
        TimeBuffer[i] = time[i];

        datetime t0time = time[i];
        double t0macd[];
        double t0signal1[];
        double t0signal2[];
        calculateMACD(_Symbol, PERIOD_CURRENT, t0time, 2, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t0macd, t0signal1, t0signal2);

        datetime t1time = time[i] - time[i] % PeriodSeconds(T1Timeframe);
        double t1macd[];
        double t1signal1[];
        double t1signal2[];
        calculateMACD(_Symbol, T1Timeframe, t1time, 2, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t1macd, t1signal1, t1signal2);

        datetime t2time = time[i] - time[i] % PeriodSeconds(T2Timeframe);
        double t2macd[];
        double t2signal1[];
        double t2signal2[];
        calculateMACD(_Symbol, T2Timeframe, t2time, 2, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t2macd, t2signal1, t2signal2);

        datetime t3time = time[i] - time[i] % PeriodSeconds(T3Timeframe);
        double t3macd[];
        double t3signal1[];
        double t3signal2[];
        calculateMACD(_Symbol, T3Timeframe, t3time, 2, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t3macd, t3signal1, t3signal2);

        datetime t4time = time[i] - time[i] % PeriodSeconds(T4Timeframe);
        double t4macd[];
        double t4signal1[];
        double t4signal2[];
        calculateMACD(_Symbol, T4Timeframe, t4time, 2, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t4macd, t4signal1, t4signal2);

        if (ArraySize(t0signal1)==2 && ArraySize(t1signal1)==2 && ArraySize(t2signal1)==2 && ArraySize(t3signal1)==2 && ArraySize(t4signal1)==2
                && ArraySize(t0signal2)==2 && ArraySize(t1signal2)==2 && ArraySize(t2signal2)==2 && ArraySize(t3signal2)==2 && ArraySize(t4signal2)==2) {
            bool buyCondition0 = t0signal1[1] > t0signal2[1];
            bool buyCondition1 = t1signal1[1] > t1signal2[1];
            bool buyCondition2 = t2signal1[1] > t2signal2[1];
            bool buyCondition3 = t3signal1[1] > t3signal2[1];
            bool buyCondition4 = t4signal1[1] > t4signal2[1];

            if (buyCondition0 && buyCondition1 && buyCondition2 && buyCondition3 && buyCondition4) {
                BuySignalBuffer[i] = MathMin(t0signal1[1], t0signal2[1]);
            } else {
                BuySignalBuffer[i] = EMPTY_VALUE;
            }

            bool sellCondition0 = t0signal1[1] < t0signal2[1];
            bool sellCondition1 = t1signal1[1] < t1signal2[1];
            bool sellCondition2 = t2signal1[1] < t2signal2[1];
            bool sellCondition3 = t3signal1[1] < t3signal2[1];
            bool sellCondition4 = t4signal1[1] < t4signal2[1];
            if (sellCondition0 && sellCondition1 && sellCondition2 && sellCondition3 && sellCondition4) {
                SellSignalBuffer[i] = MathMax(t0signal1[1], t0signal2[1]);
            } else {
                SellSignalBuffer[i] = EMPTY_VALUE;
            }
        } else {
            BuySignalBuffer[i] = EMPTY_VALUE;
            SellSignalBuffer[i] = EMPTY_VALUE;
        }
    }
    
    for(int i=ArraySize(BuySignalBuffer)-1; i>=0; i--) {
        if (BuySignalBuffer[i] != emptyvalue) {
            bool b = true;
        }
    }
    
    for(int i=ArraySize(SellSignalBuffer)-1; i>=0; i--) {
        if (SellSignalBuffer[i] != emptyvalue) {
            bool b = true;
        }
    }

    return rates_total;
}
//+------------------------------------------------------------------+
void getMacdBuffer(int handle, double &macdBuffer[], double &signalBuffer[]) {
    if (handle==INVALID_HANDLE) {
        return;
    }
    int to_copy = BarsCalculated(handle);
    if(CopyBuffer(handle,0,0,to_copy,macdBuffer)<=0) {
        Print("Getting MACD buffer is failed! Error ",GetLastError());
    }
    if(CopyBuffer(handle,1,0,to_copy,signalBuffer)<=0) {
        Print("Getting Signal buffer is failed! Error ",GetLastError());
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMacdBuffer(int handle, int startindex, int cnt, double &macdBuffer[], double &signalBuffer[]) {
    if (handle==INVALID_HANDLE) {
        return -1;
    }
    int res = CopyBuffer(handle,0,startindex,cnt,macdBuffer);
    if (res < cnt) {
        Print("Getting MACD buffer is failed! Error ",GetLastError());
    }
    res = CopyBuffer(handle,1,startindex,cnt,signalBuffer);
    if(res < cnt) {
        Print("Getting Signal buffer is failed! Error ",GetLastError());
    }
    return res;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getMacdBuffer(int handle, datetime starttime, datetime endtime, double &macdBuffer[], double &signalBuffer[]) {
    if (handle==INVALID_HANDLE) {
        return;
    }
    int to_copy = BarsCalculated(handle);
    if(CopyBuffer(handle,0,starttime,endtime,macdBuffer)<=0) {
        Print("Getting MACD buffer is failed! Error ",GetLastError());
    }
    if(CopyBuffer(handle,1,starttime,endtime,signalBuffer)<=0) {
        Print("Getting Signal buffer is failed! Error ",GetLastError());
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkBuyCriteriaSingle(double &macdbuff[], double &signalbuff[]) {
    return macdbuff[0] > signalbuff[0] && macdbuff[1] > signalbuff[1];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkSellCriteriaSingle(double &macdbuff[], double &signalbuff[]) {
    return macdbuff[0] < signalbuff[0] && macdbuff[1] < signalbuff[1];
}

//+------------------------------------------------------------------+
void getPriceData(ENUM_APPLIED_PRICE ap, string symbol, ENUM_TIMEFRAMES tf, int startpos, int count, double &price[]) {
    switch (ap) {
    case PRICE_OPEN:
        CopyOpen(symbol, tf, startpos, count, price);
        break;
    case PRICE_HIGH:
        CopyHigh(symbol, tf, startpos, count, price);
        break;
    case PRICE_LOW:
        CopyLow(symbol, tf, startpos, count, price);
        break;
    case PRICE_CLOSE:
        CopyClose(symbol, tf, startpos, count, price);
        break;
    case PRICE_MEDIAN: {
        double high[];
        CopyHigh(symbol, tf, startpos, count, high);
        double low[];
        CopyLow(symbol, tf, startpos, count, low);
        ArrayResize(price, count);
        for (int i=0; i<count; i++) {
            price[i] = (high[i] + low[i]) / 2;
        }
        break;
    }
    case PRICE_TYPICAL: {
        double high[];
        CopyHigh(symbol, tf, startpos, count, high);
        double low[];
        CopyLow(symbol, tf, startpos, count, low);
        double close[];
        CopyClose(symbol, tf, startpos, count, close);
        ArrayResize(price, count);
        for (int i=0; i<count; i++) {
            price[i] = (high[i] + low[i] + close[i]) / 3;
        }
        break;
    }
    case PRICE_WEIGHTED: {
        double open[];
        CopyOpen(symbol, tf, startpos, count, open);
        double high[];
        CopyHigh(symbol, tf, startpos, count, high);
        double low[];
        CopyLow(symbol, tf, startpos, count, low);
        double close[];
        CopyClose(symbol, tf, startpos, count, close);
        ArrayResize(price, count);
        for (int i=0; i<count; i++) {
            price[i] = (open[i] + high[i] + low[i] + close[i]) / 4;
        }
        break;
    }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getPriceData(ENUM_APPLIED_PRICE ap, string symbol, ENUM_TIMEFRAMES tf, datetime startdatetime, int count, double &price[]) {
    switch (ap) {
    case PRICE_OPEN:
        CopyOpen(symbol, tf, startdatetime, count, price);
        break;
    case PRICE_HIGH:
        CopyHigh(symbol, tf, startdatetime, count, price);
        break;
    case PRICE_LOW:
        CopyLow(symbol, tf, startdatetime, count, price);
        break;
    case PRICE_CLOSE:
        CopyClose(symbol, tf, startdatetime, count, price);
        break;
    case PRICE_MEDIAN: {
        double high[];
        CopyHigh(symbol, tf, startdatetime, count, high);
        double low[];
        CopyLow(symbol, tf, startdatetime, count, low);
        ArrayResize(price, count);
        for (int i=0; i<count; i++) {
            price[i] = (high[i] + low[i]) / 2;
        }
        break;
    }
    case PRICE_TYPICAL: {
        double high[];
        CopyHigh(symbol, tf, startdatetime, count, high);
        double low[];
        CopyLow(symbol, tf, startdatetime, count, low);
        double close[];
        CopyClose(symbol, tf, startdatetime, count, close);
        ArrayResize(price, count);
        for (int i=0; i<count; i++) {
            price[i] = (high[i] + low[i] + close[i]) / 3;
        }
        break;
    }
    case PRICE_WEIGHTED: {
        double open[];
        CopyOpen(symbol, tf, startdatetime, count, open);
        double high[];
        CopyHigh(symbol, tf, startdatetime, count, high);
        double low[];
        CopyLow(symbol, tf, startdatetime, count, low);
        double close[];
        CopyClose(symbol, tf, startdatetime, count, close);
        ArrayResize(price, count);
        for (int i=0; i<count; i++) {
            price[i] = (open[i] + high[i] + low[i] + close[i]) / 4;
        }
        break;
    }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateSMA(string symbol, ENUM_TIMEFRAMES tf, int startpost, int count, int maperiod, double &result[]) {
    double price[];
    getPriceData(InpAppliedPrice, _Symbol, tf, startpost, maperiod+count-1, price);
    ArrayResize(result, count);
    for (int i=0; i<count; i++) {
        double temp = 0;
        for (int j=i; j<i+maperiod; j++) {
            temp = temp + price[j];
        }
        temp = temp / maperiod;
        result[i] = temp;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateSMA(string symbol, ENUM_TIMEFRAMES tf, datetime startdatetime, int count, int maperiod, double &result[]) {
    double price[];
    getPriceData(InpAppliedPrice, _Symbol, tf, startdatetime, maperiod+count-1, price);
    ArrayResize(result, count);
    for (int i=0; i<count; i++) {
        double temp = 0;
        for (int j=i; j<i+maperiod; j++) {
            temp = temp + price[j];
        }
        temp = temp / maperiod;
        result[i] = temp;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateEMA(string symbol, ENUM_TIMEFRAMES tf, int startpost, int count, int maperiod, double &result[]) {
    ArrayResize(result, count);
    ArrayInitialize(result, 0);
    double price[];
    getPriceData(InpAppliedPrice, _Symbol, tf, startpost, maperiod+count-1+100, price);
    if (ArraySize(price) != maperiod+count-1+100) {
        return;
    }

    double ema[];
    ArrayResize(ema, ArraySize(price));
    ema[0] = price[0];
    double SmoothFactor=2.0/(1.0+maperiod);
    for(int i=1; i<ArraySize(ema); i++)
        ema[i]=price[i]*SmoothFactor+ema[i-1]*(1.0-SmoothFactor);

    for (int i=0; i<count; i++) {
        result[i] = ema[ArraySize(ema)-count+i];
    }
}
//+------------------------------------------------------------------+
void calculateEMA(string symbol, ENUM_TIMEFRAMES tf, datetime startdatetime, int count, int maperiod, double &result[]) {
    ArrayResize(result, count);
    ArrayInitialize(result, 0);
    double price[];
    getPriceData(InpAppliedPrice, _Symbol, tf, startdatetime, maperiod+count-1+100, price);
    if (ArraySize(price) != maperiod+count-1+100) {
        return;
    }

    double ema[];
    ArrayResize(ema, ArraySize(price));
    ema[0] = price[0];
    double SmoothFactor=2.0/(1.0+maperiod);
    for(int i=1; i<ArraySize(ema); i++)
        ema[i]=price[i]*SmoothFactor+ema[i-1]*(1.0-SmoothFactor);

    for (int i=0; i<count; i++) {
        result[i] = ema[ArraySize(ema)-count+i];
    }
}
//+------------------------------------------------------------------+
void calculateMACD(string symbol, ENUM_TIMEFRAMES tf, int startpos, int count, int fastperiod, int slowperiod, int signal1period, int signal2period, double &macdresult[], double &signal1result[], double &signal2result[]) {
    int signalperiod = MathMax(signal1period, signal2period);
    double emafast[];
    calculateEMA(symbol, tf, startpos, count+signalperiod-1, fastperiod, emafast);
    double emaslow[];
    calculateEMA(symbol, tf, startpos, count+signalperiod-1, slowperiod, emaslow);
    double macd[];
    ArrayResize(macd, ArraySize(emafast));
    for(int i=0; i<ArraySize(macd); i++) {
        macd[i] = emafast[i] - emaslow[i];
    }
    ArrayResize(macdresult, count);
    for (int i=0; i<count; i++) {
        macdresult[i] = macd[ArraySize(macd)-count+i];
    }
    double ma1[];
    ArrayResize(ma1, ArraySize(macd));
    for(int i=0; i<ArraySize(macd); i++) {
        if (i < signal1period-1) {
            ma1[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-signal1period+1; j<=i; j++) {
                temp = temp + macd[j];
            }
            temp = temp / signal1period;
            ma1[i] = temp;
        }
    }
    ArrayResize(signal1result, count);
    for (int i=0; i<count; i++) {
        signal1result[i] = ma1[ArraySize(ma1)-count+i];
    }
    double ma2[];
    ArrayResize(ma2, ArraySize(macd));
    for(int i=0; i<ArraySize(macd); i++) {
        if (i < signal2period-1) {
            ma2[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-signal2period+1; j<=i; j++) {
                temp = temp + macd[j];
            }
            temp = temp / signal2period;
            ma2[i] = temp;
        }
    }
    ArrayResize(signal2result, count);
    for (int i=0; i<count; i++) {
        signal2result[i] = ma2[ArraySize(ma2)-count+i];
    }
}
//+------------------------------------------------------------------+
void calculateMACD(string symbol, ENUM_TIMEFRAMES tf, datetime startdatetime, int count, int fastperiod, int slowperiod, int signal1period, int signal2period, double &macdresult[], double &signal1result[], double &signal2result[]) {
    int signalperiod = MathMax(signal1period, signal2period);
    double emafast[];
    calculateEMA(symbol, tf, startdatetime, count+signalperiod-1, fastperiod, emafast);
    double emaslow[];
    calculateEMA(symbol, tf, startdatetime, count+signalperiod-1, slowperiod, emaslow);
    double macd[];
    ArrayResize(macd, ArraySize(emafast));
    for(int i=0; i<ArraySize(macd); i++) {
        macd[i] = emafast[i] - emaslow[i];
    }
    ArrayResize(macdresult, count);
    for (int i=0; i<count; i++) {
        macdresult[i] = macd[ArraySize(macd)-count+i];
    }
    double ma1[];
    ArrayResize(ma1, ArraySize(macd));
    for(int i=0; i<ArraySize(macd); i++) {
        if (i < signal1period-1) {
            ma1[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-signal1period+1; j<=i; j++) {
                temp = temp + macd[j];
            }
            temp = temp / signal1period;
            ma1[i] = temp;
        }
    }
    ArrayResize(signal1result, count);
    for (int i=0; i<count; i++) {
        signal1result[i] = ma1[ArraySize(ma1)-count+i];
    }
    double ma2[];
    ArrayResize(ma2, ArraySize(macd));
    for(int i=0; i<ArraySize(macd); i++) {
        if (i < signal2period-1) {
            ma2[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-signal2period+1; j<=i; j++) {
                temp = temp + macd[j];
            }
            temp = temp / signal2period;
            ma2[i] = temp;
        }
    }
    ArrayResize(signal2result, count);
    for (int i=0; i<count; i++) {
        signal2result[i] = ma2[ArraySize(ma2)-count+i];
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ExponentialMAOnBuffer(const int rates_total,const int prev_calculated,const int begin,const int period,const double& price[],double& buffer[]) {
//--- check period
    if(period<=1 || period>(rates_total-begin))
        return(0);
//--- save and clear 'as_series' flags
    bool as_series_price=ArrayGetAsSeries(price);
    bool as_series_buffer=ArrayGetAsSeries(buffer);

    ArraySetAsSeries(price,false);
    ArraySetAsSeries(buffer,false);
//--- calculate start position
    int    start_position;
    double smooth_factor=2.0/(1.0+period);

    if(prev_calculated==0) { // first calculation or number of bars was changed
        //--- set empty value for first bars
        for(int i=0; i<begin; i++)
            buffer[i]=0.0;
        //--- calculate first visible value
        start_position=period+begin;
        buffer[begin] =price[begin];

        for(int i=begin+1; i<start_position; i++)
            buffer[i]=price[i]*smooth_factor+buffer[i-1]*(1.0-smooth_factor);
    } else
        start_position=prev_calculated-1;
//--- main loop
    for(int i=start_position; i<rates_total; i++)
        buffer[i]=price[i]*smooth_factor+buffer[i-1]*(1.0-smooth_factor);
//--- restore as_series flags
    ArraySetAsSeries(price,as_series_price);
    ArraySetAsSeries(buffer,as_series_buffer);
//---
    return(rates_total);
}
//+------------------------------------------------------------------+
