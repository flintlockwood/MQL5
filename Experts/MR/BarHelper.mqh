//+------------------------------------------------------------------+
//|                                                    BarHelper.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
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

#include <Arrays\ArrayObj.mqh>
#include <Generic\HashMap.mqh>

struct LastTimeFrame {
   ENUM_TIMEFRAMES tf;
   datetime lastTimeBar;
};

class CBarHelper {
 private:
   CHashMap<ENUM_TIMEFRAMES, datetime> tfCollection;
 public:
   CBarHelper() {
      tfCollection.Add(PERIOD_M1, 0);
   }
   
   bool IsNewBar(ENUM_TIMEFRAMES tf) {
      datetime lasttime;
      tfCollection.TryGetValue(tf, lasttime);
      datetime currtime = TimeCurrent();
      return (currtime - lasttime) >= PeriodSeconds(tf);
   }
};
