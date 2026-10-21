//+------------------------------------------------------------------+
//|                                             SignalSuperTrend.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include "IndicatorStochRSI.mqh"

class SignalStochRSI: public CExpertSignal {
    protected:
        CiStochRSI       *m_ind_stoch;
        
        //--- adjusted indicator parameters
        int               m_stochrsi_period;
        int               m_stochrsi_length;
        int               m_stochrsi_k;
        int               m_stochrsi_d;
        ENUM_APPLIED_PRICE m_applied_price;
        string            m_kd_operator;

        //--- "weights" of market models (0-100)
        int               m_pattern_0;

    public:
        SignalStochRSI(void);
        ~SignalStochRSI(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)       { m_ind_stoch.Symbol(value);  }
        void              IndicatorTimeframe(ENUM_TIMEFRAMES value) { m_ind_stoch.Timeframe(value);}
        void              RSIPeriod(int value)                { m_ind_stoch.RsiPeriod(value);     }
        void              StochLength(int value)              { m_ind_stoch.StochLength(value);   }
        void              StochK(int value)                   { m_ind_stoch.StochK(value);              }
        void              StochD(int value)                   { m_ind_stoch.StochD(value);              }
        void              RsiSource(ENUM_APPLIED_PRICE value) { m_ind_stoch.Applied(value);      }
        void              KDOperator(string value)            { m_kd_operator=value;        }

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
SignalStochRSI::SignalStochRSI(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;

    m_ind_stoch = new CiStochRSI();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalStochRSI::~SignalStochRSI(void){
    delete m_ind_stoch;
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalStochRSI::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);

    //--- ok
    return(true);
}

bool SignalStochRSI::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    
    m_ind_stoch.Initialize(symbol, period);

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalStochRSI::InitIndicators(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialization of indicators and timeseries of additional filters
    if(!CExpertSignal::InitIndicators(indicators))
        return(false);

    indicators.Add(m_ind_stoch);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalStochRSI::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    if (m_kd_operator == ">") {
        if (m_ind_stoch.FastK(idx) < 80 && m_ind_stoch.FastK(idx) > 50 && m_ind_stoch.FastK(idx) > m_ind_stoch.SlowD(idx))
            result = m_pattern_0;
    }
    else {
        result = 0;
    }
    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalStochRSI::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    if (m_kd_operator == ">") {
        if (m_ind_stoch.SlowD(idx) < 50 && m_ind_stoch.SlowD(idx) > 20 && m_ind_stoch.SlowD(idx) > m_ind_stoch.FastK(idx))
            result = m_pattern_0;
    }
    else {
        result = 0;
    }
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
