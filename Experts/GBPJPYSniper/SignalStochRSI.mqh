//+------------------------------------------------------------------+
//|                                             SignalSuperTrend.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>

class SignalStochRSI: public CExpertSignal {
    protected:
        CiCustom          m_st_handle;
        
        //--- adjusted indicator parameters
        string            m_ind_symbol;
        ENUM_TIMEFRAMES   m_ind_timeframe;
        int               m_ind_rsi_period;
        int               m_ind_stoch_length;
        int               m_ind_k;
        int               m_ind_d;
        ENUM_APPLIED_PRICE m_applied_price;
        string            m_kd_operator;

        //--- "weights" of market models (0-100)
        int               m_pattern_0;

    public:
        SignalStochRSI(void);
        ~SignalStochRSI(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)       { m_ind_symbol=value;         }
        void              IndicatorTimeframe(ENUM_TIMEFRAMES value) { m_ind_timeframe=value;}
        void              RSIPeriod(int value)                { m_ind_rsi_period=value;     }
        void              StochLength(int value)              { m_ind_stoch_length=value;   }
        void              StochK(int value)                   { m_ind_k=value;              }
        void              StochD(int value)                   { m_ind_d=value;              }
        void              KDOperator(string value)            { m_kd_operator=value;        }

        //--- methods of adjusting "weights" of market models
        void              Pattern_0(int value)                { m_pattern_0=value;          }
        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- method of creating the indicator and timeseries
        virtual bool      InitIndicators(CIndicators *indicators);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

    protected:
        //--- method of initialization of the indicator
        bool              InitStochRSI(CIndicators *indicators);
        //--- methods of getting data
        double            StochKData(int ind)                     { return(m_st_handle.GetData(0, ind));  }
        double            StochDData(int ind)                     { return(m_st_handle.GetData(1, ind));  }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalStochRSI::SignalStochRSI(void) : m_ind_rsi_period(22),
                             m_ind_stoch_length(2),
                             m_ind_k(19),
                             m_ind_d(2),
                             m_applied_price(PRICE_HIGH),
                             m_kd_operator(">") {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalStochRSI::~SignalStochRSI(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalStochRSI::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_ind_rsi_period<=0) {
        printf(__FUNCTION__+": RSI period must be greater than 0");
        return(false);
    }
    if(m_ind_stoch_length<=0) {
        printf(__FUNCTION__+": Stochastic period must be greater than 0");
        return(false);
    }
    if(m_ind_k<=0) {
        printf(__FUNCTION__+": Stochastic K length must be greater than 0");
        return(false);
    }
    if(m_ind_d<=0) {
        printf(__FUNCTION__+": Stochastic D length must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
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
    //--- create and initialize MA indicator
    if(!InitStochRSI(indicators))
        return(false);
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Initialize Super Trend indicators.                                        |
//+------------------------------------------------------------------+
bool SignalStochRSI::InitStochRSI(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);
    //--- initialize object
    MqlParam ind_params[];
    ArrayResize(ind_params, 5);
    ind_params[0].type = TYPE_STRING;
    ind_params[0].string_value = "IndicatorStochRSI.ex5";
    ind_params[1].type = TYPE_INT;
    ind_params[1].integer_value = m_ind_rsi_period;
    ind_params[2].type = TYPE_INT;
    ind_params[2].integer_value = m_ind_stoch_length;
    ind_params[3].type = TYPE_INT;
    ind_params[3].integer_value = m_ind_k;
    ind_params[4].type = TYPE_INT;
    ind_params[4].integer_value = m_ind_d;
    ind_params[5].type = TYPE_INT;
    ind_params[5].integer_value = m_applied_price;
    ind_params[6].type = TYPE_STRING;
    ind_params[6].string_value = m_kd_operator;
    if(!m_st_handle.Create(m_ind_symbol,m_ind_timeframe,IND_CUSTOM,7,ind_params)) {
        printf(__FUNCTION__+": error initializing object");
        return(false);
    }
    //--- add object to collection
    if(!indicators.Add(GetPointer(m_st_handle))) {
        printf(__FUNCTION__+": error adding object");
        return(false);
    }
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
        if (StochKData(idx) < 80 && StochKData(idx) > 50 && StochKData(idx) > StochDData(idx))
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
        if (StochDData(idx) < 50 && StochDData(idx) > 20 && StochDData(idx) > StochKData(idx))
            result = m_pattern_0;
    }
    else {
        result = 0;
    }
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
