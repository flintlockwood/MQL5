//+------------------------------------------------------------------+
//|                                                       Helper.mqh |
//|                                                  Mufraeli Rahman |
//|                                                     www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Indicators/Series.mqh>
#include "Helper.mqh"

class COpenBufferCustom: public CDoubleBuffer {
    public:
        COpenBufferCustom(void);
        ~COpenBufferCustom(void);
        //--- method of refreshing of the data buffer
        virtual bool Refresh(void);
        virtual bool RefreshCurrent(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COpenBufferCustom::COpenBufferCustom(void) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
COpenBufferCustom::~COpenBufferCustom(void) {
}

//+------------------------------------------------------------------+
//| Refreshing of the data buffer                                    |
//+------------------------------------------------------------------+
bool COpenBufferCustom::Refresh(void) {
    if ((int)m_period < 100) {
        double low_array[];
        double high_array[];
        double close_array[];
        int bars = Bars(m_symbol, m_period);

        CopyLow(m_symbol, m_period, 0, bars, low_array);
        CopyHigh(m_symbol, m_period, 0, bars, high_array);
        CopyClose(m_symbol, m_period, 0, bars, close_array);
        
        InitializeArray(m_data, bars, EMPTY_VALUE);
        for (int i=0; i<ArraySize(high_array); i++) {
            m_data[i] = MathMax(MathMax(high_array[i] - low_array[i], MathAbs(high_array[i] - close_array[i])), MathAbs(low_array[i] - close_array[i]));
        }
    }
    else {
        MqlRates rates[];
        CopyRatesCustom(m_symbol, m_period, 0, rates);

        for (int i=0; i<ArraySize(rates); i++) {
            m_data.Add(MathMax(MathMax(rates[i].high - rates[i].low, MathAbs(rates[i].high - rates[i].close)), MathAbs(rates[i].low - rates[i].close)));
        }
    }

    m_data_total=ArraySize(m_data);
    //---
    return(m_data_total>0);
}

//+------------------------------------------------------------------+
//| Refreshing of the data buffer                                    |
//+------------------------------------------------------------------+
bool COpenBufferCustom::RefreshCurrent(void) {
    return Refresh();
}
