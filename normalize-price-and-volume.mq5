// MQL5 normalize price and lot size: tick size, volume step
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/normalize-price-and-volume
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#property script_show_inputs

input double InpLots   = 0.237; // Volume to normalize, lots
input double InpOffset = 0.37;  // Price to normalize: Bid plus this many ticks

// Price on the symbol's tick grid. NormalizeDouble(price, _Digits) alone isn't enough when a tick is bigger than a point.
double NormalizePrice(const string symbol, const double price)
  {
   double tick   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   int    digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(tick <= 0.0)
      return NormalizeDouble(price, digits);
   return NormalizeDouble(MathRound(price / tick) * tick, digits);
  }

// Volume rounded DOWN to the step and capped at the maximum; 0 when it's below the minimum.
// Rounding a risk-based size up would risk more than planned, so this never does.
double NormalizeVolume(const string symbol, const double lots)
  {
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0.0 || lots <= 0.0)
      return 0.0;
   // + 1e-9: 0.3 / 0.1 is 2.9999999999999996 in floating point, and MathFloor would drop a whole step
   double v = MathFloor(lots / step + 1e-9) * step;
   if(v > vmax)
      v = vmax;
   if(v < vmin)
      return 0.0;
   int decimals = (int)MathMax(0.0, MathCeil(-MathLog10(step) - 1e-9));   // 0.01 -> 2, 0.1 -> 1, 1 -> 0
   return NormalizeDouble(v, decimals);
  }

// Room left under SYMBOL_VOLUME_LIMIT (open positions plus pending orders in one direction), or -1 if no limit
double VolumeRoom(const string symbol, const bool buy)
  {
   double limit = SymbolInfoDouble(symbol, SYMBOL_VOLUME_LIMIT);
   if(limit <= 0.0)
      return -1.0;
   double used = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) > 0 && PositionGetString(POSITION_SYMBOL) == symbol &&
         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) == buy)
         used += PositionGetDouble(POSITION_VOLUME);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderGetTicket(i) == 0 || OrderGetString(ORDER_SYMBOL) != symbol)
         continue;
      long type = OrderGetInteger(ORDER_TYPE);
      bool orderBuy = (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_STOP_LIMIT);
      if(orderBuy == buy)
         used += OrderGetDouble(ORDER_VOLUME_CURRENT);
     }
   return MathMax(0.0, limit - used);
  }

void OnStart()
  {
   double tick  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double raw   = bid + InpOffset * tick;

   PrintFormat("%s: digits %d, point %s, tick size %s, tick value %.5f %s", _Symbol, _Digits,
               DoubleToString(_Point, _Digits), DoubleToString(tick, _Digits),
               SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), AccountInfoString(ACCOUNT_CURRENCY));
   PrintFormat("Stops level %d points, freeze level %d points",
               (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL));
   PrintFormat("Volume: min %.2f, step %.2f, max %.2f, limit %.2f (0 = none)",
               SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP),
               SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT));
   PrintFormat("Price %s -> %s", DoubleToString(raw, _Digits + 3), DoubleToString(NormalizePrice(_Symbol, raw), _Digits));

   double lots = NormalizeVolume(_Symbol, InpLots);
   if(lots == 0.0)
      PrintFormat("Volume %.3f -> below this symbol's minimum: don't trade (or accept the larger risk knowingly)", InpLots);
   else
      PrintFormat("Volume %.3f -> %s", InpLots, DoubleToString(lots, 2));
   double room = VolumeRoom(_Symbol, true);
   if(room >= 0.0 && lots > room)
      PrintFormat("Only %.2f lots of buys fit under the symbol's volume limit", room);
  }
