//+------------------------------------------------------------------+
//|                                          IndicatorSuperTrend.mqh |
//|                                  Copyright 2026, Mufraeli Rahman |
//|                                                 https://mql5.com |
//| 21.09.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Mufraeli Rahman"
#property link      "https://mql5.com"

#include <Indicators/Indicator.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class CiStochRSI: public CIndicator {
    protected:
        int               m_rsi_period;
        int               m_stoch_length;
        int               m_stoch_k;
        int               m_stoch_d;
        ENUM_APPLIED_PRICE m_applied;

    public:
        CiStochRSI(void);
       ~CiStochRSI(void);

        //--- methods to set to protected data
        void            Symbol(string value) { m_symbol = value; }
        void            Timeframe(int value) { m_period = value; }
        void            RsiPeriod(int value) { m_rsi_period = value;  }
        void            StochLength(int value) { m_stoch_length = value; }
        void            StochK(int value) {m_stoch_k = value; }
        void            StochD(int value) {m_stoch_d = value; }
        void            Applied(ENUM_APPLIED_PRICE value) { m_applied = value; }

        //--- method of creation
        bool            Initialize(const string symbol,const int timeframe);

        //--- methods of access to indicator data
        double          GetData(const int buffer_num,const int index);
        int             GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]);
        double          FastK(const int index);
        double          SlowD(const int index);
        double          Trend(const int index);
        virtual void    Refresh(const int flags=OBJ_ALL_PERIODS);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiStochRSI::CiStochRSI(void) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiStochRSI::~CiStochRSI(void) {
}

bool CiStochRSI::Initialize(const string symbol,const int timeframe) {
//--- we do not need to create indicator here
    if(!Reserve(2)) {
        return false;
    }
    //--- save settings
    m_symbol = symbol;
    m_period = timeframe;

    //--- create buffers
    CIndicatorBuffer *k_buffer = new CIndicatorBuffer();
    k_buffer.Name("K");
    Add(k_buffer);

    CIndicatorBuffer *d_buffer = new CIndicatorBuffer();
    d_buffer.Name("D");
    Add(d_buffer);

    m_buffers_total=2;
    
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Access to upper band buffer                                      |
//+------------------------------------------------------------------+
double CiStochRSI::FastK(const int index) {
    CIndicatorBuffer *buffer=At(0);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

//+------------------------------------------------------------------+
//| Access to lower band buffer                                      |
//+------------------------------------------------------------------+
double CiStochRSI::SlowD(const int index) {
    CIndicatorBuffer *buffer=At(1);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

double CiStochRSI::GetData(const int buffer_num,const int index) {
    CIndicatorBuffer *buffer=At(buffer_num);
    //--- check
    if(buffer==NULL) {
        Print(__FUNCTION__,": invalid buffer");
        return(EMPTY_VALUE);
    }
    //---
    return(buffer.At(index));
}

//+------------------------------------------------------------------+
//| API access method "Copying the buffer of indicator by specifying |
//| a start position and number of elements"                         |
//+------------------------------------------------------------------+
int CiStochRSI::GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]) {
    //--- check
    CIndicatorBuffer *ind_buffer=At(buffer_num);
    if(ind_buffer==NULL) {
        Print(__FUNCTION__,": invalid buffer");
        return(-1);
    }
    if(buffer_num>=m_buffers_total) {
        SetUserError(ERR_USER_INVALID_BUFF_NUM);
        return(-1);
    }
    for (int i=start_pos; i<count; i++) {
        ArrayAppend(buffer, ind_buffer.At(i));
    }
    //---
    return(ArraySize(buffer));
}

//+------------------------------------------------------------------+
//| Refreshing data of indicator                                     |
//+------------------------------------------------------------------+
void CiStochRSI::Refresh(const int flags=OBJ_ALL_PERIODS) {
    double applied_prices[];
    CopyAppliedPrice(m_symbol, m_period, m_applied, 0, BarsCustom(m_symbol, m_period), applied_prices);

    double rsi[];
    RSIOnBuffer(m_rsi_period, applied_prices, rsi);

    double stoch[];
    StochasticOnBuffer(m_stoch_length, rsi, rsi, rsi, stoch);

    double k[];
    InitializeArray(k, ArraySize(stoch), EMPTY_VALUE);
    SimpleMAOnBuffer(ArraySize(stoch), 0, 0, m_stoch_k, stoch, k);

    double d[];
    InitializeArray(d, ArraySize(stoch), EMPTY_VALUE);
    SimpleMAOnBuffer(ArraySize(stoch), 0, 0, m_stoch_d, k, d);

    ArraySetAsSeries(k, true);
    CIndicatorBuffer *k_buffer = At(0);
    k_buffer.AssignArray(k);
    
    ArraySetAsSeries(d, true);
    CIndicatorBuffer *d_buffer = At(1);
    d_buffer.AssignArray(d);
}
