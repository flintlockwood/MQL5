//+------------------------------------------------------------------+
//|                                                         VPEA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>

#define MUF_MAGIC 141592

input double RiskPercent = 1; // fix Risk in percent
input double SLPercent   = 0; // percent candle length for SL
input double PriceMovePercent   = 33; // Price move in percent of (VAH - VAL)

bool   debug       = false;
datetime prevdate = 0;
double lowerva1;
double upperva1;
double lowerva2;
double upperva2;
double lowerva3;
double upperva3;
string objPrefix = "VPEA_";
int    boxCnt = 0;

int BoxProfileHandle;

CTrade          extTrade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    extTrade.SetDeviationInPoints(10);    // slippage
    extTrade.SetExpertMagicNumber(MUF_MAGIC); // Expert Advisor ID
    extTrade.LogLevel(LOG_LEVEL_ERRORS);

    ResetLastError();
    BoxProfileHandle = iCustom(_Symbol, PERIOD_CURRENT, "boxprofile-3.0");
    if (BoxProfileHandle == INVALID_HANDLE) {
        printf("initialization error: %d", GetLastError());
        return (INIT_FAILED);
    }
    
    debug = MQLInfoInteger(MQL_TESTER);
//---
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    ResetLastError();
    ObjectsDeleteAll(ChartID(), objPrefix);
    if (GetLastError() > 0) {
        printf("error deleting objects: %d", GetLastError());
    }
    IndicatorRelease(BoxProfileHandle);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
    datetime currdate = TimeCurrent();

    if (currdate - prevdate > PeriodSeconds(PERIOD_CURRENT)) {
        if (!checkOpenPosition()) {
            //getLevel();
            double val = GetVal();
            double vah = GetVah();
            if (val != 0 && vah != 0) {
                checkEntry(val, vah);
            }
            //checkEntry(upperva2, lowerva2);
            //checkEntry(upperva3, lowerva3);
        }
        prevdate = currdate;
    }
}
//+------------------------------------------------------------------+
void getLevel() {
    //Print("getLevel");
    int objtotal = ObjectsTotal(ChartID());
    double temp1[];
    double temp2[];
    double temp3[];
    for (int i=0; i<objtotal; i++) {
        string objName = ObjectName(ChartID(), i);
        if (StringSubstr(objName, 0, 7) == "rHstBP1") {
            color objColor = (color)ObjectGetInteger(ChartID(), objName, OBJPROP_COLOR);
            if (ColorToString(objColor, true) == "clrGray") {
                double level = ObjectGetDouble(ChartID(), objName, OBJPROP_PRICE);
                arrayPush(temp1, level);
            }
        } else if (StringSubstr(objName, 0, 7) == "rHstBP2") {
            color objColor = (color)ObjectGetInteger(ChartID(), objName, OBJPROP_COLOR);
            if (ColorToString(objColor, true) == "clrGray") {
                double level = ObjectGetDouble(ChartID(), objName, OBJPROP_PRICE);
                arrayPush(temp2, level);
            }
        } else if (StringSubstr(objName, 0, 7) == "rHstBP3") {
            color objColor = (color)ObjectGetInteger(ChartID(), objName, OBJPROP_COLOR);
            if (ColorToString(objColor, true) == "clrGray") {
                double level = ObjectGetDouble(ChartID(), objName, OBJPROP_PRICE);
                arrayPush(temp3, level);
            }
        }
    }
    if (ArraySize(temp1) == 2) {
        lowerva1 = temp1[ArrayMinimum(temp1, 0, WHOLE_ARRAY)];
        upperva1 = temp1[ArrayMaximum(temp1, 0, WHOLE_ARRAY)];
    } else {
        Print("can not find level 1");
    }
    if (ArraySize(temp2) == 2) {
        lowerva2 = temp2[ArrayMinimum(temp2, 0, WHOLE_ARRAY)];
        upperva2 = temp2[ArrayMaximum(temp2, 0, WHOLE_ARRAY)];
    } else {
        Print("can not find level 2");
    }
    if (ArraySize(temp3) == 2) {
        lowerva3 = temp3[ArrayMinimum(temp3, 0, WHOLE_ARRAY)];
        upperva3 = temp3[ArrayMaximum(temp3, 0, WHOLE_ARRAY)];
    } else {
        Print("can not find level 3");
    }
    //drawTable(upperva1, lowerva1, upperva2, lowerva2, upperva3, lowerva3);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetVal() {
    double val[];
    CopyBuffer(BoxProfileHandle, 6, 0, 1, val); // val
    return val[0];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetVah() {
    double vah[];
    CopyBuffer(BoxProfileHandle, 7, 0, 1, vah); // vah
    return vah[0];
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkOpenPosition() {
    int total = PositionsTotal();
    for (int i=0; i<total; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) {
            continue;
        }
        PositionSelectByTicket(ticket);
        string symbol = PositionGetString(POSITION_SYMBOL);
        if(symbol == _Symbol) {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkEntry(double val, double vah) {
    if (checkOpenPosition()) {
        return;
    }
    
    double currprice = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
    datetime currdate = TimeCurrent();
    datetime opendate = currdate - currdate % PeriodSeconds(PERIOD_CURRENT);
    datetime closedate = opendate + PeriodSeconds(PERIOD_CURRENT);
    MqlRates rates[];
    int cnt = 16;
    CopyRates(_Symbol, PERIOD_CURRENT, closedate, cnt, rates);

    // check long condition
    bool longRule1 = checkLongRule1(rates, val, vah);
    bool longRule2 = checkLongRule2(rates, val, vah);
    if (longRule2) {
        double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
        double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
        double sl = NormalizeDouble(rates[ArraySize(rates)-2].low + (rates[ArraySize(rates)-2].high - rates[ArraySize(rates)-2].low) * SLPercent/100, _Digits);
        double tp = NormalizeDouble(vah, _Digits);
        double lot = getVolume(ORDER_TYPE_BUY, ask, sl);
        printf("order buy price: %s sl: %s tp: %s bid: %s ask: %s", DoubleToString(ask, _Digits), DoubleToString(sl, _Digits), DoubleToString(tp, _Digits), DoubleToString(bid, _Digits), DoubleToString(ask, _Digits));
        bool status = extTrade.Buy(lot, _Symbol, ask, sl, tp);
        extTrade.PrintResult();
        if (status) {
            Alert("Buy");
            if (debug) {
                datetime t1 = rates[0].time;
                double p1 = val;
                datetime t2 = rates[ArraySize(rates)-1].time;
                double p2 = vah;
                drawBox(t1, p1, t2, p2);
            }
        }
    }

    // check short condition
    bool shortRule1 = checkShortRule1(rates, val, vah);
    bool shortRule2 = checkShortRule2(rates, val, vah);
    if (shortRule2) {
        double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
        double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
        double sl = NormalizeDouble(rates[ArraySize(rates)-2].high - (rates[ArraySize(rates)-2].high - rates[ArraySize(rates)-2].low) * SLPercent/100, _Digits);
        double tp = NormalizeDouble(val, _Digits);
        double lot = getVolume(ORDER_TYPE_SELL, bid, sl);
        printf("order buy price: %s sl: %s tp: %s bid: %s ask: %s", DoubleToString(bid, _Digits), DoubleToString(sl, _Digits), DoubleToString(tp, _Digits), DoubleToString(bid, _Digits), DoubleToString(ask, _Digits));
        bool status = extTrade.Sell(lot, _Symbol, bid, sl, tp);
        extTrade.PrintResult();
        if (status) {
            Alert("Sell");
            if (debug) {
                datetime t1 = rates[0].time;
                double p1 = val;
                datetime t2 = TimeCurrent();
                double p2 = vah;
                drawBox(t1, p1, t2, p2);
            }
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkLongRule1(MqlRates &rates[], double val, double vah) {
    bool valid = false;
    int cnt = ArraySize(rates);
    if (rates[cnt-2].close > rates[cnt-2].open
            && rates[cnt-2].open < val
            && rates[cnt-2].close > val
            && rates[cnt-2].close < vah
            && rates[cnt-2].close - val < (vah - val) * 0.25) {
        //Print("first long condition met");
        double minhigh = val;
        double minlow = val;
        datetime initTime = rates[cnt-3].time;
        for(int i=cnt-3; i>=0; i--) {
            if (rates[i].high < minhigh) {
                minhigh = rates[i].high;
            }
            if (rates[i].low < minlow) {
                minlow = rates[i].low;
            }
            if (rates[i].close < rates[i].open
                    && rates[i].low < val
                    && rates[i].high > val
                    && rates[i].time != initTime) {
                valid = true;
                break;
            }
        }
        valid = valid && (val - minlow) > (vah - val) * 0.5;
    }
    return valid;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkShortRule1(MqlRates &rates[], double val, double vah) {
    bool valid = false;
    int cnt = ArraySize(rates);
    if (rates[cnt-2].close < rates[cnt-2].open
            && rates[cnt-2].close < vah
            && rates[cnt-2].open > vah
            && rates[cnt-2].close > val
            && vah - rates[cnt-2].close < (vah - val) * 0.25) {
        //Print("first short condition met");
        double maxlow = vah;
        double maxhigh = vah;
        datetime initTime = rates[cnt-3].time;
        for(int i=cnt-3; i>=0; i--) {
            if (rates[i].low > maxlow) {
                maxlow = rates[i].low;
            }
            if (rates[i].high > maxhigh) {
                maxhigh = rates[i].high;
            }
            if (rates[i].close > rates[i].open
                    && rates[i].low < vah
                    && rates[i].high > vah
                    && rates[i].time != initTime) {
                valid = true;
                break;
            }
        }
        valid = valid && (maxhigh - vah) > (vah - val) * 0.5;
    }
    return valid;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkLongRule2(MqlRates &rates[], double val, double vah) {
    bool valid = false;
    int cnt = ArraySize(rates);
    if (rates[cnt-2].close > rates[cnt-2].open
            && rates[cnt-2].low < val
            && rates[cnt-2].close > val
            && rates[cnt-2].close < vah) {
        //Print("first long condition met");
        double minhigh = val;
        double minlow = val;
        double maxhigh = 0;
        datetime initTime = rates[cnt-3].time;
        for(int i=cnt-3; i>=0; i--) {
            if (rates[i].high < minhigh) {
                minhigh = rates[i].high;
            }
            if (rates[i].low < minlow) {
                minlow = rates[i].low;
            }            
            if (rates[i].close < rates[i].open
                    && rates[i].low < val
                    && rates[i].high > val) {
                valid = true;
                break;
            }
            if(rates[i].high > maxhigh) {
                maxhigh = rates[i].high;
            }
        }
        valid = valid && maxhigh < rates[cnt-2].open;
        valid = valid && minlow <= (val - (vah-val)*PriceMovePercent/100);
    }
    return valid;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkShortRule2(MqlRates &rates[], double val, double vah) {
    bool valid = false;
    int cnt = ArraySize(rates);
    if (rates[cnt-2].close < rates[cnt-2].open
            && rates[cnt-2].close < vah
            && rates[cnt-2].high > vah
            && rates[cnt-2].close > val) {
        //Print("first short condition met");
        double maxlow = vah;
        double maxhigh = vah;
        double minlow = 999999;
        datetime initTime = rates[cnt-3].time;
        for(int i=cnt-3; i>=0; i--) {
            if (rates[i].low > maxlow) {
                maxlow = rates[i].low;
            }
            if (rates[i].high > maxhigh) {
                maxhigh = rates[i].high;
            }
            if (rates[i].close > rates[i].open
                    && rates[i].low < vah
                    && rates[i].high > vah) {
                valid = true;
                break;
            }
            if (rates[i].low < minlow) {
                minlow = rates[i].low;
            }
        }
        valid = valid && minlow > rates[cnt-2].low;
        valid = valid && maxhigh >= (vah + (vah-val)*PriceMovePercent/100);
    }
    return valid;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getVolume(ENUM_ORDER_TYPE type, double price, double sl) {
    CSymbolInfo *m_symbol = new CSymbolInfo();
    m_symbol.Name(_Symbol);
    CAccountInfo *m_account = new CAccountInfo();

    double lot;
    double minvol=m_symbol.LotsMin();
    if(sl==0.0)
        lot=minvol;
    else {
        double loss;
        if(price==0.0)
            loss=-m_account.OrderProfitCheck(m_symbol.Name(),type,1.0,m_symbol.Ask(),sl);
        else
            loss=-m_account.OrderProfitCheck(m_symbol.Name(),type,1.0,price,sl);
        double stepvol=m_symbol.LotsStep();
        double balance = m_account.Balance();
        lot=MathFloor(balance*RiskPercent/loss/100.0/stepvol)*stepvol;
    }
//---
    if(lot<minvol)
        lot=minvol;
//---
    double maxvol=m_symbol.LotsMax();
    if(lot>maxvol)
        lot=maxvol;
//--- return trading volume

    delete m_symbol;
    delete m_account;
    return(lot);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPush(double &array[], double value) {
    ArrayResize(array, ArraySize(array)+1, 10);
    array[ArraySize(array)-1] = value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPush(int &array[], int value) {
    ArrayResize(array, ArraySize(array)+1, 10);
    array[ArraySize(array)-1] = value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPush(string &array[], string value) {
    ArrayResize(array, ArraySize(array)+1, 10);
    array[ArraySize(array)-1] = value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPush(datetime &array[], datetime value) {
    ArrayResize(array, ArraySize(array)+1, 10);
    array[ArraySize(array)-1] = value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPop(double &array[]) {
    ArrayResize(array, ArraySize(array)-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPop(int &array[]) {
    ArrayResize(array, ArraySize(array)-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPop(string &array[]) {
    ArrayResize(array, ArraySize(array)-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayPop(datetime &array[]) {
    ArrayResize(array, ArraySize(array)-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayInsert(int &array[], int index, int value) {
    int temp[];
    ArrayCopy(temp, array, 0, 0, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)+1);
    for(int i=0; i<index; i++) {
        array[i] = temp[i];
    }
    array[index] = value;
    for(int i=index+1; i<ArraySize(array); i++) {
        array[i] = temp[i-1];
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayInsert(double &array[], int index, double value) {
    double temp[];
    ArrayCopy(temp, array, 0, 0, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)+1);
    for(int i=0; i<index; i++) {
        array[i] = temp[i];
    }
    array[index] = value;
    for(int i=index+1; i<ArraySize(array); i++) {
        array[i] = temp[i-1];
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayInsert(string &array[], int index, string value) {
    string temp[];
    ArrayCopy(temp, array, 0, 0, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)+1);
    for(int i=0; i<index; i++) {
        array[i] = temp[i];
    }
    array[index] = value;
    for(int i=index+1; i<ArraySize(array); i++) {
        array[i] = temp[i-1];
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayInsert(datetime &array[], int index, datetime value) {
    datetime temp[];
    ArrayCopy(temp, array, 0, 0, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)+1);
    for(int i=0; i<index; i++) {
        array[i] = temp[i];
    }
    array[index] = value;
    for(int i=index+1; i<ArraySize(array); i++) {
        array[i] = temp[i-1];
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double arrayShift(double &array[]) {
    double value = array[0];
    double temp[];
    ArrayCopy(temp, array, 0, 1, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)-1);
    for(int i=0; i<ArraySize(array); i++) {
        array[i] = temp[i];
    }
    return value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string arrayShift(string &array[]) {
    string value = array[0];
    string temp[];
    ArrayCopy(temp, array, 0, 1, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)-1);
    for(int i=0; i<ArraySize(array); i++) {
        array[i] = temp[i];
    }
    return value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime arrayShift(datetime &array[]) {
    datetime value = array[0];
    datetime temp[];
    ArrayCopy(temp, array, 0, 1, WHOLE_ARRAY);
    ArrayResize(array, ArraySize(array)-1);
    for(int i=0; i<ArraySize(array); i++) {
        array[i] = temp[i];
    }
    return value;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeLog(string content) {
    int fhandle = FileOpen(Symbol() + "_ticks_log.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
    FileSeek(fhandle, 0, SEEK_END);
    FileWrite(fhandle, content);
    FileFlush(fhandle);
    FileClose(fhandle);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawTable(double upperVA1, double lowerVA1, double upperVA2, double lowerVA2, double upperVA3, double lowerVA3) {
    int i = 0;
    string label1 = StringFormat("%sTABLE_ROW_%d", objPrefix, i);
    string text1 = StringFormat("upper va 1 %s", DoubleToString(upperVA1, _Digits));
    if (ObjectFind(ChartID(), label1) < 0) {
        ResetLastError();
        if (!ObjectCreate(ChartID(), label1, OBJ_LABEL, 0, 0, 0)) {
            printf("failed to create label:%s error: %d", label1, GetLastError());
            return;
        }
    }
    ObjectSetInteger(ChartID(), label1, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(ChartID(), label1, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(ChartID(), label1, OBJPROP_YDISTANCE, 20+i*12);
    ObjectSetString(ChartID(), label1, OBJPROP_TEXT, text1);
    ObjectSetInteger(ChartID(), label1, OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(ChartID(), label1, OBJPROP_COLOR, clrYellow);

    i = 1;
    string label2 = StringFormat("%sTABLE_ROW_%d", objPrefix, i);
    string text2 = StringFormat("lower va 1 %s", DoubleToString(lowerVA1, _Digits));
    if (ObjectFind(ChartID(), label2) < 0) {
        ResetLastError();
        if (!ObjectCreate(ChartID(), label2, OBJ_LABEL, 0, 0, 0)) {
            printf("failed to create label:%s error: %d", label2, GetLastError());
            return;
        }
    }
    ObjectSetInteger(ChartID(), label2, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(ChartID(), label2, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(ChartID(), label2, OBJPROP_YDISTANCE, 20+i*12);
    ObjectSetString(ChartID(), label2, OBJPROP_TEXT, text2);
    ObjectSetInteger(ChartID(), label2, OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(ChartID(), label2, OBJPROP_COLOR, clrYellow);

    i = 2;
    string label3 = StringFormat("%sTABLE_ROW_%d", objPrefix, i);
    string text3 = StringFormat("upper va 2 %s", DoubleToString(upperVA2, _Digits));
    if (ObjectFind(ChartID(), label3) < 0) {
        ResetLastError();
        if (!ObjectCreate(ChartID(), label3, OBJ_LABEL, 0, 0, 0)) {
            printf("failed to create label:%s error: %d", label3, GetLastError());
            return;
        }
    }
    ObjectSetInteger(ChartID(), label3, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(ChartID(), label3, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(ChartID(), label3, OBJPROP_YDISTANCE, 20+i*12);
    ObjectSetString(ChartID(), label3, OBJPROP_TEXT, text3);
    ObjectSetInteger(ChartID(), label3, OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(ChartID(), label3, OBJPROP_COLOR, clrYellow);

    i = 3;
    string label4 = StringFormat("%sTABLE_ROW_%d", objPrefix, i);
    string text4 = StringFormat("lower va 2 %s", DoubleToString(lowerVA2, _Digits));
    if (ObjectFind(ChartID(), label4) < 0) {
        ResetLastError();
        if (!ObjectCreate(ChartID(), label4, OBJ_LABEL, 0, 0, 0)) {
            printf("failed to create label:%s error: %d", label4, GetLastError());
            return;
        }
    }
    ObjectSetInteger(ChartID(), label4, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(ChartID(), label4, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(ChartID(), label4, OBJPROP_YDISTANCE, 20+i*12);
    ObjectSetString(ChartID(), label4, OBJPROP_TEXT, text4);
    ObjectSetInteger(ChartID(), label4, OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(ChartID(), label4, OBJPROP_COLOR, clrYellow);

    i = 4;
    string label5 = StringFormat("%sTABLE_ROW_%d", objPrefix, i);
    string text5 = StringFormat("upper va 3 %s", DoubleToString(upperVA3, _Digits));
    if (ObjectFind(ChartID(), label5) < 0) {
        ResetLastError();
        if (!ObjectCreate(ChartID(), label5, OBJ_LABEL, 0, 0, 0)) {
            printf("failed to create label:%s error: %d", label5, GetLastError());
            return;
        }
    }
    ObjectSetInteger(ChartID(), label5, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(ChartID(), label5, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(ChartID(), label5, OBJPROP_YDISTANCE, 20+i*12);
    ObjectSetString(ChartID(), label5, OBJPROP_TEXT, text5);
    ObjectSetInteger(ChartID(), label5, OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(ChartID(), label5, OBJPROP_COLOR, clrYellow);

    i = 5;
    string label6 = StringFormat("%sTABLE_ROW_%d", objPrefix, i);
    string text6 = StringFormat("lower va 3 %s", DoubleToString(lowerVA3, _Digits));
    if (ObjectFind(ChartID(), label6) < 0) {
        ResetLastError();
        if (!ObjectCreate(ChartID(), label6, OBJ_LABEL, 0, 0, 0)) {
            printf("failed to create label:%s error: %d", label6, GetLastError());
            return;
        }
    }
    ObjectSetInteger(ChartID(), label6, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(ChartID(), label6, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(ChartID(), label6, OBJPROP_YDISTANCE, 20+i*12);
    ObjectSetString(ChartID(), label6, OBJPROP_TEXT, text6);
    ObjectSetInteger(ChartID(), label6, OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(ChartID(), label6, OBJPROP_COLOR, clrYellow);
}
//+------------------------------------------------------------------+
void drawBox(datetime time1, double price1, datetime time2, double price2) {
    string box = StringFormat("%sBOX_%d", objPrefix, boxCnt);
    ResetLastError();
    if (!ObjectCreate(ChartID(), box, OBJ_RECTANGLE, 0, time1, price1, time2, price2)) {
        printf("failed to create label:%s error: %d", box, GetLastError());
        return;
    }
    ObjectSetInteger(ChartID(),box,OBJPROP_COLOR,clrGray);
    ObjectSetInteger(ChartID(),box,OBJPROP_WIDTH,1);
    boxCnt++;
}
//+------------------------------------------------------------------+
