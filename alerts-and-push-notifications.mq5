// MQL5 alerts: Alert, PlaySound and SendNotification
// Explained (key lines, pitfalls, variations, FAQ): https://edgoro.com/mql5-examples/alerts-and-push-notifications
// MIT License, Copyright (c) 2026 Edgoro. For education: test on a demo account before any live use.

input double InpLevel     = 0.0;         // Price level to watch (0 = previous day's high)
input bool   InpPopup     = true;        // Pop-up alert in the terminal
input bool   InpSound     = false;       // Play a sound
input string InpSoundFile = "alert2.wav"; // Sound file, in the terminal's Sounds folder
input bool   InpPush      = false;       // Push notification to the MetaTrader app on your phone

// Sends one message through every channel that's switched on
void Notify(const string text)
  {
   string msg = StringFormat("%s %s: %s", _Symbol, StringSubstr(EnumToString(_Period), 7), text);
   if(InpPopup)
      Alert(msg);                         // also plays the terminal's alert sound
   if(InpSound && !PlaySound(InpSoundFile))
      PrintFormat("PlaySound(%s) failed: is the file in the Sounds folder?", InpSoundFile);
   if(InpPush)
     {
      // MetaQuotes allows about 2 pushes a second and 10 a minute: keep at least 6 seconds between them
      static ulong lastPush = 0;
      if(lastPush > 0 && GetTickCount64() - lastPush < 6000)
        {
         Print("Push skipped (too soon after the last one): ", msg);
         return;
        }
      ResetLastError();
      if(!SendNotification(StringSubstr(msg, 0, 255)))   // 255 characters at most
         PrintFormat("SendNotification failed: error %d", GetLastError());
      else
         lastPush = GetTickCount64();
     }
  }

int OnInit()
  {
   if(InpPush && (!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED) || TerminalInfoInteger(TERMINAL_MQID) == 0))
      Print("Push notifications are off: add your MetaQuotes ID in Tools > Options > Notifications and tick Enable");
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   static datetime lastBar = 0;
   datetime bar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(bar == 0 || bar == lastBar)
      return;                             // check once per bar, so one cross sends one message
   lastBar = bar;

   double level = InpLevel > 0.0 ? InpLevel : iHigh(_Symbol, PERIOD_D1, 1);
   double c1    = iClose(_Symbol, PERIOD_CURRENT, 1);
   double c2    = iClose(_Symbol, PERIOD_CURRENT, 2);
   if(level <= 0.0 || c2 <= 0.0)
      return;
   if(c2 <= level && c1 > level)
      Notify(StringFormat("closed above %s at %s", DoubleToString(level, _Digits), DoubleToString(c1, _Digits)));
   else if(c2 >= level && c1 < level)
      Notify(StringFormat("closed below %s at %s", DoubleToString(level, _Digits), DoubleToString(c1, _Digits)));
  }
