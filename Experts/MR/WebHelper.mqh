//+------------------------------------------------------------------+
//|                                                    WebHelper.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include "PriceHelper.mqh"

string broadcastUrl = "http://localhost/broadcast";
string messageUrl = "http://localhost/message";
string signalUrl = "http://localhost/signal";
string newBarUrl = "http://localhost/newbar";

void BroadcastMessage(string symbol, ENUM_TIMEFRAMES tf, string message) {
   string cookie=NULL,headers,result_header;
   char   post[],result[];

   headers = "Content-Type:application/json";

// JSON text to send
   string currtime = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
   string timeframe = TimeFrameToString(tf);
   string strJsonText = StringFormat("{\"time\":\"%s\", \"symbol\":\"%s\", \"timeframe\":\"%s\", \"message\":\"%s\"}", currtime, symbol, timeframe, message);
   uchar jsonData[];
   StringToCharArray(strJsonText,jsonData,0,StringLen(strJsonText),CP_UTF8);

   ResetLastError();

   printf("sending signal to %s with message: %s", signalUrl, strJsonText);
   int res=WebRequest("POST",signalUrl,headers,500,jsonData,result,result_header);
   if(res==-1) {
      Print("Error in WebRequest. Error code  =",GetLastError());
      MessageBox("Add the address '"+signalUrl+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
   } else {
      if(res != 200) {
         PrintFormat("Downloading '%s' failed, error code %d",broadcastUrl,res);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrivateMessage(string chatid, string message) {
   string cookie=NULL,headers,result_header;
   char   post[],result[];

   headers = "Content-Type:application/json";

// JSON text to send
   string strJsonText = StringFormat("{\"id\":\"%s\", \"message\":\"%s\"}", chatid, message);
   StringReplace(strJsonText, "\\", "\\\\");
   printf(strJsonText);
   uchar jsonData[];
   StringToCharArray(strJsonText,jsonData,0,StringLen(strJsonText),CP_UTF8);

   ResetLastError();

   int res=WebRequest("POST",messageUrl,headers,500,jsonData,result,result_header);
   if(res==-1) {
      Print("Error in WebRequest. Error code  =",GetLastError());
      MessageBox("Add the address '"+messageUrl+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
   } else {
      if(res != 200) {
         PrintFormat("Downloading '%s' failed, error code %d",messageUrl,res);
      }
   }
}
//+------------------------------------------------------------------+
string ScreenCaptureChart(string symbol, ENUM_TIMEFRAMES period) {
   long id = ChartFirst();
   while(id >= -1) {
      if (ChartSymbol(id) == symbol) {
         break;
      }
      id = ChartNext(id);
   }
   string strPeriod = EnumToString(period);
   StringReplace(strPeriod, "PERIOD_", "");

   string filename = StringFormat("%s_%s.png", symbol, strPeriod);
//printf("filename: %s", filename);
   ResetLastError();
   bool success = ChartScreenShot(id, filename, 1000, 600, ALIGN_RIGHT);
   int err = GetLastError();
   if (err > 0) {
      printf("error: %i", err);
      return NULL;
   } else {
      string filepath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + filename;
      return filepath;
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendNewBarEvent(string symbol, ENUM_TIMEFRAMES period) {
   string cookie=NULL,headers,result_header;
   char   post[],result[];

   headers = "Content-Type:application/json";

// JSON text to send
   string strJsonText = StringFormat("{\"symbol\":\"%s\", \"period\":\"%s\"}", symbol, EnumToString(period));
   StringReplace(strJsonText, "\\", "\\\\");
   printf(strJsonText);
   uchar jsonData[];
   StringToCharArray(strJsonText,jsonData,0,StringLen(strJsonText),CP_UTF8);

   ResetLastError();

   int res=WebRequest("POST",newBarUrl,headers,500,jsonData,result,result_header);
   if(res==-1) {
      Print("Error in WebRequest. Error code  =",GetLastError());
      MessageBox("Add the address '"+newBarUrl+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
   } else {
      if(res != 200) {
         PrintFormat("Downloading '%s' failed, error code %d",messageUrl,res);
      }
   }
}