use aiken/collection/dict
use aiken/collection/list
use aiken/math
use cardano/address.{Script}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}

// This is my own design for programmable tokens
// The idea is to keep it super simple, as little complexity as possible
// The validator doesnt care if you are sending anything to the correct account,
// all it checks for is that the value of total inputs == total outputs

// Supply: If a token has a fixed supply - an 'all in one mint' will initialise the token
// Account: A User's account token, an NFT with the PKH assetName

pub type AccountMintAction {
  Supply { quantity: Int }
  Account { owner: ByteArray }
  Burn
}

// Transfer: This is for transferring tokens between accounts
//    The accounts must already exist
// Close: This is for a user to close their account -> burn the account token
// BurnSupply: kinda self explanatory, but it will only allow burning of CNTs
//    NOT Account Tokens

pub type AccountAction {
  Transfer
  Close
  BurnSupply
}

validator account(boot: OutputReference) {
  mint(r: AccountMintAction, p: PolicyId, tx: Transaction) {
    when r is {
      Supply { quantity } -> {
        // mints the total supply of the asset, spending the boot OutputReference 
        // to prevent re-minting the supply in future
        expect [Pair("", supplyQty),
          Pair(supplyName, 1)] =
          tx.mint
            |> assets.tokens(p)
            |> dict.to_pairs()

        expect Some(_bootIn) =
          list.find(tx.inputs, fn(in) { in.output_reference == boot })

        expect Some(accountOut) =
          list.find(
            tx.outputs,
            fn(out) { out.address.payment_credential == Script(p) },
          )
        let accountRoot = assets.from_asset(p, supplyName, 1)
        let tokenSupply = assets.from_asset(p, "", quantity)
        and {
          assets.without_lovelace(accountOut.value) == assets.merge(
            accountRoot,
            tokenSupply,
          ),
          supplyQty == quantity,
          supplyName == p,
        }
      }
      Account { owner } -> {
        // Because we are finding here, we can only have this single user Account output to script
        // alternatively we could use a tx.output index as part of the redeemer to allow us to
        // deposit straight into the newly created account, this would allow for account creation
        // and deposits in the same transaction which would obviously be a better process
        expect [Pair(accountName, 1)] =
          tx.mint
            |> assets.tokens(p)
            |> dict.to_pairs()

        expect Some(accountOut) =
          list.find(
            tx.outputs,
            fn(out) { out.address.payment_credential == Script(p) },
          )
        let accountRoot = assets.from_asset(p, owner, 1)
        and {
          assets.without_lovelace(accountOut.value) == accountRoot,
          accountName == owner,
        }
      }
      Burn -> {
        expect [Pair(burnName, burnQty)] =
          tx.mint
            |> assets.tokens(p)
            |> dict.to_pairs()
        if burnName == "" {
          burnQty < 0
        } else {
          burnQty == -1
        }
      }
    }
  }

  spend(
    _dat: Option<Data>,
    r: AccountAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(ownIn) =
      list.find(tx.inputs, fn(in) { in.output_reference == oref })

    expect Script(ownHash) = ownIn.output.address.payment_credential

    let ownIns =
      list.filter(
        tx.inputs,
        fn(in) { in.output.address.payment_credential == Script(ownHash) },
      )

    let ownOuts =
      list.filter(
        tx.outputs,
        fn(out) { out.address.payment_credential == Script(ownHash) },
      )
    // Here we are just checking that the total in == total out of our programmables
    // ins and outs are of our ownHash, so we cant leak any tokens
    // this covers assets and account tokens so we cant mint and send as mentioned above
    let inValue =
      list.foldl(
        ownIns,
        assets.zero,
        fn(in, acc) { assets.merge(in.output.value, acc) },
      )

    let outValue =
      list.foldl(
        ownOuts,
        assets.zero,
        fn(out, acc) { assets.merge(out.value, acc) },
      )

    when r is {
      Transfer ->
        assets.tokens(inValue, ownHash) == assets.tokens(outValue, ownHash)
      Close -> {
        // If someone wants to close their account
        expect [Pair(accountName, -1)] =
          tx.mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        let accountValue = assets.from_asset(ownHash, accountName, 1)

        and {
          list.has(tx.extra_signatories, accountName),
          assets.without_lovelace(assets.merge(outValue, accountValue)) == assets.without_lovelace(
            inValue,
          ),
        }
      }
      BurnSupply -> {
        expect [Pair("", burnQty)] =
          tx.mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        let burnValue = assets.from_asset(ownHash, "", math.abs(burnQty))

        and {
          burnQty < 0,
          assets.without_lovelace(assets.merge(outValue, burnValue)) == assets.without_lovelace(
            inValue,
          ),
        }
      }
    }
  }

  else(_) {
    fail
  }
}
