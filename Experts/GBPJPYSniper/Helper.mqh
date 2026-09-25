//+------------------------------------------------------------------+
//|                                                       Helper.mqh |
//|                                                  Mufraeli Rahman |
//|                                                     www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MovingAverages.mqh>

enum ENUM_TIMEFRAMES_CUSTOM {    
    PERIOD_M19 = 119,
    PERIOD_M45 = 145
};

// initialize array with value 
void InitializeArray(double &array[], int size, double value = EMPTY_VALUE) {
    ArrayResize(array, size);
    ArrayInitialize(array, value);
}

void InitializeArray(bool &array[], int size, bool value = false) {
    ArrayResize(array, size);
    ArrayInitialize(array, value);
}

int BarsCustom(string symbol, int timeframe) {
    if (timeframe < 100) {
        return Bars(symbol, (ENUM_TIMEFRAMES)timeframe);
    }
    else {
        datetime times[];
        CopyTime(symbol, PERIOD_M1, 0, Bars(symbol, PERIOD_M1), times);
        int cnt = 0;
        int pm = GetPeriodSeconds(timeframe) / 60;
        for (int i=0; i<ArraySize(times); i++) {
            if (times[i] % pm == 0) {
                cnt++;
            }
        }
        return cnt;
    }
}

int CopyAppliedPrice(string symbol_name, int timeframe, ENUM_APPLIED_PRICE applied_price, int start_pos, int count, double &applied_price_array[]) {
    double open_array[];
    double high_array[];
    double low_array[];
    double close_array[];
    if (timeframe < 100) {
        CopyOpen(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, open_array);
        CopyHigh(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, high_array);
        CopyLow(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, low_array);
        CopyClose(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, close_array);
    }
    else {
        MqlRates rates[];
        CopyRatesCustom(symbol_name, timeframe, 0, rates);
        CopyOpenFromMqlRates(rates, open_array);
        CopyHighFromMqlRates(rates, high_array);
        CopyLowFromMqlRates(rates, low_array);
        CopyCloseFromMqlRates(rates, close_array);
    }
    switch (applied_price)
    {
        case ENUM_APPLIED_PRICE::PRICE_CLOSE:
            return ArrayCopy(applied_price_array, close_array, 0, 0, WHOLE_ARRAY);
        case ENUM_APPLIED_PRICE::PRICE_HIGH:
            return ArrayCopy(applied_price_array, high_array, 0, 0, WHOLE_ARRAY);
        case ENUM_APPLIED_PRICE::PRICE_LOW:
            return ArrayCopy(applied_price_array, low_array, 0, 0, WHOLE_ARRAY);
        case ENUM_APPLIED_PRICE::PRICE_MEDIAN:
            ArrayResize(applied_price_array, ArraySize(high_array));
            for (int i=0; i<ArraySize(high_array); i++) {
                applied_price_array[i] = (high_array[i] + low_array[i]) / 2;
            }
            return ArraySize(applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_OPEN:
            return ArrayCopy(applied_price_array, open_array, 0, 0, WHOLE_ARRAY);
        case ENUM_APPLIED_PRICE::PRICE_TYPICAL:
            ArrayResize(applied_price_array, ArraySize(high_array));
            for (int i=0; i<ArraySize(high_array); i++) {
                applied_price_array[i] = (high_array[i] + low_array[i] + close_array[i]) / 3;
            }
            return ArraySize(applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_WEIGHTED:
            ArrayResize(applied_price_array, ArraySize(high_array));
            for (int i=0; i<ArraySize(high_array); i++) {
                applied_price_array[i] = (high_array[i] + low_array[i] + close_array[i] + open_array[i]) / 4;
            }
            return ArraySize(applied_price_array);
        default:
            return 0;
    }
}

int CopyTR(string symbol_name, int timeframe, int start_pos, int count, double &tr_array[]) {
    if (timeframe < 100) {
        double low_array[];
        double high_array[];
        double close_array[];
        if (count == -1) {
            count = Bars(symbol_name, (ENUM_TIMEFRAMES)timeframe);
        }
        CopyLow(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, low_array);
        CopyHigh(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, high_array);
        CopyClose(symbol_name, (ENUM_TIMEFRAMES)timeframe, start_pos, count, close_array);
        
        InitializeArray(tr_array, count, EMPTY_VALUE);
        for (int i=0; i<ArraySize(high_array); i++) {
            tr_array[i] = MathMax(MathMax(high_array[i] - low_array[i], MathAbs(high_array[i] - close_array[i])), MathAbs(low_array[i] - close_array[i]));
        }

        return count;
    }
    else {
        MqlRates rates[];
        CopyRatesCustom(symbol_name, timeframe, 0, rates);
        
        InitializeArray(tr_array, ArraySize(rates), EMPTY_VALUE);
        for (int i=0; i<ArraySize(rates); i++) {
            tr_array[i] = MathMax(MathMax(rates[i].high - rates[i].low, MathAbs(rates[i].high - rates[i].close)), MathAbs(rates[i].low - rates[i].close));
        }

        return ArraySize(rates);
    }
}

void MAOnBuffer(const int rates_total,const int prev_calculated,const int begin,const int period,ENUM_MA_METHOD ma_method, double& price[],double& buffer[]) {
    switch (ma_method)
    {
        case MODE_SMA:
            SimpleMAOnBuffer(rates_total, prev_calculated, begin, period, price, buffer);
            break;
        case MODE_EMA:
            ExponentialMAOnBuffer(rates_total, prev_calculated, begin, period, price, buffer);
            break;
        case MODE_LWMA:
            LinearWeightedMAOnBuffer(rates_total, prev_calculated, begin, period, price, buffer);
            break;
        case MODE_SMMA:
            SmoothedMAOnBuffer(rates_total, prev_calculated, begin, period, price, buffer);
            break;
        default:
            break;
    }
}

void CopyRatesCustom(string symbol, int timeframe, int start_pos, MqlRates &rates[]){
    if (timeframe < 100) {
        int bars = Bars(symbol, (ENUM_TIMEFRAMES)timeframe);
        CopyRates(symbol, (ENUM_TIMEFRAMES)timeframe, start_pos, bars, rates);
    }
    else {
        int bars = Bars(symbol, PERIOD_M1);
        MqlRates rates_m1[];
        CopyRates(symbol, PERIOD_M1, 0, bars, rates_m1);
        int ps = GetPeriodSeconds(timeframe);
        int pm = ps / 60;
        MqlRates temp[];
        int j = 0;
        for (int i=0; i<bars; i++) {
            if (rates_m1[i].time % ps == 0) {
                MqlRates newRate;
                newRate.time = rates_m1[i].time;
                newRate.open = temp[0].open;
                newRate.high = RatesMaximum(temp);
                newRate.low = RatesMinimum(temp);
                newRate.close = temp[ArraySize(temp)-1].close;
                newRate.real_volume = RatesRealVolumeSum(temp);
                newRate.tick_volume = RatesTickVolumeSum(temp);
                ArrayAppend(rates, newRate);
                ArrayFree(temp);
            }
            else {
                ArrayAppend(temp, rates_m1[i]);
            }
        }
    }
}

int CopyOpenFromMqlRates(MqlRates &rates[], double &open_array[]) {
    ArrayResize(open_array, ArraySize(rates));
    for (int i=0; i<ArraySize(rates); i++) {
        open_array[i] = rates[i].open;
    }
    return ArraySize(open_array);
}

int CopyHighFromMqlRates(MqlRates &rates[], double &high_array[]) {
    ArrayResize(high_array, ArraySize(rates));
    for (int i=0; i<ArraySize(rates); i++) {
        high_array[i] = rates[i].high;
    }
    return ArraySize(high_array);
}

int CopyLowFromMqlRates(MqlRates &rates[], double &low_array[]) {
    ArrayResize(low_array, ArraySize(rates));
    for (int i=0; i<ArraySize(rates); i++) {
        low_array[i] = rates[i].low;
    }
    return ArraySize(low_array);
}

int CopyCloseFromMqlRates(MqlRates &rates[], double &close_array[]) {
    ArrayResize(close_array, ArraySize(rates));
    for (int i=0; i<ArraySize(rates); i++) {
        close_array[i] = rates[i].close;
    }
    return ArraySize(close_array);
}

int GetPeriodSeconds(int timeframe) {
    if (timeframe < 100) {
        return PeriodSeconds((ENUM_TIMEFRAMES)timeframe);
    }
    else {
        switch (timeframe) {
            case PERIOD_M45:
                return 45 * 60;
            default:
                return 0;
        }
    }
}

void ArrayAppend(MqlRates &rates[], MqlRates &value) {
    int n = ArraySize(rates);
    ArrayResize(rates, n+1);
    rates[n] = value;
}

void ArrayAppend(double &rates[], double value) {
    int n = ArraySize(rates);
    ArrayResize(rates, n+1);
    rates[n] = value;
}

double RatesMinimum(MqlRates &rates[]) {
    double min = 999999999;
    for (int i=0; i<ArraySize(rates); i++) {
        if (rates[i].low < min) {
            min = rates[i].low;
        }
    }
    return min;
}

double RatesMaximum(MqlRates &rates[]) {
    double max = 0;
    for (int i=0; i<ArraySize(rates); i++) {
        if (rates[i].high > max) {
            max = rates[i].high;
        }
    }
    return max;
}

long RatesTickVolumeSum(MqlRates &rates[]) {
    long sum = 0;
    for (int i=0; i<ArraySize(rates); i++) {
        sum += rates[i].tick_volume;
    }
    return sum;
}

long RatesRealVolumeSum(MqlRates &rates[]) {
    long sum = 0;
    for (int i=0; i<ArraySize(rates); i++) {
        sum += rates[i].real_volume;
    }
    return sum;
}
