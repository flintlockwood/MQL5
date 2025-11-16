//+------------------------------------------------------------------+
//|                                                  SignalClass.mqh |
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

#include <MR\Dvp.mqh>

enum ENUM_SIGNAL_TYPE
{
   SIGNAL_TYPE_BULLISH,
   
   SIGNAL_TYPE_BEARISH
};

struct Line
{
   double x1;
   double y1;
   double x2;
   double y2;
   string type;
};

class SignalBase
{
   public:
      string symbol;
      ENUM_TIMEFRAMES timeframe;
      ENUM_SIGNAL_TYPE type;
      datetime time;
      double price;
      string comment;
      
      virtual string Name() = NULL;
      virtual string ToString() = NULL;
      virtual ENUM_OBJECT GetObjectType() = NULL;
      virtual uchar GetArrowCode() = NULL;
      virtual long GetColor() = NULL;
      virtual double GetEntry();
      virtual double GetStopLoss();
      virtual double GetTakeProfit();
};

class SlippageSignal : public SignalBase
{
   public:
      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BUY_SLIPPAGE" : "SELL_SLIPPAGE";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return 0;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class MarubozuSignal : public SignalBase
{
   public:      
      MqlRates bar;
      DvpRates dvp; 
      
      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_MARUBOZU" : "BEARISH_MARUBOZU";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class RejectionSignal : public SignalBase
{
   public:      
      MqlRates bar;
      DvpRates dvp; 
      
      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_REJECTION" : "BEARISH_REJECTION";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class EngulfingSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      DvpRates dvp;
      double KeyLevel;

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_ENGULFING" : "BEARISH_ENGULFING";
      }
      
      virtual string ToString() {
         return StringFormat("%s, #%s, %s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             _Symbol,
                             Name(),
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class HaramiSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      DvpRates dvp;      

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_HARAMI" : "BEARISH_HARAMI";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class StarSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      DvpRates dvp;      

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_MORNING_STAR" : "BEARISH_EVENING_STAR";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class TripleCsSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      DvpRates dvp;      

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_THREE_WHITE_SOLDIERS" : "BEARISH_THREE_BLACK_CROWS";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};

class ThreeInsideSignal : public SignalBase
{
   public:
      MqlRates firstBar;
      MqlRates secondBar;
      DvpRates dvp;      

      virtual string Name() {
         return type == SIGNAL_TYPE_BULLISH ? "BULLISH_THREE_INSIDE_UP" : "BEARISH_THREE_INSIDE_DOWN";
      }
      
      virtual string ToString() {
         return StringFormat("%s, %s, #%s, %s, %s",
                             TimeToString(time, TIME_DATE|TIME_SECONDS),
                             Name(),
                             _Symbol,
                             EnumToString(timeframe),
                             DoubleToString(price, _Digits));
      }
      
      virtual ENUM_OBJECT GetObjectType() {
         return type == SIGNAL_TYPE_BULLISH ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
      }
      
      virtual uchar GetArrowCode() {
         return type == SIGNAL_TYPE_BULLISH ? 233 : 243;
      }
      
      virtual long GetColor() {
         return type == SIGNAL_TYPE_BULLISH ? clrGreen : clrRed;
      }
      
      virtual double GetEntry() {
         return 0;
      }
      
      virtual double GetStopLoss() {
         return 0;
      }
      
      virtual double GetTakeProfit() {
         return 0;
      }
};