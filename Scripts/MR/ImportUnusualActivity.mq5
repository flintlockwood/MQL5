//+------------------------------------------------------------------+
//|                                        ImportUnusualActivity.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//--- input parameters
input int      nSignal=100;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
   int fhandle = FileOpen("UnusualActivity.txt", FILE_READ|FILE_TXT|FILE_ANSI);
   int i = 0;
   string lines[];
   while(!FileIsEnding(fhandle))
   {
      string line = FileReadString(fhandle);
      ArrayResize(lines, ArraySize(lines)+1, 100);
      lines[i] = line;
      i++;
   }
   FileClose(fhandle);
   int ncount = 0;
   for(int j=ArraySize(lines)-1; j>=0; j--)
   {
      string line = lines[j];
      string sep = ",";
      ushort usep = StringGetCharacter(sep, 0);
      string strArr[];
      StringSplit(line, usep, strArr);
      if (ArraySize(strArr) > 1)
      {
         string sym = strArr[1];
         StringTrimLeft(sym);
         StringTrimRight(sym);
         if (sym == Symbol())
         {
            datetime time = StringToTime(strArr[0]);
            double price = StringToDouble(strArr[6]);
            string type = strArr[2];
            StringTrimLeft(type);
            StringTrimRight(type);
            ObjectCreate(0, "unusual_" + j, OBJ_ARROW_LEFT_PRICE, 0, time, price);
            long clr = type == "Buy" ? clrGreen : type == "Sell" ? clrRed : clrBlack;
            ObjectSetInteger(0, "unusual_" + j, OBJPROP_COLOR, clr);
            ncount++;
         }
      }
      if (ncount > nSignal)
      {
         break;
      }
   }
}
//+------------------------------------------------------------------+
