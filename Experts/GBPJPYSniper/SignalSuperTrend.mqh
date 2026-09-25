//+------------------------------------------------------------------+
//|                                             SignalSuperTrend.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include "Helper.mqh"
#include "IndicatorSuperTrend.mqh"

class SignalSuperTrend: public CExpertSignal {
    protected:
        CiSuperTrend      m_st_indicator;
        
        //--- adjusted signal & indicator parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        int               m_st_period;
        double            m_st_multiplier;
        ENUM_MA_METHOD    m_st_ma_method;
        ENUM_APPLIED_PRICE m_st_applied_price;

    public:
        SignalSuperTrend(void);
        ~SignalSuperTrend(void);

        //--- methods of setting adjustable indicator parameters
        void              SignalSymbol(string value)          { m_sig_symbol=value;         }
        void              SignalTimeframe(int value)          { m_sig_timeframe=value; }
        void              PeriodMA(int value)                 { m_st_period=value;          }
        void              Multiplier(double value)            { m_st_multiplier=value;      }
        void              MaMethod(ENUM_MA_METHOD value)      { m_st_ma_method=value;       }
        void              Applied(ENUM_APPLIED_PRICE value)   { m_st_applied_price=value;   }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

    protected:
        //--- method of initialization of the indicator
        bool              InitSuperTrend(CIndicators *indicators);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalSuperTrend::SignalSuperTrend(void) : m_sig_symbol("GBPJPY"),
                            m_sig_timeframe(PERIOD_M30),
                            m_st_period(10),
                            m_st_multiplier(3.1),
                            m_st_ma_method(ENUM_MA_METHOD::MODE_SMMA),
                            m_st_applied_price(PRICE_OPEN) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalSuperTrend::~SignalSuperTrend(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalSuperTrend::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_st_period<=0) {
        printf(__FUNCTION__+": period MA must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalSuperTrend::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);
    //--- create and initialize MA indicator
    if(!InitSuperTrend(indicators))
        return(false);
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Initialize Super Trend indicators.                                        |
//+------------------------------------------------------------------+
bool SignalSuperTrend::InitSuperTrend(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    
    //--- initialize object
    if(!m_st_indicator.Create(m_sig_symbol, (ENUM_TIMEFRAMES)m_sig_timeframe,
                        m_st_period, m_st_multiplier,
                        m_st_ma_method, m_st_applied_price)) {
        printf(__FUNCTION__+": error initializing object");
        return(false);
    }
    //--- add object to collection
    if(!indicators.Add(GetPointer(m_st_indicator))) {
        printf(__FUNCTION__+": error adding object");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalSuperTrend::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    bool cond = m_st_indicator.Trend(idx) == 1 && Close(idx) > Close(idx-1);

    //--- return the result
    return(cond == 1 ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalSuperTrend::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    bool cond = m_st_indicator.Trend(idx) == -1 && Close(idx) > Close(idx-1);
    //--- return the result
    return(cond == -1 ? 100 : 0);
}
//+------------------------------------------------------------------+
