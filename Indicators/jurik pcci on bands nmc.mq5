#property indicator_separate_window
#property indicator_buffers    6
#property indicator_color1     LimeGreen
#property indicator_color2     Red
#property indicator_color3     Red
#property indicator_color4     SlateGray
#property indicator_color5     SlateGray
#property indicator_color6     SlateGray
#property indicator_width1     2
#property indicator_width2     2
#property indicator_width3     2
#property indicator_style4     STYLE_DASH
#property indicator_style5     STYLE_DASHDOTDOT
#property indicator_style6     STYLE_DASH
#property indicator_level1     0
#property indicator_levelcolor DarkOrchid

//
//
//
//
//

string ENUM_TIME                = "Current time frame";
int    PcciSmoothLength         = 10;
double PcciSmoothPhase          = 0;
bool   PcciSmoothDouble         = false;
int    VolatilityBandPeriod     = 34;
int    VolatilityBandMAMode     = MODE_LWMA;
double VolatilityBandMultiplier = 1.6185;
bool   Interpolate              = true;
bool   MultiColor               = true;

bool   alertsOn                 = true;
bool   alertsOnCurrent          = false;
bool   alertsMessage            = true;
bool   alertsSound              = false;
bool   alertsEmail              = false;

string  __                      = "arrows settings";
bool   ShowArrows               = true;
string arrowsIdentifier         = "pcci arrows";
color  arrowsUpColor            = Lime;
color  arrowsDnColor            = Orange;

//
//
//
//
//

double pcci[];
double pcciUa[];
double pcciUb[];
double bandUp[];
double bandMiddle[];
double bandDown[];
double trend[];

//
//
//
//
//

string indicatorFileName;
bool   calculateValue;
bool   returnBars;
int    timeFrame;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

int init()
  {
  IndicatorBuffers(7);
    SetIndexBuffer(0,pcci);
    SetIndexBuffer(1,pcciUa);
    SetIndexBuffer(2,pcciUb);
    SetIndexBuffer(3,bandUp);
    SetIndexBuffer(4,bandMiddle);
    SetIndexBuffer(5,bandDown);
    SetIndexBuffer(6,trend);
    
    //
    //
    //
    //
    //
   
      indicatorFileName = WindowExpertName();
      calculateValue    = (TimeFrame=="calculateValue"); if (calculateValue) return(0);
      returnBars        = (TimeFrame=="returnBars");     if (returnBars)     return(0);
      timeFrame         = stringToTimeFrame(TimeFrame);
   
   //
   //
   //
   //
   //
   
   IndicatorShortName(timeFrameToString(timeFrame)+" jurik Pcci bands ");
   
 return(0);
}
    
//
//
//
//
//

int deinit(){  if (!calculateValue && ShowArrows) deleteArrows();  return(0); }

//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
   int i,n,k,limit;
   
   if(counted_bars < 0) return(-1);
   if(counted_bars > 0) counted_bars--;
           limit = MathMin(Bars-counted_bars,Bars-1); 
           if (returnBars)  { pcci[0] = limit+1; return(0); }
   
   //
   //
   //
   //
   //
   
   if (calculateValue || timeFrame == Period())
   {
 
   
   if (MultiColor && !calculateValue && trend[limit]==-1) CleanPoint(limit,pcciUa,pcciUb);
   
   //
   //
   //
   //
   //        
      
   for(i=limit; i>=0; i--)
   {  
      double response =
       
              0.1177628838235*Close[i+0]
             +0.1170077388431*Close[i+1]
             +0.1147601209029*Close[i+2]
             +0.1110729054065*Close[i+3]
             +0.1060324421434*Close[i+4]
             +0.0997560988008*Close[i+5]
             +0.0923890376402*Close[i+6]
             +0.0841000389219*Close[i+7]
             +0.0750766919597*Close[i+8]
             +0.0655202662708*Close[i+9]
             +0.0556401583046*Close[i+10]
             +0.0456482572592*Close[i+11]
             +0.0357530528012*Close[i+12]
             +0.02615415804227*Close[i+13]
             +0.01703731282680*Close[i+14]
             +0.00856960311288*Close[i+15]
             +0.000895555708556*Close[i+16]
             -0.00586627422066*Close[i+17]
             -0.01162552971203*Close[i+18]
             -0.01632152444323*Close[i+19]
             -0.01992414580732*Close[i+20]
             -0.02243335117589*Close[i+21]
             -0.02387813894599*Close[i+22]
             -0.02431430200598*Close[i+23]
             -0.02382176331725*Close[i+24]
             -0.02250140527159*Close[i+25]
             -0.02047075493180*Close[i+26]
             -0.01786000052706*Close[i+27]
             -0.01480733499641*Close[i+28]
             -0.01145463232852*Close[i+29]
             -0.00794304696010*Close[i+30]
             -0.00440829083275*Close[i+31]
             -0.000977238472653*Close[i+32]
             +0.002235823933755*Close[i+33]
             +0.00513191787383*Close[i+34]
             +0.00762972457736*Close[i+35]
             +0.00966747623918*Close[i+36]
             +0.01120310303187*Close[i+37]
             +0.01221499285956*Close[i+38]
             +0.01270127547603*Close[i+39]
             +0.01267881242200*Close[i+40]
             +0.01218165493397*Close[i+41]
             +0.01125820035359*Close[i+42]
             +0.00996954486984*Close[i+43]
             +0.00838605323109*Close[i+44]
             +0.00658436935337*Close[i+45]
             +0.00464439195323*Close[i+46]
             +0.002645759417416*Close[i+47]
             +0.000666068159555*Close[i+48]
             -0.001222776729259*Close[i+49]
             -0.002956488520058*Close[i+50]
             -0.00448011021214*Close[i+51]
             -0.00574988855361*Close[i+52]
             -0.00673332989225*Close[i+53]
             -0.00741117882839*Close[i+54]
             -0.00777644547070*Close[i+55]
             -0.00783388153265*Close[i+56]
             -0.00759966748743*Close[i+57]
             -0.00709931269272*Close[i+58]
             -0.00636769053766*Close[i+59]
             -0.00544559940274*Close[i+60]
             -0.00437852874428*Close[i+61]
             -0.00321542503890*Close[i+62]
             -0.002005580069262*Close[i+63]
             -0.000798178859997*Close[i+64]
             +0.000361723322003*Close[i+65]
             +0.001433101593600*Close[i+66]
             +0.002380073229874*Close[i+67]
             +0.00317453700490*Close[i+68]
             +0.00379492177651*Close[i+69]
             +0.00422884523807*Close[i+70]
             +0.00447038314289*Close[i+71]
             +0.00452100306476*Close[i+72]
             +0.00439082398691*Close[i+73]
             +0.00409492037175*Close[i+74]
             +0.00365528338580*Close[i+75]
             +0.003096238149856*Close[i+76]
             +0.002446112685573*Close[i+77]
             +0.001736376831290*Close[i+78]
             +0.000996103380422*Close[i+79]
             +0.0002557237615143*Close[i+80]
             -0.000458282529397*Close[i+81]
             -0.001119581482823*Close[i+82]
             -0.001704893115208*Close[i+83]
             -0.002199032152313*Close[i+84]
             -0.002586916898054*Close[i+85]
             -0.002861741841535*Close[i+86]
             -0.003018651749353*Close[i+87]
             -0.003060101508137*Close[i+88]
             -0.002997112675297*Close[i+89]
             -0.002834938217095*Close[i+90]
             -0.002589089321820*Close[i+91]
             -0.002272072078644*Close[i+92]
             -0.001902835889698*Close[i+93]
             -0.001502872027811*Close[i+94]
             -0.001077466851623*Close[i+95]
             -0.000655481642188*Close[i+96]
             -0.0002511660753314*Close[i+97]
             +0.0001137882502083*Close[i+98]
             +0.000426098842482*Close[i+99]
             +0.000714775119642*Close[i+100]
             +0.000916639580735*Close[i+101]
             +0.001063116482197*Close[i+102]
             +0.001143113996535*Close[i+103]
             +0.001159315803654*Close[i+104]
             +0.00922554212244*Close[i+105];
             
             //
             //
             //
             //
             //
             
             pcci[i] = iDSmooth(Close[i]-response,PcciSmoothLength,PcciSmoothPhase,PcciSmoothDouble,i,0); 

             }
             
             //
             //
             //
             //
             //
             
             for(i=limit; i>=0; i--)
             {                   
              double deviation = iStdDevOnArray(pcci,0,VolatilityBandPeriod,0,VolatilityBandMAMode,i);
              double   average = iMAOnArray(pcci,0,VolatilityBandPeriod,0,VolatilityBandMAMode,i);
                     bandUp[i] = average+VolatilityBandMultiplier*deviation;
                   bandDown[i] = average-VolatilityBandMultiplier*deviation;
                 bandMiddle[i] = average;
                     pcciUa[i] = EMPTY_VALUE;
                     pcciUb[i] = EMPTY_VALUE;
                      trend[i] = trend[i+1];
 
             //
             //
             //
             //
             //
           
             if (pcci[i] > pcci[i+1]) trend[i]=  1;
             if (pcci[i] < pcci[i+1]) trend[i]= -1;
             
             if (!calculateValue) manageArrow(i);
           
             //
             //
             //
             //
             //
           
             if (MultiColor && !calculateValue && trend[i]==-1) PlotPoint(i,pcciUa,pcciUb,pcci);
 
             }
          
             manageAlerts();           
             return (0);
             }        

   
             limit = MathMax(limit,MathMin(Bars,iCustom(NULL,timeFrame,indicatorFileName,"returnBars",0,0)*timeFrame/Period()));
             
             if (MultiColor && trend[limit]==-1) CleanPoint(limit,pcciUa,pcciUb);
             for (i=limit;i>=0; i--)
             {
               int y = iBarShift(NULL,timeFrame,Time[i]);
               
                pcci[i]       = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",PcciSmoothLength,PcciSmoothPhase,PcciSmoothDouble,VolatilityBandPeriod,VolatilityBandMAMode,VolatilityBandMultiplier,0,y);
                pcciUa[i]     = EMPTY_VALUE;
                pcciUb[i]     = EMPTY_VALUE;
                bandUp[i]     = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",PcciSmoothLength,PcciSmoothPhase,PcciSmoothDouble,VolatilityBandPeriod,VolatilityBandMAMode,VolatilityBandMultiplier,3,y);
                bandMiddle[i] = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",PcciSmoothLength,PcciSmoothPhase,PcciSmoothDouble,VolatilityBandPeriod,VolatilityBandMAMode,VolatilityBandMultiplier,4,y);
                bandDown[i]   = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",PcciSmoothLength,PcciSmoothPhase,PcciSmoothDouble,VolatilityBandPeriod,VolatilityBandMAMode,VolatilityBandMultiplier,5,y);
                trend[i]      = iCustom(NULL,timeFrame,indicatorFileName,"calculateValue",PcciSmoothLength,PcciSmoothPhase,PcciSmoothDouble,VolatilityBandPeriod,VolatilityBandMAMode,VolatilityBandMultiplier,6,y);
                
                manageArrow(i);
                
                //
                //
                //
                //
                //
        
                if (!Interpolate || y==iBarShift(NULL,timeFrame,Time[i-1])) continue;
      
                //
                //
                //
                //
                //

                datetime time = iTime(NULL,timeFrame,y);
                   for(n = 1; i+n < Bars && Time[i+n] >= time; n++) continue;	
                   for(k = 1; k < n; k++)
                   {
                      pcci[i+k]       = pcci[i]        + (pcci[i+n]      - pcci[i])       * k/n;
                      bandUp[i+k]     = bandUp[i]      + (bandUp[i+n]    - bandUp[i])     * k/n;
                      bandMiddle[i+k] =  bandMiddle[i] + (bandMiddle[i+n]- bandMiddle[i]) * k/n;
                      bandDown[i+k]   = bandDown[i]    + (bandDown[i+n]  - bandDown[i])   * k/n;
   
                   }  	            
                   }
                   
                   //
                   //
                   //
                   //
                   //
                   
                   if (MultiColor) for (i=limit;i>=0;i--) if (trend[i]==-1) PlotPoint(i,pcciUa,pcciUb,pcci);
                manageAlerts(); 
    
   return(0);
}

//+------------------------------------------------------------------+
//
//
//
//

double wrk[][20];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iDSmooth(double price, double length, double phase, bool isDouble, int i, int s=0)
{
   if (isDouble)
         return (iSmooth(iSmooth(price,MathSqrt(length),phase,i,s),MathSqrt(length),phase,i,s+10));
   else  return (iSmooth(price,length,phase,i,s));
}

//
//
//
//
//

double iSmooth(double price, double length, double phase, int i, int s=0)
{
   if (length <=1) return(price);
   if (ArrayRange(wrk,0) != Bars) ArrayResize(wrk,Bars);
   
   int r = Bars-i-1; 
      if (r==0) { for(int k=0; k<7; k++) wrk[r][k+s]=price; for(; k<10; k++) wrk[r][k+s]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax+s];
      double del2   = price - wrk[r-1][bsmin+s];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = MathMin(r,10);
	
         wrk[r][volty+s] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty+s] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty+s] = MathAbs(del2); 
         wrk[r][vsum+s] =	wrk[r-1][vsum+s] + (wrk[r][volty+s]-wrk[r-forBar][volty+s])*div;
         
         //
         //
         //
         //
         //
   
         wrk[r][avolty+s] = wrk[r-1][avolty+s]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum+s]-wrk[r-1][avolty+s]);
            if (wrk[r][avolty+s] > 0)
               double dVolty = wrk[r][volty+s]/wrk[r][avolty+s]; else dVolty = 0;   
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax+s] = price; else wrk[r][bsmax+s] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin+s] = price; else wrk[r][bsmin+s] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0+s] = price + alpha*(wrk[r-1][0+s]-price);
         wrk[r][1+s] = (price - wrk[r][0+s])*(1-beta) + beta*wrk[r-1][1+s];
         wrk[r][2+s] = (wrk[r][0+s] + R*wrk[r][1+s]);
         wrk[r][3+s] = (wrk[r][2+s] - wrk[r-1][4+s])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3+s];
         wrk[r][4+s] = (wrk[r-1][4+s] + wrk[r][3+s]); 

   //
   //
   //
   //
   //

   return(wrk[r][4+s]);
}

//
//
//
//
//

void manageAlerts()
{
   if (!calculateValue && alertsOn)
   {
      if (alertsOnCurrent)
           int whichBar = 0;
      else     whichBar = 1; whichBar = iBarShift(NULL,0,iTime(NULL,timeFrame,whichBar));
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] ==  1) doAlert(whichBar,"up");
         if (trend[whichBar] == -1) doAlert(whichBar,"down");
      }
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != Time[forBar]) {
       previousAlert  = doWhat;
       previousTime   = Time[forBar];

       //
       //
       //
       //
       //

       message =  StringConcatenate(Symbol()," ",timeFrameToString(timeFrame)," at ",TimeToStr(TimeLocal(),TIME_SECONDS)," pcci changed direction to ",doWhat);
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(StringConcatenate(Symbol()," pcci "),message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

//+-------------------------------------------------------------------
//|                                                                  
//+-------------------------------------------------------------------
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

//
//
//
//
//

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
         if (first[i+2] == EMPTY_VALUE) {
                first[i]   = from[i];
                first[i+1] = from[i+1];
                second[i]  = EMPTY_VALUE;
            }
         else {
                second[i]   =  from[i];
                second[i+1] =  from[i+1];
                first[i]    = EMPTY_VALUE;
            }
      }
   else
      {
         first[i]  = from[i];
         second[i] = EMPTY_VALUE;
      }
}
  
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   StringToUpper(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}


//
//
//
//
//

void manageArrow(int i)
{
   if (!calculateValue && ShowArrows)
   {
      deleteArrow(Time[i]);
      if (trend[i]!=trend[i+1])
      {
         if (trend[i] == 1) drawArrow(i,arrowsUpColor,221,false);
         if (trend[i] ==-1) drawArrow(i,arrowsDnColor,222,true);
      }
   }
}               

//
//
//
//
//

void drawArrow(int i,color theColor,int theCode,bool up)
{
   string name = arrowsIdentifier+":"+Time[i];
   double gap  = iATR(NULL,0,20,i);   
   
      //
      //
      //
      //
      //
      
      ObjectCreate(name,OBJ_ARROW,0,Time[i],0);
         ObjectSet(name,OBJPROP_ARROWCODE,theCode);
         ObjectSet(name,OBJPROP_COLOR,theColor);
  
         if (up)
               ObjectSet(name,OBJPROP_PRICE1,High[i]+gap);
         else  ObjectSet(name,OBJPROP_PRICE1,Low[i] -gap);
}

//
//
//
//
//

void deleteArrows()
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal()-1; i>=0; i--)
   {
      string objectName = ObjectName(i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(objectName);
   }
}

void deleteArrow(datetime time)
{
   string lookFor = arrowsIdentifier+":"+time; ObjectDelete(lookFor);
}

//
//
//
//
//

