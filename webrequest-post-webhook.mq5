// MQL5 WebRequest: POST JSON to a webhook
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/webrequest-post-webhook
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

#property script_show_inputs

input string InpUrl     = "https://example.com/webhook"; // Webhook URL (its domain must be in the allowed list)
input string InpMessage = "Test from MetaTrader 5";       // Text to send
input int    InpTimeout = 5000;                           // Timeout, milliseconds

// Escapes a string for a JSON value
string JsonEscape(const string text)
  {
   string s = text;
   StringReplace(s, "\\", "\\\\");
   StringReplace(s, "\"", "\\\"");
   StringReplace(s, "\n", "\\n");
   StringReplace(s, "\r", "");
   return s;
  }

// "https://hooks.example.com/abc" -> "https://hooks.example.com": the part the allowed-URL list needs
string Origin(const string url)
  {
   int scheme = StringFind(url, "://");
   int slash  = (scheme < 0) ? -1 : StringFind(url, "/", scheme + 3);
   return slash < 0 ? url : StringSubstr(url, 0, slash);
  }

void OnStart()
  {
   if(MQLInfoInteger(MQL_TESTER))
     {
      Print("WebRequest() doesn't run in the Strategy Tester");
      return;
     }
   string json = StringFormat("{\"symbol\":\"%s\",\"bid\":%s,\"time\":\"%s\",\"text\":\"%s\"}",
                              _Symbol, DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits),
                              TimeToString(TimeTradeServer(), TIME_DATE | TIME_SECONDS), JsonEscape(InpMessage));

   char body[];
   int size = StringToCharArray(json, body, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(body, size - 1);   // drop the terminating zero StringToCharArray() adds: it isn't part of the JSON

   char   reply[];
   string replyHeaders;
   string headers = "Content-Type: application/json\r\n";
   ResetLastError();
   int status = WebRequest("POST", InpUrl, headers, InpTimeout, body, reply, replyHeaders);
   if(status == -1)
     {
      int err = GetLastError();
      if(err == ERR_FUNCTION_NOT_ALLOWED)   // 4014
         PrintFormat("URL not allowed: add %s in Tools > Options > Expert Advisors, \"Allow WebRequest for listed URL\"", Origin(InpUrl));
      else
         PrintFormat("WebRequest failed: error %d", err);   // 5200-5203: bad address, no connection, timeout, HTTP failure
      return;
     }
   // status is the HTTP code: 200-299 means the server accepted it
   PrintFormat("HTTP %d: %s", status, CharArrayToString(reply, 0, WHOLE_ARRAY, CP_UTF8));
  }
