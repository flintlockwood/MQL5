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
    PERIOD_M19,
    PERIOD_M45
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

int CopyAppliedPrice(string symbol_name, ENUM_TIMEFRAMES timeframe, ENUM_APPLIED_PRICE applied_price, int start_pos, int count, double &applied_price_array[]) {
    double open_array[];
    double high_array[];
    double low_array[];
    double close_array[];
    switch (applied_price)
    {
        case ENUM_APPLIED_PRICE::PRICE_CLOSE:
            return CopyClose(symbol_name, timeframe, start_pos, count, applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_HIGH:
            return CopyHigh(symbol_name, timeframe, start_pos, count, applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_LOW:
            return CopyLow(symbol_name, timeframe, start_pos, count, applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_MEDIAN:
            CopyHigh(symbol_name, timeframe, start_pos, count, high_array);
            CopyLow(symbol_name, timeframe, start_pos, count, low_array);
            ArrayResize(applied_price_array, ArraySize(high_array));
            for (int i=0; i<ArraySize(high_array); i++) {
                applied_price_array[i] = (high_array[i] + low_array[i]) / 2;
            }
            return ArraySize(applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_OPEN:
            return CopyOpen(symbol_name, timeframe, start_pos, count, applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_TYPICAL:
            CopyHigh(symbol_name, timeframe, start_pos, count, high_array);
            CopyLow(symbol_name, timeframe, start_pos, count, low_array);
            CopyLow(symbol_name, timeframe, start_pos, count, close_array);
            ArrayResize(applied_price_array, ArraySize(high_array));
            for (int i=0; i<ArraySize(high_array); i++) {
                applied_price_array[i] = (high_array[i] + low_array[i] + close_array[i]) / 3;
            }
            return ArraySize(applied_price_array);
        case ENUM_APPLIED_PRICE::PRICE_WEIGHTED:
            CopyHigh(symbol_name, timeframe, start_pos, count, high_array);
            CopyLow(symbol_name, timeframe, start_pos, count, low_array);
            CopyLow(symbol_name, timeframe, start_pos, count, close_array);
            ArrayResize(applied_price_array, ArraySize(high_array));
            for (int i=0; i<ArraySize(high_array); i++) {
                applied_price_array[i] = (high_array[i] + low_array[i] + close_array[i] + open_array[i]) / 4;
            }
            return ArraySize(applied_price_array);
        default:
            return 0;
    }
}

int CopyTR(string symbol_name, ENUM_TIMEFRAMES timeframe, int start_pos, int count, double &tr_array[]) {
    double low_array[];
    double high_array[];
    double close_array[];

    CopyLow(symbol_name, timeframe, start_pos, count, low_array);
    CopyHigh(symbol_name, timeframe, start_pos, count, high_array);
    CopyClose(symbol_name, timeframe, start_pos, count, close_array);
    
    InitializeArray(tr_array, count, EMPTY_VALUE);
    for (int i=0; i<ArraySize(high_array); i++) {
        tr_array[i] = MathMax(MathMax(high_array[i] - low_array[i], MathAbs(high_array[i] - close_array[i])), MathAbs(low_array[i] - close_array[i]));
    }

    return count;
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

void CopyRatesCustom(string symbol, ENUM_TIMEFRAMES_CUSTOM timeframe, int start_pos, int count, MqlRates &rates[]){
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
