// THIS IS A WORK IN PROGRESS OF THE PROPOSED CIP STANDARD CIP-113 PROGRAMMABLE TOKENS //

// pub type AccountMintAction {
//   AMint { acc: ByteArray }
//   ABurn
// }

// pub type AccountAction {AccountAction}

// pub type AccountDatum {
//   // this field wouldnt be needed if the AssetName is the credential
//   credentials: ByteArray,
//   state: Data,
// }

// // this implementation is simple, it expects that ONLY one asset is minted/burned
// // it also expects that ONLY this asset is at the output except lovelace
// validator stateManager {
//   mint(r: AccountAction, p: PolicyId, tx: Transaction) {
//     expect [Pair(accName, accQty)] =
//       tx.mint
//         |> assets.tokens(p)
//         |> dict.to_pairs()
//     when r is {
//       AMint { acc } -> {
//         let accountList =
//           list.filter(
//             tx.outputs,
//             fn(out) { out.address.payment_credential == Script(p) },
//           )

//         expect Some(accOut) = list.head(accountList)

//         let expectedAccount = assets.from_asset(p, acc, 1)

//         and {
//           acc == accName,
//           assets.without_lovelace(accOut) == expectedAccount,
//         }
//       }
//       ABurn -> True
//     }
//     // todo
//   }

//   spend(
//     datum: Option<AccountDatum>,
//     r: AccountAction,
//     oref: OutputReference,
//     tx: Transaction,
//   ) {
//     todo
//   }

//   else(_) {
//     fail
//   }
// }
