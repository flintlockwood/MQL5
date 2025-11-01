//+------------------------------------------------------------------+
//|                                                   FileHelper.mqh |
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
void writeLineToFile(string filename, string line, bool common = true) {
   int fhandle = 0;
   int flags = FILE_READ|FILE_WRITE|FILE_CSV;
   if (common) {
      flags = FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON;
   }
   fhandle = FileOpen(filename, flags);
   FileSeek(fhandle, 0, SEEK_END);
   FileWrite(fhandle, line);
   FileFlush(fhandle);
   FileClose(fhandle);
}
