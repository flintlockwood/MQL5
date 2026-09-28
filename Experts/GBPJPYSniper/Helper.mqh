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
    PERIOD_M19 = 50019,
    PERIOD_M45 = 50045
};

int BarsCustom(string symbol, int timeframe) {
    if (timeframe < 50000) {
        return Bars(symbol, (ENUM_TIMEFRAMES)timeframe);
    }
    else {
        datetime times[];
        CopyTime(symbol, PERIOD_M1, 0, Bars(symbol, PERIOD_M1), times);
        int cnt = 0;
        int ps = GetPeriodSeconds(timeframe);
        for (int i=0; i<ArraySize(times); i++) {
            if (times[i] % ps == 0) {
                cnt++;
            }
        }
        return cnt;
    }
}

int GetPeriodSeconds(int timeframe) {
    if (timeframe < 50000) {
        return PeriodSeconds((ENUM_TIMEFRAMES)timeframe);
    }
    else {
        switch (timeframe) {
            case PERIOD_M19:
                return 19 * 60;
            case PERIOD_M45:
                return 45 * 60;
            default:
                return 0;
        }
    }
}

double GetPoint(string symbol) {
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    return point;
}

//+------------------------------------------------------------------+
//| Array Functions                                                  |
//+------------------------------------------------------------------+
void InitializeArray(double &array[], int size, double value = EMPTY_VALUE) {
    ArrayResize(array, size);
    ArrayInitialize(array, value);
}

void InitializeArray(bool &array[], int size, bool value = false) {
    ArrayResize(array, size);
    ArrayInitialize(array, value);
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

//+------------------------------------------------------------------+
//| Timeseries Functions                                             |
//+------------------------------------------------------------------+
double GetAppliedPrice(string symbol, int timeframe, ENUM_APPLIED_PRICE source, int index) {
    double open = EMPTY_VALUE;
    double high = EMPTY_VALUE;
    double low = EMPTY_VALUE;
    double close = EMPTY_VALUE;
    if (timeframe < 50000) {
        open = iOpen(symbol, (ENUM_TIMEFRAMES)timeframe, index);
        high = iHigh(symbol, (ENUM_TIMEFRAMES)timeframe, index);
        low = iLow(symbol, (ENUM_TIMEFRAMES)timeframe, index);
        close = iClose(symbol, (ENUM_TIMEFRAMES)timeframe, index);
    }
    else {
        // not implemented 
    }
    switch (source)
    {
        case ENUM_APPLIED_PRICE::PRICE_CLOSE:
            return close;
        case ENUM_APPLIED_PRICE::PRICE_HIGH:
            return high;
        case ENUM_APPLIED_PRICE::PRICE_LOW:
            return low;
        case ENUM_APPLIED_PRICE::PRICE_MEDIAN:
            return (high + low) / 2;
        case ENUM_APPLIED_PRICE::PRICE_OPEN:
            return open;
        case ENUM_APPLIED_PRICE::PRICE_TYPICAL:
            return (high + low + close) / 3;
        case ENUM_APPLIED_PRICE::PRICE_WEIGHTED:
            return (high + low + close + open) / 4;
        default:
            return 0;
    }
}

int CopyAppliedPrice(string symbol_name, int timeframe, ENUM_APPLIED_PRICE applied_price, int start_pos, int count, double &applied_price_array[]) {
    double open_array[];
    double high_array[];
    double low_array[];
    double close_array[];
    if (timeframe < 50000) {
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

int CopyTR(string symbol_name, int timeframe, int start_pos, int count, double &tr_array[]) {
    if (timeframe < 50000) {
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

int CopyRatesCustom(string symbol, int timeframe, int start_pos, MqlRates &rates[]){
    if (timeframe < 50000) {
        int bars = Bars(symbol, (ENUM_TIMEFRAMES)timeframe);
        return CopyRates(symbol, (ENUM_TIMEFRAMES)timeframe, start_pos, bars, rates);
    }
    else {
        int bars = Bars(symbol, PERIOD_M1);
        MqlRates rates_m1[];
        CopyRates(symbol, PERIOD_M1, 0, bars, rates_m1);
        int ps = GetPeriodSeconds(timeframe);
        int pm = ps / 60;
        datetime openTime = 0;
        double open = 0.0;
        double high = 0.0;
        double low = 999999999.0;
        double close = 0.0;
        long tickVolume = 0;
        long realVolume = 0;

        MqlRates temp[];
        int j = 0;
        ArrayResize(rates, ArraySize(rates_m1) / pm + 2);
        for (int i=0; i<bars; i++) {
            if (rates_m1[i].time % ps == 0 && openTime != 0) {
                MqlRates newRate;
                newRate.time = openTime;
                newRate.open = open;
                newRate.high = high;
                newRate.low = low;
                newRate.close = close;
                newRate.real_volume = realVolume;
                newRate.tick_volume = tickVolume;
                rates[j] = newRate;
                // reset
                openTime = 0;
                open = 0.0;
                high = 0.0;
                low = 999999999.0;
                close = 0.0;
                tickVolume = 0;
                realVolume = 0;
                j++;
            }
            else {
                if (rates_m1[i].time % ps == 60) {
                    openTime = rates_m1[i].time - 60;
                    open = rates_m1[i].open;
                }
                if (rates_m1[i].high > high) {
                    high = rates_m1[i].high;
                }
                if (rates_m1[i].low < low) {
                    low = rates_m1[i].low;
                }
                close = rates_m1[i].close;
                realVolume += rates_m1[i].real_volume;
                tickVolume += rates_m1[i].tick_volume;
            }
        }
        if (openTime != 0) {
            MqlRates newRate;
            newRate.time = openTime;
            newRate.open = open;
            newRate.high = high;
            newRate.low = low;
            newRate.close = close;
            newRate.real_volume = realVolume;
            newRate.tick_volume = tickVolume;
            rates[j] = newRate;
            j++;
        }
        ArrayResize(rates, j);
        return ArraySize(rates);
    }
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

//+------------------------------------------------------------------+
//| Indicator on Buffer Functions                                    |
//+------------------------------------------------------------------+
void MAOnBuffer(const int rates_total,const int prev_calculated,const int begin,const int period,ENUM_MA_METHOD ma_method, double& price[],double& buffer[]) {
    InitializeArray(buffer, ArraySize(price), EMPTY_VALUE);
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

void RSIOnBuffer(const int period, double& price[], double& buffer[]) {
    double gain[];
    double loss[];
    double again[];
    double aloss[];
    InitializeArray(gain, ArraySize(price), 0);
    InitializeArray(loss, ArraySize(price), 0);
    InitializeArray(again, ArraySize(price), 0);
    InitializeArray(aloss, ArraySize(price), 0);

    for (int i=1; i<ArraySize(price); i++) {
        gain[i] = MathMax(price[i] - price[i-1], 0);
        loss[i] = MathMax(price[i-1] - price[i], 0);
    }
    SmoothedMAOnBuffer(ArraySize(gain), 0, 0, period, gain, again);
    SmoothedMAOnBuffer(ArraySize(loss), 0, 0, period, loss, aloss);
    
    InitializeArray(buffer, ArraySize(price), EMPTY_VALUE);
    for(int i=0; i<ArraySize(again); i++) {
        if (again[i] == 0) {
            continue;
        }
        double rs = again[i] / aloss[i];
        buffer[i] = 100 - 100 / (1 + rs);
    }
}

void StochasticOnBuffer(const int period, double &price[], double &high[], double &low[], double &buffer[]) {
    InitializeArray(buffer, ArraySize(price), EMPTY_VALUE);
    for (int i=period; i<ArraySize(price); i++) {
        double min = low[ArrayMinimum(low, i-period, period)];
        double max = high[ArrayMaximum(high, i-period, period)];
        if (min == EMPTY_VALUE || max == EMPTY_VALUE) {
            continue;
        }
        if (max - min == 0) {
            continue;
        }
        buffer[i] = 100 * (price[i] - min) / (max - min);
    }
}

double LinReg(const int period, const int offset, double &price[], const int index) {
    if(period <= 0)
        return EMPTY_VALUE;

    double sumX  = 0.0;
    double sumY  = 0.0;
    double sumXY = 0.0;
    double sumXX = 0.0;

    for(int i = 0; i < period; i++) {
        double x = i;
        double y = price[index - i];

        sumX  += x;
        sumY  += y;
        sumXY += x * y;
        sumXX += x * x;
    }

    double denominator = period * sumXX - sumX * sumX;
    if(denominator == 0.0)
        return EMPTY_VALUE;

    double slope = (period * sumXY - sumX * sumY) / denominator;
    double intercept = (sumY - slope * sumX) / period;
    double x = (period - 1) - offset;

    return intercept + slope * x;
}

void LinRegOnBuffer(const int period, const int offset, double &price[], double &buffer[]) {
    InitializeArray(buffer, ArraySize(price), EMPTY_VALUE);
    for (int i=period-1; i<ArraySize(price); i++) {
        double linreg = LinReg(period, offset, price, i);
        buffer[i] = linreg;
    }
}