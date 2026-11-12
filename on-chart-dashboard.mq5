// MQL5 on-chart dashboard with labels (or Comment)
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/on-chart-dashboard
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#define PFX "exdash_"

input long  InpMagic   = -1;          // Positions and deals to count (-1 = all on this account)
input int   InpX       = 12;          // Distance from the left edge, pixels
input int   InpY       = 24;          // Distance from the top edge, pixels
input color InpBg      = C'24,24,28'; // Background
input color InpText    = clrWhite;    // Text

string ROWS[] = {"Balance", "Equity", "Floating P/L", "Closed today", "Open positions", "Spread", "Server time"};
double scale  = 1.0;                  // screen DPI / 96, so the panel isn't tiny on a 4K screen

int Px(const int v) { return (int)MathRound(v * scale); }

void CreateLabel(const string name, const int x, const int y, const string text)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_COLOR, InpText);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);    // not listed in the chart's object list
   ObjectSetString(0, name, OBJPROP_TEXT, text);
  }

void CreatePanel()
  {
   int rows = ArraySize(ROWS);
   string bg = PFX + "bg";
   ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, Px(InpX));
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, Px(InpY));
   ObjectSetInteger(0, bg, OBJPROP_XSIZE, Px(250));
   ObjectSetInteger(0, bg, OBJPROP_YSIZE, Px(16 + rows * 18));
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, InpBg);
   ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bg, OBJPROP_COLOR, InpBg);
   ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);
   for(int i = 0; i < rows; i++)
     {
      int y = Px(InpY + 8 + i * 18);
      CreateLabel(PFX + "k" + IntegerToString(i), Px(InpX + 10), y, ROWS[i]);
      CreateLabel(PFX + "v" + IntegerToString(i), Px(InpX + 130), y, "-");
     }
  }

bool Counted(const long magic) { return InpMagic < 0 || magic == InpMagic; }

// Net result of today's deals (profit, swap, commission, fees), deposits and withdrawals excluded
double ClosedToday()
  {
   datetime now = TimeTradeServer();
   if(!HistorySelect((datetime)((long)now / 86400 * 86400), now + 60))
      return 0.0;
   double sum = 0.0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0 || !Counted(HistoryDealGetInteger(deal, DEAL_MAGIC)))
         continue;
      long type = HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;                                     // balance, credit, bonus... aren't trading results
      sum += HistoryDealGetDouble(deal, DEAL_PROFIT) + HistoryDealGetDouble(deal, DEAL_SWAP)
             + HistoryDealGetDouble(deal, DEAL_COMMISSION) + HistoryDealGetDouble(deal, DEAL_FEE);
     }
   return sum;
  }

void SetValue(const int row, const string text)
  {
   ObjectSetString(0, PFX + "v" + IntegerToString(row), OBJPROP_TEXT, text);
  }

void Update()
  {
   string ccy = AccountInfoString(ACCOUNT_CURRENCY);
   double floating = 0.0;
   int    count    = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0 || !Counted(PositionGetInteger(POSITION_MAGIC)))
         continue;
      floating += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      count++;
     }
   SetValue(0, StringFormat("%.2f %s", AccountInfoDouble(ACCOUNT_BALANCE), ccy));
   SetValue(1, StringFormat("%.2f %s", AccountInfoDouble(ACCOUNT_EQUITY), ccy));
   SetValue(2, StringFormat("%+.2f %s", floating, ccy));
   SetValue(3, StringFormat("%+.2f %s", ClosedToday(), ccy));
   SetValue(4, IntegerToString(count));
   SetValue(5, StringFormat("%d points", (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)));
   SetValue(6, TimeToString(TimeTradeServer(), TIME_DATE | TIME_SECONDS));
   ChartRedraw();
  }

int OnInit()
  {
   scale = TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;
   CreatePanel();
   Update();
   EventSetTimer(1);   // refresh once a second, ticks or not
   return INIT_SUCCEEDED;
  }

void OnTimer()
  {
   Update();
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0, PFX);
   ChartRedraw();
  }
