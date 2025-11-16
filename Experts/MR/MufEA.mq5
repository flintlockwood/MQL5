//+------------------------------------------------------------------+
//|                                                        MufEA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MR\Array.mqh>
#include <Generic\HashMap.mqh>
#include "Common.mqh"
//#include "MufEAInit.mqh"
//#include "MufEADvp.mqh"
//#include "MufEATick.mqh"
#include "MufEACommand.mqh"
#include "CurrencyStrength.mqh"
#include "SignalCheck.mqh"
#include "Alerter.mqh"

input double           VolumeTreshold     = 10;
input int              inpRsiPeriod       = 12;
input ENUM_TIMEFRAMES  inpRsiTimeFrame    = PERIOD_H1;
//input bool             inpNotifyBullishCross = false;
//input bool             inpNotifyBearishCross = false;
//input bool             inpNotifyCSPatternM15 = false;
//input bool             inpNotifyCSPatternM30 = false;
//input bool             inpNotifyCSPatternH1 = false;
//input bool             inpNotifyCSPatternH4 = false;
//input bool             inpNotifyCSPatternD1 = false;
input string           comment            = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_DELETE,true);
   EventSetTimer(1);
   commandInit();
   keyLevelInit();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Comment("");
   EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//void OnTick()
//{
//calculateDvp();
//OnTickProcess();
//bool redraw = checkSlippage();
//if (redraw) {
//   drawSignals();
//}
//}
//+------------------------------------------------------------------+
void OnTimer() {
   checkNewCommand();
//EAinit();

   datetime dt = TimeCurrent();
   if ((dt-1) % (50*60) == 0) {
      keyLevelInit();
   }

   checkSignal();
//checkBreakout();

   calculateCurrencyStrength(inpRsiPeriod, inpRsiTimeFrame, comment);

//if (inpNotifyBullishCross || inpNotifyBearishCross) {
//   if (isNewBar2(PERIOD_M15)) {
//      CHashMap<string, double> map;
//      calculateCurrencyStrength(12, PERIOD_M5, map);
//      string strSym = _Symbol;
//      string base = StringSubstr(strSym, 0, 3);
//      string quote = StringSubstr(strSym, 3, 3);
//      double baseStrength;
//      double quoteStrength;
//      map.TryGetValue(base, baseStrength);
//      map.TryGetValue(quote, quoteStrength);
//      if (inpNotifyBullishCross && baseStrength > quoteStrength && (baseStrength > 60 || quoteStrength < 40)) {
//         string content = StringFormat("%s, #%s BULLISH_CROSS %s (%s) is stronger than %s (%s)", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, base, DoubleToString(baseStrength, 1), quote, DoubleToString(quoteStrength, 1));
//         writeSignal(content);
//         //inpNotifyBullishCross = false;
//      }
//      else if (inpNotifyBearishCross && baseStrength < quoteStrength && (baseStrength < 40 || quoteStrength > 60)) {
//         string content = StringFormat("%s, #%s BEARISH_CROSS %s (%s) is stronger than %s (%s)", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), _Symbol, quote, DoubleToString(quoteStrength, 1), base, DoubleToString(baseStrength, 1));
//         writeSignal(content);
//         //inpNotifyBearishCross = false;
//      }
//   }
//}

//   if (inpNotifyCSPatternM15) {
//      if (isNewBar2(PERIOD_M15)) {
//         //Print("checking all cs pattern on M15 timeframe");
//         bool redraw = checkAllCSPattern(PERIOD_M15);
//         //if (redraw) {
//         //   drawSignals();
//         //}
//      }
//   }
//
//   if (inpNotifyCSPatternM30) {
//      if (isNewBar2(PERIOD_M30)) {
//         //Print("checking all cs pattern on M30 timeframe");
//         bool redraw = checkAllCSPattern(PERIOD_M30);
//         //if (redraw) {
//         //   drawSignals();
//         //}
//      }
//   }
//
//   if (inpNotifyCSPatternH1) {
//      if (isNewBar2(PERIOD_H1)) {
//         //Print("checking all cs pattern on H1 timeframe");
//         checkAllCSPattern(PERIOD_H1);
//      }
//   }
//
//   if (inpNotifyCSPatternH4) {
//      if (isNewBar2(PERIOD_H4)) {
//         //Print("checking all cs pattern on H4 timeframe");
//         checkAllCSPattern(PERIOD_H4);
//      }
//   }
//
//   if (inpNotifyCSPatternD1) {
//      if (isNewBar2(PERIOD_D1)) {
//         //Print("checking all cs pattern on D1 timeframe");
//         checkAllCSPattern(PERIOD_D1);
//      }
//   }
}

// monitor last deal (open/close) trade
void OnTrade() {
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {
   if (id == CHARTEVENT_OBJECT_DELETE || id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_ENDEDIT || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG) {
      string arr[];
      StringSplit(sparam, StringGetCharacter(" ", 0), arr);
      ENUM_TIMEFRAMES tf = StringToTimeframe("PERIOD_" + arr[1]);
      string type = arr[2];
      StringToLower(type);
      type = StringSubstr(type, 0, 1) == "s" ? "breakdown" : "breakout";
      double d1 = ObjectGetDouble(0, sparam, OBJPROP_PRICE, 0);
      datetime t1 = ObjectGetInteger(0, sparam, OBJPROP_TIME, 0);
      double d2 = ObjectGetDouble(0, sparam, OBJPROP_PRICE, 1);
      datetime t2 = ObjectGetInteger(0, sparam, OBJPROP_TIME, 1);
      string content = StringFormat("%s %s %s %s %i %s %i %s", arr[0], _Symbol, EnumToString(tf), type, t1, DoubleToString(d1, _Digits), t2, DoubleToString(d2, _Digits));

      if (StringSubstr(sparam, 0, 1) == "#") {
         if(id==CHARTEVENT_OBJECT_DELETE) {
            deleteAlert(content);
         }
         if(id==CHARTEVENT_OBJECT_CREATE) {
            addAlert(content);
         }
         if(id==CHARTEVENT_OBJECT_ENDEDIT || id==CHARTEVENT_OBJECT_CHANGE || id==CHARTEVENT_OBJECT_DRAG) {
            updateAlert(content);
         }
         keyLevelInit();
      }

   } else {
      return;
   }
}

//void drawSignals()
//{
//   ObjectsDeleteAll(0, "Signal*");
//   int n = 0;
//   if (signals.Length() >= 50)
//   {
//      n = signals.Length()-50;
//   }
//
//   for(int i=n; i<signals.Length(); i++)
//   {
//      if (signals.GetValueAt(i).timeframe == PERIOD_M30) {
//         string name = StringFormat("Signal #%i %s", i, signals.GetValueAt(i).Name());
//         string comment = signals.GetValueAt(i).ToString();
//         ENUM_OBJECT arrowType = signals.GetValueAt(i).GetObjectType();
//         ObjectCreate(0, name, arrowType, 0, signals.GetValueAt(i).time, signals.GetValueAt(i).price);
//         ObjectSetInteger(0, name, OBJPROP_COLOR, signals.GetValueAt(i).GetColor());
//         ObjectSetString(0, name, OBJPROP_TEXT, comment);
//         if (signals.GetValueAt(i).GetArrowCode() > 0) {
//            ObjectSetInteger(0, name, OBJPROP_ARROWCODE, signals.GetValueAt(i).GetArrowCode());
//         }
//      }
//   }
//   ChartRedraw();
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendNotification() {
// define the URL you want to send the POST request to
   string url = "http://localhost:3000/";

// define the POST data you want to send
   string post_data = "param1=value1&param2=value2";

// create a new web request object
   CWebRequest request;

// set the URL and POST data on the request object
   request.Url(url);
   request.Post(post_data);

// send the POST request
   string result = request.Send();

// handle the result of the request
   if (request.ErrorCode() == WEB_REQUEST_ERROR_NONE) {
      // successful request
      Print("Result: ", result);
   } else {
      // error occurred
      Print("Error: ", request.ErrorDescription());
   }
}


//+------------------------------------------------------------------+
