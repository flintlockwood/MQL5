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

//SignalBase* signals[];
//TArrayStack<SignalBase*> signals(100);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   //EventSetTimer(15*60);
   EventSetTimer(1);
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

//   MqlRates rates[];
//   int period = 61;
//   int cnt = CopyRates(Symbol(), PERIOD_M15, 0, period, rates);
//
//   MqlRates fsRates[];
//   ArrayCopy(fsRates, rates, 0, ArraySize(rates)-4, 4);
//
//   FtrSignal *fs;
//   fs = new FtrSignal(fsRates);
//   if (fs.CheckSignal(PERIOD_M15)) {
//      printf("FTR signal detected: %s " + fs.ToString());
//      if (fs.type == SIGNAL_TYPE_BULLISH) {
//         sendOrder("buy", 0, fs.GetStopLoss(), 0);
//      }
//      else {
//         sendOrder("sell", 0, fs.GetStopLoss(), 0);
//      }
//   }

   inbM15.SetPeriod(PERIOD_M15);
   inbM30.SetPeriod(PERIOD_M30);
   inbH1.SetPeriod(PERIOD_H1);
   datetime dt  = TimeCurrent();

   if (inbM15.isNewBar()>0) {

      MqlRates rates[];
      int period = 61;
      int cnt = CopyRates(Symbol(), PERIOD_M15, 1, period, rates);

      MqlRates rates2[];
      ArrayCopy(rates2, rates, 0, ArraySize(rates)-2, 2);
      MqlRates rates4[];
      ArrayCopy(rates4, rates, 0, ArraySize(rates)-4, 4);
      MqlRates rates5[];
      ArrayCopy(rates5, rates, 0, ArraySize(rates)-5, 5);

      //FtrSignal *fs2;
      //fs2= new FtrSignal(rates2);
      //if (fs2.CheckSignal(PERIOD_M15)) {
      //   printf("FTR signal detected: %s " + fs2.ToString());
      //   if (fs2.type == SIGNAL_TYPE_BULLISH) {
      //      sendOrder("buy", 0, fs2.GetStopLoss(), 0);
      //   } else {
      //      sendOrder("sell", 0, fs2.GetStopLoss(), 0);
      //   }
      //}
      //delete fs2;
      //fs2 = NULL;
      
      datetime lastbardate;
      SeriesInfoInteger(_Symbol,PERIOD_M15,SERIES_LASTBAR_DATE,lastbardate);
      if (lastbardate == StringToTime("2021.12.03 17:45")) {
         bool stop = true;
      }

      FtrSignal *fs4;
      fs4= new FtrSignal(rates4);
      if (fs4.CheckSignal(PERIOD_M15)) {
         printf("FTR signal detected: %s " + fs4.ToString());
         if (fs4.type == SIGNAL_TYPE_BULLISH) {
            sendOrder("buy", 0, fs4.GetStopLoss(), fs4.GetTakeProfit());
         } else {
            sendOrder("sell", 0, fs4.GetStopLoss(), fs4.GetTakeProfit());
         }
      } //else if (fs4.CheckForClose()) {
      //   ulong ticket = fs4.GetTicket();
      //   closeOrder(ticket);
      //}
      delete fs4;
      fs4 = NULL;

      //FtrSignal *fs2;
      //fs2= new FtrSignal(rates5);
      //if (fs2.CheckSignal(PERIOD_M15)) {
      //   printf("FTR signal detected: %s " + fs2.ToString());
      //   if (fs2.type == SIGNAL_TYPE_BULLISH) {
      //      sendOrder("buy", 0, fs2.GetStopLoss(), 0);
      //   }
      //   else {
      //      sendOrder("sell", 0, fs2.GetStopLoss(), 0);
      //   }
      //}
      //delete fs2;
      //fs2 = NULL;
   }

   if (inbM30.isNewBar()>0) {

      MqlRates rates[];
      int period = 61;
      int cnt = CopyRates(Symbol(), PERIOD_M30, 1, period, rates);

      MqlRates rates2[];
      ArrayCopy(rates2, rates, 0, ArraySize(rates)-2, 2);
      MqlRates rates4[];
      ArrayCopy(rates4, rates, 0, ArraySize(rates)-4, 4);
      MqlRates rates5[];
      ArrayCopy(rates5, rates, 0, ArraySize(rates)-5, 5);

      //FtrSignal *fs2;
      //fs2= new FtrSignal(rates2);
      //if (fs2.CheckSignal(PERIOD_M30)) {
      //   printf("FTR signal detected: %s " + fs2.ToString());
      //   if (fs2.type == SIGNAL_TYPE_BULLISH) {
      //      sendOrder("buy", 0, fs2.GetStopLoss(), 0);
      //   } else {
      //      sendOrder("sell", 0, fs2.GetStopLoss(), 0);
      //   }
      //}
      //delete fs2;
      //fs2 = NULL;

      //FtrSignal *fs4;
      //fs4= new FtrSignal(rates4);
      //if (fs4.CheckSignal(PERIOD_M30)) {
      //   printf("FTR signal detected: %s " + fs4.ToString());
      //   if (fs4.type == SIGNAL_TYPE_BULLISH) {
      //      sendOrder("buy", 0, fs4.GetStopLoss(), fs4.GetTakeProfit());
      //   } else {
      //      sendOrder("sell", 0, fs4.GetStopLoss(), fs4.GetTakeProfit());
      //   }
      //} else if (fs4.CheckForClose()) {
      //   ulong ticket = fs4.GetTicket();
      //   closeOrder(ticket);
      //}
      //delete fs4;
      //fs4 = NULL;
   }

   // Test SND Signal
//   if (inbH1.isNewBar()>0) {
//      MqlRates rates[];
//      int period = 7;
//      int cnt = CopyRates(Symbol(), PERIOD_H1, 1, period, rates);
//
//      MqlRates rates7[];
//      ArrayCopy(rates7, rates, 0, ArraySize(rates)-7, 7);
//
//      SndSignal *snds;
//      snds= new SndSignal(rates7);
//      if (snds.CheckSignal(PERIOD_H1)) {
//         printf("SND signal detected: %s " + snds.ToString());
//         if (snds.type == SIGNAL_TYPE_BULLISH) {
//            sendOrder("buy", snds.GetEntry(), snds.GetStopLoss(), snds.GetTakeProfit());
//         } else {
//            sendOrder("sell", snds.GetEntry(), snds.GetStopLoss(), snds.GetTakeProfit());
//         }
//      }
//      delete snds;
//      snds = NULL;
//   }

   //if(inbM30.isNewBar()>0) {
   //   CHashMap<string, double> csi;
   //   calculateCurrencyStrength(24, PERIOD_M30, csi);
   //}

   //Line keyLevel;
   //if (cnt == period) {
   //   MqlRates rates1[];
   //   MqlRates rates2[];
   //   ArrayCopy(rates1, rates, 0, ArraySize(rates)-61, 60);
   //   ArrayCopy(rates2, rates, 0, ArraySize(rates)-60, 60);
   //   DvpRates dvp1[];
   //   DvpRates dvp2[];
   //   CalculateDvp(60, 100, 70, rates1, dvp1, Symbol(), false);
   //   CalculateDvp(60, 100, 70, rates2, dvp2, Symbol(), false);
   //   keyLevel.x1 = dvp1[ArraySize(dvp1)-1].Time;
   //   keyLevel.y1 = dvp1[ArraySize(dvp1)-1].Poc;
   //   keyLevel.x2 = dvp2[ArraySize(dvp2)-1].Time;
   //   keyLevel.y2 = dvp2[ArraySize(dvp2)-1].Poc;
   //}

//   EngulfingSignal *es;
//   MqlRates esRates[];
//   ArrayCopy(esRates, rates, 0, ArraySize(rates)-2, 2);
//   es = new EngulfingSignal(esRates, keyLevel);
//   if (es.CheckSignal(PERIOD_CURRENT)) {
//      printf("engulfing signal detected: %s " + es.ToString());
//   }
//
//   RejectionSignal *rs;
//   MqlRates rsRates[];
//   ArrayCopy(rsRates, rates, 0, ArraySize(rates)-1, 1);
//   rs = new RejectionSignal(rsRates[0], keyLevel);
//   if (rs.CheckSignal(PERIOD_CURRENT)) {
//      printf("rejection signal detected: %s " + rs.ToString());
//   }
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
void sendOrder(string orderType, double price, double sl, double tp) {
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
