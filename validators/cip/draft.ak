

validator tokenRegistry() {
  mint(r: RegistryMintAction, p: PolicyId, tx: Transaction) {
    expect [Pair(listName, listQty) =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()
    
    when r is { 
      RMint { policy, transfer, user, global } -> { 
        expect Some(registryOut) = 
          list.find(
            tx.outputs,
            fn(out) { 
              and {
                out.address.payment_credential == Script(p),
                assets.without_lovelace(out.value) == assets.from_asset(p, listName, 1)
              }
            },
          )

        expect InlineDatum(datum) = registryOut.datum
        expect rDatum: RegistryDatum = datum

        and {
          listQty == 1,
          rDatum.tokenPolicy == policy,
          rDatum.nextTokenPolicy == "",
          rDatum.transferManagerHash == transfer,
          rDatum.userStateManagerHash == user,
          rDatum.globalStatePolicy == global,
        }
      }
      RBurn -> { listQty == -1 }
    }
  }

  spend(d: Option<RegistryDatum>, r: RegistryAction, oref: OutputReference, tx: Transaction) {
    expect Some(ownInput) =
      list.find(inputs, fn(input) { input.output_reference == oref })

    expect Script(ownHash) = ownInput.output.address.payment_credential

    expect Some(d) = datum

    when r is {
      RInsert -> {
        // new list element
        expect [Pair(newTokenName, 1)] =
          mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()
        // original element output
        expect Some(listOut) =
          list.find(
            outputs,
            fn(output) { output.value == ownInput.output.value },
          )
        expect InlineDatum(datum) = listOut.datum
        expect outDatum: RegistryDatum = datum

        // new element output
        expect Some(newOut) =
          list.find(
            outputs,
            fn(output) {
              dict.to_pairs(assets.tokens(output.value, ownHash)) == [
                Pair(newTokenName, 1),
              ]
            },
          )
        expect InlineDatum(datum) = newOut.datum
        expect newDatum: RegistryDatum = datum

        and {
          newDatum.nextTokenPolicy == "",
          newDatum.tokenPolicy == newTokenName,
          outDatum.nextTokenPolicy == newTokenName,
          d.tokenPolicy == outDatum.tokenPolicy,
          d.transferManagerHash == outDatum.transferManagerHash,
          d.userStateManagerHash == outDatum.userStateManagerHash,
          d.globalStatePolicy == outDatum.globalStatePolicy,
        }
      }
      RRemove { prev } -> {
        // remove an element from the list
        // check input has 1 token of our policy
        expect [Pair(tokenName, 1)] =
          ownInput.output.value
            |> assets.tokens(ownHash)
            |> dict.to_pairs()
        // check we are burning one token
        expect [Pair(burnName, -1)] =
          mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()
        // find another input
        expect Some(prevNode) =
          list.find(
            inputs,
            fn(input) {
              input.output.address.payment_credential == Script(ownHash) && oref != input.output_reference
            },
          )

        expect InlineDatum(datum) = prevNode.output.datum
        expect prevDatum: LinkedDatum = datum
        expect prevDatum.next == burnName

        expect Some(ownOut) =
          list.find(
            outputs,
            fn(output) {
              and {
                output.value == prevNode.output.value,
                output.address.payment_credential == Script(ownHash),
              }
            },
          )

        expect InlineDatum(datum) = ownOut.datum
        expect newDatum: LinkedDatum = datum

        and {
          tokenName == burnName,
          newDatum.nextTokenPolicy == d.nextTokenPolicy,
          newDatum.transferManagerHash == prevDatum.transferManagerHash,
          newDatum.userStateManagerHash == prevDatum.userStateManagerHash,
          newDatum.globalStatePolicy == prevDatum.globalStatePolicy,
        }
      } 
      RPrevious -> {
        // this is for the prevNode of the list to update it when you are removing one
        expect Some(nextNode) =
          list.find(
            inputs,
            fn(input) {
              input.output.address.payment_credential == Script(ownHash) && oref != input.output_reference
            },
          )

        expect InlineDatum(datum) = nextNode.output.datum
        expect nextDatum: LinkedDatum = datum

        expect [Pair(nextName, 1)] =
          nextNode.output.value
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect [Pair(burnName, -1)] =
          mint
            |> assets.tokens(ownHash)
            |> dict.to_pairs()

        expect Some(ownOut) =
          list.find(
            outputs,
            fn(output) { output.address.payment_credential == Script(ownHash) },
          )
        expect InlineDatum(datum) = ownOut.datum
        expect outDatum: LinkedDatum = datum

        and {
          ownOut.value == ownInput.output.value,
          nextDatum.next == outDatum.next,
          outDatum.count == d.count,
          outDatum.root == d.root,
          outDatum.head == d.head,
          outDatum.whitelist == d.whitelist,
          nextName == d.next,
          nextName == burnName,
        }
      }
    }
  }
}

validator globalState(boot: OutputReference, owner: ByteArray) {
  // globalState refIn w scripts
  // references withdrawal scripts for various asset functions
  mint(r: GlobalMintAction, p: PolicyId, tx: Transaction) { 
    expect [Pair("", supplyQty) =
      tx.mint
        |> assets.tokens(p)
        |> dict.to_pairs()

    when r is {
      GMint { state, wList } -> { 
        expect Some(_bootIn) =
          list.find(tx.inputs, fn(in) { in.output_reference == boot })

        expect Some(globalOut) =
          list.find(
            tx.outputs,
            fn(out) { 
              and {
                out.address.payment_credential == Script(p),
                assets.without_lovelace(out.value) == assets.from_asset(p, "", 1)
              }
            },
          )
        
        expect InlineDatum(datum) = globalOut.datum
        expect gDatum: GlobalDatum = datum

        and {
          gDatum.state == state,
          gDatum.wList == wList,
        }
      }
      GBurn -> { 
        and {
          supplyQty == -1,
          list.has(tx.extra_signatories, owner)
        } 
      }
    }
  }

  spend(d: Option<GlobalDatum>, r: GlobalRedeemer, tx: Transaction) { 
    when r is {
      GState { state } -> {

        and {
          outDatum.state == state,
          outDatum.wList == d.wList,
          list.has(tx.extra_signatories, owner)
        }
      }
      GUpdate { wList } -> {
        and {
          outDatum.wList == wList,
          outDatum.state == d.state,
          list.has(tx.extra_signatories, owner)
        }
      }
    }
  }
}

validator transferManager(globalState: PolicyId, owner: ByteArray) {
  spend(_d: Option<TransferDatum>, r: List<Int>, oref: OutputReference, tx: Transaction) {
    // holds token UTxOs
    // spends if withdraws
    expect Some(globalState) =
      list.find(
        tx.reference_inputs,
        fn(input) {
          list.has(assets.policies(input.output.value), globalState)
        },
      )

    expect InlineDatum(datum) = config.output.datum
    expect gDatum: GlobalDatum = datum

    expect Some(withdrawalVal) =
      gDatum.wList
        |> list.at(r)

    pairs.has_key(tx.withdrawals, Script(withdrawalVal))
  }

  // withdraw(r: List<Int>, c: Credential, tx: Transaction) {
  //   // this manages total IO
    
  // }
}

validator userStateManager(owner: ByteArray) {
  // linked list?
  // user accounts for KYC/blacklisting etc
  mint(r: UserStateMintAction, p: PolicyId, tx: Transaction) {
    True
  }

  spend(d: UserStateDatum, r: UserStateAction, oref: OutputReference, tx: Transaction) {
    True
  }
}

validator blacklist() {
  withdraw() 
}

validator whitelist() {
  withdraw()
}

validator pause() {
  withdraw()
}

validator minting() {
  withdraw()
}