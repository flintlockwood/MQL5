//+------------------------------------------------------------------+
//|                                                          dvp.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
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
struct DvpRates
  {
   datetime          Time;
   double            Poc;
   double            Vah;
   double            Val;
   double            Max;
   double            Min;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CalculateDvp(int period,int nRow,int pctVa,MqlRates &rates[],DvpRates &dvpRates[],string symbol="",bool returnAll=true)
  {
   int arrSize=ArraySize(rates);

   ArrayResize(dvpRates,arrSize);
   double prices[];
   ArrayResize(prices,arrSize);
   for(int j=0; j<arrSize; j++)
     {
      prices[j]=rates[j].close;
     }
   long volumes[];
   ArrayResize(volumes,arrSize);
   for(int j=0; j<arrSize; j++)
     {
      volumes[j]=rates[j].tick_volume;
     }

   for(int i=0;i<arrSize && !IsStopped();i++)
     {
      if(i<period-1)
        {
         dvpRates[i].Poc = 0;
         dvpRates[i].Vah = 0;
         dvpRates[i].Val = 0;
         dvpRates[i].Max = 0;
         dvpRates[i].Min = 0;
         continue;
        }

      double min = prices[ArrayMinimum(prices, i-period+1, period)];
      double max = prices[ArrayMaximum(prices, i-period+1, period)];
      double d=(max-min)/nRow;

      long totalVolume=0;
      long levelVolume[];
      ArrayResize(levelVolume,nRow+1);
      ArrayFill(levelVolume,0,nRow+1,0);
      for(int j=i-period+1;j<i;j++)
        {
         int lvl=getPriceLevel(prices[j],min,d,nRow);
         levelVolume[lvl]+=volumes[j];
         totalVolume+=volumes[j];
        }

      long pocVol=0.0;
      int pocLevel=0;
      for(int j=1; j<=nRow; j++)
        {
         long vol=levelVolume[j];
         if(vol>pocVol)
           {
            pocLevel=j;
            pocVol=vol;
           }
        }

      double valueArea=totalVolume*pctVa/100.0;
      double val = 0.0;
      double vah = 0.0;
      long tempVol=levelVolume[pocLevel];
      for(int j=1; j<=nRow; j++)
        {
         long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
         long v2 = pocLevel+j <= nRow ? levelVolume[pocLevel+j] : 0;
         tempVol = tempVol + v1 + v2;
         if(tempVol>=valueArea)
           {
            val = v1==0 ? min : min+(pocLevel-j-1)*d;
            vah = v2==0 ? max : min+(pocLevel+j)*d;
            break;
           }
        }
      if(val==0 && vah==0)
        {
         val = min;
         vah = max;
        }

      symbol=symbol=="" ? _Symbol : symbol;
      long digit=SymbolInfoInteger(symbol,SYMBOL_DIGITS);
      dvpRates[i].Time = rates[i].time;
      dvpRates[i].Poc = NormalizeDouble(min + (pocLevel-0.5)*d, digit);
      dvpRates[i].Vah = NormalizeDouble(vah, digit);
      dvpRates[i].Val = NormalizeDouble(val, digit);
      dvpRates[i].Max = NormalizeDouble(max, digit);
      dvpRates[i].Min = NormalizeDouble(min, digit);
     }
   if(!returnAll)
     {
      DvpRates temp[];
      int ret = ArrayCopy(temp, dvpRates, 0, period-1, arrSize-period+1);
      ArrayResize(dvpRates, arrSize-period+1);
      ArrayCopy(dvpRates, temp, 0, 0, WHOLE_ARRAY);
      return ret;
     }
   return ArraySize(dvpRates);
  }
//+------------------------------------------------------------------+
int getPriceLevel(double price,double min,double d,int nrow)
  {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
  }
//+------------------------------------------------------------------+

int getMutiplier(ENUM_TIMEFRAMES p)
  {
   switch(p)
     {
      case PERIOD_M1:
         return 1;
         break;
      case PERIOD_M2:
         return 2;
         break;
      case PERIOD_M3:
         return 3;
         break;
      case PERIOD_M4:
         return 4;
         break;
      case PERIOD_M5:
         return 5;
         break;
      case PERIOD_M6:
         return 6;
         break;
      case PERIOD_M10:
         return 10;
         break;
      case PERIOD_M12:
         return 12;
         break;
      case PERIOD_M15:
         return 15;
         break;
      case PERIOD_M20:
         return 20;
         break;
      case PERIOD_M30:
         return 30;
         break;
      case PERIOD_H1:
         return 60;
         break;
      case PERIOD_H2:
         return 120;
         break;
      case PERIOD_H4:
         return 240;
         break;
      case PERIOD_H6:
         return 360;
         break;
      case PERIOD_H8:
         return 480;
         break;
      case PERIOD_H12:
         return 720;
         break;
      case PERIOD_D1:
         return 1440;
         break;
      case PERIOD_W1:
         return 10080;
         break;
      case PERIOD_MN1:
         return 302400;
         break;
      default:
         return 1440;
         break;
     }
  }
//+------------------------------------------------------------------+
