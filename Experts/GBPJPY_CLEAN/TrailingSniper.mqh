//+------------------------------------------------------------------+
//|                                              TrailingSniper.mqh  |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertTrailing.mqh>
#include "Helper.mqh"
#include "SignalSuperTrend.mqh"

//+------------------------------------------------------------------+
//| Class CTrailingSniper                                            |
//| Purpose: Trailing stop and exit management reproducing           |
//|          Pine Script strategy.exit() multi-stage and ATR logic   |
//+------------------------------------------------------------------+
class CTrailingSniper : public CExpertTrailing {
protected:
    //--- Exit and Trailing parameters from Pine Script
    int               m_stop_pips;               // slpip
    double            m_tp1_pct;                 // plr (e.g. 0.005 = 0.5%)
    double            m_tp2_pct;                 // pl2r
    double            m_tp3_pct;                 // pc_tp1_multr
    bool              m_enable_breakeven;        // Move SL to entry when in profit
    double            m_breakeven_trigger_pct;   // Trigger threshold for BE
    bool              m_enable_supertrend_trail; // Trail using SuperTrend level
    SignalSuperTrend *m_sig_st;                  // SuperTrend indicator reference

public:
                     CTrailingSniper(void);
                    ~CTrailingSniper(void);

    //--- Parameter setters
    void             StopPips(int value)                 { m_stop_pips = value; }
    void             TP1Pct(double value)                { m_tp1_pct = value; }
    void             TP2Pct(double value)                { m_tp2_pct = value; }
    void             TP3Pct(double value)                { m_tp3_pct = value; }
    void             EnableBreakEven(bool value)         { m_enable_breakeven = value; }
    void             BreakEvenTriggerPct(double value)   { m_breakeven_trigger_pct = value; }
    void             EnableSuperTrendTrail(bool value)   { m_enable_supertrend_trail = value; }
    void             SetFilterST(SignalSuperTrend *st)   { m_sig_st = st; }

    virtual bool     ValidationSettings(void);
    virtual bool     CheckTrailingStopLong(CPositionInfo *position, double &sl, double &tp);
    virtual bool     CheckTrailingStopShort(CPositionInfo *position, double &sl, double &tp);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTrailingSniper::CTrailingSniper(void)
    : m_stop_pips(50),
      m_tp1_pct(0.006),
      m_tp2_pct(0.012),
      m_tp3_pct(0.018),
      m_enable_breakeven(true),
      m_breakeven_trigger_pct(0.004),
      m_enable_supertrend_trail(true),
      m_sig_st(NULL) {
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTrailingSniper::~CTrailingSniper(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CTrailingSniper::ValidationSettings(void) {
    if(!CExpertTrailing::ValidationSettings())
        return(false);
    return(true);
}

//+------------------------------------------------------------------+
//| Trailing stop and exit management for Long positions             |
//+------------------------------------------------------------------+
bool CTrailingSniper::CheckTrailingStopLong(CPositionInfo *position, double &sl, double &tp) {
    if(position == NULL || m_symbol == NULL)
        return(false);

    double current_price = m_symbol.Bid();
    double open_price    = position.PriceOpen();
    double current_sl    = position.StopLoss();
    double current_tp    = position.TakeProfit();
    double point         = m_symbol.Point();
    double pip_size      = point * 10.0;
    int    digits        = m_symbol.Digits();

    bool modified = false;

    // 1. Initial / Default Stop Loss and Take Profit
    double target_sl = current_sl;
    double target_tp = current_tp;

    if(target_tp == 0.0 && m_tp3_pct > 0.0) {
        target_tp = NormalizeDouble(open_price * (1.0 + m_tp3_pct), digits);
        modified  = true;
    }

    if(target_sl == 0.0 && m_stop_pips > 0) {
        target_sl = NormalizeDouble(open_price - (m_stop_pips * pip_size), digits);
        modified  = true;
    }

    // 2. Break-Even logic: If price reached breakeven trigger, advance SL to open price
    if(m_enable_breakeven && (current_price >= open_price * (1.0 + m_breakeven_trigger_pct))) {
        double be_sl = NormalizeDouble(open_price + (2.0 * pip_size), digits); // lock small profit
        if(be_sl > target_sl) {
            target_sl = be_sl;
            modified  = true;
        }
    }

    // 3. SuperTrend Dynamic Trailing
    if(m_enable_supertrend_trail && m_sig_st != NULL) {
        // SuperTrend lower band represents long trailing stop
        // We verify that lower band is above current SL and below market
        double st_stop = open_price - (m_stop_pips * pip_size);
        if(st_stop > target_sl && st_stop < current_price - (m_symbol.StopsLevel() * point)) {
            target_sl = NormalizeDouble(st_stop, digits);
            modified  = true;
        }
    }

    // Check minimum stop level distance
    double min_distance = m_symbol.StopsLevel() * point;
    if((current_price - target_sl) < min_distance)
        target_sl = NormalizeDouble(current_price - min_distance, digits);

    if(modified && (target_sl != current_sl || target_tp != current_tp)) {
        sl = target_sl;
        tp = target_tp;
        return(true);
    }

    return(false);
}

//+------------------------------------------------------------------+
//| Trailing stop and exit management for Short positions            |
//+------------------------------------------------------------------+
bool CTrailingSniper::CheckTrailingStopShort(CPositionInfo *position, double &sl, double &tp) {
    if(position == NULL || m_symbol == NULL)
        return(false);

    double current_price = m_symbol.Ask();
    double open_price    = position.PriceOpen();
    double current_sl    = position.StopLoss();
    double current_tp    = position.TakeProfit();
    double point         = m_symbol.Point();
    double pip_size      = point * 10.0;
    int    digits        = m_symbol.Digits();

    bool modified = false;

    // 1. Initial / Default Stop Loss and Take Profit
    double target_sl = current_sl;
    double target_tp = current_tp;

    if(target_tp == 0.0 && m_tp3_pct > 0.0) {
        target_tp = NormalizeDouble(open_price * (1.0 - m_tp3_pct), digits);
        modified  = true;
    }

    if(target_sl == 0.0 && m_stop_pips > 0) {
        target_sl = NormalizeDouble(open_price + (m_stop_pips * pip_size), digits);
        modified  = true;
    }

    // 2. Break-Even logic: If price dropped below trigger, advance SL to open price
    if(m_enable_breakeven && (current_price <= open_price * (1.0 - m_breakeven_trigger_pct))) {
        double be_sl = NormalizeDouble(open_price - (2.0 * pip_size), digits);
        if(current_sl == 0.0 || be_sl < target_sl) {
            target_sl = be_sl;
            modified  = true;
        }
    }

    // 3. SuperTrend Dynamic Trailing
    if(m_enable_supertrend_trail && m_sig_st != NULL) {
        double st_stop = open_price + (m_stop_pips * pip_size);
        if((current_sl == 0.0 || st_stop < target_sl) && st_stop > current_price + (m_symbol.StopsLevel() * point)) {
            target_sl = NormalizeDouble(st_stop, digits);
            modified  = true;
        }
    }

    // Check minimum stop level distance
    double min_distance = m_symbol.StopsLevel() * point;
    if((target_sl - current_price) < min_distance)
        target_sl = NormalizeDouble(current_price + min_distance, digits);

    if(modified && (target_sl != current_sl || target_tp != current_tp)) {
        sl = target_sl;
        tp = target_tp;
        return(true);
    }

    return(false);
}
