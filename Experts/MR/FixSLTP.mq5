//+------------------------------------------------------------------+
//|                                                      FixSLTP.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

#define MUF_MAGIC 141592

input double SLPercent = 0.3;
input double TPPercent = 0.3; 

CTrade m_trade;
CSymbolInfo m_symbol;

datetime prevdatem1 = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
    m_trade.SetDeviationInPoints(10);    // slippage
    m_trade.SetExpertMagicNumber(MUF_MAGIC); // Expert Advisor ID
    m_trade.LogLevel(LOG_LEVEL_ERRORS); 
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
    datetime currdate = TimeCurrent();
    datetime currh1dt = currdate - currdate % PeriodSeconds(PERIOD_H1);
      
    if (currdate - prevdatem1 > PeriodSeconds(PERIOD_M1)) {
        if (PositionsTotal() > 0) {
            if (currh1dt == D'2025.01.20 08:00') {
                bool bre = true;
            }
            checkSlTp();
        }
        prevdatem1 = currdate;
    }
    
    if(currh1dt == D'2025.01.20 03:00' && PositionsTotal() == 0) {
        m_symbol.RefreshRates();
        double ask = m_symbol.Ask();
        double sl = ask - SLPercent/100 * ask;
        double tp = ask + SLPercent/100 * ask;
        m_trade.Buy(0.01, _Symbol, ask, sl, tp);
    }
    else if (currh1dt == D'2025.01.20 22:00' && PositionsTotal() == 0) {
        m_symbol.RefreshRates();
        double bid = m_symbol.Bid();
        double sl = bid + SLPercent/100 * bid;
        double tp = bid - SLPercent/100 * bid;
        m_trade.Sell(0.01, _Symbol, bid, sl, tp);
    }
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
        double tp=PositionGetDouble(POSITION_TP);
        double profit = PositionGetDouble(POSITION_PROFIT);
        ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        
        if (type == POSITION_TYPE_BUY) {
            double newsl = sl;
            double newtp = tp;
            double temp1 = -(sl - currentprice) / currentprice;
            if(-(sl - currentprice) / currentprice > SLPercent/100) {
                newsl = NormalizeDouble(currentprice - currentprice * SLPercent/100, _Digits);
            }
            double temp2 = (tp - currentprice) / currentprice;
            if((tp - currentprice) / currentprice < TPPercent/100) {
                newtp = NormalizeDouble(currentprice + currentprice * TPPercent/100, _Digits);
            }
            if (newsl > sl || newtp > tp) {
                m_trade.PositionModify(position_ticket, newsl, newtp);
                m_trade.PrintResult();
            }
            //if((tp - currentprice) / currentprice <= TrailingSLPercent/100*0.75) {
            //    closePosition(position_ticket);
            //}
        }
        else if (type == POSITION_TYPE_SELL) {
            double newsl = sl;
            double newtp = tp;
            double temp1 = (sl - currentprice) / currentprice;
            if ((sl - currentprice) / currentprice > SLPercent/100) {
                newsl = NormalizeDouble(currentprice + currentprice * SLPercent/100, _Digits);
            }
            double temp2 = -(tp - currentprice) / currentprice;
            if(-(tp - currentprice) / currentprice < TPPercent/100) {
                newtp = NormalizeDouble(currentprice - currentprice * TPPercent/100, _Digits);
            }
            if (newsl < sl || newtp < tp) {
                m_trade.PositionModify(position_ticket, newsl, newtp);
                m_trade.PrintResult();
            }
            //if((sl - currentprice) / currentprice <= TrailingSLPercent/100*0.75) {
            //    closePosition(position_ticket);
            //}
        }
    }
}
