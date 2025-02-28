import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Producer registration test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('gridflow', 'register-producer', 
        [types.uint(1000), types.uint(10)], 
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    const response = chain.callReadOnlyFn(
      'gridflow',
      'get-producer-data',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    response.result.expectOk().expectSome();
  }
});

Clarinet.test({
  name: "Energy listing and purchase test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    // Register producer
    chain.mineBlock([
      Tx.contractCall('gridflow', 'register-producer',
        [types.uint(1000), types.uint(10)],
        deployer.address
      )
    ]);
    
    // List energy
    let block = chain.mineBlock([
      Tx.contractCall('gridflow', 'list-energy',
        [types.uint(500), types.uint(10)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Purchase energy
    block = chain.mineBlock([
      Tx.contractCall('gridflow', 'purchase-energy',
        [types.uint(100), types.principal(deployer.address)],
        buyer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(0);
    
    // Verify updated producer data
    const response = chain.callReadOnlyFn(
      'gridflow',
      'get-producer-data',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    const producerData = response.result.expectOk().expectSome();
    assertEquals(producerData['available'], types.uint(400));
  }
});

Clarinet.test({
  name: "Invalid purchase attempts test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    // Register and list energy
    chain.mineBlock([
      Tx.contractCall('gridflow', 'register-producer',
        [types.uint(1000), types.uint(10)],
        deployer.address
      ),
      Tx.contractCall('gridflow', 'list-energy',
        [types.uint(500), types.uint(10)],
        deployer.address
      )
    ]);
    
    // Attempt to purchase more than available
    let block = chain.mineBlock([
      Tx.contractCall('gridflow', 'purchase-energy',
        [types.uint(600), types.principal(deployer.address)],
        buyer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(102);
  }
});
