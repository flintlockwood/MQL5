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
        double          FastK(const int index);
        double          SlowD(const int index);
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
                    params[3].integer_value, params[4].int_value,
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
