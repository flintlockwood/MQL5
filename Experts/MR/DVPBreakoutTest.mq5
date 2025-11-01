//+------------------------------------------------------------------+
//|                                                        MufEA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MR\Dvp.mqh>
#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
#include <MR\Array.mqh>
#include "CSEngulfing.mqh"
#include "CSRejection.mqh"
#include "CSFtr.mqh"
#include "CurrencyStrength.mqh"
#include "CIsNewBar.mqh";
#include "SignalSnd.mqh"
#include <Trade\Trade.mqh>

#define MUF_MAGIC 141592

int nticks = 125000;
int volumeTreshold = 7;
bool initialize = false;
datetime lastticktime = 0;
int lasttotalcnt = 0;
int lastbuycnt = 0;
int lastsellcnt = 0;
double lastbid = 0;
double lastask = 0;
double lastprice = 0;
datetime lastinittime = 0;

CIsNewBar inbM15;
CIsNewBar inbM30;
CIsNewBar inbH1;

CTrade         m_trade;
int            dvp_handle;

//SignalBase* signals[];
//TArrayStack<SignalBase*> signals(100);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   //EventSetTimer(15*60);
   EventSetTimer(1);
   inbM30.SetPeriod(PERIOD_M30);
   dvp_handle = iCustom(_Symbol, PERIOD_M30, "MR\\CSPatternWithDVP", 60, 100, 70);
   if (dvp_handle == INVALID_HANDLE) {
      printf("invalid handle");
      return (INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
bool run = false;
int signalId = 0;
void OnTick() {

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   if (inbM30.isNewBar()>0) {
      DvpRates dvp[];
      double poc_buffer[];
      double vah_buffer[];
      double val_buffer[];
      int nd = 2;
      if(CopyBuffer(dvp_handle, 0, 1, nd, poc_buffer)<=0) return;
      if(CopyBuffer(dvp_handle, 15, 1, nd, vah_buffer)<=0) return;
      if(CopyBuffer(dvp_handle, 16, 1, nd, val_buffer)<=0) return;
      int pt = PositionsTotal();
      if (pt == 1) {
         // check for exit
         ulong  position_ticket=PositionGetTicket(0);
         double sl=PositionGetDouble(POSITION_SL);
         double tp=PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); 
         int n = 2;
         MqlRates rates[];
         CopyRates(_Symbol, PERIOD_M30, 1, 2, rates);
         if (type == POSITION_TYPE_BUY) {
            if ((rates[n-2].low < poc_buffer[nd-1] && rates[n-2].high > poc_buffer[nd-1] && rates[n-1].high < poc_buffer[nd-1]) ||
                (rates[n-2].low < vah_buffer[nd-1] && rates[n-2].high > vah_buffer[nd-1] && rates[n-1].high < vah_buffer[nd-1])) {
                closeOrder(position_ticket);
            }
         }
         else {
            if ((rates[n-2].low < poc_buffer[nd-1] && rates[n-2].high > poc_buffer[nd-1] && rates[n-1].low > poc_buffer[nd-1]) ||
                (rates[n-2].low < val_buffer[nd-1] && rates[n-2].high > val_buffer[nd-1] && rates[n-1].low > val_buffer[nd-1])) {
                closeOrder(position_ticket);
            }
         }
      }
      else if (pt == 0) {
         MqlDateTime dt;
         TimeCurrent(dt);
         double ask, bid;
         SymbolInfoDouble(_Symbol, SYMBOL_ASK, ask);
         SymbolInfoDouble(_Symbol, SYMBOL_BID, bid);
         double spread = ask-bid;
         // check for signal
         if (spread<=20*_Point && dt.hour>7 && dt.hour<22) {
            
            double poc0 = NormalizeDouble(poc_buffer[0], _Digits);
            double poc1 = NormalizeDouble(poc_buffer[1], _Digits);
            int n = 2;
            MqlRates rates[];
            CopyRates(_Symbol, PERIOD_M30, 1, n, rates);
            if (rates[n-2].low <= poc1 && rates[n-2].high >= poc1 && poc0 == poc1) {
               if (rates[n-1].low > poc1) {
                  sendOrder("buy", 0, poc1-50*_Point, 0);
               }
               else if (rates[n-1].high < poc1) {
                  sendOrder("sell", 0, poc1+50*_Point, 0);
               }
            }            
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeLogTest(string content) {
   int fhandle = FileOpen(Symbol() + "_cspattern_log.txt", FILE_READ|FILE_WRITE|FILE_CSV);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculateDvp() {
   datetime currTime = TimeCurrent();
   MqlDateTime currDT;
   TimeToStruct(currTime, currDT);
   if (currDT.min == 0 || currDT.min == 30) {
      int n = 20*24*2;
      MqlRates rates[];
      DvpRates dvp[];
      int n1 = CopyRates(Symbol(), PERIOD_M30, 0, n, rates);
      if (n1 == n) {
         CalculateDvp(60, 100, 70, rates, dvp, Symbol(), false);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void exportTick() {
   MqlTick tick;
   SymbolInfoTick(Symbol(), tick);
   double price = NormalizeDouble(tick.bid+(tick.ask-tick.bid)/2, Digits());
   string format="%s, %s, %s, %s, %G, %d, %i, %G";
   CFileTxt     File;
   File.Open(Symbol() + "_ticks_test.csv",FILE_READ|FILE_WRITE|FILE_CSV,9);
   File.Seek(0, SEEK_END);
   string sOut = StringFormat(format,
                              TimeToString(tick.time, TIME_DATE|TIME_SECONDS),
                              DoubleToString(tick.bid, Digits()),
                              DoubleToString(tick.ask, Digits()),
                              DoubleToString(price, Digits()),
                              tick.volume,
                              tick.time_msc,
                              tick.flags,
                              tick.volume_real);
   File.WriteString(sOut + "\r\n");
   File.Close();
}
//+------------------------------------------------------------------+
void sendOrder(string orderType, double price, double sl = 0, double tp = 0) {
   if (PositionsTotal() > 0) {
      return;
   }
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol   = Symbol();
   request.volume   = 0.1;
   request.deviation= 5;
   request.magic    = MUF_MAGIC;
   request.action   = TRADE_ACTION_DEAL;
   //--- set the price and order type depending on the position type
   double pip = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(orderType == "buy") {
      if (price == 0) {
         request.price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         request.type = ORDER_TYPE_BUY;
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
      } else {
         request.price = price;
         double currprice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         if (price > currprice) {
            request.type = ORDER_TYPE_SELL_LIMIT;
         } else if (price > currprice) {
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
   MqlTradeCheckResult checkresult;
   bool valid = OrderCheck(request, checkresult);
   if (valid) {
      MqlTradeResult result;
      bool res = OrderSend(request, result);
      if (!res) {
         printf("Order fail: %s", result.comment);
      }
   } else {
      Print("Order invlalid");
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeOrder(ulong position) {
   bool res = m_trade.PositionClose(position);
   if (!res) {
      printf("fail to close position: %s", m_trade.ResultComment());
   }
}
//+------------------------------------------------------------------+
