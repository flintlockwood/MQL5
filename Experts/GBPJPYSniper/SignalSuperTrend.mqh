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
        CiSuperTrend      m_st_handle;
        
        //--- adjusted signal & indicator parameters
        string            m_sig_symbol;
        int               m_sig_timeframe;
        int               m_st_period;
        double            m_st_multiplier;
        ENUM_MA_METHOD    m_st_ma_method;
        ENUM_APPLIED_PRICE m_st_applied_price;

        //--- "weights" of market models (0-100)
        int               m_pattern_0;
        int               m_pattern_1;
        int               m_pattern_2;

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
        //--- methods of getting data
        double            Trend(int ind)                       { return(m_st_handle.GetData(0, ind));  }
        double            Signal1(int ind)                     { return(m_st_handle.GetData(1, ind));  }
        double            Signal2(int ind)                     { return(m_st_handle.GetData(2, ind));  }
        double            Signal3(int ind)                     { return(m_st_handle.GetData(3, ind));  }
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
    MqlParam ind_params[];
    ArrayResize(ind_params, 5);
    ind_params[0].type = TYPE_STRING;
    ind_params[0].string_value = "IndicatorSuperTrend";
    ind_params[1].type = TYPE_INT;
    ind_params[1].integer_value = m_st_period;
    ind_params[2].type = TYPE_DOUBLE;
    ind_params[2].double_value = m_st_multiplier;
    ind_params[3].type = TYPE_INT;
    ind_params[3].integer_value = m_st_ma_method;
    ind_params[4].type = TYPE_INT;
    ind_params[4].integer_value = m_st_applied_price;
    if(!m_st_handle.Create(m_sig_symbol,(ENUM_TIMEFRAMES)m_sig_timeframe,IND_CUSTOM,5,ind_params)) {
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
int SignalSuperTrend::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    if(Signal2(idx) == 1) {
        result = m_pattern_1;
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
int SignalSuperTrend::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    if(Signal2(idx) == 0) {
        result = m_pattern_1;
    }
    else {
        result = 0;
    }
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
