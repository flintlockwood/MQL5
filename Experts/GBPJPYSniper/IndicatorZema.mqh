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

class CiZema: public CIndicator {
    protected:
        string            m_ind_symbol;
        int               m_ind_timeframe;
        int               m_zema_period_long;
        int               m_zema_period_short;

    public:
        CiZema(void);
        ~CiZema(void);

        //--- methods to set to protected data
        void            IndSymbol(string value)    { m_ind_symbol = value;        }
        void            IndTimeframe(int value)    { m_ind_timeframe = value;     }
        void            ZemaPeriodLong(int value)  { m_zema_period_long = value;  }
        void            ZemaPeriodShort(int value) { m_zema_period_short = value; }
        
        //--- method of creation
        bool            Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]);
        bool            Create(const string symbol,const int period,
                            const int zema_period_long, const int zema_period_short);
        
        //--- methods of access to indicator data
        double          GetData(const int buffer_num,const int index);
        int             GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]);
        double          ZemaLong(const int index);
        double          ZemaShort(const int index);
        virtual void    Refresh(const int flags=OBJ_ALL_PERIODS);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiZema::CiZema(void) : m_ind_symbol("GBPJPY"),
                   m_ind_timeframe(PERIOD_M30),
                   m_zema_period_long(73),
                   m_zema_period_short(73) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiZema::~CiZema(void) {
}

//+------------------------------------------------------------------+
//| Create indicator                                                 |
//+------------------------------------------------------------------+
bool CiZema::Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]) {
    return(Create(params[1].string_value, (int)params[2].integer_value, 
                    (int)params[3].integer_value, (int)params[4].integer_value));
}

bool CiZema::Create(const string symbol,const int period,
                        const int zema_period_long, const int zema_period_short) {
//--- we do not need to create indicator here
    if(Reserve(2)) {
        //--- string of status of drawing
        m_name  ="ST";
        m_status="("+symbol+","+PeriodDescription()+","+
               IntegerToString(zema_period_long)+","+IntegerToString(zema_period_short)+")";
        //--- save settings
        m_ind_symbol = symbol;
        m_ind_timeframe = period;
        m_zema_period_long = zema_period_long;
        m_zema_period_long = zema_period_short;

        //--- create buffers
        CIndicatorBuffer *zema_buffer_long = new CIndicatorBuffer();
        zema_buffer_long.Name("Zema Long");
        Add(zema_buffer_long);

        CIndicatorBuffer *zema_buffer_short = new CIndicatorBuffer();
        zema_buffer_short.Name("Zema Short");
        Add(zema_buffer_short);

        //--- ok
        return(true);
    }
    return(false);
}

//+------------------------------------------------------------------+
//| Access to Zema buffer                                            |
//+------------------------------------------------------------------+
double CiZema::ZemaLong(const int index) {
    CIndicatorBuffer *buffer=At(0);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

//+------------------------------------------------------------------+
//| Access to Zema buffer                                            |
//+------------------------------------------------------------------+
double CiZema::ZemaShort(const int index) {
    CIndicatorBuffer *buffer=At(1);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

double CiZema::GetData(const int buffer_num,const int index) {
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
int CiZema::GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]) {
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
void CiZema::Refresh(const int flags=OBJ_ALL_PERIODS) {
    double close[];
    CopyClose(m_ind_symbol, (ENUM_TIMEFRAMES)m_ind_timeframe, 0, Bars(m_ind_symbol, (ENUM_TIMEFRAMES)m_ind_timeframe), close);

    double ema1_long[];
    ExponentialMAOnBuffer(ArraySize(close), 0, 0, m_zema_period_long, close, ema1_long);

    double ema2_long[];
    ExponentialMAOnBuffer(ArraySize(ema1_long), 0, 0, m_zema_period_long, ema1_long, ema2_long);

    double zema_long[];
    InitializeArray(zema_long, ArraySize(close), EMPTY_VALUE);
    for (int i=0; i<ArraySize(close); i++) {
        double diff = ema1_long[i] - ema2_long[i];
        zema_long[i] = ema1_long[i] + diff;
    }

    double ema1_short[];
    ExponentialMAOnBuffer(ArraySize(close), 0, 0, m_zema_period_short, close, ema1_short);

    double ema2_short[];
    ExponentialMAOnBuffer(ArraySize(ema1_short), 0, 0, m_zema_period_short, ema1_short, ema2_short);

    double zema_short[];
    InitializeArray(zema_short, ArraySize(close), EMPTY_VALUE);
    for (int i=0; i<ArraySize(close); i++) {
        double diff = ema1_short[i] - ema2_short[i];
        zema_short[i] = ema1_short[i] + diff;
    }

    CIndicatorBuffer *zema_buffer_long = At(0);
    zema_buffer_long.AssignArray(zema_long);

    CIndicatorBuffer *zema_buffer_short = At(1);
    zema_buffer_short.AssignArray(zema_short);
}
