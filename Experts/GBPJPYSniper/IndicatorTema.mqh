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

class CiTema: public CIndicator {
    protected:
        string            m_ind_symbol;
        int               m_ind_timeframe;
        int               m_tema_period;
        ENUM_APPLIED_PRICE m_applied;

    public:
        CiTema(void);
        ~CiTema(void);

        //--- methods to set to protected data
        void            IndSymbol(string value) { m_ind_symbol = value; }
        void            IndTimeframe(int value) { m_ind_timeframe = value; }
        void            TemaPeriod(int value) { m_tema_period = value;  }
        void            Applied(ENUM_APPLIED_PRICE value) { m_applied = value; }
        
        //--- method of creation
        bool            Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]);
        bool            Create(const string symbol,const int period,
                            const int tema_period,
                            const ENUM_APPLIED_PRICE applied);
        
        //--- methods of access to indicator data
        double          GetData(const int buffer_num,const int index);
        int             GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]);
        double          Tema(const int index);
        virtual void    Refresh(const int flags=OBJ_ALL_PERIODS);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiTema::CiTema(void) : m_ind_symbol("GBPJPY"),
                   m_ind_timeframe(PERIOD_M30),
                   m_tema_period(72),
                   m_applied(PRICE_OPEN) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiTema::~CiTema(void) {
}

//+------------------------------------------------------------------+
//| Create indicator                                                 |
//+------------------------------------------------------------------+
bool CiTema::Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const ENUM_INDICATOR type,const int num_params,const MqlParam &params[]) {
    return(Create(params[1].string_value, (int)params[2].integer_value, 
                    (int)params[3].integer_value,
                    (ENUM_APPLIED_PRICE)params[4].integer_value));
}

bool CiTema::Create(const string symbol,const int period,
                        const int tema_period, const ENUM_APPLIED_PRICE applied) {
//--- we do not need to create indicator here
    if(Reserve(3)) {
        //--- string of status of drawing
        m_name  ="ST";
        m_status="("+symbol+","+PeriodDescription()+","+
               IntegerToString(tema_period)+","+
               ","+PriceDescription(applied)+")";
        //--- save settings
        m_ind_symbol = symbol;
        m_ind_timeframe = period;
        m_tema_period=tema_period;
        m_applied  =applied;
        //--- create buffers
        CIndicatorBuffer *tema_buffer = new CIndicatorBuffer();
        tema_buffer.Name("Tema");
        Add(tema_buffer);
        //--- ok
        return(true);
    }
    return(false);
}

//+------------------------------------------------------------------+
//| Access to linear regression buffer                               |
//+------------------------------------------------------------------+
double CiTema::Tema(const int index) {
    CIndicatorBuffer *buffer=At(0);
    //--- check
    if(buffer==NULL)
        return(EMPTY_VALUE);
    //---
    return(buffer.At(index));
}

double CiTema::GetData(const int buffer_num,const int index) {
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
int CiTema::GetData(const int start_pos,const int count,const int buffer_num,double &buffer[]) {
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
void CiTema::Refresh(const int flags=OBJ_ALL_PERIODS) {
    double applied_prices[];
    double ema1[];
    double ema2[];
    double ema3[];
    double tema[];
    CopyAppliedPrice(m_ind_symbol, m_ind_timeframe, m_applied, 0, BarsCustom(m_ind_symbol, m_ind_timeframe), applied_prices);
    InitializeArray(ema1, ArraySize(applied_prices), EMPTY_VALUE);
    InitializeArray(ema2, ArraySize(applied_prices), EMPTY_VALUE);
    InitializeArray(ema3, ArraySize(applied_prices), EMPTY_VALUE);
    InitializeArray(tema, ArraySize(applied_prices), EMPTY_VALUE);
    ExponentialMAOnBuffer(ArraySize(applied_prices), 0, 0, m_tema_period, applied_prices, ema1);
    ExponentialMAOnBuffer(ArraySize(applied_prices), 0, 0, m_tema_period, ema1, ema2);
    ExponentialMAOnBuffer(ArraySize(applied_prices), 0, 0, m_tema_period, ema2, ema3);

    for (int i=0; i<ArraySize(applied_prices); i++) {
        if (ema1[i] == EMPTY_VALUE || ema2[i] == EMPTY_VALUE || ema3[i] == EMPTY_VALUE) {
            continue;
        }
        tema[i] = 3 * ema1[i] - 3 * ema2[i] + ema3[i];
    }

    CIndicatorBuffer *linreg_buffer = At(0);
    linreg_buffer.AssignArray(tema);
}
