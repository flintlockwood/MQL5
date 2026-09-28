//+------------------------------------------------------------------+
//|                                             SignalLinearRegresssion.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalLinearRegresssion: public CExpertSignal {
    protected:
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        ENUM_APPLIED_PRICE m_lr_source;
        int               m_lr_period;
        int               m_lr_offset;

    public:
        SignalLinearRegresssion(void);
        ~SignalLinearRegresssion(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;    }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value; }
        void              LrSource(ENUM_APPLIED_PRICE value)   { m_lr_source=value;     }
        void              LrPeriod(int value)                  { m_lr_period=value;     }
        void              LrOffset(int value)                  { m_lr_offset=value;     }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

    protected:
        //--- method of initialization of the indicator
        bool              InitLR(CIndicators *indicators);
        //--- methods of getting data
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalLinearRegresssion::SignalLinearRegresssion(void) : m_lr_source(PRICE_CLOSE),
                             m_lr_period(18),
                             m_lr_offset(5) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalLinearRegresssion::~SignalLinearRegresssion(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalLinearRegresssion::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_lr_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalLinearRegresssion::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    //--- create and initialize MA indicator
    if(!InitLR(indicators))
        return(false);
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Initialize Super Trend indicators.                                        |
//+------------------------------------------------------------------+
bool SignalLinearRegresssion::InitLR(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegresssion::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();

    bool cond = true;

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegresssion::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = true;
    
    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+
