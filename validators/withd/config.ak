// Config Validator needs to manage all of the scriptHashes for the withdrawl actions
// this will then be used as a refeerence input by the main token validator to validate
// withdrawal actions against

// Datums && Redeemers //

pub type ConfigMintAction {
  CMint {
    scripts: List<ScriptHash>
  }
  CBurn
}

pub type ConfigAction {
  CUpdate { 
    scripts: List<ScriptHash> 
  }
  CClose
}

pub type ConfigDatum {
  scripts: List<ScriptHash>
}

// All we need to do here is make sure the list of scriptHashes can be updated provided
// we have the right signature in the transaction (owner)
validator config(boot: OutputReference, owner: ScriptHash) {
  spend(
    d: Option<ConfigDatum>,
    r: ConfigAction,
    o: OutputReference,
    tx: Transaction,  
  ) {
    when r is {
      CUpdate { scripts } -> {
        expect Some(ownInput) =
          list.find(tx.inputs, fn(input) { input.output_reference == oref })

        expect Some(ownOutput) =
          list.find(
            tx.outputs,
            fn(output) {
              output.address == ownInput.output.address && output.value == ownInput.output.value
            },
          )

        expect InlineDatum(datum) = ownOutput.datum
        expect outDatum: ConfigDatum = datum

        and {
          outDatum.scripts == scripts,
          list.has(tx.extra_signatories, owner),
        }
      }
      CClose -> list.has(tx.extra_signatories, owner)
    }
  }

  mint(r: ConfigMintAction, p: PolicyId, tx: Transaction) {
    when r is {
      CMint -> True
      CBurn -> list.has(tx.extraa_signatories, owner)
    }
  }
}