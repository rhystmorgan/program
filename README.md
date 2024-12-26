# Programmable Tokens

This is a little repo to explore some different variations of programmable tokens on Cardano.

I will be looking primarily at CIP-113 (MetaAssets) as the inspiration for this design.

You can find the draft CIP here:

![CIP-113](https://github.com/HarmonicLabs/CIPs/blob/master/CIP-meta-assets%20(ERC20-like%20assets)/README.md)

I will likely look at designing an alternative mechanism to this as well to see if there 
are ways we can simplify or streamline it to be cheaper/easier to handle - as both of 
these things could make a difference.

---

## Initial Design

This is my own initial idea for implementing programmable tokens and is not based on the cip.

It essentially has a minting/spending validator which mints an account token or CNTs

The account token is an NFT where the asset name is the users PKH, and will hold the 
amount of CNTs owned by that user

each account NFT essentially acts as a user thread.

There is an issue here, that is using a linked list means having a big sweaty validator, 
OR haveng multiple withdrawal validators to offload to. There is also another issue in 
having some potential UTxO contention (which is why users may want to have multiple).

We could overcome the first issue by simply not using a linked list and haveng multiple 
assets floating about (this wouldnt really be a problem because they can be tracked
based on the asset name)

We could also use a linked list for each user and the users beacon NFT is the head of 
the list, this will allow for multiple utxos attached to the same list, with a single 
beacon, and it would avoid the potential utxo contention issue.

This could still present a small issue with minUTxO, but for less than 1ADA it isnt 
really an issue I want to tackle in this draft.

---

## CIP-113

The Cip 113 implementation involves a few more things:

There are 2 validators:
  StateManager
  TransferManager

### StateManager

Mints a validity NFT
Holds the state info
NFT has `AccountDatum`

```
AccountDatum {
  credentials: PaymentCredential,
  state: Data,
}
```

statemanager `Account Creation` mints a token with an `AssetName` of `list.head(inputs)`
it can mint other assets but not of an assetname length of 32 ( this would be another account )

only one state nft can exist at a state UTxO ( obviously ) as it represents a user's account



### TransferManager



---

Write validators in the `validators` folder, and supporting functions in the `lib` folder using `.ak` as a file extension.

```aiken
validator my_first_validator {
  spend(_datum: Option<Data>, _redeemer: Data, _output_reference: Data, _context: Data) {
    True
  }
}
```

## Building

```sh
aiken build
```

## Configuring

**aiken.toml**
```toml
[config.default]
network_id = 41
```

Or, alternatively, write conditional environment modules under `env`.

## Testing

You can write tests in any module using the `test` keyword. For example:

```aiken
use config

test foo() {
  config.network_id + 1 == 42
}
```

To run all tests, simply do:

```sh
aiken check
```

To run only tests matching the string `foo`, do:

```sh
aiken check -m foo
```

## Documentation

If you're writing a library, you might want to generate an HTML documentation for it.

Use:

```sh
aiken docs
```

## Resources

Find more on the [Aiken's user manual](https://aiken-lang.org).
