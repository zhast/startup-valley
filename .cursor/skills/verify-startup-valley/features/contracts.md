# Contracts

## Sub-features

- One client offer on Company Journey. The card names the client, the topic × type, and a fixed cash bonus.
- Accept contract is a secondary button. Hire stays the one primary action.
- Accepting locks the next product to that pair. Other topics and types read "· contract" and stay disabled.
- Ignoring the offer leaves the free picker. No contract pays no bonus.
- Release adds one cash line, "Contract: <client>", and shows "Contract: <client> · +$80" on the release card.

## How to get to it (user POV)

Start the company. On Company Journey, scroll to the Contract card. Read the client and press Accept contract, or press New Product and ship anything else. After a contract ships, the next offer is on the card.

## Driving it with capture_journey.gd

The helper snaps `22-contract-offer.png` on the first Company Journey, with the contract card in view. It leaves that offer alone for the first newsletter. After the small-ad launch it accepts the same offer, ships that pair, and snaps `23-contract-released.png` on the release line.

## Gotchas

- Accept is disabled while a product is on the bench.
- The bonus is not part of the sales math. The first newsletter with no contract still pays 20700 cents and 5 fans.
- The offer does not change when the day ends. It changes when a contracted product is released.
