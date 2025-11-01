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
#include <Trade\Trade.mqh>
#include "common.mqh"

#define MUF_MAGIC 141592

string lastCommand = "";

void commandInit()
{
   int fhandle = FileOpen(_Symbol + "_LastCommand.txt", FILE_READ|FILE_CSV|FILE_COMMON);
   while(!FileIsEnding(fhandle))
   {
      lastCommand = FileReadString(fhandle);
   }
   FileClose(fhandle);
}

void checkNewCommand()
{
   if (lastCommand == "")
   {
      commandInit();
   }
   int fhandle = FileOpen(_Symbol + "_TradeCommand.txt", FILE_READ|FILE_SHARE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON);
   string allLines[];
   string newLines[];
   string line = "";
   bool beginNewLine = false;
   while(!FileIsEnding(fhandle))
   {
      line = FileReadString(fhandle);
      if (lastCommand == "")
      {
         beginNewLine = true;
      }
      else if (line == lastCommand)
      {
         beginNewLine = true;
         continue;
      }
      if (beginNewLine)
      {
         ArrayResize(newLines, ArraySize(newLines)+1, 10);
         newLines[ArraySize(newLines)-1] = line;
      }
      ArrayResize(allLines, ArraySize(allLines)+1, 100);
      allLines[ArraySize(allLines)-1] = line;
   }
   FileClose(fhandle);
   
   if (!beginNewLine)
   {
      ArrayCopy(newLines, allLines, 0, 0, WHOLE_ARRAY);
   }
   if (ArraySize(newLines) > 0)
   {
      execCommand(newLines);
   }
}

void execCommand(string &commands[])
{
   for(int i=0; i<ArraySize(commands); i++)
   {
      string command = commands[i];
      string sep = " ";
      ushort usep = StringGetCharacter(sep, 0);
      string strArr[];
      StringSplit(command, usep, strArr);
      if (ArraySize(strArr) < 3)
      {
         continue;
      }
      
      if (strArr[0] == "new")
      {
         //cmdNew(line);
      }
      else if (strArr[0] == "mod")
      {
         cmdMod();
      }
      else if (strArr[0] == "position")
      {
         string sym = "";
         string chatid = "";
         string messageid = "";
         if (ArraySize(strArr) > 3) 
         {
            sym = strArr[1];
            chatid = StringSubstr(strArr[2], StringFind(strArr[2], "chatid:")+7);
            messageid = StringSubstr(strArr[3], StringFind(strArr[3], "messageid:")+10);
         }
         else
         {
            chatid = StringSubstr(strArr[1], StringFind(strArr[1], "chatid:")+7);
            messageid = StringSubstr(strArr[2], StringFind(strArr[2], "messageid:")+10);
         }
         
         bool res = cmdPos(sym, chatid, messageid);
      }
      else if (strArr[0] == "chart")
      {       
         string sym = strArr[1];
         string period = strArr[2];
         string chatid = StringSubstr(strArr[3], StringFind(strArr[3], "chatid:")+7);
         string messageid = StringSubstr(strArr[4], StringFind(strArr[4], "messageid:")+10);
         bool res = cmdChart(sym, period, chatid, messageid);
      }
      lastCommand = command;
   }
   writeLastCommand();
}

void cmdNew(string orderType, string sym, double vol, double price, double sl, double tp)
{
   CTrade ct;
   vol = vol == 0 ? 0.1 : vol;
   bool res;
   if (orderType == "Buy")
   {
      res = ct.Buy(vol, sym, price, sl, tp);
   }
   else
   {
      res = ct.Sell(vol, sym, price, sl, tp);
   }
   if (res)
   {
      
   }
   else
   {
      uint errcode = ct.ResultRetcode();
      printf("error: %i", errcode);
   }
//   string sep = " ";
//   ushort usep = StringGetCharacter(sep, 0);
//   string strArr[];
//   StringSplit(line, usep, strArr);
//   int arrSize = ArraySize(strArr);
//   
//   if (arrSize > 3)
//   {
//      if (arrSize > 4) 
//      {
//         price = strArr[4];
//         if (arrSize > 5) 
//         {
//            sl = strArr[5];
//            if (arrSize > 6) 
//            {
//               tp = strArr[6];
//            }
//         }
//      }
//   }
//   
//   CTrade trade;
//   
//   //request.position = position_ticket;        // ticket of the position
//   request.symbol   = symbol;                   // symbol 
//   request.volume   = volume;                   // volume of the position
//   request.deviation= 5;                        // allowed deviation from the price
//   request.magic    = MUF_MAGIC;                // MagicNumber of the position
//   request.price    = price;
//   request.sl       = sl;
//   request.tp       = tp;
//   if (price == 0)
//   {
//      request.action   = TRADE_ACTION_DEAL;
//   }
//   else 
//   {
//      request.action   = TRADE_ACTION_PENDING;
//   }
//   //--- set the price and order type depending on the position type
//   if(orderType == "buy")
//   {
//      if (price == 0) 
//      {
//         request.price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
//      }
//      request.type = ORDER_TYPE_BUY;
//   }
//   else
//   {
//      if (price == 0)
//      {
//         request.price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
//      }
//      request.type = ORDER_TYPE_SELL;
//   }
}

void cmdMod()
{
   //string ticket = strArr[2];
   //sl = strArr[3];
   //if (arrSize > 3)
   //{
   //   tp = strArr[4];
   //}
   //request.action   = TRADE_ACTION_SLTP;        // type of trade operation
   //request.position = ticket;                   // ticket of the position
   //request.symbol   = symbol;                   // symbol 
   //request.sl       = sl;
   //request.tp       = tp;
   //request.magic    = MUF_MAGIC;
   //Print(request.action);
   //Print(request.position);
   //Print(request.symbol);
   //Print(request.sl);
   //Print(request.tp);
}

bool cmdPos(string sym, string chatid, string messageid)
{
   ResetLastError();
   int totalPos = PositionsTotal();
   for(int i=0; i<totalPos; i++)
   {
      CPositionInfo pi;
      pi.SelectByIndex(i);
      ulong ticket;
      pi.InfoInteger(POSITION_TICKET, ticket);
      string type = pi.PositionType() == POSITION_TYPE_BUY ? "Buy" : "Sell";
      string symbol = pi.Symbol();
      double vol = pi.Volume();
      double sl = pi.StopLoss();
      double tp = pi.TakeProfit();
      double profit = pi.Profit();
      double openprice = pi.PriceOpen();
      double currprice = pi.PriceCurrent();
      string str = StringFormat("%s, chatid:%s, messageid:%s, position, #%s, %s, %s, %s, sl:%s, tp:%s, open:%s, curr:%s, profit:%s",
                                TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                chatid,
                                messageid,
                                IntegerToString(ticket),
                                symbol,
                                type,
                                DoubleToString(vol,2),
                                DoubleToString(sl, Digits()),
                                DoubleToString(tp, Digits()),
                                DoubleToString(openprice, Digits()),
                                DoubleToString(currprice, Digits()),
                                DoubleToString(profit, 2));
      if (symbol == sym || sym == "")
      {
         writeSignal(str);
      }
   }
   
   int totalOrd = OrdersTotal();
   for(int i=0; i<totalOrd; i++)
   {
      COrderInfo oi;
      oi.SelectByIndex(i);
      ulong ticket;
      oi.InfoInteger(ORDER_TICKET, ticket);
      string type = EnumToString(oi.OrderType());
      string symbol = oi.Symbol();
      double vol = oi.VolumeInitial();
      double sl = oi.StopLoss();
      double tp = oi.TakeProfit();
      double openprice = oi.PriceOpen();
      double currprice = oi.PriceCurrent();
      string str = StringFormat("%s, chatid:%s, messageid:%s, position, #%s, %s, %s, %s, sl:%s, tp:%s, open:%s, curr:%s, pending",
                                TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                chatid,
                                messageid,
                                IntegerToString(ticket),
                                symbol,
                                type,
                                DoubleToString(vol,2),
                                DoubleToString(sl, Digits()),
                                DoubleToString(tp, Digits()),
                                DoubleToString(openprice, Digits()),
                                DoubleToString(currprice, Digits()));
      if (symbol == sym || sym == "")
      {
         writeSignal(str);
      }
   }
   
   if (totalPos == 0)
   {
      string str = StringFormat("%s, chatid:%s, messageid:%s, position, there is no open position", 
                                 TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                 chatid,
                                 messageid);
      writeSignal(str);
   }
   if (totalOrd == 0)
   {
      string str = StringFormat("%s, chatid:%s, messageid:%s, position, there is no pending order", 
                                 TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                 chatid,
                                 messageid);
      writeSignal(str);
   }
   int err = GetLastError();
   if (err > 0)
   {
      printf("error: %i", err);
      return false;
   }
   return true;
}

bool cmdChart(string sym, string period, string chatid, string messageid)
{
   //printf("sym:%s, period:%s, chatid:%s", sym, period, chatid);
   long id = ChartFirst();
   while(id >= -1)
   {
      if (ChartSymbol(id) == sym)
      {
         break;
      }
      id = ChartNext(id);
   }
   //Print(id);
   
   string filename = StringFormat("%s_%s.png", sym, period);
   //printf("filename: %s", filename);
   ResetLastError();
   bool success = ChartScreenShot(id, filename, 1000, 600, ALIGN_RIGHT);
   int err = GetLastError();
   if (err > 0)
   {
      printf("error: %i", err);
   }
   //printf("success: %i", success);
   if (success)
   {
      string filepath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + filename;
      writeSignal(StringFormat("%s, chatid:%s, messageid:%s, chart, filepath:%s",
                                         TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                         chatid, 
                                         messageid,
                                         filepath));
      return true;
   }
   return false;
}

void writeLastCommand()
{
   int fhandle = FileOpen(_Symbol + "_LastCommand.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
   FileSeek(fhandle, 0, SEEK_SET);
   FileWriteString(fhandle, lastCommand);
   FileFlush(fhandle);
   FileClose(fhandle);
}
