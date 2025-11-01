//+------------------------------------------------------------------+
//|                                              CSlippageSignal.mqh |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

#include <Math\Stat\Math.mqh>
#include <Generic\HashMap.mqh>
#include <MR\Array.mqh>
#include "MufEAInclude.mqh"
#include "MufEAInit.mqh"
#include "MufEAGlobal.mqh"

bool checkSlippage() {
   // calculate DVP
   ENUM_TIMEFRAMES tf = PERIOD_M30;
   int period = 60;
   MqlRates rates[];
   CopyRates(_Symbol, tf, 1, period, rates);
   DvpRates dvp;
   getCurrDVP(period, 100, 70, rates, dvp);  
   
   MqlTick ticks[];
   CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 2);
   
   bool ret = false;
   
   SignalBase *bSignal;
   bSignal = new SlippageSignal();
   if (checkBuySlippage(ticks, spreadTreshold, slippageTreshold, dvp, bSignal)) {
      bSignal.timeframe = tf;
      writeSignal(bSignal.ToString());
      signals.Push(bSignal);
      ret = true;
      printf("buy slippage at %s, %s", TimeToString(bSignal.time), DoubleToString(bSignal.price, _Digits));
   }
   
   SignalBase *sSignal;
   sSignal = new SlippageSignal();
   if (checkSellSlippage(ticks, spreadTreshold, slippageTreshold, dvp, sSignal)) {
      sSignal.timeframe = tf;
      writeSignal(sSignal.ToString());
      signals.Push(sSignal);
      ret = true;
      printf("sell slippage at %s, %s", TimeToString(sSignal.time), DoubleToString(sSignal.price, _Digits));
   }
   
   return ret;
}

bool checkBuySlippage(MqlTick &ticks[], double spth, double sth, DvpRates &dvp, SignalBase &signal) {
   if (ArraySize(ticks) != 2) {
      return false;
   }
   
   double spread = ticks[1].ask - ticks[1].bid;
   if (spread > spth)
   {
      return false;
   }
   
   double bidChanges = ticks[1].bid - ticks[0].bid;
   double askChanges = ticks[1].ask - ticks[0].ask;
   if (sth > 0 && MathAbs(bidChanges) >= sth && MathAbs(askChanges) >= sth)
   {
      if (bidChanges > 0 && askChanges > 0)
      {
         if ((ticks[0].ask < dvp.Val && ticks[1].ask > dvp.Val) ||
             (ticks[0].ask < dvp.Poc && ticks[1].ask > dvp.Poc) ||
             (ticks[0].ask < dvp.Vah && ticks[1].ask > dvp.Vah) ||
             (ticks[0].ask - dvp.Val > 0 && MathAbs(ticks[0].ask - dvp.Val) <= 15*_Point) ||
             (ticks[0].ask - dvp.Poc > 0 && MathAbs(ticks[0].ask - dvp.Poc) <= 15*_Point) ||
             (ticks[0].ask - dvp.Vah > 0 && MathAbs(ticks[0].ask - dvp.Vah) <= 15*_Point)) {
             SlippageSignal s;
             s.price = ticks[1].ask;
             s.time = ticks[1].time;
             s.type = SIGNAL_TYPE_BULLISH;
             signal = s;
             return true;
         }
      }
   }
   return false;
}

bool checkSellSlippage(MqlTick &ticks[], double spth, double sth, DvpRates &dvp, SignalBase &signal) {
   if (ArraySize(ticks) != 2) {
      return false;
   }
   
   double spread = ticks[1].ask - ticks[1].bid;
   if (spread > spth)
   {
      return false;
   }
   
   double bidChanges = ticks[1].bid - ticks[0].bid;
   double askChanges = ticks[1].ask - ticks[0].ask;
   if (sth > 0 && MathAbs(bidChanges) >= sth && MathAbs(askChanges) >= sth)
   {
      if (bidChanges < 0 && askChanges < 0)
      {
         if ((ticks[0].bid > dvp.Val && ticks[1].bid < dvp.Val) ||
             (ticks[0].bid > dvp.Poc && ticks[1].bid < dvp.Poc) ||
             (ticks[0].bid > dvp.Vah && ticks[1].bid < dvp.Vah) ||
             (ticks[0].bid - dvp.Val < 0 && MathAbs(ticks[0].bid - dvp.Val) <= 15*_Point) ||
             (ticks[0].bid - dvp.Poc < 0 && MathAbs(ticks[0].bid - dvp.Poc) <= 15*_Point) ||
             (ticks[0].bid - dvp.Vah < 0 && MathAbs(ticks[0].bid - dvp.Vah) <= 15*_Point)) {
             SlippageSignal s;
             s.price = ticks[1].ask;
             s.time = ticks[1].time;
             s.type = SIGNAL_TYPE_BEARISH;
             signal = s;
             return true;
         }
      }
   }
   return false;
}

class CSlippageSignal
{
protected:
   
private:
   int m_ntick;
   MqlTick m_lasttick;
   double m_slippage_th;
   double m_spread_th;
   double m_volume_th;
   int m_signalCapacity;
   TArrayStack<MSignal> *m_signals;
   
   void calcSlippageTH(MqlTick &ticks[], double &sth)
   {
      double changes[];
      double prevbid = 0;
      double prevask = 0;
      ArrayResize(changes, ArraySize(ticks)*2);
      for(int i=0; i<ArraySize(ticks); i=i+2)
      {
         if (prevbid > 0 && prevask > 0) 
         {
            changes[i] = NormalizeDouble(MathAbs(ticks[i].bid - prevbid), Digits());
            changes[i+1] = NormalizeDouble(MathAbs(ticks[i].ask - prevask), Digits());
         }
         prevbid = ticks[i].bid;
         prevask = ticks[i].ask;
      }
      double sd = MathStandardDeviation(changes);
      double avg = MathMean(changes);
      sth = NormalizeDouble(avg + sd*7, Digits());
   }
   
   void calcVolumeTH(MqlTick &ticks[], double &vth, double &spth)
   {
      double spreads[];
      CHashMap<datetime, double> hmTicks;
      for(int i=0; i<ArraySize(ticks); i++)
      {
         if (hmTicks.ContainsKey(ticks[i].time))
         {
            double val;
            hmTicks.TryGetValue(ticks[i].time, val);
            val++;
            hmTicks.TrySetValue(ticks[i].time, val);
         }
         else 
         {
            hmTicks.Add(ticks[i].time, 1);
         }
         ArrayResize(spreads, ArraySize(spreads)+1, 1000);
         spreads[ArraySize(spreads)-1] = NormalizeDouble(ticks[i].ask - ticks[i].bid, Digits());
      }
      datetime dts[];
      double tc[];
      hmTicks.CopyTo(dts, tc);
      double avg = MathMean(tc);
      double sd = MathStandardDeviation(tc);
      vth = NormalizeDouble(avg + sd*7, Digits());
      // spread treshold calculation
      avg = MathMean(spreads);
      sd = MathStandardDeviation(spreads);
      spth = NormalizeDouble(avg + sd, Digits());
   }
   
   void checkDoubleSlippage()
   {
   }
   
   void checkTripleSlippage()
   {
   }
   
   void checkQuadrupleSlippage()
   {
   }
   
public:
   void CSlippageSignal()
   {
      m_signals = new TArrayStack<MSignal>(200);
   }
   
   void SetNTicks(int n)
   {
      m_ntick = n;
   }
   
   void setSlippageTH(double th)
   {
      this.m_slippage_th = th;
   }
   
   void SetSpreadTH(double th)
   {
      this.m_spread_th = th;
   }
   
   void SetVolumeTH(double th)
   {
      this.m_volume_th = th;
   }
   
   void SetSignalCapacity(int n)
   {
      this.m_signalCapacity = n;
   }
   
   void Init()
   {
      m_signals = new TArrayStack<MSignal>(m_signalCapacity);
      
      MqlTick ticks[];
      int n = CopyTicks(Symbol(), ticks, COPY_TICKS_ALL, 0, m_ntick);
      if (n == m_ntick)
      {
         Comment("Initialiazing...");
         calcSlippageTH(ticks, m_slippage_th);
         calcVolumeTH(ticks, m_volume_th, m_spread_th);
         
         Comment(StringFormat("sth:%s vth:%s spth:%s",
                              DoubleToString(m_slippage_th,Digits()), 
                              DoubleToString(m_volume_th, Digits()),
                              DoubleToString(m_spread_th, Digits())));
      }
   }
   
   void CheckCondition(MqlTick &tick, MSignal &signal)
   {
      MufTick mtick = new MufTick(tick);
      mtick.prevtime = m_lasttick.time;
      mtick.prevbid = m_lasttick.bid;
      mtick.prevask = m_lasttick.ask;
      mtick.slippage_treshold = m_slippage_th;
      mtick.spread_treshold = m_spread_th;
      m_lasttick = tick;
      if (mtick.BuySlippage() || mtick.SellSlippage())
      {
         
      }
   }
};
