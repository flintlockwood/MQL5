//+------------------------------------------------------------------+
//|                                             SignalTema.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "IndicatorTema.mqh"

class SignalTema: public CExpertSignal {
    protected:
        CiTema            m_tema_indicator;

        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        ENUM_APPLIED_PRICE m_tema_source;
        int               m_tema_period;

    public:
        SignalTema(void);
        ~SignalTema(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;    }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value; }
        void              TemaSource(ENUM_APPLIED_PRICE value) { m_tema_source=value;   }
        void              TemaPeriod(int value)                { m_tema_period=value;   }
        
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
SignalTema::SignalTema(void) : m_tema_source(PRICE_CLOSE),
                             m_tema_period(18) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalTema::~SignalTema(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalTema::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_tema_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalTema::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    
    //--- create and initialize MA indicator
    if(!m_tema_indicator.Create(m_sig_symbol, (ENUM_TIMEFRAMES)m_sig_timeframe,
                        m_tema_period, m_tema_source)) {
        printf(__FUNCTION__+": error initializing object");
        return(false);
    }
    //--- add object to collection
    if(!indicators.Add(GetPointer(m_tema_indicator))) {
        printf(__FUNCTION__+": error adding object");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalTema::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();

    bool cond = Close(idx) > m_tema_indicator.Tema(idx);

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalTema::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) < m_tema_indicator.Tema(idx);
    
    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+
