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
        string            m_ind_symbol;
        int               m_ind_timeframe;
        int               m_rsi_period;
        int               m_stoch_length;
        int               m_stoch_k;
        int               m_stoch_d;
        ENUM_APPLIED_PRICE m_applied;

    public:
        CiStochRSI(void);
        ~CiStochRSI(void);

        //--- methods to set to protected data
        void            IndSymbol(string value) { m_ind_symbol = value; }
        void            IndTimeframe(int value) { m_ind_timeframe = value; }
        void            RsiPeriod(int value) { m_rsi_period = value;  }
        void            StochLength(int value) { m_stoch_length = value; }
        void            StochK(int value) {m_stoch_k = value; }
        void            StochD(int value) {m_stoch_d = value; }
        void            Applied(ENUM_APPLIED_PRICE value) { m_applied = value; }
        
        //--- method of creation
        bool            Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]);
        bool            Create(const string symbol,const int period,
                            const int rsi_period,const int stoch_length,
                            const int k,const int d, const ENUM_APPLIED_PRICE applied);
        
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
CiStochRSI::CiStochRSI(void) : m_ind_symbol("GBPJPY"),
                   m_ind_timeframe(PERIOD_M30),
                   m_rsi_period(22),
                   m_stoch_length(2),
                   m_stoch_k(19),
                   m_stoch_d(2),
                   m_applied(PRICE_HIGH) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiStochRSI::~CiStochRSI(void) {
}

//+------------------------------------------------------------------+
//| Create indicator                                                 |
//+------------------------------------------------------------------+
bool CiStochRSI::Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]) {
    return(Create(params[1].string_value, (int)params[2].integer_value, 
                    params[3].integer_value, params[4].integer_value,
                    params[5].integer_value, params[6].integer_value, (ENUM_APPLIED_PRICE)params[7].integer_value));
}

bool CiStochRSI::Create(const string symbol,const int period,
                        const int rsi_period,const int stoch_length,
                        const int k,const int d, const ENUM_APPLIED_PRICE applied) {
//--- we do not need to create indicator here
    if(Reserve(2)) {
        //--- string of status of drawing
        m_name  ="ST";
        m_status="("+symbol+","+PeriodDescription()+","+
               IntegerToString(rsi_period)+","+IntegerToString(stoch_length)+","+
               IntegerToString(k)+","+IntegerToString(d)+")";
        //--- save settings
        m_ind_symbol = symbol;
        m_ind_timeframe = period;
        m_rsi_period = rsi_period;
        m_stoch_length = stoch_length;
        m_stoch_k = k;
        m_stoch_d = d;
        m_applied  =applied;
        //--- create buffers
        CIndicatorBuffer *k_buffer = new CIndicatorBuffer();
        k_buffer.Name("K");
        Add(k_buffer);

        CIndicatorBuffer *d_buffer = new CIndicatorBuffer();
        d_buffer.Name("D");
        Add(d_buffer);
        //--- ok
        return(true);
    }
    return(false);
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
    CopyAppliedPrice(m_ind_symbol, m_ind_timeframe, m_applied, 0, BarsCustom(m_ind_symbol, m_ind_timeframe), applied_prices);

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

    CIndicatorBuffer *k_buffer = At(0);
    k_buffer.AssignArray(k);
    
    CIndicatorBuffer *d_buffer = At(1);
    d_buffer.AssignArray(d);
}
