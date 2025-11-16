//+------------------------------------------------------------------+
//|                                             MACD Screener EA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
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
#property indicator_label3  "BuySignal"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label4  "SellSignal"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrYellow
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#define MUF_MAGIC 141592

//--- input parameters
input int                InpFastEMA=35;               // Fast EMA period
input int                InpSlowEMA=40;               // Slow EMA period
input int                InpMAPeriod=3;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price

input bool            Enable_TF1  = true;
input ENUM_TIMEFRAMES T1Timeframe = PERIOD_D1;
input bool            Enable_TF2  = true;
input ENUM_TIMEFRAMES T2Timeframe = PERIOD_H4;
input bool            Enable_TF3  = true;
input ENUM_TIMEFRAMES T3Timeframe = PERIOD_H1;
input bool            Enable_TF4  = true;
input ENUM_TIMEFRAMES T4Timeframe = PERIOD_M30;
input bool            Enable_TF5  = true;
input ENUM_TIMEFRAMES T5Timeframe = PERIOD_M5;

//--- indicator buffers
double MacdBuffer[];
double SignalLineBuffer[];
double BuySignalBuffer[];
double SellSignalBuffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
    SetIndexBuffer(0,MacdBuffer,INDICATOR_DATA);
    SetIndexBuffer(1,SignalLineBuffer,INDICATOR_DATA);
    SetIndexBuffer(2,BuySignalBuffer,INDICATOR_DATA);
    SetIndexBuffer(3,SellSignalBuffer,INDICATOR_DATA);

    PlotIndexSetInteger(2,PLOT_ARROW,233);
    PlotIndexSetInteger(3,PLOT_ARROW,234);

    PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,10);
    PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,-10);

    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
    PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- name for indicator subwindow label
    string short_name=StringFormat("MACD(%d,%d,%d)",InpFastEMA,InpSlowEMA,InpMAPeriod);
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
    //if (rates_total==prev_calculated) {
    //    return(rates_total);
    //}

// can not do calculation because available bar is less than InpSignalSMA
    if(rates_total<InpMAPeriod)
        return(0);

    double price[];
    double fastEma[];
    double slowEma[];
    ArrayResize(fastEma, rates_total);
    ArrayResize(slowEma, rates_total);
    getPriceData(InpAppliedPrice, _Symbol, PERIOD_CURRENT, 0, rates_total, price);
    ExponentialMAOnBuffer(rates_total, 0, 0, InpFastEMA, price, fastEma);
    ExponentialMAOnBuffer(rates_total, 0, 0, InpSlowEMA, price, slowEma);

    int startcalc = prev_calculated == 0 ? 0 : prev_calculated - 1;
    for(int i=startcalc; i<rates_total; i++) {
        MacdBuffer[i] = fastEma[i] - slowEma[i];
    }

    for(int i=startcalc; i<rates_total; i++) {
        if (i < InpMAPeriod-1) {
            SignalLineBuffer[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-InpMAPeriod+1; j<=i; j++) {
                temp = temp + MacdBuffer[j];
            }
            temp = temp / InpMAPeriod;
            SignalLineBuffer[i] = temp;
        }
    }

    //ArrayResize(BuySignalBuffer, rates_total);
    //ArrayResize(SellSignalBuffer, rates_total);
    //ArrayInitialize(BuySignalBuffer, EMPTY_VALUE);
    //ArrayInitialize(SellSignalBuffer, EMPTY_VALUE);
    double emptyvalue = EMPTY_VALUE;

    for(int i=startcalc; i<rates_total; i++) {
        int cnt = 2;   

        if (time[i] == D'2025.02.06 05:20') {
            bool b = true;
        }
        
        datetime currtime = (datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
        datetime closetime = time[i] + PeriodSeconds(PERIOD_CURRENT);
        datetime t1time = time[i] - (time[i] % PeriodSeconds(T1Timeframe));
        double t1macd[];
        double t1signalline[];
        if (Enable_TF1) {
            calculateMACD(_Symbol, T1Timeframe, closetime, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod, t1macd, t1signalline);
        }

        datetime t2time = time[i] - (time[i] % PeriodSeconds(T2Timeframe));
        double t2macd[];
        double t2signalline[];
        if (Enable_TF2) {
            calculateMACD(_Symbol, T2Timeframe, closetime, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod, t2macd, t2signalline);
        }

        datetime t3time = time[i] - (time[i] % PeriodSeconds(T3Timeframe));
        double t3macd[];
        double t3signalline[];
        if (Enable_TF3) {
            calculateMACD(_Symbol, T3Timeframe, closetime, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod, t3macd, t3signalline);
        }

        datetime t4time = time[i] - (time[i] % PeriodSeconds(T4Timeframe));
        double t4macd[];
        double t4signalline[];
        if (Enable_TF4) {
            calculateMACD(_Symbol, T4Timeframe, closetime, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod, t4macd, t4signalline);
        }

        datetime t5time = time[i] - (time[i] % PeriodSeconds(T5Timeframe));
        double t5macd[];
        double t5signalline[];
        if (Enable_TF5) {
            calculateMACD(_Symbol, T5Timeframe, closetime, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod, t5macd, t5signalline);
        }
        
        if ((Enable_TF1 ? ArraySize(t1macd) == cnt && ArraySize(t1signalline) == cnt : true)
              && (Enable_TF2 ? ArraySize(t2macd) == cnt && ArraySize(t2signalline) == cnt : true)
              && (Enable_TF3 ? ArraySize(t3macd) == cnt && ArraySize(t3signalline) == cnt : true)
              && (Enable_TF4 ? ArraySize(t4macd) == cnt && ArraySize(t4signalline) == cnt : true) 
              && (Enable_TF5 ? ArraySize(t5macd) == cnt && ArraySize(t5signalline) == cnt : true)) {
            bool buyCondition1 = Enable_TF1 ? t1macd[cnt-1] > t1signalline[cnt-1] : true;
            bool buyCondition2 = Enable_TF2 ? t2macd[cnt-1] > t2signalline[cnt-1] : true;
            bool buyCondition3 = Enable_TF3 ? t3macd[cnt-1] > t3signalline[cnt-1] : true;
            bool buyCondition4 = Enable_TF4 ? t4macd[cnt-1] > t4signalline[cnt-1] : true;
            bool buyCondition5 = Enable_TF5 ? t5macd[cnt-1] > t5signalline[cnt-1] && t5macd[cnt-2] <= t5signalline[cnt-2] : true;
   
            if (buyCondition1 && buyCondition2 && buyCondition3 && buyCondition4 && buyCondition5) {
                BuySignalBuffer[i] = MathMin(MacdBuffer[i], SignalLineBuffer[i]);
            } else {
                BuySignalBuffer[i] = EMPTY_VALUE;
            }
   
            bool sellCondition1 = Enable_TF1 ? t1macd[cnt-1] < t1signalline[cnt-1] : true;
            bool sellCondition2 = Enable_TF2 ? t2macd[cnt-1] < t2signalline[cnt-1] : true;
            bool sellCondition3 = Enable_TF3 ? t3macd[cnt-1] < t3signalline[cnt-1] : true;
            bool sellCondition4 = Enable_TF4 ? t4macd[cnt-1] < t4signalline[cnt-1] : true;
            bool sellCondition5 = Enable_TF5 ? t5macd[cnt-1] < t5signalline[cnt-1] && t5macd[cnt-2] >= t5signalline[cnt-2] : true;
            if (sellCondition1 && sellCondition2 && sellCondition3 && sellCondition4 && sellCondition5) {
                SellSignalBuffer[i] = MathMax(MacdBuffer[i], SignalLineBuffer[i]);
            } else {
                SellSignalBuffer[i] = EMPTY_VALUE;
            }
        }
        else {
            BuySignalBuffer[i] = EMPTY_VALUE;
            SellSignalBuffer[i] = EMPTY_VALUE;
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
        double v = NormalizeDouble(macd[ArraySize(macd)-count+i], _Digits+1);
        macdresult[i] = v;
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
        double v = NormalizeDouble(ma1[ArraySize(ma1)-count+i], _Digits+1);
        signal1result[i] = v;
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
        double v = NormalizeDouble(ma2[ArraySize(ma2)-count+i], _Digits+1);
        signal2result[i] = v;
    }
}
//+------------------------------------------------------------------+
void calculateMACD(string symbol, ENUM_TIMEFRAMES tf, datetime startdatetime, int count, int fastperiod, int slowperiod, int signallineperiod, double &macdresult[], double &signallineresult[]) {
    double emafast[];
    calculateEMA(symbol, tf, startdatetime, count+signallineperiod-1, fastperiod, emafast);
    double emaslow[];
    calculateEMA(symbol, tf, startdatetime, count+signallineperiod-1, slowperiod, emaslow);
    double macd[];
    ArrayResize(macd, ArraySize(emafast));
    for(int i=0; i<ArraySize(macd); i++) {
        macd[i] = emafast[i] - emaslow[i];
    }
    ArrayResize(macdresult, count);
    for (int i=0; i<count; i++) {
        macdresult[i] = macd[ArraySize(macd)-count+i];
    }
    double ma[];
    ArrayResize(ma, ArraySize(macd));
    for(int i=0; i<ArraySize(macd); i++) {
        if (i < signallineperiod-1) {
            ma[i] = EMPTY_VALUE;
        } else {
            double temp = 0;
            for (int j=i-signallineperiod+1; j<=i; j++) {
                temp = temp + macd[j];
            }
            temp = temp / signallineperiod;
            ma[i] = temp;
        }
    }
    ArrayResize(signallineresult, count);
    for (int i=0; i<count; i++) {
        signallineresult[i] = ma[ArraySize(ma)-count+i];
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
