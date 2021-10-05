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

		Hierarchy old:
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

		System.debug('FIRSTUPDATE');
//		ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE = true;

		update contacts.values();

		insert new Contact(
				LastName = 'zipex',
				ReportsTo = contacts.get('Dima'),
				Parent_Contact__c = contacts.get('Dima').Id
		);

		Contact andrey = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'kolia'];
		Contact diana = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'diana'];
		Contact zipex = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'zipex'];

		System.debug('Andrey: ' + andrey);
		System.debug('vlad: ' + vlad);
		System.debug('dima: ' + dima);
		System.debug('sasha: ' + sasha);
		System.debug('kolia: ' + kolia);
		System.debug('diana: ' + diana);
		System.debug('zipex: ' + zipex);

		System.assertEquals(6, andrey.ChildCount__c);
		System.assertEquals(5, vlad.ChildCount__c);
		System.assertEquals(4, dima.ChildCount__c);
		System.assertEquals(0, sasha.ChildCount__c);
		System.assertEquals(0, zipex.ChildCount__c);
		System.assertEquals(0, kolia.ChildCount__c);
		System.assertEquals(0, diana.ChildCount__c);
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

		System.debug('FIRSTUPDATE');
//		ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE = true;

		update contacts.values();

		for(Contact contact : [SELECT Id, ChildCount__c, Parent_Contact__r.Id, Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Id FROM Contact]) {
			System.debug(contact);
		}

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

		System.debug('SECONDUPDATE');
//		ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE = true;
		update contacts.values();

		Contact andrey = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'kolia'];
		Contact diana = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'diana'];

		System.debug('Andrey: ' + andrey);
		System.debug('vlad: ' + vlad);
		System.debug('dima: ' + dima);
		System.debug('sasha: ' + sasha);
		System.debug('kolia: ' + kolia);
		System.debug('diana: ' + diana);

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
	static void testDeleteWithHierarchy1() {
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

		System.debug('FIRSTUPDATE');
//		ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE = true;

		update contacts.values();

		delete contacts.get('Diana');

		Contact andrey = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'kolia'];

		System.debug('Andrey: ' + andrey);
		System.debug('vlad: ' + vlad);
		System.debug('dima: ' + dima);
		System.debug('sasha: ' + sasha);
		System.debug('kolia: ' + kolia);

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
	static void testDeleteWithHierarchy2() {
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

		System.debug('FIRSTUPDATE');
//		ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE = true;

		update contacts.values();

		delete contacts.get('Dima');

		Contact andrey = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c, Highest_Parent__c FROM Contact WHERE LastName = 'vlad'];

		System.debug('Andrey: ' + andrey);
		System.debug('vlad: ' + vlad);

		System.assertEquals(1, andrey.ChildCount__c);
		System.assertEquals(0, vlad.ChildCount__c);
	}
}