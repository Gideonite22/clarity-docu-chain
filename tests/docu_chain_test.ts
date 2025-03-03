import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const TEST_HASH = types.buff(Buffer.from('1234567890123456789012345678901234567890', 'hex'));

Clarinet.test({
  name: "Test complete document lifecycle",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test storing a new document
    let block = chain.mineBlock([
      Tx.contractCall('docu-chain', 'store-document',
        [
          TEST_HASH,
          types.ascii("test.pdf"),
          types.ascii("application/pdf")
        ],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test document verification
    let response = chain.callReadOnlyFn(
      'docu-chain',
      'verify-document',
      [TEST_HASH],
      deployer.address
    );
    response.result.expectOk();
    
    // Test ownership transfer
    block = chain.mineBlock([
      Tx.contractCall('docu-chain', 'transfer-ownership',
        [
          TEST_HASH,
          types.principal(wallet1.address)
        ],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test status update
    block = chain.mineBlock([
      Tx.contractCall('docu-chain', 'set-document-status',
        [
          TEST_HASH,
          types.ascii("inactive")
        ],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify final state
    response = chain.callReadOnlyFn(
      'docu-chain',
      'verify-document',
      [TEST_HASH],
      wallet1.address
    );
    let result = response.result.expectOk().expectTuple();
    assertEquals(result['status'], "inactive");
    assertEquals(result['owner'], wallet1.address);
  }
});
