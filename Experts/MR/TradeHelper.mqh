//+------------------------------------------------------------------+
//|                                                  TradeHelper.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define MUF_MAGIC 142857

void SendOrder(string ordertype, string symbol, double price = 0, double sl = 0, double tp = 0, double volume = 0.01, ulong deviation = 5, string comment = "") {
   if (PositionsTotal() > 0) {
      return;
   }
   
   MqlTradeRequest request;
   ZeroMemory(request);
   request.symbol   = symbol;
   request.volume   = volume;
   request.deviation= deviation;
   request.magic    = MUF_MAGIC;
//--- set the price and order type depending on the position type
   double pip = SymbolInfoDouble(symbol, SYMBOL_POINT);
   StringToLower(ordertype);
   if(ordertype == "buy") {
      double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
      if (price == 0) {
         request.type = ORDER_TYPE_BUY;
         request.action   = TRADE_ACTION_DEAL;
      } else if (price > ask) {
         request.type = ORDER_TYPE_BUY_STOP;
         request.action   = TRADE_ACTION_PENDING;
      } else if (price < ask) {
         request.type = ORDER_TYPE_BUY_LIMIT;
         request.action   = TRADE_ACTION_PENDING;
      }
   } else if (ordertype == "sell") {
      double bid = SymbolInfoDouble(symbol,SYMBOL_BID);
      if (price == 0) {
         request.type = ORDER_TYPE_SELL;
         request.action   = TRADE_ACTION_DEAL;
      } else if (price < bid) {
         request.type = ORDER_TYPE_SELL_STOP;
         request.action   = TRADE_ACTION_PENDING;
      } else if (price > bid) {
         request.type = ORDER_TYPE_SELL_LIMIT;
         request.action   = TRADE_ACTION_PENDING;
      }
   }
   else {
      string exception = "invalid order type";
      Print(exception);
      return;
   }
   request.price = price;
   if (sl != 0) {
      request.sl = sl;
   }
   if (tp != 0) {
      request.tp = tp;
   }
   request.comment = comment;
   MqlTradeCheckResult checkresult;
   bool valid = OrderCheck(request, checkresult);
   if (valid) {
      MqlTradeResult result;
      bool res = OrderSend(request, result);
      if (!res) {
         printf("Order fail: %s", result.comment);
      }
      //else {
      //   ulong ticketNo = result.deal == 0 ? result.order : result.deal;
      //   string objName = StringFormat("MBOT_OPEN_%s", IntegerToString(ticketNo));
      //   ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, TimeCurrent(), price);
      //   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGray);
      //   objName = StringFormat("MBOT_SL_%s", IntegerToString(ticketNo));
      //   ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, TimeCurrent(), sl);
      //   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrPink);
      //   objName = StringFormat("MBOT_TP_%s", IntegerToString(ticketNo));
      //   ObjectCreate(0, objName, OBJ_ARROW_RIGHT_PRICE, 0, TimeCurrent(), tp);
      //   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGreenYellow);
      //}
   } else {
      Print("Order invlalid: %s", checkresult.comment);
   }
}
//+------------------------------------------------------------------+
void Buy(string symbol, double price = 0, double sl = 0, double tp = 0, double volume = 0.01, ulong deviation = 5, string comment = "") {
   SendOrder("buy", symbol, price, sl, tp, volume, deviation);
}

void Sell(string symbol, double price = 0, double sl = 0, double tp = 0, double volume = 0.01, ulong deviation = 5, string comment = "") {
   SendOrder("sell", symbol, price, sl, tp, volume, deviation);
}
