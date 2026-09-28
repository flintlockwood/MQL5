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
#include "IndicatorLinearRegression.mqh"

class SignalLinearRegresssion: public CExpertSignal {
    protected:
        CiLinearRegression m_lr_indicator;

        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        ENUM_APPLIED_PRICE m_lr_source;
        int               m_lr_period;
        int               m_lr_offset;
        double            m_lr_pip_long;
        double            m_lr_pip_short;

    public:
        SignalLinearRegresssion(void);
        ~SignalLinearRegresssion(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;    }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value; }
        void              LrSource(ENUM_APPLIED_PRICE value)   { m_lr_source=value;     }
        void              LrPeriod(int value)                  { m_lr_period=value;     }
        void              LrOffset(int value)                  { m_lr_offset=value;     }
        void              LrPipLong(double value)              { m_lr_pip_long=value;   }
        void              LrPipShort(double value)             { m_lr_pip_short=value;  }
        
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
    if(!m_lr_indicator.Create(m_sig_symbol, (ENUM_TIMEFRAMES)m_sig_timeframe,
                        m_lr_period, m_lr_offset, m_lr_source)) {
        printf(__FUNCTION__+": error initializing object");
        return(false);
    }
    //--- add object to collection
    if(!indicators.Add(GetPointer(m_lr_indicator))) {
        printf(__FUNCTION__+": error adding object");
        return(false);
    }
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

    bool cond = Open(idx) < m_lr_indicator.LinReg(idx) + m_lr_pip_long * GetPoint(m_sig_symbol) * 10;

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalLinearRegresssion::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) > m_lr_indicator.LinReg(idx) - m_lr_pip_short * GetPoint(m_sig_symbol) * 10;
    
    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+
