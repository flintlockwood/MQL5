//+------------------------------------------------------------------+
//|                                                        MufEA.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MR\Dvp.mqh>
#include <Trade\SymbolInfo.mqh>
#include <ChartObjects\ChartObjectsArrows.mqh>
#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
#include <MR\Array.mqh>
#include "Common.mqh"
#include "CIsNewBar.mqh"

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
CChartObjectArrow arrow;
CChartObjectArrow arrow2;
CIsNewBar inbM15;

//SignalBase* signals[];
//TArrayStack<SignalBase*> signals(100);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   inbM15.SetPeriod(PERIOD_M15);
   double t = TimeCurrent();
   EventSetTimer(1);
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_DELETE,true);
   //Print("CHARTEVENT_OBJECT_DELETE ", CHARTEVENT_OBJECT_DELETE);
   //Print("CHARTEVENT_OBJECT_CREATE ", CHARTEVENT_OBJECT_CREATE);
   //Print("CHARTEVENT_OBJECT_ENDEDIT ", CHARTEVENT_OBJECT_ENDEDIT);
   //Print("CHARTEVENT_OBJECT_CHANGE ", CHARTEVENT_OBJECT_CHANGE);
   //Print("CHARTEVENT_OBJECT_DRAG ", CHARTEVENT_OBJECT_DRAG);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
bool run = false;
void OnTick()
{
//---
   
   //int rsiHandle = iRSI("EURUSD", PERIOD_H1, 12, PRICE_CLOSE);
   //double rsiBuffer[];
   //CopyBuffer(rsiHandle,0,0,1,rsiBuffer);
   //if (rsiHandle != INVALID_HANDLE) {
   //   printf("value of curent rsi: %s", DoubleToString(rsiBuffer[0], _Digits));
   //}
   
//   if (isNewBar(PERIOD_M1)) {
//      printf("%s new bar is form", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
//      SignalBase *sb;
//      sb = new SlippageSignal();
//      ArrayResize(signals, ArraySize(signals)+1,10);
//      signals[ArraySize(signals)-1] = sb;
//      signals.Push(sb);
//      printf(sb.ToString());
//      
//      SignalBase *sb2;
//      sb2 = new MarubozuSignal();
//      ArrayResize(signals, ArraySize(signals)+1,10);
//      signals[ArraySize(signals)-1] = sb2;
//      signals.Push(sb2);
//      printf(sb2.ToString());
//      for(int i=0; i<signals.Length(); i++) {
//         SignalBase *signal;
//         signal = signals.GetValueAt(i);
//         printf("from loop: " + signal.ToString());
//      }
//   }
   //exportTick();
   //if (!run)
   //{  
   //   long chartID=ChartFirst();
   //   while(chartID >= 0)
   //   {
   //      Print(chartID);
   //      string symbol = ChartSymbol(chartID);
   //      Print(symbol);
   //      chartID = ChartNext(chartID);
   //   }
   //   run = true;
   //}
   //checkCommand();
   //initialize();
   //calculateDvp();
   //calculateTick();
}
//+------------------------------------------------------------------+



void OnTimer()
{
   //checkBreakout();
   if (inbM15.isNewBar()>0) {
      for(int i=0; i<ObjectsTotal(0, 0, OBJ_TREND); i++) {
         string name = ObjectName(0, i, 0, OBJ_TREND);
         double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
         datetime t1 = ObjectGetInteger(0, name, OBJPROP_TIME, 0);
         double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
         datetime t2 = ObjectGetInteger(0, name, OBJPROP_TIME, 1);
         datetime x = TimeCurrent();
         double y = calculateY(x, t1, p1, t2, p2);
         MqlRates rates[];
         CopyRates(_Symbol, PERIOD_M15, 1, 1, rates);
         if (y >= rates[0].low && y <= rates[0].high) {
            printf("price alert");
            Alert("price alert");
         }
      }
   }
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if (id == CHARTEVENT_OBJECT_DELETE) {
      Print("delete");
   }
   else if (id == CHARTEVENT_OBJECT_CREATE) {
      Print("create");
   }
   else if (id == CHARTEVENT_OBJECT_ENDEDIT) {
      Print("endedit");
   }
   else if (id == CHARTEVENT_OBJECT_CHANGE) {
      Print("change");
   }
   else if (id == CHARTEVENT_OBJECT_DRAG) {
      Print("drag");
   }
   if (id == CHARTEVENT_OBJECT_DELETE || id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_ENDEDIT || id == CHARTEVENT_OBJECT_CHANGE || id == CHARTEVENT_OBJECT_DRAG) {
      string arr[];
      StringSplit(sparam, StringGetCharacter(" ", 0), arr);
      double p1 = ObjectGetDouble(0, sparam, OBJPROP_PRICE, 0);
      datetime t1 = ObjectGetInteger(0, sparam, OBJPROP_TIME, 0);
      double p2 = ObjectGetDouble(0, sparam, OBJPROP_PRICE, 1);
      datetime t2 = ObjectGetInteger(0, sparam, OBJPROP_TIME, 1);
      
      printf("p1: %d, t1: %d, p2: %d, t2: %d", DoubleToString(p1,2), IntegerToString(t1), DoubleToString(p2,2), IntegerToString(t2));
      bool isAbove = false;
      if (t1 != t2) {
         double currprice = 0;
         SymbolInfoDouble(_Symbol, SYMBOL_BID, currprice);
         isAbove = currprice > calculateY(TimeCurrent(), t1, p1, t2, p2);
      }
      if (StringSubstr(sparam, 0, 1) != "#") {
         if (arr[1] == "Trendline") {
            if (t1 != t2) {
               string sr = isAbove ? "Sup" : "Res";
               string newname = StringFormat("#%s %s %s", arr[2], arr[0], sr);
               ObjectSetString(0, sparam, OBJPROP_NAME, newname);
               ENUM_TIMEFRAMES tf = StringToTimeframe("PERIOD_" + arr[0]);
               string type = arr[2];
               StringToLower(sr);
               type = StringSubstr(sr, 0, 1) == "s" ? "breakdown" : "breakout";
               string content = StringFormat("#%s %s %s %s %i %s %i %s", arr[2], _Symbol, EnumToString(tf), type, t1, DoubleToString(p1, _Digits), t2, DoubleToString(p2, _Digits));
               addAlert(content);
            }
         }
      }
      else {
         if (StringSubstr(sparam, 0, 1) == "#") {
            if(id==CHARTEVENT_OBJECT_CREATE) {
               //addAlert(content);
            }
            if(id==CHARTEVENT_OBJECT_DELETE) {
               deleteAlert(arr[0]);
            } 
            if(id==CHARTEVENT_OBJECT_ENDEDIT || id==CHARTEVENT_OBJECT_CHANGE || id==CHARTEVENT_OBJECT_DRAG) {
               string id = StringSubstr(arr[0], 1, StringLen(arr[0])-1);
               if(isAbove && arr[2] == "Sup") {
                  string newname = StringFormat("#%s %s %s", id, arr[1], "Res");
                  ObjectSetString(0, sparam, OBJPROP_NAME, newname);
               }
               else if (!isAbove && arr[2] == "Res") {                  
                  string newname = StringFormat("#%s %s %s", id, arr[1], "Sup");
                  ObjectSetString(0, sparam, OBJPROP_NAME, newname);
               }
               
               ENUM_TIMEFRAMES tf = StringToTimeframe("PERIOD_" + arr[1]);
               string type = arr[2];
               StringToLower(type);
               type = StringSubstr(type, 0, 1) == "s" ? "breakdown" : "breakout";
               string contentold = StringFormat("%s %s %s %s %i %s %i %s", arr[0], _Symbol, EnumToString(tf), type, t1, DoubleToString(p1, _Digits), t2, DoubleToString(p2, _Digits));
               string sor = isAbove ? "breakout" : "breakdown";
               string contentnew = StringFormat("%s %s %s %s %i %s %i %s", arr[0], _Symbol, EnumToString(tf), sor, t1, DoubleToString(p1, _Digits), t2, DoubleToString(p2, _Digits));
               updateAlert(contentnew);
               string sr = isAbove ? "Res" : "Sup";
               if (arr[2] != sr) {
                  string newname = StringFormat("%s %s %s", arr[0], arr[1], sr);
                  ObjectSetString(0, sparam, OBJPROP_NAME, newname);
               }
            }
         }
      }
   }
}

void initialize()
{
   if (TimeCurrent() - lastinittime >= 3600)
   {
      initialize = false;
   }
   if (!initialize) 
   {
      MqlTick ticks[];
      int n = CopyTicks(Symbol(), ticks, COPY_TICKS_ALL, 0, nticks);
      if (n == nticks)
      {
         datetime lastticktime = 0;
         double lastcnt = 0;
         double sum = 0;
         double cnt = 0;
         double avg = 0;
         
         for(int i=0; i<ArraySize(ticks); i++)
         {
            if (ticks[i].time != lastticktime)
            {
               sum = sum + lastcnt;
               lastcnt = 1;
               cnt = cnt + 1;
               lastticktime = ticks[i].time;
            }
            else 
            {
               lastcnt = lastcnt + 1;
            }
         }
         sum = sum + lastcnt;
         avg = sum / cnt;
         volumeTreshold = floor(avg*4);
         Comment("Current treshold " + volumeTreshold);
         initialize = true;
         lastinittime = TimeCurrent();
      }
   }
}

void sendOrder(string orderType)
{
   if (PositionsTotal() > 0)
   {
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
   if(orderType == "buy")
   {
      request.price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      request.type = ORDER_TYPE_BUY;
      request.sl = request.price - pip*200;
      request.tp = request.price + pip*200;
   }
   else
   {
      request.price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      request.type = ORDER_TYPE_SELL;
      request.sl = request.price + pip*200;
      request.tp = request.price - pip*200;
   }
   MqlTradeCheckResult checkresult;
   bool valid = OrderCheck(request, checkresult);
   if (valid)
   {
      MqlTradeResult result;
      bool res = OrderSend(request, result);
      if (!res)
      {
         Print("Order fail");
      }
   }
   else
   {
      Print("Order invlalid");
   }
}

void calculateTick()
{
   MqlTick tempTicks[];
   CopyTicks(Symbol(), tempTicks, COPY_TICKS_ALL, 0, 1);
   MqlTick currTick = tempTicks[0];
   MqlRates tempRates[];
   CopyRates(Symbol(), PERIOD_M1, 0, 1, tempRates);
   MqlRates currRates = tempRates[0];
   
   lastprice = currRates.close;
   lastbid = currTick.bid;
   lastask = currTick.ask;
   bool buyflag = false;
   bool sellflag = false;
   if (lastprice == lastbid)
   {
      buyflag = true;
   }
   else if (lastprice == lastask)
   {
      sellflag = true;
   }
//   if (currTick.time != lastticktime)
//   {
//      string signalType = "";
//      if (lastbuycnt > lastsellcnt)
//      {
//         signalType = "Buy";
//      }
//      else if (lastbuycnt < lastsellcnt)
//      {
//         signalType = "Sell";
//      }
//      else 
//      {
//         signalType = "Neutral";
//      }
//      //string format = "%s,%s,%s,%i,%i,%i,%G";
//      //if (lasttotalcnt >= volumeTreshold)
//      //{
//      //   string strOut = StringFormat(format,
//      //                                TimeToString(currTick.time,TIME_DATE|TIME_SECONDS),
//      //                                Symbol(),
//      //                                signalType,
//      //                                lastbuycnt,
//      //                                lastsellcnt,
//      //                                lasttotalcnt,
//      //                                lastprice);
//      //   writeUnusualActivity(strOut);
//      //   //if (lastbuycnt > lastsellcnt)
//      //   //{
//      //   //   sendOrder("buy");
//      //   //}
//      //   //else if (lastbuycnt < lastsellcnt)
//      //   //{
//      //   //   sendOrder("sell");
//      //   //}
//      //}
//      
//      lasttotalcnt = 1;
//      lastbuycnt = 0;
//      lastsellcnt = 0;
//      if ((currTick.flags & TICK_FLAG_BUY) == TICK_FLAG_BUY || buyflag)
//      {
//         lastbuycnt = 1;
//      }
//      if ((currTick.flags & TICK_FLAG_SELL) == TICK_FLAG_SELL || sellflag)
//      {
//         lastsellcnt = 1;
//      }
//      lastticktime = currTick.time;
//   }
//   else 
//   {
      //lasttotalcnt = lasttotalcnt + 1;
      ////if (currRates.close > lastprice)
      //if ((currTick.flags & TICK_FLAG_BUY) == TICK_FLAG_BUY || buyflag)
      //{
      //   lastbuycnt = lastbuycnt + 1;
      //}
      ////else if (currRates.close < lastprice)
      //if ((currTick.flags & TICK_FLAG_SELL) == TICK_FLAG_SELL || sellflag)
      //{
      //   lastsellcnt = lastsellcnt + 1;
      //}
      
      string format = "%s, %s, %s, %s, %s, %i, %i, %i";
      string sOut = StringFormat(format,
                                 TimeToString(currTick.time, TIME_DATE|TIME_SECONDS),
                                 DoubleToString(currTick.bid, 5),
                                 DoubleToString(currTick.ask, 5),
                                 DoubleToString(lastprice, 5),
                                 DoubleToString(currTick.volume, 0),
                                 currTick.time_msc,
                                 currTick.flags,
                                 currTick.volume_real);
      writeLogTest(sOut);
   //}
}

void writeLogTest(string content)
{
   int fhandle = FileOpen(Symbol() + "_log.txt", FILE_READ|FILE_WRITE|FILE_CSV);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, content);
   FileFlush(fhandle);
   FileClose(fhandle);
}

void calculateDvp()
{
   datetime currTime = TimeCurrent();
   MqlDateTime currDT;
   TimeToStruct(currTime, currDT);
   if (currDT.min == 0 || currDT.min == 30)
   {
      int n = 20*24*2;
      MqlRates rates[];
      DvpRates dvp[];
      int n1 = CopyRates(Symbol(), PERIOD_M30, 0, n, rates);
      if (n1 == n) 
      {
         CalculateDvp(60, 100, 70, rates, dvp, Symbol(), false);
      }
   }
}

void exportTick()
{
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