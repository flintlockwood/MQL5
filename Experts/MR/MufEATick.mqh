//+------------------------------------------------------------------+
//|                                                 MufEAInclude.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
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
#include <MR\Array.mqh>
#include "MufEAInclude.mqh"
#include "MufEAInit.mqh"
#include "MufEADvp.mqh"

datetime lastticktime = 0;
//int lasttotalcnt = 0;
//int lastbuycnt = 0;
//int lastsellcnt = 0;
TArrayStack<MSignal> signals(100);
TArrayStack<MSignal> signals2(100);
TArrayStack<double> lastPrices(1000);
TArrayStack<MufTick> lastTicks(100);
bool autoTrade = false;
double prevbid = 0;
double prevask = 0;
int slippagecount = 0;
int buyslippagecount = 0;
int sellslippagecount = 0;
int buytick = 0;
int selltick = 0;
int tickcount = 0;
double pocTreshold = 3*_Point;
int scount = 0;
bool redraw = false;

void OnTickProcess()
{
   MqlTick currTick;
   SymbolInfoTick(Symbol(), currTick);
   
   double currbid = currTick.bid;
   double currask = currTick.ask;
   double currprice = currbid+(currask-currbid)/2;
  
   if (currTick.time > lastticktime)
   {
      if (lastTicks.Length() >= volumeTreshold)
      {
         int buytickcount = 0;
         int selltickcount = 0;
         int slippagetickcount = 0;
         double maxbidchanges = 0;
         double maxaskchanges = 0;
         double sumprice = 0;
         for(int i=0; i<lastTicks.Length(); i++)
         {
            if (lastTicks.GetValueAt(i).TickType() == "Buy")
            {
               buytickcount++;
            }
            if (lastTicks.GetValueAt(i).TickType() == "Sell")
            {
               selltickcount++;
            }
            if (lastTicks.GetValueAt(i).TickType() == "Buy/Sell")
            {
               buytickcount++;
               selltickcount++;
            }
            if (lastTicks.GetValueAt(i).Slippage())
            {
               slippagetickcount++;
            }
            if (MathAbs(lastTicks.GetValueAt(i).BidChanges()) > MathAbs(maxbidchanges))
            {
               maxbidchanges = lastTicks.GetValueAt(i).BidChanges();
            }
            if (MathAbs(lastTicks.GetValueAt(i).AskChanges()) > MathAbs(maxaskchanges))
            {
               maxaskchanges = lastTicks.GetValueAt(i).AskChanges();
            }
            sumprice = sumprice + lastTicks.GetValueAt(i).AvgPrice();
         }
         
         MSignal signal;
         signal.signalType = NEUTRAL_UNUSUAL_VOLUME;
         signal.Time = lastticktime;
         signal.Sym = Symbol();
         signal.Price = sumprice/lastTicks.Length();
         signal.buyCount = buytickcount;
         signal.sellCount = selltickcount;
         signal.totalCount = lastTicks.Length();
         signal.BidChanges = maxbidchanges;
         signal.AskChanges = maxaskchanges;
         signals.Push(signal);
         writeSignal(signal.ToString());
         redraw = true;
      }
      lastTicks.RemoveAll();
   }
   
   MufTick mtick;
   mtick.time = currTick.time;
   mtick.bid = currTick.bid;
   mtick.ask = currTick.ask;
   mtick.last = currTick.last;
   mtick.volume = currTick.volume;
   mtick.time_msc = currTick.time_msc;
   mtick.flags = currTick.flags;
   mtick.volume_real = currTick.volume_real;
   mtick.prevtime = lastticktime;
   mtick.prevbid = prevbid;
   mtick.prevask = prevask;
   mtick.slippage_treshold = slippageTreshold;
   mtick.spread_treshold = spreadTreshold;
   lastTicks.Push(mtick);
   
   if (mtick.BuySlippage()) 
   {
      MSignal signal;
      signal.signalType = BUY_SLIPPAGE;
      signal.Time = mtick.time;
      signal.Sym = Symbol();
      signal.Price = mtick.ask;
      signal.BidChanges = mtick.BidChanges();
      signal.AskChanges = mtick.AskChanges();
      signal.Spread = mtick.Spread();
      DvpRates dvps[];
      double poc = CalculateCurrentDvp(PERIOD_M30, 60, 100, 70, dvps);
      DvpRates dvp = dvps[ArraySize(dvps)-1];
      signal.Poc = poc;
      signal.comment = MathAbs(signal.Price - signal.Poc) <= 15 * Point() ? "Confirmed by poc" : "";
      //if (checkQuadrupleSlippage())
      //{
      //}
      //else if (checkTripleSlippage())
      //{
      //}
      //else if (checkDoubleSlippage())
      //{
      //}
      //else 
      //{
      //}
      if (mtick.prevask < dvp.Val && mtick.ask > dvp.Val ||
          mtick.prevask < dvp.Poc && mtick.ask > dvp.Poc ||
          mtick.prevask < dvp.Vah && mtick.ask > dvp.Vah) {
         signals.Push(signal);
         writeSignal(signal.ToString());
         checkCondition();
         redraw = true;
      }
   }
   else if (mtick.SellSlippage())
   {
      MSignal signal;
      signal.signalType = SELL_SLIPPAGE;
      signal.Time = mtick.time;
      signal.Sym = Symbol();
      signal.Price = mtick.bid;
      signal.BidChanges = mtick.BidChanges();
      signal.AskChanges = mtick.AskChanges();
      signal.Spread = mtick.Spread();
      DvpRates dvps[];
      double poc = CalculateCurrentDvp(PERIOD_M30, 60, 100, 70, dvps);
      DvpRates dvp = dvps[ArraySize(dvps)-1];
      signal.Poc = poc;
      signal.comment = MathAbs(signal.Price - signal.Poc) <= 15 * Point() ? "Confirmed by poc" : "";
      
      if (mtick.prevbid < dvp.Val && mtick.bid > dvp.Val ||
          mtick.prevbid < dvp.Poc && mtick.bid > dvp.Poc ||
          mtick.prevbid < dvp.Vah && mtick.bid > dvp.Vah) {
         signals.Push(signal);
         writeSignal(signal.ToString());
         checkCondition();
         redraw = true;
      }
   }
   
   lastticktime = currTick.time;
   prevbid = currbid;
   prevask = currask;
   drawArrow();
}

void enterTrade(MSignal &currSignal)
{
   int cntSignal = 0;
   int cntBuy = 0;
   int cntSell = 0;
   for(int i=signals.Length()-1; i>=0; i--)
   {
      if (currSignal.Time - signals.GetValueAt(i).Time > 3600)
      {
         continue;
      }
      double p = 30 * Point();
      if (MathAbs(currSignal.Price - signals.GetValueAt(i).Price) <= p)
      {
         cntBuy = cntBuy + signals.GetValueAt(i).buyCount;
         cntSell = cntSell + signals.GetValueAt(i).sellCount;
         cntSignal++;
      }
   }
   string signalType = cntBuy > cntSell ? "Buy" : cntSell > cntBuy ? "Sell" : "";
   double poc = 0;
   MqlTick currTick;
   SymbolInfoTick(Symbol(), currTick);
   double currprice = currTick.bid+(currTick.ask-currTick.bid)/2;
   for(int i=ArraySize(dvp)-1; i>=0; i--)
   {
      poc = dvp[i].Poc;
      if (MathAbs(currprice - dvp[i].Poc) > 80*Point())
      {
         continue;
      }
      if ((currprice - dvp[i].Poc < 0 && signalType == "Buy") || (currprice - dvp[i].Poc > 0 && signalType == "Sell"))
      {
         signalType = "";
      }
      else 
      {
         break;
      }
   }
   if (signalType == "")
   {
      return;
   }
   string str = StringFormat("%s, %s, %s, %i, %i, %i, %s, recommendation to %s, poc: %s",
                             TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                             Symbol(),
                             signalType,
                             cntBuy,
                             cntSell,
                             cntSignal,
                             DoubleToString(currSignal.Price, Digits()),
                             signalType,
                             DoubleToString(poc, Digits()));                          
   writeSignal(str);
}

void drawArrow()
{
   if (!redraw)
   {
      return;
   }
   
   ObjectsDeleteAll(0, "Signal*");
   int n = 0;
   if (signals.Length() >= 50)
   {
      n = signals.Length()-50;
   }
   for(int i=n; i<signals.Length(); i++)
   {
      string name = StringFormat("Signal #%i %s", scount, signals.GetValueAt(i).SignalName());
      string comment = signals.GetValueAt(i).ToString();
      ENUM_OBJECT arrowType = signals.GetValueAt(i).SignalArrowType();
      ObjectCreate(0, name, arrowType, 0, signals.GetValueAt(i).Time, signals.GetValueAt(i).Price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, signals.GetValueAt(i).SignalColor());
      ObjectSetString(0, name, OBJPROP_TEXT, comment);
      scount++;
   }
   ChartRedraw();
   redraw = false;
}

void checkCondition()
{
   MSignal signal = signals.GetValueAt(signals.Length()-1);
   if (signal.signalType == BUY_SLIPPAGE)
   {
      for(int i=ArraySize(dvp); i>=0; i--)
      {
      }
   }
   else if (signal.signalType == SELL_SLIPPAGE)
   {
   }
}

bool checkDoubleSlippage(MSignal &s1)
{
   MSignal s2 = signals.GetValueAt(signals.Length()-1);
   MSignal signal;
   ZeroMemory(signal);
   if (s1.Type == BUY_SLIPPAGE && s2.Type == BUY_SLIPPAGE && s1.Time-s2.Time <= 60)
   {
      signal.signalType = BUY_DOUBLE_SLIPPAGE;
      signal.Time = s1.Time;
      signal.Sym = Symbol();
      signal.Price = s1.Price;
   }
   else if (s1.Type == SELL_SLIPPAGE && s2.Type == SELL_SLIPPAGE && s1.Time-s2.Time <= 60)
   {
      signal.signalType = BUY_DOUBLE_SLIPPAGE;
      signal.Time = s1.Time;
      signal.Sym = Symbol();
      signal.Price = s1.Price;
   }
   if (signal.Time > 0)
   {
      signals.Push(signal);
      return true;
   }
   return false;
}

bool checkTripleSlippage(MSignal &s1)
{
   MSignal s2 = signals.GetValueAt(signals.Length()-1);
   MSignal s3 = signals.GetValueAt(signals.Length()-2);
   MSignal signal;
   ZeroMemory(signal);
   if (s1.Type == BUY_SLIPPAGE && s2.Type == BUY_SLIPPAGE && s1.Time-s2.Time <= 60)
   {
      signal.signalType = BUY_DOUBLE_SLIPPAGE;
      signal.Time = s1.Time;
      signal.Sym = Symbol();
      signal.Price = s1.Price;
   }
   else if (s1.Type == SELL_SLIPPAGE && s2.Type == SELL_SLIPPAGE && s1.Time-s2.Time <= 60)
   {
      signal.signalType = BUY_DOUBLE_SLIPPAGE;
      signal.Time = s1.Time;
      signal.Sym = Symbol();
      signal.Price = s1.Price;
   }
   if (signal.Time > 0)
   {
      signals.Push(signal);
      return true;
   }
   return false;
}

bool checkQuadrupleSlippage(MufTick &tick)
{
   MSignal s1 = signals.GetValueAt(signals.Length()-1);
   MSignal s2 = signals.GetValueAt(signals.Length()-2);
   MSignal s3 = signals.GetValueAt(signals.Length()-3);
   MSignal signal;
   ZeroMemory(signal);
   if (tick.BuySlippage() && (s1.Type == BUY_SLIPPAGE || s1.Type == BUY_DOUBLE_SLIPPAGE || s1.Type == BUY_TRIPPLE_SLIPPAGE) && tick.time-s1.Time <= 60)
   {
      if ((s2.Type == BUY_SLIPPAGE || s2.Type == BUY_DOUBLE_SLIPPAGE || s2.Type == BUY_TRIPPLE_SLIPPAGE) && s1.Time-s2.Time <= 60)
      {
         if ((s3.Type == BUY_SLIPPAGE || s3.Type == BUY_DOUBLE_SLIPPAGE || s3.Type == BUY_TRIPPLE_SLIPPAGE) && s2.Time-s3.Time <= 60)
         {
            signal.signalType = BUY_QUADRUPLE_SLIPPAGE;
            signal.Time = tick.time;
            signal.Sym = Symbol();
            signal.Price = tick.ask;
         }
      }
   }
   else if (tick.SellSlippage() && (s1.Type == SELL_SLIPPAGE || s1.Type == SELL_DOUBLE_SLIPPAGE || s1.Type == SELL_TRIPPLE_SLIPPAGE) && tick.time-s1.Time <= 60)
   {
      if ((s2.Type == SELL_SLIPPAGE || s2.Type == SELL_DOUBLE_SLIPPAGE || s2.Type == SELL_TRIPPLE_SLIPPAGE) && s1.Time-s2.Time <= 60)
      {
         if ((s3.Type == SELL_SLIPPAGE || s3.Type == SELL_DOUBLE_SLIPPAGE || s3.Type == SELL_TRIPPLE_SLIPPAGE) && s2.Time-s3.Time <= 60)
         {
            signal.signalType = SELL_QUADRUPLE_SLIPPAGE;
            signal.Time = tick.time;
            signal.Sym = Symbol();
            signal.Price = tick.bid;
         }
      }
   }
   if (signal.Time > 0)
   {
      return true;
   }
   return false;
}

int bullEnCnt = 0;
int bearEnCnt = 0;

void checkEngulfing()
{
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   if (MathMod(t.min, 30) != 0 || t.sec != 0)
   {
      return;
   }
   //printf("Checking enggulfing..");
   
   MqlRates rates[];
   CopyRates(Symbol(), PERIOD_M30, 1, 2, rates);
   //printf("prev time:%s,open:%s,high:%s,low:%s,close:%s", TimeToString(rates[0].time,TIME_DATE|TIME_SECONDS), DoubleToString(rates[0].open,Digits()), DoubleToString(rates[0].high,Digits()), DoubleToString(rates[0].low,Digits()), DoubleToString(rates[0].close,Digits()));
   //printf("curr time:%s,open:%s,high:%s,low:%s,close:%s", TimeToString(rates[1].time,TIME_DATE|TIME_SECONDS), DoubleToString(rates[1].open,Digits()), DoubleToString(rates[1].high,Digits()), DoubleToString(rates[1].low,Digits()), DoubleToString(rates[1].close,Digits()));
   double b1 = rates[0].close - rates[0].open;
   double b2 = rates[1].close - rates[1].open;
   double range = MathAbs(rates[1].high - rates[1].low);
   double ratio = 0;
   if (b2 != 0)
   {
      ratio = range / MathAbs(b2);
   }
   //printf("time:%s, b1:%s, b2:%s, ratio:%s", TimeToString(rates[1].time,TIME_DATE|TIME_SECONDS), DoubleToString(b1, Digits()), DoubleToString(b2, Digits()), DoubleToString(ratio, 2));
   //string check1 = MathAbs(b2) > 1.5*MathAbs(b1) ? "true" : "false";
   //printf("MathAbs(b2) > 1.5*MathAbs(b1): %s", check1);
   //string check2 = ratio <= 4/3 ? "true" : "false";
   //printf("ratio <= 4/3: %s", check1);
   if ((MathAbs(b2) > 2*MathAbs(b1)) && (ratio <= 4.0/3.0))
   {
      //printf("pass first condition");
      // check for bullish engulfing
      if (b1 < 0 && b2 > 0)
      {
         printf("Bullish engulfing detected");
         string name = StringFormat("Bullish Engulfing #%i", bullEnCnt);
         double min = rates[1].low <= rates[0].low ? rates[1].low : rates[0].low;
         //ObjectCreate(0, name, OBJ_ARROW_BUY, 0, rates[1].time, min);
         //ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
         //bullEnCnt++;
         //printf("b1: %s, b2: %s, ratio: %s", DoubleToString(b1, Digits()), DoubleToString(b2, Digits()), DoubleToString(ratio, Digits()));
         MSignal signal;
         signal.signalType = BULLISH_ENGULFING;
         signal.Time = rates[1].time;
         signal.Sym = Symbol();
         signal.Price = min;
         signals.Push(signal);
         string str = StringFormat("%s, %s, %s, %s",
                        TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                        EnumToString(signal.signalType),
                        Symbol(),
                        DoubleToString(signal.Price, Digits()));
         writeSignal(str);
         redraw = true;
      }
      // check for bearish engulfing
      else if (b1 > 0 && b2 < 0)
      {
         printf("Bearish engulfing detected");
         string name = StringFormat("Bearish Engulfing #%i", bearEnCnt);
         double max = rates[1].high >= rates[0].high ? rates[1].high : rates[0].high;
         //ObjectCreate(0, name, OBJ_ARROW_SELL, 0, rates[1].time, max);
         //ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
         //bearEnCnt++;
         MSignal signal;
         signal.signalType = BEARISH_ENGULFING;
         signal.Time = rates[1].time;
         signal.Sym = Symbol();
         signal.Price = max;
         signals.Push(signal);
         string str = StringFormat("%s, %s, %s, %s",
                        TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                        EnumToString(signal.signalType),
                        Symbol(),
                        DoubleToString(signal.Price, Digits()));
         writeSignal(str);
         redraw = true;
      }
   }
}
