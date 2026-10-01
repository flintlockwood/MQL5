//+------------------------------------------------------------------+
//|                                             SignalZema.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"
#include "IndicatorZema.mqh"

class SignalZema: public CExpertSignal {
    protected:
        CiZema            m_zema_indicator;

        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        int               m_zema_period_long;
        int               m_zema_period_short;
        bool              m_enable_zema_momentum;
        string            m_zema_momentum_cond_long;
        string            m_zema_momentum_cond_short;

    public:
        SignalZema(void);
        ~SignalZema(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;             }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value;          }
        void              ZemaPeriodLong(int value)            { m_zema_period_long=value;       }
        void              ZemaPeriodShort(int value)           { m_zema_period_long=value;       }
        void              EnableZemaMomentum(bool value)       { m_enable_zema_momentum=value;   }
        void              ZemaMomentumCondLong(string value)   { m_zema_momentum_cond_long=value;}
        void              ZemaMomentumCondShort(string value)  { m_zema_momentum_cond_short=value;}
        
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
SignalZema::SignalZema(void) : m_zema_period_long(73) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalZema::~SignalZema(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalZema::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_zema_period_long<=0) {
        printf(__FUNCTION__+": period ATR must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalZema::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    //--- create and initialize MA indicator
    if(!m_zema_indicator.Create(m_sig_symbol, (ENUM_TIMEFRAMES)m_sig_timeframe,
                        m_zema_period_long, m_zema_period_short)) {
        printf(__FUNCTION__+": error initializing object");
        return(false);
    }
    //--- add object to collection
    if(!indicators.Add(GetPointer(m_zema_indicator))) {
        printf(__FUNCTION__+": error adding object");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalZema::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) > m_zema_indicator.ZemaLong(idx);

    double momentum[];
    m_zema_indicator.GetData(0, 20, 2, momentum);
    bool cond2 = !m_enable_zema_momentum || CheckSeriesCondition(m_zema_momentum_cond_long, momentum);

    //--- return the result
    return(cond && cond2 ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalZema::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    bool cond = Close(idx) < m_zema_indicator.ZemaShort(idx);

    double momentum[];
    m_zema_indicator.GetData(0, 20, 3, momentum);
    bool cond2 = !m_enable_zema_momentum || CheckSeriesCondition(m_zema_momentum_cond_short, momentum);

    //--- return the result
    return(cond && cond2 ? 100 : 0);
}
//+------------------------------------------------------------------+
