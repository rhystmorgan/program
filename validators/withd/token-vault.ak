

validator vault(boot: OutputReference, owner: SccriptHash, config: PolicyId) {
  spend(
    _dat: Option<Data>,
    r: SpendAction,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(refIn) =
      list.find(
        tx.reference_inputs,
        fn(in) {
          list.has(assets.policies(in.output.value), config) &&
          in.output.address.payment_credential == Script(config)
        }
      )
    
    expect InlineDatum(dat) = refIn.output.datum
    expect refDatum: ConfigDatum = dat

    list.has(tx.withdrawls, list.at(configDatum.scripts, r.i))
  }

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
}