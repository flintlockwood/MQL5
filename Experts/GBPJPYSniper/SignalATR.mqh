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
        string            m_atr_symbol;
        int               m_atr_timeframe;
        int               m_atr_period;
        ENUM_MA_METHOD    m_smoothing_method;
        bool              m_enable_atr_direction;
        bool              m_enable_atr_increase_by;
        double            m_atr_down_by_long;
        double            m_atr_up_by_long;
        double            m_atr_down_by_short;
        double            m_atr_up_by_short;

    public:
        SignalATR(void);
       ~SignalATR(void);

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_atr_symbol=value;             }
        void              IndicatorTimeframe(int value)        { m_atr_timeframe=value;          }
        void              ATRPeriod(int value)                 { m_atr_period=value;             }
        void              SmootingMethod(ENUM_MA_METHOD value) { m_smoothing_method=value;       }
        void              EnableATRDirectionSignal(bool value) { m_enable_atr_direction=value;   }
        void              EnableATRIncreaseBySignal(bool value){ m_enable_atr_increase_by=value; }
        void              ATRDownByLong(double value)          { m_atr_down_by_long=value;       }
        void              ATRUpByLong(double value)            { m_atr_up_by_long=value;         }
        void              ATRDownByShort(double value)         { m_atr_down_by_short=value;      }
        void              ATRUpByShort(double value)           { m_atr_up_by_short=value;        }
        
        bool              Initialize(string symbol,int period,bool every_tick);        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);

        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalATR::SignalATR(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalATR::~SignalATR(void){
}

bool SignalATR::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
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
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalATR::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    double tr_array[];
    double atr_array[];
    int bars = BarsCustom(m_atr_symbol, m_atr_timeframe);
    CopyTR(m_atr_symbol, m_atr_timeframe, 0, bars, tr_array);
    InitializeArray(atr_array, ArraySize(tr_array), EMPTY_VALUE);
    MAOnBuffer(ArraySize(tr_array), 0, 0, m_atr_period, m_smoothing_method, tr_array, atr_array);
    ArraySetAsSeries(atr_array, true);
    if ((!m_enable_atr_direction || atr_array[idx] > atr_array[idx+1]) 
        && (!m_enable_atr_increase_by || (atr_array[idx] > m_atr_down_by_long && atr_array[idx] < m_atr_up_by_long))) {
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
    int bars = BarsCustom(m_atr_symbol, m_atr_timeframe);
    CopyTR(m_atr_symbol, m_atr_timeframe, 0, bars, tr_array);
    InitializeArray(atr_array, ArraySize(tr_array), EMPTY_VALUE);
    MAOnBuffer(ArraySize(tr_array), 0, 0, m_atr_period, m_smoothing_method, tr_array, atr_array);
    ArraySetAsSeries(atr_array, true);
    if ((!m_enable_atr_direction || atr_array[idx] < atr_array[idx+1]) 
        && (!m_enable_atr_increase_by || (atr_array[idx] > m_atr_down_by_short && atr_array[idx] < m_atr_up_by_short))) {
        return 100;
    }
    
    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
