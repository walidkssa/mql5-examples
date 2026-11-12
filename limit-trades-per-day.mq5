// Limit trades per day and one trade per bar in MQL5
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/limit-trades-per-day
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#include <Trade/Trade.mqh>

input int    InpMaxPerDay  = 3;        // Maximum new trades per day
input bool   InpOnePerBar  = true;     // At most one new trade per bar
input int    InpResetHour  = 0;        // Hour the trading day starts, server time
input double InpLots       = 0.10;     // Volume, lots
input int    InpStopPoints = 300;      // Stop-loss, points
input ulong  InpMagic      = 20261112; // Magic number

CTrade trade;

// Start of the current trading day, in server time
datetime TradingDayStart(const datetime now)
  {
   datetime start = (datetime)((long)now / 86400 * 86400) + InpResetHour * 3600;
   return start > now ? start - 86400 : start;
  }

// Entries this EA made on this symbol since `from`, read from the deal history (survives restarts).
// `lastEntry` receives the time of the newest one, looked up from `historyFrom`.
int CountEntries(const datetime from, const datetime historyFrom, datetime &lastEntry)
  {
   lastEntry = 0;
   if(!HistorySelect(historyFrom, TimeCurrent() + 86400))
      return -1;
   int count = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0 || HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(deal, DEAL_MAGIC) != (long)InpMagic)
         continue;
      long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)   // INOUT: a reversal on a netting account
         continue;
      datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      if(t > lastEntry)
         lastEntry = t;
      if(t >= from)
         count++;
     }
   return count;
  }

bool CanOpen()
  {
   datetime now      = TimeCurrent();
   datetime dayStart = TradingDayStart(now);
   datetime barOpen  = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barOpen == 0)
      return false;
   datetime last;
   int today = CountEntries(dayStart, MathMin(dayStart, barOpen), last);
   if(today < 0 || today >= InpMaxPerDay)
      return false;
   if(InpOnePerBar && last >= barOpen)
      return false;                                 // already traded on this bar
   return true;
  }

// Demo signal, to replace with yours: the last closed bar closed above the high of the bar before it
bool BuySignal()
  {
   return iClose(_Symbol, PERIOD_CURRENT, 1) > iHigh(_Symbol, PERIOD_CURRENT, 2);
  }

int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetTypeFillingBySymbol(_Symbol);
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   if(!BuySignal() || !CanOpen())
      return;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl  = NormalizeDouble(bid - InpStopPoints * _Point, _Digits);
   if(!trade.Buy(InpLots, _Symbol, ask, sl, 0.0, "limited") || trade.ResultRetcode() != TRADE_RETCODE_DONE)
      PrintFormat("Buy failed: retcode %u (%s)", trade.ResultRetcode(), trade.ResultRetcodeDescription());
  }
