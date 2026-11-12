// Move stop-loss to break-even in MQL5 (costs included)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/move-stop-loss-to-break-even
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#include <Trade/Trade.mqh>

input int  InpTriggerPoints = 300;  // Profit, in points, that moves the stop to break-even
input int  InpLockPoints    = 20;   // Extra points locked in beyond break-even
input bool InpCoverCosts    = true; // Break-even after commission and swap, not just the entry price
input long InpMagic         = -1;   // Magic number to manage (-1 = every position on this symbol)

CTrade trade;

double RoundToTick(const double price)
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0.0)
      return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tick) * tick, _Digits);
  }

// Price distance that pays back the commission and swap of a position. Commission is often charged again on
// the closing deal, so the entry commission is counted twice.
double CostDistance(const long positionId, const bool isBuy, const double volume, const double open, const double swap)
  {
   double commission = 0.0;
   if(HistorySelectByPosition(positionId))
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
        {
         ulong deal = HistoryDealGetTicket(i);
         if(deal > 0)
            commission += HistoryDealGetDouble(deal, DEAL_COMMISSION);
        }
   double cost = -(2.0 * commission + swap);   // commission is negative, swap can be either
   if(cost <= 0.0)
      return 0.0;
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double perTick = 0.0;                       // money made by this volume over one tick
   if(tick <= 0.0 || !OrderCalcProfit(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, volume, open,
                                      isBuy ? open + tick : open - tick, perTick) || perTick <= 0.0)
      return 0.0;
   return MathCeil(cost / perTick) * tick;
  }

void ManageBreakEven()
  {
   double stops  = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double freeze = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(InpMagic >= 0 && PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;

      bool   isBuy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      double open  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      double price = isBuy ? tick.bid : tick.ask;   // the price the position would close at
      if((isBuy ? price - open : open - price) < InpTriggerPoints * _Point)
         continue;                                  // not far enough in profit yet

      double offset = InpLockPoints * _Point;
      if(InpCoverCosts)
         offset += CostDistance(PositionGetInteger(POSITION_IDENTIFIER), isBuy, PositionGetDouble(POSITION_VOLUME),
                                open, PositionGetDouble(POSITION_SWAP));
      double be = RoundToTick(isBuy ? open + offset : open - offset);

      if(sl != 0.0 && (isBuy ? sl >= be : sl <= be))
         continue;                                  // already at or beyond break-even: nothing to send
      double room = MathMax(stops, _Point);         // the stop must stay at least the stops level from the price
      if(isBuy ? price - be < room : be - price < room)
         continue;                                  // too close for this broker: wait for more profit
      if(freeze > 0.0 && ((sl != 0.0 && MathAbs(price - sl) < freeze) || (tp != 0.0 && MathAbs(price - tp) < freeze)))
         continue;                                  // inside the freeze level: the server refuses any change

      if(!trade.PositionModify(ticket, be, tp) || trade.ResultRetcode() != TRADE_RETCODE_DONE)
         PrintFormat("Break-even on #%I64u failed: retcode %u (%s)", ticket, trade.ResultRetcode(), trade.ResultRetcodeDescription());
      else
         PrintFormat("#%I64u: stop moved to %s (entry %s)", ticket, DoubleToString(be, _Digits), DoubleToString(open, _Digits));
     }
  }

void OnTick()
  {
   ManageBreakEven();
  }
