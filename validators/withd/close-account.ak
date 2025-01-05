//                      //
// Close User's Account //
//                      //

// There isnt muh nned for this unless the specific user particularly wants to close 
// their account.

// The only time someone would want to do this is if they want to remove themselves 
// from this asset ecosystem, bt it would mean they would no longer be able to recieve 
// these assets.

// generally speaking, the 1.5ADA it would free up is not as valuable as being able 
// to recieve the specific assets in the future, but that doesnt mena that it wont be 
// needed, just unlikely it will be used unless there is a mijor hack or serious issue 
// with the assets.

validator closeAccount(p: PolicyId) {
  withdrawal(
    r: List<ByteArray>, // this is the hash(es) of the accounts we are closing.
    _c: Credential,
    tx: Transaction 
  ) {
    // all we need to check here is that we are burning each 
    // PolicyId.r[x]
    // and that any free tokens from the input(s) are returned to the root account?

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
}
