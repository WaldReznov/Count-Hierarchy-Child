/**
 * Created by Uladzislau Yarshou on 30.09.21
**/

@IsTest
private class ContactTriggerHandlerTest {

	/*
		Hierarchy old:
					Andrey ↘︎
						  Vlad ↘︎
							Dima ↘︎
								-> Sasha
								-> Kolia
								-> Diana

		Hierarchy new:
					Andrey ↘︎
						  Vlad ↘︎
							Dima ↘︎
								-> Sasha
								-> Kolia
								-> Diana
								-> Zipex
	 */

	@IsTest
	static void testCreateWithHierarchy() {
		Test.startTest();
		Map<String, Contact> contacts = new Map<String, Contact>{
				'Andrey' => new Contact(LastName = 'Andrey'),
				'Vlad' => new Contact(LastName = 'Vlad'),
				'Dima' => new Contact(LastName = 'Dima'),
				'Sasha' => new Contact(LastName = 'Sasha'),
				'Kolia' => new Contact(LastName = 'Kolia'),
				'Diana' => new Contact(LastName = 'Diana')
		};

		insert contacts.values();

		contacts.get('Vlad').ReportsTo = contacts.get('Andrey');
		contacts.get('Dima').ReportsTo = contacts.get('Vlad');
		contacts.get('Sasha').ReportsTo = contacts.get('Dima');
		contacts.get('Kolia').ReportsTo = contacts.get('Dima');
		contacts.get('Diana').ReportsTo = contacts.get('Dima');

		contacts.get('Vlad').Parent_Contact__c = contacts.get('Andrey').Id;
		contacts.get('Dima').Parent_Contact__c = contacts.get('Vlad').Id;
		contacts.get('Sasha').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Kolia').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Diana').Parent_Contact__c = contacts.get('Dima').Id;

		update contacts.values();

		insert new Contact(
				LastName = 'zipex',
				ReportsTo = contacts.get('Dima'),
				Parent_Contact__c = contacts.get('Dima').Id
		);

		Test.stopTest();

		Contact andrey = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'kolia'];
		Contact diana = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'diana'];
		Contact zipex = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'zipex'];

		System.assertEquals(6, andrey.ChildCount__c);
		System.assertEquals(5, vlad.ChildCount__c);
		System.assertEquals(4, dima.ChildCount__c);
		System.assertEquals(0, sasha.ChildCount__c);
		System.assertEquals(0, zipex.ChildCount__c);
		System.assertEquals(0, kolia.ChildCount__c);
		System.assertEquals(0, diana.ChildCount__c);
	}

	/*
		Hierarchy:
		Andrey -> 1000 contacts
	 */

	@IsTest
	static void testCreateBulkifyWithHierarchy() {
		Test.startTest();
		Map<String, Contact> contacts = new Map<String, Contact>{
				'Andrey' => new Contact(LastName = 'Andrey')
		};

		insert contacts.values();

		List<Contact> contacts2 = new List<Contact>();

		for(integer i = 0; i < 1000; i++) {
			contacts2.add(new Contact(
					LastName = 'Test_' + i,
					Parent_Contact__c = contacts.get('Andrey').Id
			));
		}

		insert contacts2;

		Test.stopTest();

		Contact andrey = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'Andrey'];
		System.assertEquals(1000, andrey.ChildCount__c);
	}


	/*

		Hierarchy old:
					Andrey ↘︎
						  Vlad ↘︎
							Dima ↘︎
								-> Sasha
								-> Kolia
								-> Diana

		Hierarchy new:
					Diana(5) ↘︎
						  Kolia(4)↘︎
							Dima(3) ↘︎
								-> Sasha
								-> Vlad
								-> Andrey
	 */

	@IsTest
	static void testUpdateWithHierarchy() {
		Test.startTest();
		
		Map<String, Contact> contacts = new Map<String, Contact>{
				'Andrey' => new Contact(LastName = 'Andrey'),
				'Vlad' => new Contact(LastName = 'Vlad'),
				'Dima' => new Contact(LastName = 'Dima'),
				'Sasha' => new Contact(LastName = 'Sasha'),
				'Kolia' => new Contact(LastName = 'Kolia'),
				'Diana' => new Contact(LastName = 'Diana')
		};

		insert contacts.values();

		contacts.get('Vlad').ReportsTo = contacts.get('Andrey');
		contacts.get('Dima').ReportsTo = contacts.get('Vlad');
		contacts.get('Sasha').ReportsTo = contacts.get('Dima');
		contacts.get('Kolia').ReportsTo = contacts.get('Dima');
		contacts.get('Diana').ReportsTo = contacts.get('Dima');

		contacts.get('Vlad').Parent_Contact__c = contacts.get('Andrey').Id;
		contacts.get('Dima').Parent_Contact__c = contacts.get('Vlad').Id;
		contacts.get('Sasha').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Kolia').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Diana').Parent_Contact__c = contacts.get('Dima').Id;

		update contacts.values();
		
		contacts.get('Diana').ReportsTo = null;
		contacts.get('Kolia').ReportsTo = contacts.get('Diana');
		contacts.get('Dima').ReportsTo = contacts.get('Kolia');
		contacts.get('Sasha').ReportsTo = contacts.get('Dima');
		contacts.get('Vlad').ReportsTo = contacts.get('Dima');
		contacts.get('Andrey').ReportsTo = contacts.get('Dima');

		contacts.get('Diana').Parent_Contact__c = null;
		contacts.get('Kolia').Parent_Contact__c = contacts.get('Diana').Id;
		contacts.get('Dima').Parent_Contact__c = contacts.get('Kolia').Id;
		contacts.get('Sasha').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Vlad').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Andrey').Parent_Contact__c = contacts.get('Dima').Id;

		update contacts.values();

		Test.stopTest();

		Contact andrey = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'kolia'];
		Contact diana = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'diana'];

		System.assertEquals(0, andrey.ChildCount__c);
		System.assertEquals(0, vlad.ChildCount__c);
		System.assertEquals(3, dima.ChildCount__c);
		System.assertEquals(0, sasha.ChildCount__c);
		System.assertEquals(4, kolia.ChildCount__c);
		System.assertEquals(5, diana.ChildCount__c);
	}

	/*
		Hierarchy old:
					Andrey ↘︎
						  Vlad ↘︎
							Dima ↘︎
								-> Sasha
								-> Kolia
								-> Diana

		Hierarchy new:
					Andrey ↘︎
						  Vlad ↘︎
							Dima ↘︎
								-> Sasha
								-> Kolia
	 */

	@IsTest
	static void testDeleteLowestChild() {
		Test.startTest();
		
		Map<String, Contact> contacts = new Map<String, Contact>{
				'Andrey' => new Contact(LastName = 'Andrey'),
				'Vlad' => new Contact(LastName = 'Vlad'),
				'Dima' => new Contact(LastName = 'Dima'),
				'Sasha' => new Contact(LastName = 'Sasha'),
				'Kolia' => new Contact(LastName = 'Kolia'),
				'Diana' => new Contact(LastName = 'Diana')
		};

		insert contacts.values();

		contacts.get('Vlad').ReportsTo = contacts.get('Andrey');
		contacts.get('Dima').ReportsTo = contacts.get('Vlad');
		contacts.get('Sasha').ReportsTo = contacts.get('Dima');
		contacts.get('Kolia').ReportsTo = contacts.get('Dima');
		contacts.get('Diana').ReportsTo = contacts.get('Dima');

		contacts.get('Vlad').Parent_Contact__c = contacts.get('Andrey').Id;
		contacts.get('Dima').Parent_Contact__c = contacts.get('Vlad').Id;
		contacts.get('Sasha').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Kolia').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Diana').Parent_Contact__c = contacts.get('Dima').Id;

		update contacts.values();

		delete contacts.get('Diana');

		Test.stopTest();

		Contact andrey = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'kolia'];

		System.assertEquals(4, andrey.ChildCount__c);
		System.assertEquals(3, vlad.ChildCount__c);
		System.assertEquals(2, dima.ChildCount__c);
		System.assertEquals(0, sasha.ChildCount__c);
		System.assertEquals(0, kolia.ChildCount__c);
	}


	/*
		Hierarchy old:
					Andrey ↘︎
						  Vlad ↘︎
							Dima ↘︎
								-> Sasha
								-> Kolia
								-> Diana

		Hierarchy new:
					Andrey ↘︎
						  Vlad
	 */

	@IsTest
	static void testDeleteMiddleChild() {
		Test.startTest();
		
		Map<String, Contact> contacts = new Map<String, Contact>{
				'Andrey' => new Contact(LastName = 'Andrey'),
				'Vlad' => new Contact(LastName = 'Vlad'),
				'Dima' => new Contact(LastName = 'Dima'),
				'Sasha' => new Contact(LastName = 'Sasha'),
				'Kolia' => new Contact(LastName = 'Kolia'),
				'Diana' => new Contact(LastName = 'Diana')
		};

		insert contacts.values();

		contacts.get('Vlad').ReportsTo = contacts.get('Andrey');
		contacts.get('Dima').ReportsTo = contacts.get('Vlad');
		contacts.get('Sasha').ReportsTo = contacts.get('Dima');
		contacts.get('Kolia').ReportsTo = contacts.get('Dima');
		contacts.get('Diana').ReportsTo = contacts.get('Dima');

		contacts.get('Vlad').Parent_Contact__c = contacts.get('Andrey').Id;
		contacts.get('Dima').Parent_Contact__c = contacts.get('Vlad').Id;
		contacts.get('Sasha').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Kolia').Parent_Contact__c = contacts.get('Dima').Id;
		contacts.get('Diana').Parent_Contact__c = contacts.get('Dima').Id;

		update contacts.values();

		delete contacts.get('Dima');

		Test.stopTest();

		Contact andrey = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'vlad'];

		System.assertEquals(1, andrey.ChildCount__c);
		System.assertEquals(0, vlad.ChildCount__c);
	}

	@IsTest
	static void testRunAfterCreateHandler() {
		ContactTriggerHandler.IS_ALLOW_AFTER_CREATE = false;
		ContactTriggerHandler.afterInsert(null, null);
	}

	@IsTest
	static void testRunAfterDeleteHandler() {
		ContactTriggerHandler.IS_ALLOW_AFTER_DELETE = false;
		ContactTriggerHandler.afterDelete(null, null);
	}
}