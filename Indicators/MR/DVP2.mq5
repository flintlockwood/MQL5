//+------------------------------------------------------------------+
//|                                                         DVP2.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Files\File.mqh>
#include <Files\FileTxt.mqh>
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   4
//--- plot POC
#property indicator_label1  "POC"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot VAH
#property indicator_label2  "VAH"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot VAL
#property indicator_label3  "VAL"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//-- filling color
#property indicator_label4  "Filling"
#property indicator_type4   DRAW_FILLING
#property indicator_color4  clrLime
//--- input parameters
input int      inpPeriod= 60;
input int      inpNRows = 50;
input double   inpPctValueArea=70;
input bool     inpShowPoc = true;
input bool     inpShowValueAre = false;
//--- indicator buffers
double         POCBuffer[];
double         VAHBuffer[];
double         VALBuffer[];
int            nAttemp=0;

MqlRates RatesM1[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,POCBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,VAHBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,VALBuffer,INDICATOR_DATA);

//   datetime first_bar_date=SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_FIRSTDATE);
//   datetime last_bar_date=SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_LASTBAR_DATE);
//   datetime last_time=TimeCurrent();
//   int max_bars=TerminalInfoInteger(TERMINAL_MAXBARS);
//   Print("first_bar_date: ", first_bar_date);
//   Print("last_bar_date: ", last_bar_date);
//   Print("last_time: ", last_time);
//   Print("max_bars: ", max_bars);
//   ArraySetAsSeries(RatesM1,true);
//   //int CopyRatesM1Check=CopyRates(_Symbol,PERIOD_M1,first_bar_date,last_bar_date,RatesM1);
//   int CopyRatesM1Check=CopyRates(_Symbol,PERIOD_M1,last_time,max_bars,RatesM1);
//   Print("CopyRatesM1Check ",CopyRatesM1Check);
//   if (CopyRatesM1Check != max_bars)
//      Comment("Loaded failed");
//
//   int res = CheckLoadHistory(_Symbol,PERIOD_M1,last_bar_date);
//   printResult(res);

//writeToFile(RatesM1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total<=inpPeriod)
      return(0);

// force M1 to load
   int m=ArraySize(RatesM1);
   if(m==0)
     {
      datetime currentTime=TimeCurrent();
      int max_bars=TerminalInfoInteger(TERMINAL_MAXBARS);
      int CopyRatesM1Check=CopyRates(_Symbol,PERIOD_M1,currentTime,max_bars,RatesM1);
      //Print("CopyRatesM1Check ",CopyRatesM1Check);
      if(CopyRatesM1Check!=max_bars)
        {
         Comment("Loaded failed");
         return 0;
        }
     }
   Comment("Loaded success");

   int mul=getMutiplier();
//int s = ArraySize(RatesM1);
//if (ArraySize(RatesM1) < inpPeriod * mul)
//   return 0;

//--- preliminary calculations
   int pos=prev_calculated;
   if(pos<=inpPeriod)
     {
      for(int i=0;i<inpPeriod;i++)
        {
         POCBuffer[i]=0.0;
         VAHBuffer[i]=0.0;
         VALBuffer[i]=0.0;
        }
      pos=inpPeriod-1;
     }

   for(int i=pos;i<rates_total && !IsStopped();i++)
     {
      //MqlRates rates[];
      //int copied=CopyRates(Symbol(),PERIOD_M1,0,30*inpPeriod,rates);

      //int res=CheckLoadHistory(_Symbol,PERIOD_M1,time[i]-(60));
      //printResult(res);

      //datetime datetimes[];
      //ArrayCopy(datetimes,time,0,i-inpPeriod+1,inpPeriod);
      //datetime firstdate= datetimes[0];
      //datetime lastdate = datetimes[ArraySize(datetimes)-1];
      MqlRates ratesM1[];
      datetime starttime=time[i]+60*mul-60;
      //int CopyRatesM1Check=CopyRates(_Symbol,PERIOD_M1,firstdate,lastdate,ratesM1);
      double prices[];
      long volumes[];
      int check1=CopyClose(_Symbol,PERIOD_M1,starttime,inpPeriod*mul,prices);
      int check2=CopyTickVolume(_Symbol,PERIOD_M1,starttime,inpPeriod*mul,volumes);
      if(check1!=inpPeriod*mul || check2!=inpPeriod*mul)
        {
         double pct=i/rates_total*100;
         //Print(pct+"% ("+i+" of "+rates_total+")");
         //Print("failed to load bar: " + i + ", total bar: " + rates_total);
         //Print(GetLastError());
         //ResetLastError();
         //return i+1;
         continue;
        }
      //return i;

      //ArrayCopy(prices,close,0,i-inpPeriod+1,inpPeriod);
      //ArrayCopy(volumes,tick_volume,0,i-inpPeriod+1,inpPeriod);
      double min = prices[ArrayMinimum(prices, 0, WHOLE_ARRAY)];
      double max = prices[ArrayMaximum(prices, 0, WHOLE_ARRAY)];
      double d=(max-min)/inpNRows;

      long totalVolume=0;
      long levelVolume[];
      ArrayResize(levelVolume,inpNRows+1);
      ArrayFill(levelVolume,0,inpNRows+1,0);
      for(int j=0;j<inpPeriod*mul;j++)
        {
         int lvl=getPriceLevel(prices[j],min,d,inpNRows);
         levelVolume[lvl]+=volumes[j];
         totalVolume+=volumes[j];
        }

      long pocVol=0.0;
      int pocLevel=0;
      for(int j=1; j<=inpNRows; j++)
        {
         long vol=levelVolume[j];
         if(vol>pocVol)
           {
            pocLevel=j;
            pocVol=vol;
           }
        }

      double valueArea=totalVolume*inpPctValueArea/100;
      double val = 0.0;
      double vah = 0.0;
      long tempVol=levelVolume[pocLevel];
      for(int j=1; j<=inpNRows; j++)
        {
         long v1 = pocLevel-j > 0 ? levelVolume[pocLevel-j] : 0;
         long v2 = pocLevel+j <= inpNRows ? levelVolume[pocLevel+j] : 0;
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

      if (inpShowPoc) {
         POCBuffer[i] = NormalizeDouble(min + (pocLevel-0.5)*d, _Digits);
      }
      if (inpShowValueAre) {
         VALBuffer[i] = NormalizeDouble(val, _Digits);
         VAHBuffer[i] = NormalizeDouble(vah, _Digits);
      }

      //double pct=(double)i/(double)rates_total*100;
      //Print(pct+"% ("+i+" of "+rates_total+")");
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

int getPriceLevel(double price,double min,double d,int nrow)
  {
   return MathMin(MathFloor((price-min)/d)+1, nrow);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeToFile(MqlRates &rates[])
  {
   CFileTxt    File;
   string      sDateTime;
   string      ExtFileName;
   TimeToString(TimeLocal(),sDateTime);

   Comment("Writing to file... wait... ");
// prepare file name, for example, EURUSD1
   ExtFileName=Symbol();
   StringConcatenate(ExtFileName,Symbol(),"_",sDateTime,".csv");

   string format="%G,%G,%G,%G,%G,%d";
   int iCod=ArraySize(rates);
   if(iCod>1)
     {
      // open file
      File.Open(ExtFileName,FILE_WRITE,9);
      for(int i=iCod-1; i>0; i--)
        {
         // prepare a string:
         // 2009.01.05,12:49,1.36770,1.36780,1.36760,1.36760,8
         string sOut=StringFormat("%s",TimeToString(rates[i].time,TIME_DATE));
         sOut=sOut+","+TimeToString(rates[i].time,TIME_MINUTES);
         sOut=sOut+","+StringFormat(format,
                                    rates[i].open,
                                    rates[i].high,
                                    rates[i].low,
                                    rates[i].close,
                                    rates[i].tick_volume,
                                    rates[i].real_volume);
         sOut=sOut+"\n";
         File.WriteString(sOut);
        }
      File.Close();
     }
   Comment("OK. ready... ");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMutiplier()
  {
   ENUM_TIMEFRAMES p=Period();
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
//|                                                                  |
//+------------------------------------------------------------------+
int CheckLoadHistory(string symbol,ENUM_TIMEFRAMES period,datetime start_date)
  {
   datetime first_date=0;
   datetime times[100];
//--- check symbol & period 
   if(symbol==NULL || symbol=="") symbol=Symbol();
   if(period==PERIOD_CURRENT)     period=Period();
//--- check if symbol is selected in the Market Watch 
   if(!SymbolInfoInteger(symbol,SYMBOL_SELECT))
     {
      if(GetLastError()==ERR_MARKET_UNKNOWN_SYMBOL) return(-1);
      SymbolSelect(symbol,true);
     }
//--- check if data is present 
   SeriesInfoInteger(symbol,period,SERIES_FIRSTDATE,first_date);
   if(first_date>0 && first_date<=start_date) return(1);
//--- don't ask for load of its own data if it is an indicator 
   if(MQL5InfoInteger(MQL5_PROGRAM_TYPE)==PROGRAM_INDICATOR && Period()==period && Symbol()==symbol)
      return(-4);
//--- second attempt 
   if(SeriesInfoInteger(symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,first_date))
     {
      //--- there is loaded data to build timeseries 
      if(first_date>0)
        {
         //--- force timeseries build 
         CopyTime(symbol,period,first_date+PeriodSeconds(period),1,times);
         //--- check date 
         if(SeriesInfoInteger(symbol,period,SERIES_FIRSTDATE,first_date))
            if(first_date>0 && first_date<=start_date) return(2);
        }
     }
//--- max bars in chart from terminal options 
   int max_bars=TerminalInfoInteger(TERMINAL_MAXBARS);
//--- load symbol history info 
   datetime first_server_date=0;
   while(!SeriesInfoInteger(symbol,PERIOD_M1,SERIES_SERVER_FIRSTDATE,first_server_date) && !IsStopped())
      Sleep(5);
//--- fix start date for loading 
   if(first_server_date>start_date) start_date=first_server_date;
   if(first_date>0 && first_date<first_server_date)
      Print("Warning: first server date ",first_server_date," for ",symbol,
            " does not match to first series date ",first_date);
//--- load data step by step 
   int fail_cnt=0;
   while(!IsStopped())
     {
      //--- wait for timeseries build 
      while(!SeriesInfoInteger(symbol,period,SERIES_SYNCHRONIZED) && !IsStopped())
         Sleep(5);
      //--- ask for built bars 
      int bars=Bars(symbol,period);
      if(bars>0)
        {
         if(bars>=max_bars) return(-2);
         //--- ask for first date 
         if(SeriesInfoInteger(symbol,period,SERIES_FIRSTDATE,first_date))
            if(first_date>0 && first_date<=start_date) return(0);
        }
      //--- copying of next part forces data loading 
      int copied=CopyTime(symbol,period,bars,100,times);
      if(copied>0)
        {
         //--- check for data 
         if(times[0]<=start_date)  return(0);
         if(bars+copied>=max_bars) return(-2);
         fail_cnt=0;
        }
      else
        {
         //--- no more than 100 failed attempts 
         fail_cnt++;
         if(fail_cnt>=100) return(-5);
         Sleep(10);
        }
     }
//--- stopped 
   return(-3);
  }
//+------------------------------------------------------------------+

void printResult(int res,bool toChart=true)
  {
   string message="";
   switch(res)
     {
      case -1 : message = "Unknown symbol ";                            break;
      case -2 : message = "Requested bars more than max bars in chart"; break;
      case -3 : message = "Program was stopped";                        break;
      case -4 : message = "Indicator shouldn't load its own data";      break;
      case -5 : message = "Load failed";                                break;
      case  0 : message = "Loaded OK";                                  break;
      case  1 : message = "Loaded previously";                          break;
      case  2 : message = "Loaded previously and built";                break;
      default : message = "Unknown result";
     }
   if(toChart)
      Comment(message);
   else
      Print(message);
  }
//+------------------------------------------------------------------+
