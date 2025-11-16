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

#include "ENUM_SIGNAL_TYPE.mqh"

class SignalBase {
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
   virtual bool CheckSignal(ENUM_TIMEFRAMES tf) = NULL;
};
//+------------------------------------------------------------------+
