# MQL5 examples for MetaTrader 5

19 complete MQL5 programs for MetaTrader 5 (14 Expert Advisors and 5 scripts), one per common task: orders and positions, indicator values, new bars, sessions, timers, chart objects, CSV files, alerts, WebRequest and the Strategy Tester. Every file has a full explanation on [edgoro.com](https://edgoro.com/mql5-examples), with its key lines, pitfalls, variations and an FAQ.

Each program compiles in MetaEditor (build 6275) with 0 errors and 0 warnings.

## Examples

### Orders and positions

Open, close, protect and size trades with CTrade, within the broker's price, volume and distance rules.

| File | Type | What it does | Explained on edgoro.com |
| --- | --- | --- | --- |
| [`open-market-order-ctrade.mq5`](open-market-order-ctrade.mq5) | Script | A script with inputs: drop it on a chart and it opens one position on that chart's symbol. It sends a real order, so run it on a demo account first. | [MQL5 market buy and sell with CTrade (full script)](https://edgoro.com/mql5-examples/open-market-order-ctrade) |
| [`close-all-positions.mq5`](close-all-positions.mq5) | Script | A script with inputs: an empty symbol and a magic number of -1 close every position on the account. It sends real closing orders, so try it on a demo account first. | [Close all positions in MQL5 (by symbol and magic number)](https://edgoro.com/mql5-examples/close-all-positions) |
| [`pending-orders-with-expiration.mq5`](pending-orders-with-expiration.mq5) | Script | A script with inputs: pick the order type, its distance from the market and its lifetime. It places a real pending order, so run it on a demo account first. | [MQL5 buy limit and buy stop orders with expiration](https://edgoro.com/mql5-examples/pending-orders-with-expiration) |
| [`move-stop-loss-to-break-even.mq5`](move-stop-loss-to-break-even.mq5) | Expert Advisor | An Expert Advisor that manages positions already open on its chart's symbol, including manual ones when the magic number is -1. It modifies real stops, so try it on a demo account first. | [Move stop-loss to break-even in MQL5 (costs included)](https://edgoro.com/mql5-examples/move-stop-loss-to-break-even) |
| [`partial-close-position.mq5`](partial-close-position.mq5) | Expert Advisor | An Expert Advisor that watches the chart symbol's positions and closes part of each one once, at the profit you set. It sends real closing orders, so try it on a demo account first. | [Partial close a position in MQL5 (hedging and netting)](https://edgoro.com/mql5-examples/partial-close-position) |
| [`normalize-price-and-volume.mq5`](normalize-price-and-volume.mq5) | Script | A script that sends no orders: it prints the chart symbol's price and volume rules in the Experts tab, then normalizes the price and volume you enter. | [MQL5 normalize price and lot size: tick size, volume step](https://edgoro.com/mql5-examples/normalize-price-and-volume) |

### Signals, timing and rules

When the EA acts: new bars, indicator values, sessions, timers and limits on how often it trades.

| File | Type | What it does | Explained on edgoro.com |
| --- | --- | --- | --- |
| [`detect-new-bar.mq5`](detect-new-bar.mq5) | Expert Advisor | An Expert Advisor that trades nothing: it prints a line in the Experts tab when a bar opens on the chart's timeframe and on a second timeframe you choose. | [Detect a new bar in MQL5 (once per bar, any timeframe)](https://edgoro.com/mql5-examples/detect-new-bar) |
| [`read-indicator-values-copybuffer.mq5`](read-indicator-values-copybuffer.mq5) | Expert Advisor | An Expert Advisor that trades nothing: on each new bar it prints the last closed bar's close, moving average and RSI in the Experts tab. | [Read indicator values in MQL5: iMA, iRSI and CopyBuffer](https://edgoro.com/mql5-examples/read-indicator-values-copybuffer) |
| [`icustom-read-custom-indicator.mq5`](icustom-read-custom-indicator.mq5) | Expert Advisor | An Expert Advisor that trades nothing: it reads the ZigZag indicator that ships with MetaTrader 5 and prints the last two confirmed swing points on each new bar. | [MQL5 iCustom example: read a custom indicator's buffers](https://edgoro.com/mql5-examples/icustom-read-custom-indicator) |
| [`moving-average-crossover-ea.mq5`](moving-average-crossover-ea.mq5) | Expert Advisor | A complete Expert Advisor that opens and closes real positions on its own. Test it in the Strategy Tester and on a demo account: a crossover rule is an example, not a recommendation. | [MQL5 moving average crossover EA (complete code)](https://edgoro.com/mql5-examples/moving-average-crossover-ea) |
| [`trading-session-time-filter.mq5`](trading-session-time-filter.mq5) | Expert Advisor | An Expert Advisor that trades nothing: it prints when the session opens and closes, with both clocks, and marks where entry logic goes. | [MQL5 trading session filter: server time, GMT and DST](https://edgoro.com/mql5-examples/trading-session-time-filter) |
| [`limit-trades-per-day.mq5`](limit-trades-per-day.mq5) | Expert Advisor | A complete Expert Advisor with a deliberately simple demo signal (a close above the previous bar's high) to show the limits at work. It opens real positions: run it on a demo account, and replace the signal with yours. | [Limit trades per day and one trade per bar in MQL5](https://edgoro.com/mql5-examples/limit-trades-per-day) |
| [`ontimer-event.mq5`](ontimer-event.mq5) | Expert Advisor | An Expert Advisor that closes its own positions (by magic number) on Friday evening and warns when the chart's symbol stops ticking. It can close real positions, so try it on a demo account first. | [MQL5 OnTimer example: run code without waiting for ticks](https://edgoro.com/mql5-examples/ontimer-event) |

### Chart, files, messages and testing

What the EA shows and sends: objects and panels on the chart, CSV files, alerts, webhooks and the Strategy Tester.

| File | Type | What it does | Explained on edgoro.com |
| --- | --- | --- | --- |
| [`draw-objects-on-chart.mq5`](draw-objects-on-chart.mq5) | Expert Advisor | An Expert Advisor that trades nothing: it draws the previous day's high and low, and marks with an arrow and a label each bar that closed beyond them. | [Draw on the chart in MQL5: lines, arrows and text](https://edgoro.com/mql5-examples/draw-objects-on-chart) |
| [`on-chart-dashboard.mq5`](on-chart-dashboard.mq5) | Expert Advisor | An Expert Advisor that trades nothing: it draws a panel with the account's balance, equity, floating and closed results, open positions, spread and server time. | [MQL5 on-chart dashboard with labels (or Comment)](https://edgoro.com/mql5-examples/on-chart-dashboard) |
| [`write-trades-to-csv.mq5`](write-trades-to-csv.mq5) | Expert Advisor | An Expert Advisor that trades nothing: attach it to any one chart and it appends a row for every position closed on the account, with the file's full path printed at start. | [Write closed trades to a CSV file in MQL5](https://edgoro.com/mql5-examples/write-trades-to-csv) |
| [`alerts-and-push-notifications.mq5`](alerts-and-push-notifications.mq5) | Expert Advisor | An Expert Advisor that trades nothing: it alerts when a bar closes above or below a level, the previous day's high by default. Turn on the channels you want in its inputs. | [MQL5 alerts: Alert, PlaySound and SendNotification](https://edgoro.com/mql5-examples/alerts-and-push-notifications) |
| [`webrequest-post-webhook.mq5`](webrequest-post-webhook.mq5) | Script | A script with inputs that posts one JSON message, with the chart's symbol, Bid and server time, to the URL you give it. It sends data to that server, so use a webhook you own. | [MQL5 WebRequest: POST JSON to a webhook](https://edgoro.com/mql5-examples/webrequest-post-webhook) |
| [`ontester-custom-optimization-criterion.mq5`](ontester-custom-optimization-criterion.mq5) | Expert Advisor | A complete Expert Advisor with a small RSI strategy to optimize and a custom criterion. It opens real positions if attached to a live chart: it's meant for the Strategy Tester. | [MQL5 OnTester: a custom optimization criterion](https://edgoro.com/mql5-examples/ontester-custom-optimization-criterion) |

## How to use

1. In MetaTrader 5, open the data folder with File > Open Data Folder. Put Expert Advisors in `MQL5/Experts` and scripts in `MQL5/Scripts` (the Type column says which is which).
2. Open MetaEditor (F4 in MetaTrader 5), open the file with File > Open and compile it with Compile (F7).
3. In MetaTrader 5, find the program in the Navigator under Expert Advisors or Scripts and drag it onto a chart. An Expert Advisor only trades while Algo Trading is on. To run an Expert Advisor on history, use the Strategy Tester (View > Strategy Tester).

`webrequest-post-webhook.mq5` also needs its URL added under Tools > Options > Expert Advisors > "Allow WebRequest for listed URL".

## Risk

This code is for education. Test it in the Strategy Tester and on a demo account before any live use. Trading involves risk of loss, and none of these programs is a trading recommendation.

## Related

Error messages are explained in the [MQL5 error library](https://edgoro.com/mql5-errors) and the [Pine Script error library](https://edgoro.com/pine-script-errors). [Edgoro](https://edgoro.com) also writes custom code from a plain-English description: [MT5 Expert Advisor generator](https://edgoro.com/mt5-expert-advisor-generator), [Pine Script generator](https://edgoro.com/pine-script-generator).

## License

MIT, see [LICENSE](LICENSE).
