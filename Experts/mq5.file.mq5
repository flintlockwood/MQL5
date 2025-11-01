//+------------------------------------------------------------------+
//| Gold Scalping Bot - Verbesserte Version                         |
//| Entwickelt für MetaTrader 5 (MT5)                               |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>
CTrade trade;

//--- General Bot Settings
input group "General Settings"
input double LotSize             = 0.02;     // Standard Lot Size (0 ==  Dynamic lot size)
input double RiskPerTrade        = 2.0;      // Dynamic Risk per trade (% of balance)
input double DailyProfitTarget   = 0.0;      // Daily profit target (%)
input double DailyMaxRiskPercent = 0.0;      // Daily loss Limit (%)
input bool CloseOppositePositions= true;     // Close opposite positions when signal changes
input bool DetailedLogging       = false;    // Enable detailed trade logging
input int MaxOpenPositions       = 0;        // Maximum open positions (0 == Not Limit)
//--- Entry Conditions
input group "Entry & Filter Conditions"
input ENUM_TIMEFRAMES TimeFrame  = PERIOD_CURRENT; // Timeframe for indicators
input double MaxSpread           = 50;       // Maximum spread in points
//--- Indicators Parameters
input group "Indicator Settings"
input int EMA_Fast               = 50;       // Fast EMA period
input int EMA_Slow               = 200;      // Slow EMA period
input int MACD_Fast              = 12;       // MACD fast period
input int MACD_Slow              = 26;       // MACD slow period
input int MACD_Signal            = 9;        // MACD signal period (0 == Not Use)
input int RSI_Period             = 14;       // RSI period (0 == Not Use)
input int ADX_Period             = 14;       // ADX period (0 == Not Use)
//--- Exit Conditions
input group "Stop Loss & Take Profit"
input double StopLossPips        = 100.0;    // Stop Loss in Pips
input double TakeProfitPips      = 100.0;    // Take Profit in Pips
//--- Trailing Stop Settings
input group "Trailing Stop Settings"
input double TrailingStopPips    = 50.0;     // Trailing Stop in Pips (0 == Not Use)
input double TrailingStopActivationPips= 100.0; // Activate trailing stop after X pips in profit
input double MinimumTrailingStopChange = 20.0;  // Minimum change to modify trailing stop (pips)
//--- Partial Close Settings
input group "Partial Close Settings"
input double ClosePercent           = 0.0;   // Percentage to close (% of Lots) (0 == Not Use)
input double PartialClosePipPercent = 50.0;  // Percentage of TP1 Pips(% from Final TP Pips)
//--- Trading Hours
input group "Trading Hours"
input int TradeStartHour         = 0;        // Start trading hour (0-23)
input int TradeEndHour           = 23;       // End trading hour (0-23)
//---
// Global
bool UseMACD = MACD_Signal != 0;          // Use MACD filter
bool UseRSI = RSI_Period != 0;            // Use RSI filter
bool UseADX = ADX_Period != 0;            // Use ADX filter
bool UseDynamicLotSize = LotSize<=0;      // Use dynamic lot size based on risk
bool UseTrailingStop = TrailingStopPips>0;// Use trailing stop
double PartialClosePips = TakeProfitPips * (PartialClosePipPercent/100); // Pips for partial close (TP1)

bool TradingStopped = false;
// Record expected lot sizes for new positions
double ExpectedLotSize = 0.0;
// For new candle detection
datetime LastCandleTime = 0;
// For today's date tracking
datetime TodayDate = 0;

// Indicator handles
int EMA_Fast_Handle;
int EMA_Slow_Handle;
int MACD_Handle;
int RSI_Handle;
int ADX_Handle;

//+------------------------------------------------------------------+
// EMA calculation
//+------------------------------------------------------------------+
double CalculateEMA(int period, int shift)
  {
   int handle = (period == EMA_Fast) ? EMA_Fast_Handle : EMA_Slow_Handle;
   double ema_buffer[];
   ArraySetAsSeries(ema_buffer, true);

// Always use shift+1 to get the closed candle value
   if(CopyBuffer(handle, 0, shift + 1, 1, ema_buffer) > 0)
      return ema_buffer[0];

   return 0.0;
  }

//+------------------------------------------------------------------+
// MACD calculation
//+------------------------------------------------------------------+
void CalculateMACD(double &macd_main, double &macd_signal)
  {
   double macd_buffer[];
   double signal_buffer[];

   ArraySetAsSeries(macd_buffer, true);
   ArraySetAsSeries(signal_buffer, true);

// Always use closed candle values (shift=1)
   if(CopyBuffer(MACD_Handle, 0, 1, 1, macd_buffer) > 0 &&
      CopyBuffer(MACD_Handle, 1, 1, 1, signal_buffer) > 0)
     {
      macd_main = macd_buffer[0];
      macd_signal = signal_buffer[0];
     }
   else
     {
      macd_main = 0;
      macd_signal = 0;
     }
  }

//+------------------------------------------------------------------+
// RSI calculation
//+------------------------------------------------------------------+
double CalculateRSI(int period)
  {
   double rsi_buffer[];
   ArraySetAsSeries(rsi_buffer, true);

// Use closed candle value (shift=1)
   if(CopyBuffer(RSI_Handle, 0, 1, 1, rsi_buffer) > 0)
      return rsi_buffer[0];

   return 0.0;
  }

//+------------------------------------------------------------------+
// ADX calculation
//+------------------------------------------------------------------+
double CalculateADX(int period)
  {
   double adx_buffer[];
   ArraySetAsSeries(adx_buffer, true);

// Use closed candle value (shift=1)
   if(CopyBuffer(ADX_Handle, 0, 1, 1, adx_buffer) > 0)
      return adx_buffer[0];

   return 0.0;
  }
//+------------------------------------------------------------------+
// Spread filter
//+------------------------------------------------------------------+
bool CheckSpread()
  {
   if(MaxSpread==0)
      return true;
      
   double spread = (double)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   if(spread > MaxSpread)
     {
      if(DetailedLogging)
         Print("Spread too high: ", spread, " > ", MaxSpread);
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
// Check trading times
//+------------------------------------------------------------------+
bool CheckTradingTime()
  {
   if(TradeStartHour==0 && TradeEndHour==23)
      return true;
      
   MqlDateTime current_time;
   if(!TimeToStruct(TimeCurrent(), current_time))
     {
      Print("Error getting current time: ", GetLastError());
      return false;
     }

   int currentHour = current_time.hour;
   bool isValidTime = (currentHour >= TradeStartHour && currentHour < TradeEndHour);

   if(!isValidTime && DetailedLogging)
      Print("Outside trading hours: ", currentHour, " (Trading hours: ", TradeStartHour, "-", TradeEndHour, ")");

   return isValidTime;
  }

//+------------------------------------------------------------------+
// Check if a new trading day has started
//+------------------------------------------------------------------+
bool IsNewTradingDay()
  {
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);

// Create a datetime for today's date with time set to 00:00
   MqlDateTime today_struct;
   today_struct.year = current_time.year;
   today_struct.mon = current_time.mon;
   today_struct.day = current_time.day;
   today_struct.hour = 0;
   today_struct.min = 0;
   today_struct.sec = 0;

   datetime today_date = StructToTime(today_struct);

// If we're in a new day
   if(today_date > TodayDate)
     {
      if(DetailedLogging)
         Print("New trading day detected: ", TimeToString(today_date));

      TodayDate = today_date;
      TradingStopped = false; // Reset trading stopped flag for new day
      return true;
     }

   return false;
  }

// Calculate today's closed trades profit/loss
double CalculateTodayClosedTradesProfit()
  {
// Get today's date at 00:00
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   MqlDateTime today_struct;
   today_struct.year = now.year;
   today_struct.mon = now.mon;
   today_struct.day = now.day;
   today_struct.hour = 0;
   today_struct.min = 0;
   today_struct.sec = 0;

   datetime today_start = StructToTime(today_struct);
   datetime now_time = TimeCurrent();

// Select history for today
   if(!HistorySelect(today_start, now_time))
     {
      Print("Error selecting history: ", GetLastError());
      return 0.0;
     }

// Calculate profit/loss from closed trades today
   double totalProfit = 0.0;
   int totalDeals = HistoryDealsTotal();

   for(int i = 0; i < totalDeals; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket <= 0)
         continue;

      // Check if it's our symbol
      string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      if(dealSymbol != Symbol())
         continue;

      // Only consider closed positions
      long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_INOUT)
        {
         double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         totalProfit += dealProfit;
        }
     }

   return totalProfit;
  }

// Check risk management - simplified version based on closed trades
bool CheckRiskManagement()
  {
//---
   if(DailyProfitTarget==0 && DailyMaxRiskPercent==0)
      return true;
      
// Check if it's a new trading day to reset TradingStopped flag
   IsNewTradingDay();

// If trading is already stopped, exit
   if(TradingStopped)
     {
      if(DetailedLogging)
         Print("Trading stopped for today");
      return false;
     }

// Calculate profit/loss from today's closed trades
   double todayProfit = CalculateTodayClosedTradesProfit();
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double profitPercent = (todayProfit / accountBalance) * 100.0;

// Check if profit target is reached
   if(profitPercent >= DailyProfitTarget)
     {
      if(!TradingStopped)
         Print("Stopping trading - Daily profit target reached: ", profitPercent, "% >= ", DailyProfitTarget, "%");
      TradingStopped = true;
      return false;
     }

// Check if max daily loss is reached (negative profit)
   if(profitPercent <= -MathAbs(DailyMaxRiskPercent))
     {
      if(!TradingStopped)
         Print("Stopping trading - Max daily loss reached: ", profitPercent, "% <= -", DailyMaxRiskPercent, "%");
      TradingStopped = true;
      return false;
     }

   if(DetailedLogging)
      Print("Daily risk check: Today's closed trades profit = ", todayProfit,
            ", Profit percent = ", profitPercent, "% of balance ", accountBalance);

   return true;
  }

// Calculate dynamic lot size based on risk
double CalculateDynamicLotSize(double stopLossPips)
  {
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

   if(stopLossPips <= 0)
      return LotSize;

// Calculate risk amount in account currency
   double riskAmount = accountBalance * RiskPerTrade / 100;

// Convert pips to points for proper calculation
   double stopLossPoints = stopLossPips * 10;

// Calculate pip value for 1 lot
   double pipValue = tickValue * (point / tickSize);

// Calculate lot size based on risk
   double lotSizeByRisk = riskAmount / (stopLossPoints * pipValue);

// Round to lotStep
   lotSizeByRisk = MathFloor(lotSizeByRisk / lotStep) * lotStep;

   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);

// Check min/max lot sizes
   if(lotSizeByRisk < minLot)
      lotSizeByRisk = minLot;
   if(lotSizeByRisk > maxLot)
      lotSizeByRisk = maxLot;

   if(DetailedLogging)
      Print("Dynamic lot calculation: Account=", accountBalance, ", Risk=", riskAmount,
            ", SL pips=", stopLossPips, ", Points=", stopLossPoints,
            ", Pip value=", pipValue, ", Lot size=", lotSizeByRisk);

   return lotSizeByRisk;
  }

// Convert pips to price points
double PipsToPoints(double pips)
  {
   return pips * 10 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
  }

// Apply trailing stop loss
void ApplyTrailingStop()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == Symbol())
           {
            double trailingStop = PipsToPoints(TrailingStopPips);
            double activationDistance = PipsToPoints(TrailingStopActivationPips);
            double minChange = PipsToPoints(MinimumTrailingStopChange);

            double currentSL = PositionGetDouble(POSITION_SL);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               // Check if we are in enough profit to activate trailing stop
               if(currentPrice - openPrice >= activationDistance)
                 {
                  double newSL = currentPrice - trailingStop;
                  if(newSL > currentSL && MathAbs(newSL - currentSL) >= minChange)
                    {
                     if(trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
                       {
                        if(DetailedLogging)
                           Print("Trailing stop for Buy position ", ticket, " updated to ", newSL);
                       }
                     else
                       {
                        Print("Error modifying Buy position ", ticket, ": ", GetLastError());
                       }
                    }
                 }
              }
            else
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                 {
                  // Check if we are in enough profit to activate trailing stop
                  if(openPrice - currentPrice >= activationDistance)
                    {
                     double newSL = currentPrice + trailingStop;
                     if(currentSL == 0 || (newSL < currentSL && MathAbs(newSL - currentSL) >= minChange))
                       {
                        if(trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
                          {
                           if(DetailedLogging)
                              Print("Trailing stop for Sell position ", ticket, " updated to ", newSL);
                          }
                        else
                          {
                           Print("Error modifying Sell position ", ticket, ": ", GetLastError());
                          }
                       }
                    }
                 }
           }
        }
     }
  }

// Check if position has already been partially closed by comparing current lot size with expected lot size
bool IsPositionPartiallyClosedBefore(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      double currentVolume = PositionGetDouble(POSITION_VOLUME);

      // Calculate expected lot size based on current settings
      double expectedLotSize = UseDynamicLotSize ?
                               CalculateDynamicLotSize(StopLossPips) :
                               LotSize;

      // If current volume is less than expected (with some tolerance for rounding issues)
      // Consider it as partially closed
      if(currentVolume < (expectedLotSize * 0.95))
        {
         if(DetailedLogging)
            Print("Position ", ticket, " identified as partially closed: Current volume ",
                  currentVolume, " vs Expected ", expectedLotSize);
         return true;
        }
     }
   return false;
  }

// Check for partial close
void CheckPartialClose()
  {
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);

   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == Symbol())
           {
            // Skip if position was already partially closed
            if(IsPositionPartiallyClosedBefore(ticket))
               continue;

            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double partialCloseDistance = PipsToPoints(PartialClosePips);

            // If position is in profit and we haven't closed part yet
            if(profit > 0)
              {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                 {
                  if(currentPrice >= openPrice + partialCloseDistance)
                    {
                     // Calculate close volume and round it to the nearest valid lot step
                     double closeVolume = volume * (ClosePercent / 100.0);
                     closeVolume = MathFloor(closeVolume / lotStep) * lotStep;

                     // Ensure the close volume is within allowed limits
                     if(closeVolume < minLot)
                        closeVolume = minLot;
                     if(closeVolume > maxLot)
                        closeVolume = maxLot;

                     // Ensure remaining volume will be valid
                     double remainingVolume = volume - closeVolume;
                     if(remainingVolume < minLot)
                       {
                        closeVolume = volume; // Close entire position if remainder would be too small
                       }

                     if(DetailedLogging)
                        Print("Attempting to close Buy position ", ticket,
                              ", Total volume: ", volume,
                              ", Close volume: ", closeVolume,
                              ", Remaining: ", remainingVolume);

                     if(closeVolume > 0 && closeVolume <= volume)
                       {
                        if(trade.PositionClosePartial(ticket, closeVolume))
                          {
                           if(DetailedLogging)
                              Print("Partially closed Buy position ", ticket, ", volume: ", closeVolume);
                          }
                        else
                          {
                           Print("Error partially closing Buy position ", ticket, ": ", GetLastError(),
                                 ", Volume: ", closeVolume);
                          }
                       }
                    }
                 }
               else
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                    {
                     if(currentPrice <= openPrice - partialCloseDistance)
                       {
                        // Calculate close volume and round it to the nearest valid lot step
                        double closeVolume = volume * (ClosePercent / 100.0);
                        closeVolume = MathFloor(closeVolume / lotStep) * lotStep;

                        // Ensure the close volume is within allowed limits
                        if(closeVolume < minLot)
                           closeVolume = minLot;
                        if(closeVolume > maxLot)
                           closeVolume = maxLot;

                        // Ensure remaining volume will be valid
                        double remainingVolume = volume - closeVolume;
                        if(remainingVolume < minLot)
                          {
                           closeVolume = volume; // Close entire position if remainder would be too small
                          }

                        if(DetailedLogging)
                           Print("Attempting to close Sell position ", ticket,
                                 ", Total volume: ", volume,
                                 ", Close volume: ", closeVolume,
                                 ", Remaining: ", remainingVolume);

                        if(closeVolume > 0 && closeVolume <= volume)
                          {
                           if(trade.PositionClosePartial(ticket, closeVolume))
                             {
                              if(DetailedLogging)
                                 Print("Partially closed Sell position ", ticket, ", volume: ", closeVolume);
                             }
                           else
                             {
                              Print("Error partially closing Sell position ", ticket, ": ", GetLastError(),
                                    ", Volume: ", closeVolume);
                             }
                          }
                       }
                    }
              }
           }
        }
     }
  }

// Close all buy or sell positions
void CloseAllPositionsByType(ENUM_POSITION_TYPE posType)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_TYPE) == posType)
           {
            if(trade.PositionClose(ticket))
              {
               if(DetailedLogging)
                  Print("Closed ", (posType == POSITION_TYPE_BUY ? "Buy" : "Sell"),
                        " position ", ticket, " due to opposite signal");
              }
            else
              {
               Print("Error closing position ", ticket, ": ", GetLastError());
              }
           }
        }
     }
  }

// Check if positions of specified type exist
bool HasPositionsByType(ENUM_POSITION_TYPE posType)
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_TYPE) == posType)
           {
            return true;
           }
        }
     }
   return false;
  }

// Order-Check (Avoid duplicate trades)
bool IsTradeOpen(string tradeType)
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            ((tradeType == "BUY" && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ||
             (tradeType == "SELL" && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)))
           {
            if(DetailedLogging)
               Print(tradeType, " position already open: ", ticket);
            return true; // Already open position
           }
        }
     }
   return false;
  }

// Check buy conditions
bool CheckBuyConditions(double bid, double ema50, double ema200, double macd_main, double macd_signal, double rsi_value, double adx_value)
  {
   return (bid > ema200
           && bid > ema50
           && (!UseMACD || macd_main > macd_signal)
           && (!UseRSI || rsi_value > 50)
           && (!UseADX || adx_value > 20));
  }

// Check sell conditions
bool CheckSellConditions(double bid, double ema50, double ema200, double macd_main, double macd_signal, double rsi_value, double adx_value)
  {
   return (bid < ema200
           && bid < ema50
           && (!UseMACD || macd_main < macd_signal)
           && (!UseRSI || rsi_value < 50)
           && (!UseADX || adx_value > 20));
  }

// Optimized entry logic
void CheckTrade()
  {
   if(TradingStopped)
     {
      if(DetailedLogging)
         Print("Trading stopped");
      return;
     }

   if(!CheckTradingTime())
      return;
   if(!CheckSpread())
      return;
   
   if(MaxOpenPositions>0)
     {
      int totalPositions = PositionsTotal();
      if(totalPositions >= MaxOpenPositions)
        {
         if(DetailedLogging)
            Print("Max positions reached: ", totalPositions, "/", MaxOpenPositions);
         return;
        }      
     }

//---
   double EMA50 = CalculateEMA(EMA_Fast, 0);
   double EMA200 = CalculateEMA(EMA_Slow, 0);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

   double macd_main = 0, macd_signal = 0;
   if(UseMACD)
      CalculateMACD(macd_main, macd_signal);

   double rsi_value = 50;
   if(UseRSI)
      rsi_value = CalculateRSI(RSI_Period);

   double adx_value = 0;
   if(UseADX)
      adx_value = CalculateADX(ADX_Period);

   if(DetailedLogging)
      Print("Market data: EMA50=", EMA50, ", EMA200=", EMA200,
            ", MACD main=", macd_main, ", MACD signal=", macd_signal,
            ", RSI=", rsi_value, ", ADX=", adx_value);

// Buy condition
   bool buyCondition = CheckBuyConditions(bid, EMA50, EMA200, macd_main, macd_signal, rsi_value, adx_value);
   bool sellCondition = CheckSellConditions(bid, EMA50, EMA200, macd_main, macd_signal, rsi_value, adx_value);

// Check if we need to close opposite positions
   if(CloseOppositePositions)
     {
      if(buyCondition && HasPositionsByType(POSITION_TYPE_SELL))
        {
         CloseAllPositionsByType(POSITION_TYPE_SELL);
         if(DetailedLogging)
            Print("Closed all SELL positions due to BUY signal");
        }
      else
         if(sellCondition && HasPositionsByType(POSITION_TYPE_BUY))
           {
            CloseAllPositionsByType(POSITION_TYPE_BUY);
            if(DetailedLogging)
               Print("Closed all BUY positions due to SELL signal");
           }
     }

// Open new positions if conditions met
   if(buyCondition && !IsTradeOpen("BUY"))
     {
      double lotSize = UseDynamicLotSize ? CalculateDynamicLotSize(StopLossPips) : LotSize;
      ExpectedLotSize = lotSize; // Store expected lot size for comparison
      double sl = ask - PipsToPoints(StopLossPips);
      double tp = ask + PipsToPoints(TakeProfitPips);

      if(DetailedLogging)
         Print("BUY signal: Lot=", lotSize, ", Price=", ask, ", SL=", sl, ", TP=", tp);

      if(trade.Buy(lotSize, Symbol(), 0, sl, tp))
        {
         Print("Buy order placed successfully at ", ask, " SL: ", sl, " TP: ", tp);
        }
      else
        {
         Print("Error placing buy order: ", GetLastError());
        }
     }
   else
      if(sellCondition && !IsTradeOpen("SELL"))
        {
         double lotSize = UseDynamicLotSize ? CalculateDynamicLotSize(StopLossPips) : LotSize;
         ExpectedLotSize = lotSize; // Store expected lot size for comparison
         double sl = bid + PipsToPoints(StopLossPips);
         double tp = bid - PipsToPoints(TakeProfitPips);

         if(DetailedLogging)
            Print("SELL signal: Lot=", lotSize, ", Price=", bid, ", SL=", sl, ", TP=", tp);

         if(trade.Sell(lotSize, Symbol(), 0, sl, tp))
           {
            Print("Sell order placed successfully at ", bid, " SL: ", sl, " TP: ", tp);
           }
         else
           {
            Print("Error placing sell order: ", GetLastError());
           }
        }
  }

// Check if new candle has formed
bool IsNewCandle()
  {
   datetime currentCandleTime = iTime(Symbol(), TimeFrame, 0);

   if(currentCandleTime > LastCandleTime)
     {
      LastCandleTime = currentCandleTime;
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
// OnTick function
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(UseTrailingStop)
      ApplyTrailingStop();
   if(ClosePercent>0)
      CheckPartialClose();

// Check if it's a new candle, if not, exit
   if(!IsNewCandle())
      return;

   if(DetailedLogging)
      Print("New candle detected, checking trading conditions...");

   if(!CheckRiskManagement())
      return;
   CheckTrade();
  }
//+------------------------------------------------------------------+
// OnInit - Initialization
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   UseMACD = MACD_Signal != 0;            // Use MACD filter
   UseRSI = RSI_Period != 0;              // Use RSI filter
   UseADX = ADX_Period != 0;              // Use ADX filter
   UseDynamicLotSize = LotSize<=0;        // Use dynamic lot size based on risk
   UseTrailingStop = TrailingStopPips>0;  // Use trailing stop
   PartialClosePips = TakeProfitPips * (PartialClosePipPercent/100); // Pips for partial close (TP1)
   
// Initialize date and trading status
   TodayDate = 0;
   TradingStopped = false;
   ExpectedLotSize = UseDynamicLotSize ? CalculateDynamicLotSize(StopLossPips) : LotSize;

// Initialize last candle time to prevent immediate trading
   LastCandleTime = iTime(Symbol(), TimeFrame, 0);

// Initialize indicator handles
   EMA_Fast_Handle = iMA(Symbol(), TimeFrame, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   EMA_Slow_Handle = iMA(Symbol(), TimeFrame, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   if(UseMACD) MACD_Handle = iMACD(Symbol(), TimeFrame, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
   if(UseRSI) RSI_Handle = iRSI(Symbol(), TimeFrame, RSI_Period, PRICE_CLOSE);
   if(UseADX) ADX_Handle = iADX(Symbol(), TimeFrame, ADX_Period);

   if(EMA_Fast_Handle == INVALID_HANDLE || EMA_Slow_Handle == INVALID_HANDLE ||
      MACD_Handle == INVALID_HANDLE || RSI_Handle == INVALID_HANDLE ||
      ADX_Handle == INVALID_HANDLE)
     {
      Print("Error initializing indicators: ", GetLastError());
      return INIT_FAILED;
     }

   Print("Bot successfully started");
   return INIT_SUCCEEDED;
  }

// OnDeinit - Cleanup
void OnDeinit(const int reason)
  {
// Release indicator handles
   IndicatorRelease(EMA_Fast_Handle);
   IndicatorRelease(EMA_Slow_Handle);
   IndicatorRelease(MACD_Handle);
   IndicatorRelease(RSI_Handle);
   IndicatorRelease(ADX_Handle);

   Print("Bot stopped, reason: ", reason);
  }

//+------------------------------------------------------------------+
