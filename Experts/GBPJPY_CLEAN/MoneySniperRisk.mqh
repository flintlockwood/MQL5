//+------------------------------------------------------------------+
//|                                           MoneySniperRisk.mqh    |
//|                                                  Mufraeli Rahman |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mufraeli Rahman"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Expert/ExpertMoney.mqh>

//+------------------------------------------------------------------+
//| Sizing mode enumeration matching Pine Script inputs              |
//+------------------------------------------------------------------+
enum ENUM_POSITION_SIZING_TYPE {
    SIZING_RISK_EQUITY_PER_TRADE = 0, // Risk % of equity per trade
    SIZING_PERCENT_OF_EQUITY     = 1, // Percent of equity
    SIZING_FIXED_AMOUNT          = 2  // Fixed amount (lot size)
};

//+------------------------------------------------------------------+
//| Class CMoneySniperRisk                                           |
//| Purpose: Centralized money management reproducing Pine Script    |
//|          position sizing and risk models                         |
//+------------------------------------------------------------------+
class CMoneySniperRisk : public CExpertMoney {
protected:
    ENUM_POSITION_SIZING_TYPE m_sizing_type_long;
    double                    m_sizing_value_long;      // Buy sizing value (e.g. 5.75%)
    ENUM_POSITION_SIZING_TYPE m_sizing_type_short;
    double                    m_sizing_value_short;     // Sell sizing value (e.g. 5.25%)
    bool                      m_enable_night_session;   // nighte
    double                    m_night_session_pct;      // nightp

public:
                     CMoneySniperRisk(void);
                    ~CMoneySniperRisk(void);

    //--- Parameter setters
    void             SizingTypeLong(ENUM_POSITION_SIZING_TYPE value)  { m_sizing_type_long = value; }
    void             SizingValueLong(double value)                    { m_sizing_value_long = value; }
    void             SizingTypeShort(ENUM_POSITION_SIZING_TYPE value) { m_sizing_type_short = value; }
    void             SizingValueShort(double value)                   { m_sizing_value_short = value; }
    void             EnableNightSession(bool value)                   { m_enable_night_session = value; }
    void             NightSessionPct(double value)                    { m_night_session_pct = value; }

    virtual bool     ValidationSettings(void);
    virtual double   CheckOpenLong(double price, double sl);
    virtual double   CheckOpenShort(double price, double sl);
    virtual double   CheckClose(CPositionInfo *position, double price);
    virtual double   CheckReverse(CPositionInfo *position, double price);

protected:
    double           CalculateLotSize(double price, double sl, bool is_long);
    double           NormalizeLot(double lot);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMoneySniperRisk::CMoneySniperRisk(void)
    : m_sizing_type_long(SIZING_RISK_EQUITY_PER_TRADE),
      m_sizing_value_long(5.75),
      m_sizing_type_short(SIZING_RISK_EQUITY_PER_TRADE),
      m_sizing_value_short(5.25),
      m_enable_night_session(false),
      m_night_session_pct(0.10) {
    m_percent = 5.75;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMoneySniperRisk::~CMoneySniperRisk(void) {
}

//+------------------------------------------------------------------+
//| ValidationSettings                                               |
//+------------------------------------------------------------------+
bool CMoneySniperRisk::ValidationSettings(void) {
    if(!CExpertMoney::ValidationSettings())
        return(false);

    if(m_sizing_value_long <= 0 || m_sizing_value_short <= 0) {
        printf(__FUNCTION__ + ": Position sizing value must be positive");
        return(false);
    }
    return(true);
}

//+------------------------------------------------------------------+
//| Normalize lots to symbol volume min, max, step                   |
//+------------------------------------------------------------------+
double CMoneySniperRisk::NormalizeLot(double lot) {
    if(m_symbol == NULL)
        return(lot);

    double min_lot  = m_symbol.LotsMin();
    double max_lot  = m_symbol.LotsMax();
    double step_lot = m_symbol.LotsStep();

    if(step_lot <= 0)
        step_lot = 0.01;

    double normalized = MathFloor(lot / step_lot) * step_lot;
    if(normalized < min_lot)
        normalized = min_lot;
    if(normalized > max_lot)
        normalized = max_lot;

    int digits = 2;
    if(step_lot >= 1.0)
        digits = 0;
    else if(step_lot >= 0.1)
        digits = 1;

    return(NormalizeDouble(normalized, digits));
}

//+------------------------------------------------------------------+
//| Position size calculation                                        |
//+------------------------------------------------------------------+
double CMoneySniperRisk::CalculateLotSize(double price, double sl, bool is_long) {
    if(m_symbol == NULL)
        return(0.01);

    ENUM_POSITION_SIZING_TYPE sizing_type = is_long ? m_sizing_type_long : m_sizing_type_short;
    double sizing_val = is_long ? m_sizing_value_long : m_sizing_value_short;
    double equity = m_account.Equity();
    double calculated_lot = 0.01;

    switch(sizing_type) {
        case SIZING_RISK_EQUITY_PER_TRADE: {
            double diff_sl = MathAbs(price - sl);
            double point = m_symbol.Point();
            if(diff_sl <= point * 5.0)
                diff_sl = point * 50.0; // fallback 50 points if SL not given

            double tick_val = m_symbol.TickValue();
            if(tick_val <= 0)
                tick_val = 1.0;

            double loss_per_lot = (diff_sl / point) * tick_val;
            double risk_money = equity * (sizing_val / 100.0);

            if(loss_per_lot > 0)
                calculated_lot = risk_money / loss_per_lot;
            break;
        }

        case SIZING_PERCENT_OF_EQUITY: {
            double contract_size = m_symbol.ContractSize();
            if(contract_size <= 0)
                contract_size = 100000.0;
            calculated_lot = (equity * (sizing_val / 100.0)) / (price * contract_size);
            break;
        }

        case SIZING_FIXED_AMOUNT: {
            calculated_lot = sizing_val;
            break;
        }
    }

    // Night session adjustment
    if(m_enable_night_session) {
        calculated_lot += (calculated_lot * m_night_session_pct);
    }

    return(NormalizeLot(calculated_lot));
}

//+------------------------------------------------------------------+
//| CheckOpenLong                                                    |
//+------------------------------------------------------------------+
double CMoneySniperRisk::CheckOpenLong(double price, double sl) {
    return(CalculateLotSize(price, sl, true));
}

//+------------------------------------------------------------------+
//| CheckOpenShort                                                   |
//+------------------------------------------------------------------+
double CMoneySniperRisk::CheckOpenShort(double price, double sl) {
    return(CalculateLotSize(price, sl, false));
}

//+------------------------------------------------------------------+
//| CheckClose                                                       |
//+------------------------------------------------------------------+
double CMoneySniperRisk::CheckClose(CPositionInfo *position, double price) {
    if(position == NULL)
        return(0.0);
    return(position.Volume());
}

//+------------------------------------------------------------------+
//| CheckReverse                                                     |
//+------------------------------------------------------------------+
double CMoneySniperRisk::CheckReverse(CPositionInfo *position, double price) {
    if(position == NULL)
        return(0.01);
    bool is_long = (position.PositionType() == POSITION_TYPE_SELL);
    return(CalculateLotSize(price, 0.0, is_long));
}
