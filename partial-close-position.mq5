// Partial close a position in MQL5 (hedging and netting)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/partial-close-position
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#include <Trade/Trade.mqh>

input int    InpTriggerPoints = 400;   // Profit, in points, that triggers the partial close
input double InpClosePercent  = 50.0;  // Share of the original volume to close, %
input bool   InpMoveToEntry   = true;  // Then move the stop to the entry price
input long   InpMagic         = -1;    // Magic number to manage (-1 = every position on this symbol)

CTrade trade;

// Volume rounded down to the symbol's step (0 if below the minimum)
double FloorVolume(const double lots)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(step <= 0.0)
      return 0.0;
   double v = MathFloor(lots / step + 1e-9) * step;
   return v < vmin ? 0.0 : NormalizeDouble(v, 8);
  }

// Volume the position was opened with: the sum of its entry deals. Survives restarts, unlike a flag in memory.
double OpenedVolume(const long positionId)
  {
   double opened = 0.0;
   if(!HistorySelectByPosition(positionId))
      return 0.0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal > 0 && HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
         opened += HistoryDealGetDouble(deal, DEAL_VOLUME);
     }
   return opened;
  }

void ManagePartials()
  {
   bool hedging = AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
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

      bool   isBuy  = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      double open   = PositionGetDouble(POSITION_PRICE_OPEN);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double tp     = PositionGetDouble(POSITION_TP);
      double price  = isBuy ? tick.bid : tick.ask;
      if((isBuy ? price - open : open - price) < InpTriggerPoints * _Point)
         continue;

      double opened = OpenedVolume(PositionGetInteger(POSITION_IDENTIFIER));
      if(opened <= 0.0 || volume < opened - 1e-8)
         continue;                                   // already reduced once: don't close again

      double part = FloorVolume(opened * InpClosePercent / 100.0);
      if(part <= 0.0 || volume - part < vmin - 1e-8)
        {
         PrintFormat("#%I64u: %.2f lots can't be split into %.0f%% and a remainder of at least %.2f", ticket, volume, InpClosePercent, vmin);
         continue;                                   // e.g. 0.01 lots on a symbol whose minimum is 0.01
        }

      // CTrade's PositionClosePartial() only works on hedging accounts; on netting, an opposite deal reduces the position
      bool ok = hedging ? trade.PositionClosePartial(ticket, part)
                        : (isBuy ? trade.Sell(part, _Symbol) : trade.Buy(part, _Symbol));
      if(!ok || trade.ResultRetcode() != TRADE_RETCODE_DONE)
        {
         PrintFormat("Partial close of #%I64u failed: retcode %u (%s)", ticket, trade.ResultRetcode(), trade.ResultRetcodeDescription());
         continue;
        }
      PrintFormat("#%I64u: closed %.2f of %.2f lots at %s", ticket, part, volume, DoubleToString(trade.ResultPrice(), _Digits));

      // The position keeps its ticket on a hedging account; on netting, select it by symbol again
      if(InpMoveToEntry && (hedging ? PositionSelectByTicket(ticket) : PositionSelect(_Symbol)))
         if(!trade.PositionModify(PositionGetInteger(POSITION_TICKET), open, tp))
            PrintFormat("Stop to entry failed: retcode %u (%s)", trade.ResultRetcode(), trade.ResultRetcodeDescription());
     }
  }

void OnTick()
  {
   ManagePartials();
  }
