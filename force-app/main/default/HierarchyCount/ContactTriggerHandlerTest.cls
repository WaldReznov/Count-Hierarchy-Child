/**
 * Created by Uladzislau Yarshou on 30.09.21
**/

@IsTest
private class ContactTriggerHandlerTest {

	@IsTest
	static void testUpdate() {
		List<Contact> contacts = new List<Contact>{
				new Contact(LastName = 'Andrey'),
				new Contact(LastName = 'Vlad'),
				new Contact(LastName = 'Dima'),
				new Contact(LastName = 'Sasha'),
				new Contact(LastName = 'Kolia'),
				new Contact(LastName = 'Diana')
		};

		insert contacts;

		contacts[1].ReportsTo = contacts[0];
		contacts[2].ReportsTo = contacts[1];
		contacts[3].ReportsTo = contacts[2];
		contacts[4].ReportsTo = contacts[2];
		contacts[5].ReportsTo = contacts[2];

		update contacts;

		Contact andrey = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'andrey'];
		Contact vlad = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'vlad'];
		Contact dima = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'dima'];
		Contact sasha = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'sasha'];
		Contact kolia = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'kolia'];
		Contact diana = [SELECT Id, ChildCount__c FROM Contact WHERE LastName = 'diana'];

		System.debug('Andrey: ' + andrey);
		System.debug('vlad: ' + vlad);
		System.debug('dima: ' + dima);
		System.debug('sasha: ' + sasha);
		System.debug('kolia: ' + kolia);
		System.debug('diana: ' + diana);

		System.assertEquals(5, andrey.ChildCount__c);
		System.assertEquals(4, vlad.ChildCount__c);
		System.assertEquals(3, dima.ChildCount__c);
		System.assertEquals(0, sasha.ChildCount__c);
		System.assertEquals(0, kolia.ChildCount__c);
		System.assertEquals(0, diana.ChildCount__c);
	}

	@IsTest
	static void testBehavior() {
		List<Contact> contacts = new List<Contact>();

		for(Integer i = 0; i < 100; i++) {
			contacts.add(new Contact(LastName = 'Test: ' + i));
		}

		insert contacts;

		for(Integer i = 1; i < 100; i++){
			contacts[i].ReportsTo = contacts[i-1];
		}

		update contacts;
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
}