// MQL5 OnTester: a custom optimization criterion
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/ontester-custom-optimization-criterion
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#include <Trade/Trade.mqh>

// ——— A small strategy to optimize: RSI leaves oversold / overbought ———
input int    InpRsiPeriod  = 14;       // RSI period
input double InpLow        = 30.0;     // Buy when RSI crosses back above
input double InpHigh       = 70.0;     // Sell when RSI crosses back below
input int    InpStopPoints = 400;      // Stop-loss, points
input int    InpTakePoints = 400;      // Take-profit, points
input double InpLots       = 0.10;     // Volume, lots
// ——— Custom criterion ———
input int    InpMinTrades  = 50;       // Fewer trades than this scores 0
input double InpMaxDdPct   = 20.0;     // A relative equity drawdown above this scores 0, %

CTrade   trade;
int      rsi = INVALID_HANDLE;
datetime lastBar = 0;

int OnInit()
  {
   rsi = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, PRICE_CLOSE);
   if(rsi == INVALID_HANDLE)
      return INIT_FAILED;
   trade.SetExpertMagicNumber(20261112);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(rsi);
  }

void OnTick()
  {
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == lastBar || PositionSelect(_Symbol))
      return;
   double v[];
   ArraySetAsSeries(v, true);
   if(CopyBuffer(rsi, 0, 1, 2, v) != 2)
      return;
   lastBar = bar;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(v[1] < InpLow && v[0] >= InpLow)
      trade.Buy(InpLots, _Symbol, ask, NormalizeDouble(bid - InpStopPoints * _Point, _Digits), NormalizeDouble(bid + InpTakePoints * _Point, _Digits));
   else if(v[1] > InpHigh && v[0] <= InpHigh)
      trade.Sell(InpLots, _Symbol, bid, NormalizeDouble(ask + InpStopPoints * _Point, _Digits), NormalizeDouble(ask - InpTakePoints * _Point, _Digits));
  }

// R² of the balance curve, trade by trade: 1.0 for a perfectly straight rising line, near 0 for noise
double BalanceLinearity()
  {
   if(!HistorySelect(0, TimeCurrent()))
      return 0.0;
   double balance = TesterStatistics(STAT_INITIAL_DEPOSIT);
   double sx = 0, sy = 0, sxx = 0, syy = 0, sxy = 0;
   int    n  = 0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      long type = HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;                                   // the initial deposit is a deal too
      balance += HistoryDealGetDouble(deal, DEAL_PROFIT) + HistoryDealGetDouble(deal, DEAL_SWAP)
                 + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
         continue;                                   // entry commission counted; one point per closing deal
      double x = n;
      sx += x;
      sy += balance;
      sxx += x * x;
      syy += balance * balance;
      sxy += x * balance;
      n++;
     }
   if(n < 3)
      return 0.0;
   double vx = n * sxx - sx * sx;
   double vy = n * syy - sy * sy;
   double cov = n * sxy - sx * sy;
   if(vx <= 0.0 || vy <= 0.0 || cov <= 0.0)          // flat or falling curve: no score (and no division by zero)
      return 0.0;
   return (cov * cov) / (vx * vy);
  }

// Called once at the end of every test pass. With "Custom max" selected, the optimizer ranks passes by this value.
double OnTester()
  {
   double trades = TesterStatistics(STAT_TRADES);
   double profit = TesterStatistics(STAT_PROFIT);
   double ddPct  = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   if(trades < InpMinTrades || profit <= 0.0 || ddPct > InpMaxDdPct)
      return 0.0;
   // Smoothness first, then profit per unit of drawdown, so one lucky trade can't win the optimization
   double recovery = TesterStatistics(STAT_RECOVERY_FACTOR);
   return BalanceLinearity() * MathMin(recovery, 10.0);
  }
