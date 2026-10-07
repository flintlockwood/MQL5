//+------------------------------------------------------------------+
//|                                             SignalConsolidation.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalConsolidation: public CExpertSignal {
    protected:
        //--- adjusted parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        int               m_atr_period_long;
        double            m_atr_multiplier_long;
        int               m_atr_period_short;
        double            m_atr_multiplier_short;
        bool              m_long_condition;
        bool              m_short_condition;

    public:
        SignalConsolidation(void);
        ~SignalConsolidation(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;             }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value;          }
        void              ATRPeriodLong(int value)             { m_atr_period_long=value;        }
        void              ATRMultiplierLong(double value)      { m_atr_multiplier_long=value;    }
        void              ATRPeriodShort(int value)            { m_atr_period_short=value;       }
        void              ATRMultiplierShort(double value)     { m_atr_multiplier_short=value;    }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

    protected:
        void              CalculateCondition();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalConsolidation::SignalConsolidation(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalConsolidation::~SignalConsolidation(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalConsolidation::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);

    //--- ok
    return(true);
}

void SignalConsolidation::CalculateCondition() {
    MqlRates rates[];
    int bars = BarsCustom(m_sig_symbol, m_sig_timeframe);
    CopyRatesCustom(m_sig_symbol, m_sig_timeframe, 0, rates);
    

    //m_long_condition = pos == 1 && poss != -1;
    //m_short_condition = poss == -1 && pos != 1;
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalConsolidation::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    CalculateCondition();

    //--- return the result
    return(m_long_condition ? 100 : 0);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalConsolidation::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    CalculateCondition();
    
    //--- return the result
    return(m_short_condition ? 100 : 0);
}
//+------------------------------------------------------------------+
