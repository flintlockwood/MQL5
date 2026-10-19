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

class CiLinearRegression: public CIndicator {
    protected:
        int             m_lsma_period;
        int             m_lsma_offset;
        ENUM_APPLIED_PRICE m_lsma_source;

    public:
        CiLinearRegression(void);
       ~CiLinearRegression(void);

        //--- methods to set to protected data
        void            Symbol(string value) { m_symbol = value; }
        void            Period(int value) { m_period = value; }
        void            LsmaPeriod(int value) { m_lsma_period = value;  }
        void            LsmaOffset(int value) { m_lsma_offset = value; }
        void            LsmaSource(ENUM_APPLIED_PRICE value) { m_lsma_source = value; }
        
        //--- method of creation
        bool            Initialize(const string symbol,const int timeframe);
        
        //--- methods of access to indicator data
        double          GetData(const int buffer_num,const int index);
        int             GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]);
        double          LinReg(const int index);
        virtual void    Refresh(const int flags=OBJ_ALL_PERIODS);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiLinearRegression::CiLinearRegression(void) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiLinearRegression::~CiLinearRegression(void) {
}

//+------------------------------------------------------------------+
//| Create indicator                                                 |
//+------------------------------------------------------------------+
bool CiLinearRegression::Initialize(const string symbol,const int timeframe) {
//--- we do not need to create indicator here
    if(!Reserve(1)) {
        return false;
    }
    //--- save settings
    m_symbol = symbol;
    m_period = timeframe;

    //--- create buffers
    CIndicatorBuffer *lr_buffer = new CIndicatorBuffer();
    lr_buffer.Name("LSMA");
    Add(lr_buffer);
    m_buffers_total=1;
    
    //--- ok
    return(true);
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
    CopyAppliedPrice(m_symbol, m_period, m_lsma_source, 0, BarsCustom(m_symbol, m_period), applied_prices);
    LinRegOnBuffer(m_lsma_period, m_lsma_offset, applied_prices, linreg);
    ArraySetAsSeries(linreg, true);

    CIndicatorBuffer *linreg_buffer = At(0);
    linreg_buffer.AssignArray(linreg);
}
