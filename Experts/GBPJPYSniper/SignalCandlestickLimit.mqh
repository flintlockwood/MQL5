//+------------------------------------------------------------------+
//|                                             SignalCandlestickLimit.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalCandlestickLimit: public CExpertSignal {
    protected:
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        int               m_cso_idx_long;
        double            m_cso_pct_long;
        int               m_cso_idx_short;
        double            m_cso_pct_short;
        ENUM_APPLIED_PRICE m_cso_target;

    public:
        SignalCandlestickLimit(void);
        ~SignalCandlestickLimit(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)         { m_sig_symbol=value;    }
        void              IndicatorTimeframe(int value)         { m_sig_timeframe=value; }
        void              CsoIdxLong(int value)                 { m_cso_idx_long=value;  }
        void              CsoPctLong(double value)              { m_cso_pct_long=value;  }
        void              CsoIdxShort(int value)                { m_cso_idx_short=value; }
        void              CsoPctShort(double value)             { m_cso_pct_short=value; }
        void              CsoTarget(ENUM_APPLIED_PRICE value)   { m_cso_target=value;    }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalCandlestickLimit::SignalCandlestickLimit(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalCandlestickLimit::~SignalCandlestickLimit(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalCandlestickLimit::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickLimit::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_sig_symbol, m_sig_timeframe);
    double target[];
    CopyAppliedPrice(m_sig_symbol, m_sig_timeframe, m_cso_target, 0, bars, target);
    
    ArraySetAsSeries(target, true);
    bool cond = target[idx] < Open(m_cso_idx_long + idx) * (1 + m_cso_pct_long / 100);

    //--- return the result
    return(cond ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalCandlestickLimit::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    int bars = BarsCustom(m_sig_symbol, m_sig_timeframe);
    double target[];
    CopyAppliedPrice(m_sig_symbol, m_sig_timeframe, m_cso_target, 0, bars, target);
    
    ArraySetAsSeries(target, true);
    bool cond = target[idx] > Open(m_cso_idx_short + idx) * (1 - m_cso_pct_short / 100);

    //--- return the result
    return(cond ? 100 : 0);
}
//+------------------------------------------------------------------+
