// Write closed trades to a CSV file in MQL5
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/write-trades-to-csv
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

input string InpFile      = "closed_trades.csv"; // File name, in MQL5\Files
input bool   InpCommon    = false;               // Write to the Common\Files folder shared by all terminals
input string InpSeparator = ";";                 // Column separator (";" for Excel with a decimal comma)
input long   InpMagic     = -1;                  // Trades to log (-1 = all, 0 = manual)

int OnInit()
  {
   string folder = InpCommon ? TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files"
                             : TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files";
   PrintFormat("Closed trades are written to %s\\%s", folder, InpFile);
   return INIT_SUCCEEDED;
  }

// Opens the file for appending, writes the header if it's new, adds one row
bool AppendRow(const string time, const long position, const string symbol, const string side, const double volume,
               const double openPrice, const double closePrice, const double profit, const double commission,
               const double swap, const long magic, const string comment)
  {
   int flags = FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ;
   if(InpCommon)
      flags |= FILE_COMMON;
   ResetLastError();
   int h = FileOpen(InpFile, flags, (short)StringGetCharacter(InpSeparator, 0));
   if(h == INVALID_HANDLE)
     {
      PrintFormat("FileOpen %s failed: error %d (is it open in Excel?)", InpFile, GetLastError());
      return false;
     }
   if(FileSize(h) == 0)
      FileWrite(h, "close_time", "position", "symbol", "side", "volume", "open_price", "close_price",
                "profit", "commission", "swap", "magic", "comment");
   FileSeek(h, 0, SEEK_END);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   FileWrite(h, time, position, symbol, side, DoubleToString(volume, 2), DoubleToString(openPrice, digits),
             DoubleToString(closePrice, digits), DoubleToString(profit, 2), DoubleToString(commission, 2),
             DoubleToString(swap, 2), magic, comment);
   FileClose(h);   // closed after every row: nothing is lost if the terminal stops
   return true;
  }

// Every new deal arrives here. Closing deals (OUT, INOUT, OUT_BY) are written to the file.
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD || !HistoryDealSelect(trans.deal))
      return;
   long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
      return;
   long magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   if(InpMagic >= 0 && magic != InpMagic)
      return;

   // Read everything about the closing deal before HistorySelectByPosition() replaces the selection
   long     position   = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
   string   symbol     = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
   datetime time       = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
   double   volume     = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
   double   closePrice = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
   double   profit     = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
   double   commission = HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   double   swap       = HistoryDealGetDouble(trans.deal, DEAL_SWAP);
   string   comment    = HistoryDealGetString(trans.deal, DEAL_COMMENT);
   // A closing SELL deal closes a long position, and the other way round
   string   side       = HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_SELL ? "long" : "short";

   // Entry price and entry commission come from the position's opening deal
   double openPrice = 0.0;
   if(HistorySelectByPosition(position))
      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong deal = HistoryDealGetTicket(i);
         if(deal > 0 && HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
           {
            openPrice   = HistoryDealGetDouble(deal, DEAL_PRICE);
            commission += HistoryDealGetDouble(deal, DEAL_COMMISSION);
            break;
           }
        }
   AppendRow(TimeToString(time, TIME_DATE | TIME_SECONDS), position, symbol, side, volume, openPrice, closePrice,
             profit, commission, swap, magic, comment);
  }
