//+------------------------------------------------------------------+
//|                                             SignalMain.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalMain: public CExpertSignal {
    protected:
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        int               m_atr_period;
        ENUM_MA_METHOD    m_smoothing_method;
        bool              m_enable_atr_direction;
        bool              m_enable_atr_increase_by;
        double            m_atr_down_by_long;
        double            m_atr_up_by_long;
        double            m_atr_down_by_short;
        double            m_atr_up_by_short;

    public:
        SignalMain(void);
        ~SignalMain(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;             }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value;          }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalMain::SignalMain(void) : m_atr_period(3),
                             m_smoothing_method(MODE_SMMA) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalMain::~SignalMain(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalMain::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_atr_period<=0) {
        printf(__FUNCTION__+": period ATR must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalMain::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    //--- create and initialize MA indicator
    if(!InitATR(indicators))
        return(false);
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalMain::LongCondition(void) {
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalMain::ShortCondition(void) {

}

//+------------------------------------------------------------------+
//| Detecting the "weighted" direction                               |
//+------------------------------------------------------------------+
double SignalMain::Direction(void) {
    long   mask;
    double direction;
    double result=m_weight*(LongCondition()-ShortCondition());
    int    number=(result==0.0)? 0 : 1;      // number of "voted"
    //---
    int    total=m_filters.Total();
    //--- loop by filters
    for(int i=0;i<total;i++) {
        //--- mask for bit maps
        mask=((long)1)<<i;
        //--- check of the flag of ignoring the signal of filter
        if((m_ignore&mask)!=0)
            continue;
        CExpertSignal *filter=m_filters.At(i);
        //--- check pointer
        if(filter==NULL)
            continue;
        direction=filter.Direction();
        //--- the "prohibition" signal
        if(direction==EMPTY_VALUE)
            return(EMPTY_VALUE);
        //--- check of flag of inverting the signal of filter
        if((m_invert&mask)!=0)
            result-=direction;
        else
            result+=direction;
        number++;
        }
    //--- normalization
    if(number!=0)
        result/=number;
    //--- return the result
    return(result);
}