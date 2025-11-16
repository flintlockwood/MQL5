//+------------------------------------------------------------------+
//|                                                  SignalCheck.mqh |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
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

#include "Common.mqh";
#include "CIsNewBar.mqh";
#include "CSEngulfing.mqh";
#include "CSRejection.mqh";
#include "CSBreakout.mqh";
#include "CSTweezer.mqh";
#include "CSStar.mqh";
#include "CSFtr.mqh";
#include "Alerter.mqh"

string keyLevelList[];

CIsNewBar inbM15;
CIsNewBar inbM30;
CIsNewBar inbH1;
CIsNewBar inbCurrent;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void keyLevelInit() {
   ArrayFree(keyLevelList);
   ArrayResize(keyLevelList, 0);
   string filename = _Symbol + "_Alert.txt";
   int fhandle = FileOpen(filename, FILE_READ|FILE_SHARE_READ|FILE_TXT|FILE_COMMON);
   if (fhandle != INVALID_HANDLE) {
      FileSeek(fhandle, 0, SEEK_SET);
      while(!FileIsEnding(fhandle)) {
         string line = FileReadString(fhandle);
         //printf(line);
         if (StringLen(line) > 0) {
            ArrayResize(keyLevelList, ArraySize(keyLevelList)+1, 10);
            keyLevelList[ArraySize(keyLevelList)-1] = line;
         }
      }
      FileClose(fhandle);
      //for(int i=0; i<ArraySize(keyLevelList); i++) {
      //   printf(keyLevelList[i]);
      //}
   } else {
      printf("error while opening file %s", filename);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkSignal() {
   bool reload = false;

   inbM15.SetPeriod(PERIOD_M15);
   inbM30.SetPeriod(PERIOD_M30);
   inbH1.SetPeriod(PERIOD_H1);
   inbCurrent.SetPeriod(PERIOD_CURRENT);

   if (inbM15.isNewBar() > 0) {
      //printf("checking ftr M15");
      
      checkAlert();
      
      int period = 4;
      MqlRates rates[];
      int n = CopyRates(_Symbol, PERIOD_M15, 1, period, rates);

      SignalBase *ftrSignal;
      ftrSignal = new FtrSignal(rates);
      ENUM_TIMEFRAMES tf_m15 = PERIOD_M15;
      if (ftrSignal.CheckSignal(tf_m15)) {
         ftrSignal.timeframe = PERIOD_M15;
         string content = ftrSignal.ToString();
         printf("%s ftr signal detected period M15. %s", TimeToString(TimeCurrent()), content);
         writeSignal(content);
      }
      delete ftrSignal;
      ftrSignal = NULL;
   }

   if (inbM30.isNewBar() > 0) {
      //printf("checking ftr M30");
      int period = 4;
      MqlRates rates[];
      int n = CopyRates(_Symbol, PERIOD_M30, 1, period, rates);

      SignalBase *ftrSignal;
      ftrSignal = new FtrSignal(rates);
      ENUM_TIMEFRAMES tf_m30 = PERIOD_M30;
      if (ftrSignal.CheckSignal(tf_m30)) {
         ftrSignal.timeframe = PERIOD_M30;
         string content = ftrSignal.ToString();
         printf("%s ftr signal detected period M30. %s", TimeToString(TimeCurrent()), content);
         writeSignal(content);
      }
      delete ftrSignal;
      ftrSignal = NULL;
   }

   for(int i=0; i<ArraySize(keyLevelList); i++) {
      string arr[];
      string line = keyLevelList[i];
      StringSplit(line, StringGetCharacter(" ", 0), arr);
      ENUM_TIMEFRAMES tf = StringToTimeframe(arr[2]);
      inbCurrent.SetPeriod(tf);
      if (inbCurrent.isNewBar()>0 || inbH1.isNewBar()>0) {
         string type = arr[3];
         StringToLower(type);
         double x1 = StringToDouble(arr[4]);
         double y1 = StringToDouble(arr[5]);
         double x2 = StringToDouble(arr[6]);
         double y2 = StringToDouble(arr[7]);
         Line l;
         l.x1 = x1;
         l.y1 = y1;
         l.x2 = x2;
         l.y2 = y2;
         l.type = type == "breakout" ? SOR_RESISTANCE : SOR_SUPPORT;

         if (inbCurrent.isNewBar()>0) {
            tf = tf;
         }
         else if (inbH1.isNewBar()>0) {
            tf = PERIOD_H1;
         }

         int period = 5;
         MqlRates rates[];
         int n = CopyRates(_Symbol, tf, 1, period, rates);
         MqlRates rates1[];
         ArrayCopy(rates1, rates, 0, period-1, 1);
         MqlRates rates2[];
         ArrayCopy(rates2, rates, 0, period-2, 2);
         MqlRates rates3[];
         ArrayCopy(rates3, rates, 0, period-3, 3);
         MqlRates rates4[];
         ArrayCopy(rates4, rates, 0, period-4, 4);

         SignalBase *eSignal;
         eSignal = new EngulfingSignal(rates2, l);
         eSignal.timeframe = tf;
         if (eSignal.CheckSignal(tf)) {
            string content = eSignal.ToString();
            printf("%s engulfing signal detected period H1. %s", TimeToString(TimeCurrent()), content);
            writeSignal(content);
         }
         delete eSignal;
         eSignal = NULL;

         SignalBase *rSignal;
         rSignal = new RejectionSignal(rates1[0], l);
         rSignal.timeframe = tf;
         if (rSignal.CheckSignal(tf)) {
            string content = rSignal.ToString();
            printf("%s rejection signal detected period H1. %s", TimeToString(TimeCurrent()), content);
            writeSignal(content);
         }
         delete rSignal;
         rSignal = NULL;

         SignalBase *bSignal;
         bSignal = new BreakoutSignal(rates1[0], l);
         bSignal.timeframe = tf;
         if (bSignal.CheckSignal(tf)) {
            string content = bSignal.ToString();
            printf("%s breakout signal detected period H1. %s", TimeToString(TimeCurrent()), content);
            writeSignal(content);
         }
         delete bSignal;
         bSignal = NULL;

         SignalBase *tSignal;
         tSignal = new TweezerSignal(rates2, l);
         tSignal.timeframe = tf;
         if (tSignal.CheckSignal(tf)) {
            string content = tSignal.ToString();
            printf("%s tweezer signal detected period H1. %s", TimeToString(TimeCurrent()), content);
            writeSignal(content);
         }
         delete tSignal;
         tSignal = NULL;

         SignalBase *sSignal;
         sSignal = new StarSignal(rates3, l);
         sSignal.timeframe = tf;
         if (sSignal.CheckSignal(tf)) {
            string content = sSignal.ToString();
            printf("%s star signal detected period H1. %s", TimeToString(TimeCurrent()), content);
            writeSignal(content);
         }
         delete sSignal;
         sSignal = NULL;

         //if (tf != tf_h1) {
         //   if (checkEnGulfingCross(tf, rates2, l, eSignal)) {
         //      string content = eSignal.ToString();
         //      writeSignal(content);
         //   }
         //   if (checkRejectionCross(tf, rates1[0], l, rSignal)) {
         //      string content = rSignal.ToString();
         //      writeSignal(content);
         //   }
         //}

         // if we change a key level in file, set reload to true
         // reload = true;
      }
   }
   if (reload) {
      keyLevelInit();
   }
}
//+------------------------------------------------------------------+
