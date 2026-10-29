# Localization

## Sub-features

- One optional Spanish edition of a finished product. Copy only, on that product's existing shelf. A product translates once. A port can sit on the same product.
- The Shipped card shows "Translate · Spanish edition · $50, one extra sales day" and a secondary Translate button. Sequel, Enter award, Port, and Translate share one row. Hire stays the one primary action.
- The fee is $50. The next day end pays one quieter extra sales day, then the translation is done. The button is gone once the fee is paid.
- Short cash disables the button with "Translate · Need $50" and writes nothing.
- No translation is the default. The first newsletter still pays 20700 cents and 5 fans, and the next office day is still 33300 cents.

## How to get to it (user POV)

Start the company. Ship Crypto Alpha Newsletter and let the four sales days finish. On Company Journey the Shipped card shows the translate line and Translate. Press it. The card reads "Spanish edition · one extra sales day" and the cash is $50 lower. End the day. The card then names the cash from that quieter day.

The edition is Spanish edition in copy only. The fee and the quieter day are in `docs/TYCOON_DESIGN.md`.

## Driving it with capture_journey.gd

The main playthrough never presses Translate, so the later cash checks stay on the old path. A separate save finishes Crypto Alpha Newsletter and does not translate it. The helper snaps `48-localize-offer.png` on that shelf row, clicks Translate, and snaps `49-localize-bought.png` with cash $50 lower and "Spanish edition · one extra sales day".

## Gotchas

- The Selling card does not offer a translation. The button appears after sales finish.
- A second press is not offered. The extra day pays once.
- The quieter day uses half the units of the port's extra day. It does not add a fifth day to the sales window.
- Old rows without a localization field count as not translated and are not rewritten on read.
