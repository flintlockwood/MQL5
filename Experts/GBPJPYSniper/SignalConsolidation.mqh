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
        int               m_cons_lookback;
        int               m_cons_length;

    public:
        SignalConsolidation(void);
        ~SignalConsolidation(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_sig_symbol=value;             }
        void              IndicatorTimeframe(int value)        { m_sig_timeframe=value;          }
        void              ATRPeriodLong(int value)             { m_cons_lookback=value;          }
        void              ATRMultiplierLong(double value)      { m_cons_length=value;            }
        
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
    double high[];
    double low[];
    double close[];
    int bars = BarsCustom(m_sig_symbol, m_sig_timeframe);
    CopyRatesCustom(m_sig_symbol, m_sig_timeframe, 0, m_cons_lookback, rates);
    CopyHighFromMqlRates(rates, high);
    CopyLowFromMqlRates(rates, low);
    CopyCloseFromMqlRates(rates, close);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);

    double hb_ = ArrayMaximum(high, 0, WHOLE_ARRAY) == 0 ? high[0] : EMPTY_VALUE;
    double lb_ = ArrayMinimum(low, 0, WHOLE_ARRAY) == 0 ? low[0] : EMPTY_VALUE;
    int dir[];
    InitializeArray(dir, ArraySize(high), 0);
    double zz = 0;
    double pp = 0;

    for (int i=0; i<ArraySize(high); i++) {
        dir[i] = 
    }

    dir = hb_ != EMPTY_VALUE && lb_ == EMPTY_VALUE ? 1 : lb_ != EMPTY_VALUE && hb_ == EMPTY_VALUE ? -1 : 0;
    if (hb_ != EMPTY_VALUE && lb_ != EMPTY_VALUE) {
        if (dir == 1) {
            zz = hb_;
        }
        else {
            zz = lb_;
        }
    }
    else {
        zz = hb_ != EMPTY_VALUE ? hb_ : lb_ != EMPTY_VALUE ? lb_ : EMPTY_VALUE;
    }

    for (int x=0; x<=1000; x++) {
        if ()
    }

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
