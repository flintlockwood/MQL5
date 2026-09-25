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
        string            m_kd_operator;

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
        void            KDOperator(string value) { m_kd_operator = value; }
        
        //--- method of creation
        bool            Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]);
        bool            Create(const string symbol,const int period,
                            const int atr_period,const double atr_mutiplier,
                            const ENUM_MA_METHOD ma_method,const ENUM_APPLIED_PRICE applied);
        
        //--- methods of access to indicator data
        double          GetData(const int buffer_num,const int index);
        int             GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]);
        int             GetData(const datetime start_time,const int count,const int buffer_num,double &buffer[]);
        int             GetData(const datetime start_time,const datetime stop_time,const int buffer_num,double &buffer[]);
        double          UpperBand(const int index);
        double          LowerBand(const int index);
        double          Trend(const int index);
        virtual void    Refresh(const int flags=OBJ_ALL_PERIODS);
        bool            Refresh(const int handle,const int num);
        bool            RefreshCurrent(const int handle,const int num);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiStochRSI::CiStochRSI(void) : m_ind_symbol("GBPJPY"),
                   m_ind_timeframe(PERIOD_M30),
                   m_atr_period(10),
                   m_atr_multiplier(3.1),
                   m_ma_method(MODE_SMMA),
                   m_applied(PRICE_OPEN) {
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
                    (int)params[3].integer_value, params[4].double_value,
                    (ENUM_MA_METHOD)params[5].integer_value, (ENUM_APPLIED_PRICE)params[6].integer_value));
}

bool CiStochRSI::Create(const string symbol,const int period,
                        const int atr_period,const double atr_mutiplier,
                        const ENUM_MA_METHOD ma_method,const ENUM_APPLIED_PRICE applied) {
//--- we do not need to create indicator here
    if(Reserve(3)) {
        //--- string of status of drawing
        m_name  ="ST";
        m_status="("+symbol+","+PeriodDescription()+","+
               IntegerToString(atr_period)+","+DoubleToString(atr_mutiplier)+","+
               MethodDescription(ma_method)+","+PriceDescription(applied)+")";
        //--- save settings
        m_ind_symbol = symbol;
        m_ind_timeframe = period;
        m_atr_period=atr_period;
        m_atr_multiplier=atr_mutiplier;
        m_ma_method=ma_method;
        m_applied  =applied;
        //--- create buffers
        CIndicatorBuffer *upper_band_buffer = new CIndicatorBuffer();
        upper_band_buffer.Name("Upper Band");
        Add(upper_band_buffer);

        CIndicatorBuffer *lower_band_buffer = new CIndicatorBuffer();
        lower_band_buffer.Name("Lower Band");
        Add(lower_band_buffer);

        CIndicatorBuffer *trend_buffer = new CIndicatorBuffer();
        trend_buffer.Name("Trend");
        Add(trend_buffer);
        //--- ok
        return(true);
    }
    return(false);
}

//+------------------------------------------------------------------+
//| Access to upper band buffer                                      |
//+------------------------------------------------------------------+
double CiStochRSI::UpperBand(const int index) {
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
double CiStochRSI::LowerBand(const int index) {
    CIndicatorBuffer *buffer=At(1);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

//+------------------------------------------------------------------+
//| Access to lower trend buffer                                     |
//+------------------------------------------------------------------+
double CiStochRSI::Trend(const int index) {
    CIndicatorBuffer *buffer=At(2);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

double CiStochRSI::GetData(const int buffer_num,const int index) {
    bool success = Refresh(NULL, buffer_num);
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
//| API access method "Copying the buffer of indicator by specifying |
//| start time and number of elements"                               |
//+------------------------------------------------------------------+
int CiStochRSI::GetData(const datetime start_time,const int count,const int buffer_num,double &buffer[]) {
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
    //---
    return(CopyBuffer(m_handle,buffer_num,start_time,count,buffer));
}

//+------------------------------------------------------------------+
//| API access method "Copying the buffer of indicator by specifying |
//| start and final time                                             |
//+------------------------------------------------------------------+
int CiStochRSI::GetData(const datetime start_time,const datetime stop_time,const int buffer_num,double &buffer[]) {
    //--- check
    if(buffer_num>=m_buffers_total) {
        SetUserError(ERR_USER_INVALID_BUFF_NUM);
        return(-1);
    }
    //---
    return(CopyBuffer(m_handle,buffer_num,start_time,stop_time,buffer));
}

//+------------------------------------------------------------------+
//| Refreshing data of indicator                                     |
//+------------------------------------------------------------------+
void CiStochRSI::Refresh(const int flags=OBJ_ALL_PERIODS) {
    double tr[];
    double atr[];
    double applied_prices[];
    MqlRates rates[];
    double close[];
    CopyAppliedPrice(m_ind_symbol, m_ind_timeframe, m_applied, 0, BarsCustom(m_ind_symbol, m_ind_timeframe), applied_prices);
    CopyTR(m_ind_symbol, m_ind_timeframe, 0, BarsCustom(m_ind_symbol, m_ind_timeframe), tr);
    CopyRatesCustom(m_ind_symbol, m_ind_timeframe, 0, rates);
    CopyCloseFromMqlRates(rates, close);

    ArrayResize(atr, ArraySize(tr));
    switch (m_ma_method)
    {
        case MODE_SMA:
            SimpleMAOnBuffer(ArraySize(tr), 0, 0, m_atr_period, tr, atr);
            break;
        case MODE_EMA:
            ExponentialMAOnBuffer(ArraySize(tr), 0, 0, m_atr_period, tr, atr);
            break;
        case MODE_LWMA:
            LinearWeightedMAOnBuffer(ArraySize(tr), 0, 0, m_atr_period, tr, atr);
            break;
        case MODE_SMMA:
            SmoothedMAOnBuffer(ArraySize(tr), 0, 0, m_atr_period, tr, atr);
            break;
        default:
            break;
    }
    
    double upper_band[];
    double lower_band[];
    double trend[];
    InitializeArray(upper_band, ArraySize(atr), EMPTY_VALUE);
    InitializeArray(lower_band, ArraySize(atr), EMPTY_VALUE);
    InitializeArray(trend, ArraySize(atr), EMPTY_VALUE);
    trend[0] = 1;
    for (int i=0; i<ArraySize(atr); i++) {
        upper_band[i] = applied_prices[i] + m_atr_multiplier * atr[i];
        lower_band[i] = applied_prices[i] - m_atr_multiplier * atr[i];
        if (i>0) {
            if (upper_band[i-1] == EMPTY_VALUE) {
                continue;
            }
            if (close[i-1] < lower_band[i-1]) {
                lower_band[i] = MathMin(lower_band[i], lower_band[i-1]);
            }
            if (lower_band[i-1] == EMPTY_VALUE){
                continue;
            }
            if (close[i-1] > upper_band[i-1]) {
                upper_band[i] = MathMax(upper_band[i], upper_band[i-1]);
            }
            trend[i] = trend[i-1] == -1 && close[i] > upper_band[i-1] ? 1 : trend[i-1] == -1 && close[i] > lower_band[i-1] ? -1 : trend[i-1];
        }
    }

    CIndicatorBuffer *upper_band_buffer = At(0);
    upper_band_buffer.AssignArray(upper_band);
    
    CIndicatorBuffer *lower_band_buffer = At(1);
    lower_band_buffer.AssignArray(lower_band);

    CIndicatorBuffer *trend_buffer = At(2);
    trend_buffer.AssignArray(trend);
}

//+------------------------------------------------------------------+
//| Refreshing of data in buffer                                     |
//+------------------------------------------------------------------+
bool CiStochRSI::Refresh(const int handle,const int num) {
    //--- check
    if(handle==INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return(false);
    }
    //---
    //m_data_total=CopyBuffer(handle,num,-m_offset,m_size,m_data);
    //---
    return(m_data_total>0);
}

//+------------------------------------------------------------------+
//| Refreshing of the data in buffer                                 |
//+------------------------------------------------------------------+
bool CiStochRSI::RefreshCurrent(const int handle,const int num) {
    double array[1];
    //--- check
    if(handle==INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return(false);
    }
    //---
    //if(CopyBuffer(handle,num,-m_offset,1,array)>0 && m_data_total>0) {
    //    m_data[0]=array[0];
    //    return(true);
    //}
    //--- error
    return(false);
}
