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

class CiLinearRegression: public CIndicator {
    protected:
        string          m_ind_symbol;
        int             m_ind_timeframe;
        int             m_lsma_period;
        int             m_lsma_offset;
        ENUM_APPLIED_PRICE m_lsma_source;

    public:
        CiLinearRegression(void);
        ~CiLinearRegression(void);

        //--- methods to set to protected data
        void            IndSymbol(string value) { m_ind_symbol = value; }
        void            IndTimeframe(int value) { m_ind_timeframe = value; }
        void            LsmaPeriod(int value) { m_lsma_period = value;  }
        void            LsmaOffset(int value) { m_lsma_offset = value; }
        void            LsmaSource(ENUM_APPLIED_PRICE value) { m_lsma_source = value; }
        
        //--- method of creation
        bool            Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]);
        bool            Create(const string symbol,const int period);
        
        //--- methods of access to indicator data
        double          GetData(const int buffer_num,const int index);
        int             GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]);
        double          LinReg(const int index);
        virtual void    Refresh(const int flags=OBJ_ALL_PERIODS);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiLinearRegression::CiLinearRegression(void) : m_ind_symbol("GBPJPY"),
                   m_ind_timeframe(PERIOD_M30),
                   m_lsma_period(18),
                   m_lsma_offset(5),
                   m_lsma_source(PRICE_OPEN) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiLinearRegression::~CiLinearRegression(void) {
}

//+------------------------------------------------------------------+
//| Create indicator                                                 |
//+------------------------------------------------------------------+
bool CiLinearRegression::Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]) {
    return(Create(symbol, period));
}

bool CiLinearRegression::Create(const string symbol,const int period) {
//--- we do not need to create indicator here
    if(Reserve(3)) {
        //--- string of status of drawing
        m_name  ="LSMA";
        m_status="("+symbol+","+PeriodDescription()+","+
               IntegerToString(m_lsma_period)+","+IntegerToString(m_lsma_offset)+","+
               ","+PriceDescription(m_lsma_source)+")";
        //--- save settings
        m_ind_symbol = symbol;
        m_ind_timeframe = period;
        m_lsma_period = m_lsma_period;
        m_lsma_offset = m_lsma_offset;
        m_lsma_source =m_lsma_source;
        //--- create buffers
        CIndicatorBuffer *lr_buffer = new CIndicatorBuffer();
        lr_buffer.Name("LSMA");
        Add(lr_buffer);
        m_buffers_total=1;
        //--- ok
        return(true);
    }
    return(false);
}

//+------------------------------------------------------------------+
//| Access to linear regression buffer                               |
//+------------------------------------------------------------------+
double CiLinearRegression::LinReg(const int index) {
    CIndicatorBuffer *buffer=At(0);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

double CiLinearRegression::GetData(const int buffer_num,const int index) {
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
int CiLinearRegression::GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]) {
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
void CiLinearRegression::Refresh(const int flags=OBJ_ALL_PERIODS) {
    double applied_prices[];
    double linreg[];
    CopyAppliedPrice(m_ind_symbol, m_ind_timeframe, m_lsma_source, 0, BarsCustom(m_ind_symbol, m_ind_timeframe), applied_prices);
    LinRegOnBuffer(m_lsma_period, m_lsma_offset, applied_prices, linreg);
    ArraySetAsSeries(linreg, true);

    CIndicatorBuffer *linreg_buffer = At(0);
    linreg_buffer.AssignArray(linreg);
}
