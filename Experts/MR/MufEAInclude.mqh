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

#include <MR\Dvp.mqh>
#include "SignalClass.mqh"

enum SignalType
{
   BUY_SLIPPAGE,
   SELL_SLIPPAGE,
   BUY_UNUSUAL_VOLUME,
   SELL_UNUSUAL_VOLUME,
   NEUTRAL_UNUSUAL_VOLUME,
   BUY_DOUBLE_SLIPPAGE,
   SELL_DOUBLE_SLIPPAGE,
   BUY_TRIPPLE_SLIPPAGE,
   SELL_TRIPPLE_SLIPPAGE,
   BUY_QUADRUPLE_SLIPPAGE,
   SELL_QUADRUPLE_SLIPPAGE,
   BULLISH_ENGULFING,
   BEARISH_ENGULFING
};

struct MSignal
{
   datetime Time;
   string Sym;
   SignalType signalType;
   string Type;
   int buyCount;
   int sellCount;
   int totalCount;
   double Price;
   double Poc;
   datetime PocTime;
   double BidChanges;
   double AskChanges;
   double Spread;
   string comment;
   
   string SignalName()
   {
      string format = "";
      string strOut = "";
      if (signalType == BUY_SLIPPAGE || signalType == SELL_SLIPPAGE)
      { 
         format = "%s BC:%s AC:%s S:%s";
         strOut = StringFormat(format,
                               EnumToString(signalType),
                               DoubleToString(BidChanges, Digits()),
                               DoubleToString(AskChanges, Digits()),
                               DoubleToString(Spread, Digits()));
      }
      else if (signalType == BUY_UNUSUAL_VOLUME || signalType == SELL_UNUSUAL_VOLUME || signalType == NEUTRAL_UNUSUAL_VOLUME)
      {
         format = "%s %s TotalCount:%i";
         strOut = StringFormat(format,
                               EnumToString(signalType),
                               TimeToString(Time, TIME_DATE|TIME_SECONDS),
                               totalCount,
                               DoubleToString(Price, Digits()));
      }
      else
      {
         format = "%s";
         strOut = StringFormat(format, EnumToString(signalType));
      }
      return strOut;
   }
   
   string ToString()
   {
      string format = "";
      string strOut = "";
      if (signalType == BUY_SLIPPAGE || signalType == SELL_SLIPPAGE)
      {
         format = "%s, %s, %s, Price:%s, BidChanges:%s, AskChanges:%s, Spread:%s, POC:%s";
         strOut = StringFormat(format,
                               TimeToString(Time, TIME_DATE|TIME_SECONDS),
                               EnumToString(signalType),
                               Sym,
                               DoubleToString(Price, Digits()),
                               DoubleToString(BidChanges, Digits()),
                               DoubleToString(AskChanges, Digits()),
                               DoubleToString(Spread, Digits()),
                               DoubleToString(Poc, Digits()));
      }
      else if (signalType == BUY_UNUSUAL_VOLUME || signalType == SELL_UNUSUAL_VOLUME || signalType || NEUTRAL_UNUSUAL_VOLUME)
      {
         format = "%s, %s, %s, BuyCount:%i, SellCount:%i, TotalCount:%i, Price:%s";
         strOut = StringFormat(format,
                               TimeToString(Time, TIME_DATE|TIME_SECONDS),
                               EnumToString(signalType),
                               Sym,
                               buyCount,
                               sellCount,
                               totalCount,
                               DoubleToString(Price, Digits()));
      }
      else
      {
         format = "%s, %s, %s, Price:%s, %s";
         strOut = StringFormat(format,
                               TimeToString(Time, TIME_DATE|TIME_SECONDS),
                               EnumToString(signalType),
                               Sym,
                               DoubleToString(Price, Digits()));
      }
      if (comment != NULL && comment != "")
      {
         strOut = StringFormat(strOut + ", Comment:%s",
                               comment);
      }
      return strOut;            
   }
   
   ENUM_OBJECT SignalArrowType()
   {
      if (signalType == BUY_SLIPPAGE || signalType == BULLISH_ENGULFING)
      {
         return OBJ_ARROW_BUY;
      }
      else if (signalType == SELL_SLIPPAGE || signalType == BEARISH_ENGULFING)
      {
         return OBJ_ARROW_SELL;
      }
      else if (signalType == BUY_UNUSUAL_VOLUME || signalType == SELL_UNUSUAL_VOLUME || signalType == NEUTRAL_UNUSUAL_VOLUME)
      {
         return OBJ_ARROW_LEFT_PRICE;
      }
      return OBJ_ARROW_STOP;
   }
   
   long SignalColor()
   {
      if (signalType == BUY_SLIPPAGE || signalType == BUY_UNUSUAL_VOLUME)
      {
         return clrGreen;
      }
      else if (signalType == SELL_SLIPPAGE || signalType == SELL_UNUSUAL_VOLUME)
      {
         return clrRed;
      }
      else if (signalType == BULLISH_ENGULFING)
      {
         return clrBlue;
      }
      else if (signalType == BEARISH_ENGULFING)
      {
         return clrYellow;
      }
      return clrPink;
   }
};

class MufTick
{
   private:
      double _slippage_factor;
      
   public:
      datetime time;
      double bid;
      double ask;
      double last;
      ulong volume;
      long time_msc;
      uint flags;
      double volume_real;
      datetime prevtime;
      double prevbid;
      double prevask;
      double slippage_treshold;
      double spread_treshold;
   
   MufTick()
   {
      if (Symbol() == "EURUSD" || Symbol() == "GBPUSD")
      {
         _slippage_factor = 15;
      }
      else 
      {
         _slippage_factor = 1;
      }
      spread_treshold = 35*Point();
   }
   
   MufTick(MqlTick &tick)
   {
      this.time = tick.time;
      this.bid = tick.bid;
      this.ask = tick.ask;
      this.last = tick.last;
      this.volume = tick.volume;
      this.time_msc = tick.time_msc;
      this.flags = tick.flags;
      this.volume_real = tick.volume_real;
      MufTick();
   }
   
   MufTick(const MufTick& that)
   {
      this.time = that.time;
      this.bid = that.bid;
      this.ask = that.ask;
      this.last = that.last;
      this.volume = that.volume;
      this.time_msc = that.time_msc;
      this.flags = that.flags;
      this.volume_real = that.volume_real;
      this.prevtime = that.prevtime;
      this.prevbid = that.prevbid;
      this.prevask = that.prevask;
      MufTick();
   }
   
   double AvgPrice()
   {
      return bid+(ask-bid)/2;
   }
   
   double Spread()
   {
      return ask-bid;
   }
   
   double BidChanges()
   {
      if (prevbid == 0)
      {
         return 0;
      }
      return bid-prevbid;
   }
   
   double AskChanges()
   {
      if (prevask == 0)
      {
         return 0;
      }
      return ask-prevask;
   }
   
   bool Slippage()
   {
      if (Spread() > spread_treshold)
      {
         return false;
      }
      double sth = 10*Point();
      //double sth = (prevask-prevbid)*_slippage_factor;
      if (slippage_treshold > 0)
      {
         sth = slippage_treshold;
      }
      if (sth > 0 && MathAbs(BidChanges()) >= sth && MathAbs(AskChanges()) >= sth)
      {
         return true;
      }
      return false;
   }
   
   bool BuySlippage()
   {
      if (Spread() > spread_treshold)
      {
         return false;
      }
      double sth = 10*Point();
      //double sth = (prevask-prevbid)*_slippage_factor;
      if (slippage_treshold > 0)
      {
         sth = slippage_treshold;
      }
      if (sth > 0 && MathAbs(BidChanges()) >= sth && MathAbs(AskChanges()) >= sth)
      {
         if (BidChanges() > 0 && AskChanges() > 0)
         {
            return true;
         }
      }
      return false;
   }
   
   bool SellSlippage()
   {
      if (Spread() > spread_treshold)
      {
         return false;
      }
      double sth = 10*Point();
      //double sth = (prevask-prevbid)*_slippage_factor;
      if (slippage_treshold > 0)
      {
         sth = slippage_treshold;
      }
      if (sth > 0 && MathAbs(BidChanges()) >= sth && MathAbs(AskChanges()) >= sth)
      {
         if (BidChanges() < 0 && AskChanges() < 0)
         {
            return true;
         }
      }
      return false;
   }
   
   string TickType()
   {
      string type = "";
      //if ((tickArray[i].flags & TICK_FLAG_BUY) == TICK_FLAG_BUY  || (tickArray[i].flags & TICK_FLAG_ASK) == TICK_FLAG_ASK)
      //{
      //   buytick++;
      //}
      //if ((tickArray[i].flags & TICK_FLAG_SELL) == TICK_FLAG_SELL || (tickArray[i].flags & TICK_FLAG_BID) == TICK_FLAG_BID)
      //{
      //   selltick++;
      //}
      if ((BidChanges() > 0 && AskChanges() > 0) || (BidChanges() == 0 && AskChanges() > 0) || (BidChanges() == 0 && AskChanges() < 0))
      {
         type = "Buy";
      }
      if ((BidChanges() < 0 && AskChanges() < 0) || (BidChanges() < 0 && AskChanges() == 0) || (BidChanges() > 0 && AskChanges() == 0))
      {
         type = "Sell";
      }
      if((BidChanges() < 0 && AskChanges() > 0) || (BidChanges() > 0 && AskChanges() < 0))
      {
         if (MathAbs(BidChanges()) > MathAbs(AskChanges()))
         {
            type = "Sell";
         }
         else if (MathAbs(BidChanges()) < MathAbs(AskChanges()))
         {
            type = "Buy";
         }
         else
         {
            type = "Buy/Sell";
         }
      }
      if (BidChanges() == 0 && AskChanges() == 0)
      {
         type = "Buy/Sell";
      }
      return type;
   }
   
   string ToString()
   {
      double price = NormalizeDouble(bid+(ask-bid)/2, Digits());
      string format="%s, %s, %s, %s, %G, %d, %i, %G, %s, %s, %s, %s, %s";
      string sOut = StringFormat(format,
                                 TimeToString(time, TIME_DATE|TIME_SECONDS),
                                 DoubleToString(bid, Digits()),
                                 DoubleToString(ask, Digits()),
                                 DoubleToString(price, Digits()),
                                 volume,
                                 time_msc,
                                 flags,
                                 volume_real,
                                 TickType(),
                                 Slippage() ? "true" : "false",
                                 DoubleToString(BidChanges(), Digits()),
                                 DoubleToString(AskChanges(), Digits()),
                                 DoubleToString(Spread(), Digits()));
      return sOut;
   }
};

enum MufCommandStatus
{
   NEW,
   DONE,
   ERROR
};

struct MufCommand
{
   string command;
   MufCommandStatus status;
};

void writeSignal(string content)
{
   int fhandle = FileOpen(_Symbol + "_Signals.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

void writeTicksProve(string content)
{
   int fhandle = FileOpen(Symbol() + "_TicksProve.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

void writeLog(string content)
{
   int fhandle = FileOpen(Symbol() + "_ticks_log.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

template<typename T>
T StringToEnum(string str,T enu)
{
   for(int i=0;i<65536;i++)
      if(EnumToString(enu=(T)i)==str)
         return(enu);
   return(-1);
}

bool isNewBar(ENUM_TIMEFRAMES tf) {
   //--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
   //--- current time
   datetime lastbar_time = SeriesInfoInteger(Symbol(), tf, SERIES_LASTBAR_DATE);

   //--- if it is the first call of the function
   if(last_time==0)
     {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
     }

   //--- if the time differs
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
   //--- if we passed to this line, then the bar is not new; return false
   return(false);
}

bool isNewBar2(ENUM_TIMEFRAMES tf) {
   datetime dt = TimeCurrent();
   if (tf == PERIOD_M1) {
      return (dt-1) % 60 == 0;
   }
   else if (tf == PERIOD_M2) {
      return (dt-1) % (2*60) == 0;
   }
   else if (tf == PERIOD_M3) {
      return (dt-1) % (3*60) == 0;
   }
   else if (tf == PERIOD_M4) {
      return (dt-1) % (4*60) == 0;
   }
   else if (tf == PERIOD_M5) {
      return (dt-1) % (5*60) == 0;
   }
   else if (tf == PERIOD_M6) {
      return (dt-1) % (6*60) == 0;
   }
   else if (tf == PERIOD_M10) {
      return (dt-1) % (10*60) == 0;
   }
   else if (tf == PERIOD_M12) {
      return (dt-1) % (12*60) == 0;
   }
   else if (tf == PERIOD_M15) {
      return (dt-1) % (15*60) == 0;
   }
   else if (tf == PERIOD_M20) {
      return (dt-1) % (20*60) == 0;
   }
   else if (tf == PERIOD_M30) {
      return (dt-1) % (30*60) == 0;
   }
   else if (tf == PERIOD_H1) {
      return (dt-1) % (60*60) == 0;
   }
   else if (tf == PERIOD_H2) {
      return (dt-1) % (2*60*60) == 0;
   }
   else if (tf == PERIOD_H3) {
      return (dt-1) % (3*60*60) == 0;
   }
   else if (tf == PERIOD_H4) {
      return (dt-1) % (4*60*60) == 0;
   }
   else if (tf == PERIOD_H6) {
      return (dt-1) % (6*60*60) == 0;
   }
   else if (tf == PERIOD_H8) {
      return (dt-1) % (8*60*60) == 0;
   }
   else if (tf == PERIOD_H12) {
      return (dt-1) % (12*60*60) == 0;
   }
   else if (tf == PERIOD_D1) {
      return (dt-1) % (24*60*60) == 0;
   }
   return false;
}

void getCurrDVP(int period, int nrow, double vapct, MqlRates &rates[], DvpRates &dvp)
{
   if (ArraySize(rates) != period) {
      return;
   }
   
   double prices[];
   long volumes[];
   ArrayResize(prices, period);
   ArrayResize(volumes, period);
   
   for(int i=0; i<period; i++) {
      prices[i] = rates[i].close;
      volumes[i] = rates[i].tick_volume;
   }
   
   double min = prices[ArrayMinimum(prices, 0, period)];
   double max = prices[ArrayMaximum(prices, 0, period)];
   double d=(max-min)/nrow;

   long totalVolume=0;
   long levelVolume[];
   ArrayResize(levelVolume,nrow+1);
   ArrayFill(levelVolume,0,nrow+1,0);
   for(int j=0;j<period;j++) {
      int lvl=getPriceLevel(prices[j],min,d,nrow);
      levelVolume[lvl]+=volumes[j];
      totalVolume+=volumes[j];
   }

   long pocVol=0.0;
   int pocLevel=0;
   for(int j=1; j<=nrow; j++){
      long vol=levelVolume[j];
      if(vol>pocVol) {
         pocLevel=j;
         pocVol=vol;
      }
   }

   double valueArea=totalVolume*vapct/100;
   double val = 0.0;
   double vah = 0.0;
   long tempVol=levelVolume[pocLevel];
   for(int j=1; j<=nrow; j++) {
      long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
      long v2 = pocLevel+j <= nrow ? levelVolume[pocLevel+j] : 0;
      tempVol = tempVol + v1 + v2;
      if(tempVol>=valueArea) {
         val = v1==0 ? min : min+(pocLevel-j-1)*d;
         vah = v2==0 ? max : min+(pocLevel+j)*d;
         break;
      }
   }
   
   if(val==0 && vah==0) {
      val = min;
      vah = max;
   }

   dvp.Time = rates[period-1].time;
   dvp.Poc = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
   dvp.Val = NormalizeDouble(val, _Digits);
   dvp.Vah = NormalizeDouble(vah, _Digits);
}

double getCurrentRsi(string symbol, ENUM_TIMEFRAMES tf, int period) {
   int rsiHandle = iRSI(symbol, tf, period, PRICE_CLOSE);
   if (rsiHandle != INVALID_HANDLE) {
      double rsiBuffer[];
      CopyBuffer(rsiHandle,0,0,1,rsiBuffer);
      return rsiBuffer[0];
   }
   else {
      printf("invalid RSI handle for symbol: %s", symbol);
      return 0;
   }
}

double getCurrRange(ENUM_TIMEFRAMES tf) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, 1, rates);
   if (n == 1) {
      double range = rates[0].high - rates[0].low;
      return NormalizeDouble(range / _Point / 10, 0);
   }
   else {
      printf("cannot calculate getCurrRange because copyrates return: %i", n);
      return 0;
   }
}

double getAverageRange(ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, period, rates);
   if (n == period) {
      double sum = 0;
      for(int i=0; i<period; i++) {
         sum = sum + rates[i].high - rates[i].low;
      }
      return NormalizeDouble(sum / period, _Digits);
   }
   else {
      printf("cannot calculate average range because copyrates return: %i", n);
      return 0;
   }
}

double getAverageRangeInPips(ENUM_TIMEFRAMES tf, int period) {
   return NormalizeDouble(getAverageRange(tf, period) / _Point / 10, 0);
}

double getAverageBody(ENUM_TIMEFRAMES tf, int period) {
   MqlRates rates[];
   int n = CopyRates(_Symbol, tf, 0, period, rates);
   if (n == period) {
      double sum = 0;
      for(int i=0; i<period; i++) {
         sum = sum + MathAbs(rates[i].close - rates[i].open);
      }
      return NormalizeDouble(sum / period, _Digits);
   }
   else {
      printf("cannot calculate average range because copyrates return: %i", n);
      return 0;
   }
}

ENUM_TIMEFRAMES StringToTimeframe(string str) {
   StringToUpper(str);
   if (str == "PERIOD_M1") {
      return PERIOD_M1;
   }
   else if (str == "PERIOD_M2") {
      return PERIOD_M2;
   }
   else if (str == "PERIOD_M3") {
      return PERIOD_M3;
   }
   else if (str == "PERIOD_M4") {
      return PERIOD_M4;
   }
   else if (str == "PERIOD_M5") {
      return PERIOD_M5;
   }
   else if (str == "PERIOD_M6") {
      return PERIOD_M6;
   }
   else if (str == "PERIOD_M10") {
      return PERIOD_M10;
   }
   else if (str == "PERIOD_M12") {
      return PERIOD_M12;
   }
   else if (str == "PERIOD_M15") {
      return PERIOD_M15;
   }
   else if (str == "PERIOD_M20") {
      return PERIOD_M20;
   }
   else if (str == "PERIOD_M30") {
      return PERIOD_M30;
   }
   else if (str == "PERIOD_H1") {
      return PERIOD_H1;
   }
   else if (str == "PERIOD_H2") {
      return PERIOD_H2;
   }
   else if (str == "PERIOD_H3") {
      return PERIOD_H3;
   }
   else if (str == "PERIOD_H4") {
      return PERIOD_H4;
   }
   else if (str == "PERIOD_H6") {
      return PERIOD_H6;
   }
   else if (str == "PERIOD_H8") {
      return PERIOD_H8;
   }
   else if (str == "PERIOD_H12") {
      return PERIOD_H12;
   }
   else if (str == "PERIOD_D1") {
      return PERIOD_D1;
   }
   else if (str == "PERIOD_W1") {
      return PERIOD_W1;
   }
   else if (str == "PERIOD_MN1") {
      return PERIOD_MN1;
   }
   return PERIOD_CURRENT;
}

double calculateY(double x, double x1, double y1, double x2, double y2) {
   return ((y2 - y1) / (x2 - x1) * x) - ((y2 - y1) / (x2 - x1) * x1) + y1;
}

bool isInFrame(ENUM_TIMEFRAMES tf, MqlRates &rates, Line &keyLevel) {
   double currLevel = calculateY(rates.time, keyLevel.x1, keyLevel.y1, keyLevel.x2, keyLevel.y2);
   double avgRange = getAverageRange(tf, 100);
   if (rates.high >= currLevel-avgRange/4 && rates.low <= currLevel+avgRange/4) {
      return true;
   }
   return false;
}

bool isInFrame(ENUM_TIMEFRAMES tf, MqlRates &rates[], Line &keyLevel) {
   for(int i=0; i<ArraySize(rates); i++) {
      if (!isInFrame(tf, rates[i], keyLevel)) {
         return false;
      }
   }
   return true;
}