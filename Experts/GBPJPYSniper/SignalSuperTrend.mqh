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
        CiSuperTrend     *m_st_indicator;
        
        //--- adjusted signal & indicator parameters
        int               m_st_period;
        double            m_st_multiplier;
        ENUM_MA_METHOD    m_st_ma_method;
        ENUM_APPLIED_PRICE m_st_applied_price;
        bool              m_enable_close;

    public:
        SignalSuperTrend(void);
       ~SignalSuperTrend(void);

        //--- methods of setting adjustable indicator parameters
        void              SignalSymbol(string value)          { m_st_indicator.Symbol(value);         }
        void              SignalTimeframe(int value)          { m_st_indicator.Timeframe(value); }
        void              PeriodMA(int value)                 { m_st_indicator.AtrPeriod(value);          }
        void              Multiplier(double value)            { m_st_indicator.AtrMultiplier(value);      }
        void              MaMethod(ENUM_MA_METHOD value)      { m_st_indicator.MaMethod(value);       }
        void              Applied(ENUM_APPLIED_PRICE value)   { m_st_indicator.Applied(value);   }
        void              EnableClose(bool value)             { m_enable_close=value;       }

        bool              Initialize(string symbol,int period,bool every_tick);
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
SignalSuperTrend::SignalSuperTrend(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;

    m_st_indicator = new CiSuperTrend();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalSuperTrend::~SignalSuperTrend(void){
    delete m_st_indicator;
}

bool SignalSuperTrend::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_st_indicator.Initialize(symbol, period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
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
    
    indicators.Add(m_st_indicator);
    
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalSuperTrend::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    bool cond = m_st_indicator.Trend(idx) == 1;
    if (m_enable_close) {
        cond = cond && Close(idx) > Close(idx+1);
    }

    //--- return the result
    return(cond == 1 ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalSuperTrend::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    bool cond = m_st_indicator.Trend(idx) == -1;
    if (m_enable_close) {
        cond = cond && Close(idx) > Close(idx+1);
    }
    
    //--- return the result
    return(cond == -1 ? 100 : 0);
}
//+------------------------------------------------------------------+
