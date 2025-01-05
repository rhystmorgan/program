# Withdrawal Validator Optimisation

This set of validators takes Init and applies the Withdraw0 optimisation to see how that
affects the exUnits for the various states and transactions.

---

## Multusigs

In order to have clawbacks, blacklisting and other kinds of functionality, we will need
to have some kind of authority who will have the power to manage the various withdrawal
validators with the Config Input, as well as be the arbiter or any protocol decisions that
need to be made.

We will assume this party is also the creator of the probgrammable assets.

They will be set up as a multisig which will use the `multisig3` validators from the 
`multisig` repo, which you can look into more on that repo if needed.

the multisig will have its own set of withdrawal validators which will be used to manage
spending etc, howver I will likely try to use the multisig config to manage assets instead
of the spending validators themselves.

This will allow us to save some transaction space etc, which will definitely help if we 
want to enable defi within this prgrammable token protocol.

---

## Validator Setup

There will be one root token validator which will manage minting and signing,

We will have a config ref input which will manage all of the stake hashes for the various
actions.

Otherwise there will be a param for the multisig hash to validate any authoritative 
actions beyond user account spending etc.

Aside, from this, it will basically be the same as the `init` example.

---

