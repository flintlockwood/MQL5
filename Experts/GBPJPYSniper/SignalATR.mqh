//+------------------------------------------------------------------+
//|                                             SignalATR.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalATR: public CExpertSignal {
    protected:
        //--- adjusted parameters
        string            m_sig_symbol;
        ENUM_TIMEFRAMES   m_sig_timeframe;
        int               m_atr_period;
        ENUM_MA_METHOD    m_smoothing_method;
        bool              m_enable_atr_direction;
        bool              m_enable_atr_increase_by;

    public:
        SignalATR(void);
        ~SignalATR(void);

        //--- methods of setting adjustable indicator parameters
        void              SignalSymbol(string value)          { m_sig_symbol=value;          }
        void              SignalTimeframe(ENUM_TIMEFRAMES value) { m_sig_timeframe=value; }
        void              ATRPeriod(int value)                 { m_atr_period=value;          }
        void              SmootingMethod(ENUM_MA_METHOD value) { m_smoothing_method=value;          }
        void              EnableATRDirectionSignal(bool value) { m_enable_atr_direction=value;         }
        void              EnableATRIncreaseBySignal(bool value){ m_enable_atr_increase_by=value;          }
        
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
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalATR::SignalATR(void) : m_atr_period(3),
                             m_smoothing_method(MODE_SMMA) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalATR::~SignalATR(void){
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalATR::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    //--- initial data checks
    if(m_atr_period<=0) {
        printf(__FUNCTION__+": period ATR must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool SignalATR::InitIndicators(CIndicators *indicators) {
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
bool SignalATR::InitSuperTrend(CIndicators *indicators) {
    //--- check pointer
    if(indicators==NULL)
        return(false);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalATR::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    double tr_array[];
    double atr_array[];
    int bars = Bars(m_sig_symbol, m_sig_timeframe);
    CopyTR(m_sig_symbol, m_sig_timeframe, 0, bars, tr_array);
    MAOnBuffer(bars, 0, 0, m_atr_period, m_smoothing_method, tr_array, atr_array);
    ArraySetAsSeries(atr_array, true);
    if (!m_enable_atr_direction || atr_array[idx] > atr_array[idx+1]) {
        return 100;
    }

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalATR::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    double tr_array[];
    double atr_array[];
    int bars = Bars(m_sig_symbol, m_sig_timeframe);
    CopyTR(m_sig_symbol, m_sig_timeframe, 0, bars, tr_array);
    MAOnBuffer(bars, 0, 0, m_atr_period, m_smoothing_method, tr_array, atr_array);
    ArraySetAsSeries(atr_array, true);
    if (!m_enable_atr_direction || atr_array[idx] > atr_array[idx+1]) {
        return 100;
    }
    
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
