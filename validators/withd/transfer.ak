//                                  //
// Transfer assets between accounts //
//                                  //

// This validator will act as the `TransferAction`. It will allow users to transfer tokens
// between accounts so that regular transactions are enabled between parties

validator transfer(p: PolicyId) {
  withdrawal(
    r: TransferAction,
    _c: Credential,
    tx: Transaction,
  ) {
    let vaultHash = Script(p)

    let vaultIns =
      list.filter(
        tx.inputs,
        fn(in) { in.output.address.payment_credential == vaultHash },
      )

    let ownOuts =
      list.filter(
        tx.outputs,
        fn(out) { out.address.payment_credential == vaultHash },
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

    // We have our total IO checked but now we need to figure out who is spending
    // and we need to make sure they are only spending what they are supposed to.

    expect [Pair("", inQty),
      Pair(ownerName, 1)] =
      ownIn.output.value
        |> assets.tokens(ownHash)
        |> dict.to_pairs()

    expect Some(ownerOut) =
      list.find(
        ownOuts,
        fn(out) { list.has(assets.flatten(out.value), (ownHash, owner, 1)) },
      )

    and {
      assets.quantity_of(ownerOut.value, ownHash, "") == inQty - quantity,
      assets.tokens(inValue, ownHash) == assets.tokens(outValue, ownHash),
      list.has(tx.extra_signatories, owner),
      ownerName == owner,
    }
  }
}