//+------------------------------------------------------------------+
//|                                             StrategyBacktest.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>
#include "MufEAInclude.mqh"
#include "SignalClass.mqh"
#include "CSPatternWithDVP.mqh"

CTrade ExtTrade;

#define MA_MAGIC 141592

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
   
   ExtTrade.SetExpertMagicNumber(MA_MAGIC);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(Symbol());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   datetime dt = TimeCurrent();
   if (isNewBar(PERIOD_D1)) {
      CheckForOpen();
   }
  }
//+------------------------------------------------------------------+

void CheckForOpen()
{
   // get rates
   int period = 60;
   MqlRates rates[];
   int n = CopyRates(_Symbol, PERIOD_D1, 1, period, rates);
   if (n != period) {
      printf("cannot process checkAllCSPattern because CopyRates return: %i", n);
      return;
   }
   
   // calculate DVP
   DvpRates dvp;
   getCurrDVP(period, 100, 70, rates, dvp);  
   
   MqlRates rates2[];
   ArrayCopy(rates2, rates, 0, period-3, 2);
   
   RejectionSignal *rSignal;
   rSignal = new RejectionSignal();
   int rejectPeriod = 100;
   MqlRates rejectRates[];
   int rn = CopyRates(_Symbol, PERIOD_D1, 1, rejectPeriod, rejectRates);
   if (rn != rejectPeriod) {
      printf("cannot process CheckForOpen because CopyRates return: %i", n);
      return;
   }
   double rAvg[];
   ArrayResize(rAvg, rejectPeriod);
   for(int i=0; i<rejectPeriod; i++) {
      rAvg[i] = rejectRates[i].high - rejectRates[i].low;
   }
   double avgRange = MathMean(rAvg);
   double stdDevRange = MathStandardDeviation(rAvg);
   double rangeTh = avgRange + stdDevRange;
   bool rFlag = checkRejection2(rates[ArraySize(rates)-1], rangeTh, rSignal);
   if (rFlag) {
      rSignal.timeframe = PERIOD_D1;
      if (rSignal.type == SIGNAL_TYPE_BULLISH) {
         printf("bullish rejection at %s, %s", TimeToString(rSignal.time), DoubleToString(rSignal.price, _Digits));
         double price = rates[ArraySize(rates)-1].low + 10*_Point;
         double sl = rates[ArraySize(rates)-1].low - 70*_Point;
         double tp = rates[ArraySize(rates)-1].low + 510*_Point;
         ExtTrade.BuyLimit(1, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, NULL);
      }
      else {
         printf("bearish rejection at %s, %s", TimeToString(rSignal.time), DoubleToString(rSignal.price, _Digits));
         double price = rates[ArraySize(rates)-1].high - 10*_Point;
         double sl = rates[ArraySize(rates)-1].high + 70*_Point;
         double tp = rates[ArraySize(rates)-1].high - 510*_Point;
         ExtTrade.SellLimit(1, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, NULL);
      }
   }
   
   //EngulfingSignal *eSignal;
   //eSignal = new EngulfingSignal();
   //bool eFlag = checkEnGulfing(rates2, dvp, eSignal);
   //if (eFlag) {
   //   eSignal.timeframe = PERIOD_M30;
   //   printf("engulfing at %s, %s", TimeToString(eSignal.time), DoubleToString(eSignal.price, _Digits));
   //   if (eSignal.type == SIGNAL_TYPE_BULLISH) {
   //      if (rates[ArraySize(rates)-1].low > eSignal.KeyLevel) {
   //         double price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   //         double sl = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - 100*_Point;
   //         double tp = SymbolInfoDouble(_Symbol,SYMBOL_ASK) + 100*_Point;
   //         ExtTrade.PositionOpen(_Symbol,
   //                               eSignal.type == SIGNAL_TYPE_BULLISH ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
   //                               1,
   //                               price,
   //                               sl,
   //                               tp);
   //      }
   //   }
   //   else {
   //      if (rates[ArraySize(rates)-1].high < eSignal.KeyLevel) {
   //         double price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   //         double sl = SymbolInfoDouble(_Symbol,SYMBOL_BID) + 100*_Point;
   //         double tp = SymbolInfoDouble(_Symbol,SYMBOL_BID) - 100*_Point;
   //         ExtTrade.PositionOpen(_Symbol,
   //                               eSignal.type == SIGNAL_TYPE_BULLISH ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
   //                               0.1,
   //                               price,
   //                               sl,
   //                               tp);
   //      }
   //   }
   //}
}

void CheckForClose()
{
}

