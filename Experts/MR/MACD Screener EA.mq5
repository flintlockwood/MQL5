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

#include <MovingAverages.mqh>
#include <Trade\Trade.mqh>

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

input int NumberOfLayer = 1;
input double LotSize = 0.01;
//input double TrailingSLPip = 15;
input double TrailingSLPercent = 0.3;
//input double TrailingTPPip = 15;
input double TrailingTPPercent = 0.3;

int    MacdScreenerHandle;
datetime prevdate = 0;
datetime prevdatem1 = 0;

CTrade   extTrade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    MacdScreenerHandle = iCustom(_Symbol, PERIOD_CURRENT, "MR\\MACD Screener Indicator", InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, InpAppliedPrice, T1Timeframe, T2Timeframe, T3Timeframe, T4Timeframe);

    if(MacdScreenerHandle==INVALID_HANDLE) {
        //--- tell about the failure and output the error code
        PrintFormat("Failed to create handle of the iMACD indicator, error code %d", GetLastError());
        //--- the indicator is stopped early
        return(INIT_FAILED);
    }

    //EventSetTimer(PeriodSeconds(PERIOD_CURRENT));

    extTrade.SetDeviationInPoints(10);    // slippage
    extTrade.SetExpertMagicNumber(MUF_MAGIC); // Expert Advisor ID
    extTrade.LogLevel(LOG_LEVEL_ERRORS);

    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
    IndicatorRelease(MacdScreenerHandle);
    //EventKillTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void) {
    datetime currdate = TimeCurrent();

    if (currdate - prevdatem1 > PeriodSeconds(PERIOD_M1)) {
        if (checkOpenPosition()) {
            checkSlTp();
        }
        prevdatem1 = currdate;
    }

    if (currdate - prevdate > PeriodSeconds(PERIOD_CURRENT)) {
        datetime tftime = currdate - currdate % PeriodSeconds(PERIOD_CURRENT);
        checkSignal(tftime);
        prevdate = currdate;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//void OnTimer() {
//    //if (prevdate == 0) {
//    //    prevdate = TimeCurrent();
//    //}
//    datetime currdate = TimeCurrent();
////    if ((currdate - currdate % PeriodSeconds(PERIOD_H1)) == D'2021.01.15 16:00') {
////        bool brea = true;
////
////        datetime tftime = currdate - currdate % PeriodSeconds(PERIOD_CURRENT);
////
////        double macdbuff[];
////        CopyBuffer(MacdScreenerHandle, 0, tftime, 2, macdbuff);
////        double signalbuff[];
////        CopyBuffer(MacdScreenerHandle, 1, tftime, 2, signalbuff);
////        double buybuff[];
////        CopyBuffer(MacdScreenerHandle, 2, tftime, 2, buybuff);
////        double sellbuff[];
////        CopyBuffer(MacdScreenerHandle, 3, tftime, 2, sellbuff);
////        double timebuff[];
////        CopyBuffer(MacdScreenerHandle, 4, tftime, 2, timebuff);
////    }
//    //if (currdate - prevdate > PeriodSeconds(PERIOD_CURRENT)) {
//    //    datetime tftime = currdate - currdate % PeriodSeconds(PERIOD_CURRENT);
//    //    checkSignal(tftime);
//    //    prevdate = currdate;
//    //}
//    datetime tftime = currdate - (currdate % PeriodSeconds(PERIOD_CURRENT));
//    checkSignal(tftime);
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkSignal(datetime tftime) {
    string signal[];
    getSignal(tftime, 2, signal);
    string criteria = signal[1];

    bool checkreversal = true;
    if (criteria == "buy") {
        if (!checkOpenPosition() && !checkHistoryTrade(tftime, criteria)) {
            for (int i=0; i<NumberOfLayer; i++) {
                double ask;
                SymbolInfoDouble(_Symbol, SYMBOL_ASK, ask);
                double sl = ask * (1 - TrailingTPPercent/100);
                double tp = ask * (1 + TrailingTPPercent/100);
                sendOrder("buy", 0, LotSize, sl, tp);
                checkreversal = false;
            }
        } else {
            for (int i=0; i<PositionsTotal(); i++) {
                ulong ticket=PositionGetTicket(i);
                ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                if (type == POSITION_TYPE_SELL) {
                    closeAllPosition();
                    //for (int i=0; i<NumberOfLayer; i++) {
                    //    sendOrder("buy", 0, LotSize, 0, 0);
                    //}
                }
            }
        }
    } else if (criteria == "sell") {
        if (!checkOpenPosition() && !checkHistoryTrade(tftime, criteria)) {
            for (int i=0; i<NumberOfLayer; i++) {
                double bid;
                SymbolInfoDouble(_Symbol, SYMBOL_BID, bid);
                double sl = bid * (1 + TrailingTPPercent/100);
                double tp = bid * (1 - TrailingTPPercent/100);
                sendOrder("sell", 0, LotSize, sl, tp);
                checkreversal = false;
            }
        } else {
            for (int i=0; i<PositionsTotal(); i++) {
                ulong ticket=PositionGetTicket(i);
                ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                if (type == POSITION_TYPE_BUY) {
                    closeAllPosition();
                    //for (int i=0; i<NumberOfLayer; i++) {
                    //    sendOrder("sell", 0, LotSize, 0, 0);
                    //}
                }
            }
        }
    }
    // check reversal in current timeframe
    if (PositionsTotal() > 0 && checkreversal) {
        string signal[];
        getSignalCurrentTf(tftime, 2, signal);
        for (int i=0; i<PositionsTotal(); i++) {
            ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if (type == POSITION_TYPE_BUY && signal[1] == "sell") {
                closeAllPosition();
            } else if(type == POSITION_TYPE_SELL && signal[1] == "buy") {
                closeAllPosition();
            }
        }
    }
}

// check whether there is open position for current symbol
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
bool checkHistoryTrade(datetime tftime, string initCondition) {
    string signal[];
    int cnt = 100;
    getSignal(tftime, cnt, signal);

    datetime enddate = tftime;
    datetime startdate = tftime;
    for (int i=cnt-2; i>=0; i--) {
        string condition = signal[i];
        if (initCondition != condition) {
            datetime time[];
            CopyTime(_Symbol, PERIOD_CURRENT, 0, cnt-i-1, time);
            startdate = time[0];
            break;
        }
    }

    if (startdate != enddate) {
        HistorySelect(startdate, enddate);
        int totaldeal = HistoryDealsTotal();
        for (int i=HistoryDealsTotal(); i>=0; i--) {
            ulong ticket = HistoryDealGetTicket(i);
            string symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);
            if (ticket == 0 || symbol != _Symbol) {
                continue;
            }
            ENUM_DEAL_ENTRY entrytype = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if (entrytype == DEAL_ENTRY_OUT) {
                return true;
            } else {
                continue;
            }
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getSignalCurrentTf(datetime time, int cnt, string &signal[]) {
    double macd[];
    double signal1[];
    double signal2[];
    calculateMACD(_Symbol, PERIOD_CURRENT, time, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, macd, signal1, signal2);

    double emptyvalue = EMPTY_VALUE;

    ArrayResize(signal, cnt);
    for (int i=0; i<cnt; i++) {
        bool buyCondition = signal1[i] > signal2[i];
        bool sellCondition = signal1[i] < signal2[i];

        if (buyCondition) {
            signal[i] =  "buy";
        } else if (sellCondition) {
            signal[i] = "sell";
        } else {
            signal[i] = "none";
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void getSignal(datetime t0time, int cnt, string &signal[]) {
    double t0macd[];
    double t0signal1[];
    double t0signal2[];
    calculateMACD(_Symbol, PERIOD_CURRENT, t0time, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t0macd, t0signal1, t0signal2);

    datetime t1time = t0time - t0time % PeriodSeconds(T1Timeframe);
    double t1macd[];
    double t1signal1[];
    double t1signal2[];
    calculateMACD(_Symbol, T1Timeframe, t1time, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t1macd, t1signal1, t1signal2);

    datetime t2time = t0time - t0time % PeriodSeconds(T2Timeframe);
    double t2macd[];
    double t2signal1[];
    double t2signal2[];
    calculateMACD(_Symbol, T2Timeframe, t2time, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t2macd, t2signal1, t2signal2);

    datetime t3time = t0time - t0time % PeriodSeconds(T3Timeframe);
    double t3macd[];
    double t3signal1[];
    double t3signal2[];
    calculateMACD(_Symbol, T3Timeframe, t3time, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t3macd, t3signal1, t3signal2);

    datetime t4time = t0time - t0time % PeriodSeconds(T4Timeframe);
    double t4macd[];
    double t4signal1[];
    double t4signal2[];
    calculateMACD(_Symbol, T4Timeframe, t4time, cnt, InpFastEMA, InpSlowEMA, InpMAPeriod1, InpMAPeriod2, t4macd, t4signal1, t4signal2);

    double emptyvalue = EMPTY_VALUE;

    ArrayResize(signal, cnt);
    for (int i=0; i<cnt; i++) {
        bool buyCondition0 = t0signal1[i] > t0signal2[i];
        bool buyCondition1 = t1signal1[i] > t1signal2[i];
        bool buyCondition2 = t2signal1[i] > t2signal2[i];
        bool buyCondition3 = t3signal1[i] > t3signal2[i];
        bool buyCondition4 = t4signal1[i] > t4signal2[i];

        bool sellCondition0 = t0signal1[i] < t0signal2[i];
        bool sellCondition1 = t1signal1[i] < t1signal2[i];
        bool sellCondition2 = t2signal1[i] < t2signal2[i];
        bool sellCondition3 = t3signal1[i] < t3signal2[i];
        bool sellCondition4 = t4signal1[i] < t4signal2[i];

        if (buyCondition0 && buyCondition1 && buyCondition2 && buyCondition3 && buyCondition4) {
            signal[i] =  "buy";
        } else if (sellCondition0 && sellCondition1 && sellCondition2 && sellCondition3 && sellCondition4) {
            signal[i] = "sell";
        } else {
            signal[i] = "none";
        }
    }
}
//+------------------------------------------------------------------+
void sendOrder(string orderType, double price, double volume, double sl, double tp, string comment = NULL, datetime expiration = 0) {
    //if (PositionsTotal() > 0) {
    //   return;
    //}

    MqlTradeRequest request;
    ZeroMemory(request);
    request.symbol   = Symbol();
    request.volume   = volume;
    request.deviation= 5;
    request.magic    = MUF_MAGIC;
    if (expiration != 0) {
        request.type_time = ORDER_TIME_SPECIFIED;
        request.expiration = expiration;
    }
//--- set the price and order type depending on the position type
    double pip = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    if(orderType == "buy") {
        if (price == 0) {
            request.price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            request.type = ORDER_TYPE_BUY;
            request.action   = TRADE_ACTION_DEAL;
        } else {
            request.price = price;
            double currprice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            if (price < currprice) {
                request.type = ORDER_TYPE_BUY_LIMIT;
            } else if (price > currprice) {
                request.type = ORDER_TYPE_BUY_STOP;
            }
            request.action   = TRADE_ACTION_PENDING;
        }

        if (sl != 0) {
            request.sl = sl;
        }
        if (tp != 0) {
            request.tp = tp;
        }
    } else {
        if (price == 0) {
            request.price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
            request.type = ORDER_TYPE_SELL;
            request.action   = TRADE_ACTION_DEAL;
        } else {
            request.price = price;
            double currprice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            if (price > currprice) {
                request.type = ORDER_TYPE_SELL_LIMIT;
            } else if (price < currprice) {
                request.type = ORDER_TYPE_SELL_STOP;
            }
            request.action   = TRADE_ACTION_PENDING;
        }

        if (sl != 0) {
            request.sl = sl;
        }
        if (tp != 0) {
            request.tp = tp;
        }
    }
    if (comment != NULL) {
        request.comment = comment;
    }
    MqlTradeCheckResult checkresult;
    bool valid = OrderCheck(request, checkresult);
    if (valid) {
        MqlTradeResult result;
        bool res = OrderSend(request, result);
        if (!res) {
            printf("Order fail: %s", result.comment);
        } else {
            string alertmessage = StringFormat("%s %s at %s sl:%s tp:%s", orderType, _Symbol, DoubleToString(request.price), DoubleToString(sl), DoubleToString(tp));
            Alert(alertmessage);
        }
    } else {
        PrintFormat("Order invlalid %s", checkresult.comment);
    }
}
//+------------------------------------------------------------------+
void closeAllPosition() {
    int total = PositionsTotal();
    for (int i=total-1; i>=0; i--) {
        ulong ticket=PositionGetTicket(i);
        if(ticket!=0) {
            //--- get the name of the symbol and the position id (magic)
            string symbol=PositionGetString(POSITION_SYMBOL);
            long   magic =PositionGetInteger(POSITION_MAGIC);
            //--- if they correspond to our values
            if(symbol==Symbol() && magic==MUF_MAGIC) {
                //if(PositionGetInteger(POSITION_TYPE)==type) {
                extTrade.PositionClose(ticket, 10);
                extTrade.PrintResult();
                Print("   ");
                //}
            }
        }
        // Get the current order
        //ulong  position_ticket=PositionGetTicket(i);
        //closePosition(position_ticket);
        ////ulong  position_ticket=PositionGetTicket(i);                                    // ticket of the position
        //string position_symbol=PositionGetString(POSITION_SYMBOL);                      // symbol
        //int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);            // ticket of the position
        //ulong  magic=PositionGetInteger(POSITION_MAGIC);                                // MagicNumber of the position
        //double volume=PositionGetDouble(POSITION_VOLUME);                               // volume of the position
        //double sl=PositionGetDouble(POSITION_SL);                                       // Stop Loss of the position
        //double tp=PositionGetDouble(POSITION_TP);                                       // Take Profit of the position
        //ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position
        //if (type == POSITION_TYPE_BUY) {
        //    MqlTradeRequest request;
        //    MqlTradeResult  result;
        //    ZeroMemory(request);
        //    ZeroMemory(result);
        //    //--- setting the operation parameters
        //    request.action=TRADE_ACTION_CLOSE_BY;                         // type of trade operation
        //    request.position=position_ticket;                             // ticket of the position
        //    request.position_by=PositionGetInteger(POSITION_TICKET);      // ticket of the opposite position
        //    //request.symbol     =position_symbol;
        //    request.magic=MUF_MAGIC;                                   // MagicNumber of the position
        //    //--- send the request
        //    if(!OrderSend(request,result))
        //        PrintFormat("OrderSend error %s %d",result.comment, GetLastError()); // if unable to send the request, output the error code
        //}
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closePosition(ulong position_ticket) {
    MqlTradeRequest request;
    MqlTradeResult  result;
    ZeroMemory(request);
    ZeroMemory(result);
    PositionSelectByTicket(position_ticket);
    double currprice, openprice;
    PositionGetDouble(POSITION_PRICE_CURRENT, currprice);
    PositionGetDouble(POSITION_PRICE_OPEN, openprice);
    double limit = SYMBOL_TRADE_FREEZE_LEVEL*_Point;
    if (MathAbs(currprice - openprice) < SYMBOL_TRADE_FREEZE_LEVEL*_Point) {
        PrintFormat("Cannot close order because the price does not move far enough from open price");
    }

    //--- setting the operation parameters
    request.action=TRADE_ACTION_CLOSE_BY;                         // type of trade operation
    request.position=position_ticket;                             // ticket of the position
    request.position_by=PositionGetInteger(POSITION_TICKET);      // ticket of the opposite position
    //request.symbol     =position_symbol;
    request.magic=MUF_MAGIC;                                   // MagicNumber of the position
    //--- send the request
    ResetLastError();
    if(!OrderSend(request,result))
        PrintFormat("Can not close position. comment: %s error code: %d",result.comment, GetLastError()); // if unable to send the request, output the error code
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifySLTP(ulong ticket, double newsl, double newtp) {
    MqlTradeRequest request;
    MqlTradeResult  result;
    ZeroMemory(request);
    ZeroMemory(result);
    //--- setting the operation parameters
    request.action=TRADE_ACTION_SLTP;                         // type of trade operation
    request.position=ticket;                             // ticket of the position
    if (newtp != 0) {
        request.tp = newtp;
    }
    if (newsl != 0) {
        request.sl = newsl;
    }
    //request.symbol     =position_symbol;
    request.magic=MUF_MAGIC;                                   // MagicNumber of the position
    //--- send the request
    if(!OrderSend(request,result))
        PrintFormat("Can not modify SLTP error %s", result.comment); // if unable to send the request, output the error code
}
//+------------------------------------------------------------------+
void checkSlTp() {
    int total = PositionsTotal();
    for (int i=0; i<total; i++) {
        // Get the current order
        PositionSelect(i);
        ulong  position_ticket=PositionGetTicket(i);
        string position_symbol=PositionGetString(POSITION_SYMBOL);
        double openprice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentprice = PositionGetDouble(POSITION_PRICE_CURRENT);
        double sl=PositionGetDouble(POSITION_SL);
        if (sl == 0) {
            bool brea = true;
        }
        double tp=PositionGetDouble(POSITION_TP);
        double profit = PositionGetDouble(POSITION_PROFIT);
        ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if (type == POSITION_TYPE_BUY) {
            double newsl = sl;
            double newtp = tp;
            if(-(sl - currentprice) / currentprice > TrailingSLPercent/100) {
                newsl = NormalizeDouble(currentprice - currentprice * TrailingSLPercent/100, _Digits);
            }
            if((tp - currentprice) / currentprice < TrailingTPPercent/100) {
                newtp = NormalizeDouble(currentprice + currentprice * TrailingTPPercent/100, _Digits);
            }
            if (newsl > sl && newtp > tp) {
                modifySLTP(position_ticket, newsl, newtp);
            }
            //if((tp - currentprice) / currentprice <= TrailingSLPercent/100*0.75) {
            //    closePosition(position_ticket);
            //}
        } else if (type == POSITION_TYPE_SELL) {
            double newsl = sl;
            double newtp = tp;
            if ((sl - currentprice) / currentprice > TrailingSLPercent/100) {
                newsl = NormalizeDouble(currentprice + currentprice * TrailingSLPercent/100, _Digits);
            }
            if(-(tp - currentprice) / currentprice < TrailingSLPercent/100) {
                newtp = NormalizeDouble(currentprice - currentprice * TrailingSLPercent/100, _Digits);
            }
            if (newsl < sl && newtp < tp) {
                modifySLTP(position_ticket, newsl, newtp);
            }
            //if((sl - currentprice) / currentprice <= TrailingSLPercent/100*0.75) {
            //    closePosition(position_ticket);
            //}
        }
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

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
