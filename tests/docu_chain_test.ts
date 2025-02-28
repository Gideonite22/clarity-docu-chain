import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test document storage and verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test storing a new document
    let block = chain.mineBlock([
      Tx.contractCall('docu-chain', 'store-document',
        [
          types.buff(Buffer.from('1234567890123456789012345678901234567890', 'hex')),
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
      [types.buff(Buffer.from('1234567890123456789012345678901234567890', 'hex'))],
      deployer.address
    );
    response.result.expectOk();
  }
});

Clarinet.test({
  name: "Test ownership transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Store document first
    let block = chain.mineBlock([
      Tx.contractCall('docu-chain', 'store-document',
        [
          types.buff(Buffer.from('1234567890123456789012345678901234567890', 'hex')),
          types.ascii("test.pdf"),
          types.ascii("application/pdf")
        ],
        deployer.address
      )
    ]);
    
    // Test ownership transfer
    block = chain.mineBlock([
      Tx.contractCall('docu-chain', 'transfer-ownership',
        [
          types.buff(Buffer.from('1234567890123456789012345678901234567890', 'hex')),
          types.principal(wallet1.address)
        ],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify new ownership
    let response = chain.callReadOnlyFn(
      'docu-chain',
      'verify-document',
      [types.buff(Buffer.from('1234567890123456789012345678901234567890', 'hex'))],
      wallet1.address
    );
    response.result.expectOk();
  }
});
