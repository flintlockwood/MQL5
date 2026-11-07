//+------------------------------------------------------------------+
//|                                             SignalATRTrailing.mq5 |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertSignal.mqh>
#include <MovingAverages.mqh>
#include "Helper.mqh"

class SignalATRTrailing: public CExpertSignal {
    protected:
        CSignalExporter   m_exporter;

        //--- adjusted parameters
        string            m_atr_symbol;
        int               m_atr_timeframe;
        int               m_atr_period_long;
        double            m_atr_multiplier_long;
        int               m_atr_period_short;
        double            m_atr_multiplier_short;
        bool              m_long_condition;
        bool              m_short_condition;

    public:
        SignalATRTrailing(void);
       ~SignalATRTrailing(void);

        //--- export methods
        void              EnableExport(bool enable, bool common_folder = false) { m_exporter.Enable(enable, common_folder); }
        void              ExportFilename(string filename)                       { m_exporter.SetFilename(filename); }
        void              ExportConditions(void) {
            datetime dt = (m_time != NULL && m_time.GetData(0) > 0) ? m_time.GetData(0) : iTime(m_symbol != NULL ? m_symbol.Name() : _Symbol, m_period, 0);
            m_exporter.Export(dt);
        }

        //--- methods of setting adjustable indicator parameters
        void              IndicatorSymbol(string value)        { m_atr_symbol=value;             }
        void              IndicatorTimeframe(int value)        { m_atr_timeframe=value;          }
        void              ATRPeriodLong(int value)             { m_atr_period_long=value;        }
        void              ATRMultiplierLong(double value)      { m_atr_multiplier_long=value;    }
        void              ATRPeriodShort(int value)            { m_atr_period_short=value;       }
        void              ATRMultiplierShort(double value)     { m_atr_multiplier_short=value;    }
        
        bool              Initialize(string symbol,int period,bool every_tick);        
        //--- method of verification of settings
        virtual bool      ValidationSettings(void);
        //--- methods of checking if the market models are formed
        virtual int       LongCondition(void);
        virtual int       ShortCondition(void);

    protected:
        void              CalculateCondition();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalATRTrailing::SignalATRTrailing(void) {
    //--- initialization of protected data
    m_used_series=USE_SERIES_OPEN+USE_SERIES_HIGH+USE_SERIES_LOW+USE_SERIES_CLOSE;
    m_exporter.SetFilename("SignalATRTrailing.csv");
    m_atr_symbol="";
    m_atr_timeframe=PERIOD_CURRENT;
    m_atr_period_long=10;
    m_atr_multiplier_long=3.6;
    m_atr_period_short=6;
    m_atr_multiplier_short=2.2;
    m_long_condition=false;
    m_short_condition=false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalATRTrailing::~SignalATRTrailing(void){
}

bool SignalATRTrailing::Initialize(string symbol,int period,bool every_tick) {
    if(m_symbol==NULL) {
        if((m_symbol=new CSymbolInfo)==NULL)
            return(false);
    }
    if(!m_symbol.Name(symbol))
        return(false);
    m_period    =period;
    m_every_tick=every_tick;
    if(m_atr_symbol=="")
        m_atr_symbol = symbol;
    if(m_atr_timeframe<=0)
        m_atr_timeframe = period;

    CExpertBase::Init(m_symbol, (ENUM_TIMEFRAMES)period, 1);

    return (true);
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool SignalATRTrailing::ValidationSettings(void) {
    //--- validation settings of additional filters
    if(!CExpertSignal::ValidationSettings())
        return(false);
    if(m_atr_period_long<=0 || m_atr_period_short<=0) {
        printf(__FUNCTION__+": period ATR must be greater than 0");
        return(false);
    }
    //--- ok
    return(true);
}

void SignalATRTrailing::CalculateCondition() {
    MqlRates rates[];
    double close[];
    double tr_array[];
    double atr_array_long[];
    double atr_array_short[];
    int bars = BarsCustom(m_symbol.Name(), m_period);
    CopyRatesCustom(m_symbol.Name(), m_period, 0, bars, rates);
    CopyCloseFromMqlRates(rates, close);
    CopyTR(m_symbol.Name(), m_period, 0, bars, tr_array);
    InitializeArray(atr_array_short, ArraySize(tr_array), EMPTY_VALUE);
    MAOnBuffer(ArraySize(tr_array), 0, 0, m_atr_period_long, MODE_SMMA, tr_array, atr_array_long);
    MAOnBuffer(ArraySize(tr_array), 0, 0, m_atr_period_short, MODE_SMMA, tr_array, atr_array_short);

    double xATRTrailingStop = 0;
    double xATRTrailingStops = 0;
    double prev_xATRTrailingStop = 0;
    double prev_xATRTrailingStops = 0;
    double pos = 6;
    double poss = 6;
    double prev_pos = 0;
    double prev_poss = 0;
    for (int i=1; i<ArraySize(atr_array_long); i++) {
        double nLoss = atr_array_long[i] * m_atr_multiplier_long;
        double iff_1F = close[i] > prev_xATRTrailingStops ? close[i] - nLoss : close[i] + nLoss;
        double iff_2F = close[i] < prev_xATRTrailingStops && close[i-1] < prev_xATRTrailingStops ? MathMin(prev_xATRTrailingStops, close[i] + nLoss) : iff_1F;
        xATRTrailingStop = close[i] > prev_xATRTrailingStops && close[i-1] > prev_xATRTrailingStops ? MathMax(prev_xATRTrailingStops, close[i] - nLoss) : iff_2F;
        double iff_3F = close[i-1] > prev_xATRTrailingStops && close[i] < prev_xATRTrailingStops ? -1 : prev_pos;
        pos = close[i-1] < prev_xATRTrailingStops && close[i] > prev_xATRTrailingStops ? 1 : iff_3F;
        prev_xATRTrailingStop = xATRTrailingStop;

        double nLosss = atr_array_short[i] * m_atr_multiplier_short;
        double iff_1Fs = close[i] > prev_xATRTrailingStops ? close[i] - nLosss : close[i] + nLosss;
        double iff_2Fs = close[i] < prev_xATRTrailingStops && close[i-1] < prev_xATRTrailingStops ? MathMin(prev_xATRTrailingStops, close[i] + nLosss) : iff_1Fs;
        xATRTrailingStops = close[i] > prev_xATRTrailingStops && close[i-1] > prev_xATRTrailingStops ? MathMax(prev_xATRTrailingStops, close[i] - nLosss) : iff_2Fs;
        double iff_3Fs = close[i-1] > prev_xATRTrailingStops && close[i] < prev_xATRTrailingStops ? -1 : prev_poss;
        poss = close[i-1] < prev_xATRTrailingStops && close[i] > prev_xATRTrailingStops ? 1 : iff_3Fs;
        prev_xATRTrailingStops = xATRTrailingStops;
    }

    m_long_condition = pos == 1 && poss != -1;
    m_short_condition = poss == -1 && pos != 1;
}

//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int SignalATRTrailing::LongCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    CalculateCondition();

    result = m_long_condition ? 100 : 0;
    m_exporter.UpdateLong(result);
    ExportConditions();

    //--- return the result
    return(result);
}

//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int SignalATRTrailing::ShortCondition(void) {
    int result=0;
    int idx   =StartIndex();
    
    CalculateCondition();
    
    result = m_short_condition ? 100 : 0;
    m_exporter.UpdateShort(result);
    ExportConditions();

    //--- return the result
    return(result);
}
//+------------------------------------------------------------------+
