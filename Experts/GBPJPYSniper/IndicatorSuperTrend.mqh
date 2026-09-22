//+------------------------------------------------------------------+
//|                                          IndicatorSuperTrend.mqh |
//|                                  Copyright 2026, Mufraeli Rahman |
//|                                                 https://mql5.com |
//| 21.09.2026 - Initial release                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Mufraeli Rahman"
#property link      "https://mql5.com"

#include <Indicators/Indicator.mqh>
#include "Helper.mqh"

class CiSuperTrend: public CIndicator {
    protected:
        string            m_ind_symbol;
        int               m_ind_timeframe;
        int               m_atr_period;
        double            m_atr_multiplier;
        ENUM_MA_METHOD    m_ma_method;
        ENUM_APPLIED_PRICE m_applied;

    public:
        CiSuperTrend(void);
        ~CiSuperTrend(void);

        //--- methods to set to protected data
        void            IndSymbol(string value) { m_ind_symbol = value; }
        void            IndTimeframe(int value) { m_ind_timeframe = value; }
        void            AtrPeriod(int value) { m_atr_period = value;  }
        void            AtrMultiplier(double value) { m_atr_multiplier = value; }
        void            Applied(ENUM_APPLIED_PRICE value) { m_applied = value; }
        
        //--- method of creation
        bool            Create(const string symbol,const int period,
                            const int atr_period,const double atr_mutiplier,
                            const ENUM_MA_METHOD ma_method,const ENUM_APPLIED_PRICE applied);
        
        //--- methods of access to indicator data
        double          Main(const int index) const;
        bool            Refresh();

    protected:
        //--- methods of tuning
        bool            Initialize(const string symbol,const int period,const int num_params,const MqlParam &params[]);
        bool            Initialize(const string symbol,const int period,
                            const int atr_period,const double atr_mutiplier,
                            const ENUM_MA_METHOD ma_method,const ENUM_APPLIED_PRICE applied);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiSuperTrend::CiSuperTrend(void) : m_ind_symbol("GBPJPY"),
                   m_ind_timeframe(PERIOD_M30),
                   m_atr_period(10),
                   m_atr_multiplier(3.1),
                   m_ma_method(MODE_SMMA),
                   m_applied(PRICE_OPEN) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiSuperTrend::~CiSuperTrend(void) {
}

//+------------------------------------------------------------------+
//| Create indicator                                                 |
//+------------------------------------------------------------------+
bool CiSuperTrend::Create(const string symbol,const int period,
                        const int atr_period,const double atr_mutiplier,
                        const ENUM_MA_METHOD ma_method,const ENUM_APPLIED_PRICE applied) {
//--- we do not need to create indicator here
   return(true);
}

//+------------------------------------------------------------------+
//| Initialize the indicator with universal parameters               |
//+------------------------------------------------------------------+
bool CiSuperTrend::Initialize(const string symbol,const int period,const int num_params,const MqlParam &params[]) {
    return(Initialize(symbol,period,(int)params[0].integer_value,(double)params[1].double_value,
        (ENUM_MA_METHOD)params[2].integer_value,(ENUM_APPLIED_PRICE)params[3].integer_value));
}

//+------------------------------------------------------------------+
//| Initialize indicator with the special parameters                 |
//+------------------------------------------------------------------+
bool CiSuperTrend::Initialize(const string symbol,const int period,
                        const int atr_period,const double atr_mutiplier,
                        const ENUM_MA_METHOD ma_method,const ENUM_APPLIED_PRICE applied) {
    if(CreateBuffers(symbol,(ENUM_TIMEFRAMES)period,2)) {
        //--- string of status of drawing
        m_name  ="TREND";
        m_status="("+symbol+","+PeriodDescription()+","+
               IntegerToString(atr_period)+","+DoubleToString(atr_mutiplier)+","+
               MethodDescription(ma_method)+","+PriceDescription(applied)+")";
        //--- save settings
        m_atr_period=atr_period;
        m_atr_multiplier=atr_mutiplier;
        m_ma_method=ma_method;
        m_applied  =applied;
        //--- create buffers
        ((CIndicatorBuffer*)At(0)).Name("BUY TREND");
        ((CIndicatorBuffer*)At(0)).Offset(0);
        ((CIndicatorBuffer*)At(1)).Name("SELL TREND");
        ((CIndicatorBuffer*)At(1)).Offset(0);
        //--- ok
        return(true);
    }
    //--- error
    return(false);
}

//+------------------------------------------------------------------+
//| Access to buffer                                                 |
//+------------------------------------------------------------------+
double CiSuperTrend::Main(const int index) const {
    CIndicatorBuffer *buffer=At(0);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

//+------------------------------------------------------------------+
//| API access method "Copying an element of indicator buffer        |
//| by specifying number of buffer and position of element"          |        
//+------------------------------------------------------------------+
double CIndicator::GetData(const int buffer_num,const int index) const {
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
int CIndicator::GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]) const {
    //--- check
    CIndicatorBuffer *buffer=At(buffer_num);
    if(buffer==NULL) {
        Print(__FUNCTION__,": invalid buffer");
        return(-1);
    }
    if(buffer_num>=m_buffers_total) {
        SetUserError(ERR_USER_INVALID_BUFF_NUM);
        return(-1);
    }
    for (int i=start_pos; i<count; i++) {
        ArrayAppend(buffer, buffer.At(i));
    }
    //---
    return(ArraySize(buffer));
}

//+------------------------------------------------------------------+
//| API access method "Copying the buffer of indicator by specifying |
//| start time and number of elements"                               |
//+------------------------------------------------------------------+
int CIndicator::GetData(const datetime start_time,const int count,const int buffer_num,double &buffer[]) const
  {
//--- check
    CIndicatorBuffer *buffer=At(buffer_num);
    if(buffer==NULL) {
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
int CIndicator::GetData(const datetime start_time,const datetime stop_time,const int buffer_num,double &buffer[]) const {
    //--- check
   if(buffer==NULL) {
        Print(__FUNCTION__,": invalid buffer");
        return(-1);
    }
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
void CIndicator::Refresh(const int flags) {
    int               i;
    CIndicatorBuffer *buff;
    //--- refreshing buffers
    for(i=0;i<Total();i++) {
        buff=At(i);
        if(m_redrawer)
        {
            buff.Refresh(m_handle,i);
            continue;
        }
        if(!(flags&m_timeframe_flags))
        {
            if(m_refresh_current)
            buff.RefreshCurrent(m_handle,i);
        }
        else
            buff.Refresh(m_handle,i);
    }
}

//+------------------------------------------------------------------+
//| Refreshing of data in buffer                                     |
//+------------------------------------------------------------------+
bool CIndicatorBuffer::Refresh(const int handle,const int num) {
    //--- check
    if(handle==INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return(false);
    }
    //---
    m_data_total=CopyBuffer(handle,num,-m_offset,m_size,m_data);
    //---
    return(m_data_total>0);
}

//+------------------------------------------------------------------+
//| Refreshing of the data in buffer                                 |
//+------------------------------------------------------------------+
bool CIndicatorBuffer::RefreshCurrent(const int handle,const int num) {
    double array[1];
    //--- check
    if(handle==INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return(false);
    }
    //---
    if(CopyBuffer(handle,num,-m_offset,1,array)>0 && m_data_total>0) {
        m_data[0]=array[0];
        return(true);
    }
    //--- error
    return(false);
}
