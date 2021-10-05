/**
 * Created by Uladzislau Yarshou on 30.09.21
**/

public with sharing class ContactTriggerHandler {
	@TestVisible public static Boolean IS_ALLOW_AFTER_UPDATE = true;

	public static void beforeInsert(List<Contact> newContacts) {
		Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();

		// sort contact which will used in hierarchy
		List<Contact> sortedContacts = sortContacts(newContacts);
		// populate existing contacts (ChildCount__c)
		List<Contact> populatedContacts = populateExistingContacts(newContacts);

		//getContactIds
		Set<Id> contactIds = new Set<Id>();
		for(Contact contact : populatedContacts) {
			if(contact.ReportsToId != null) {
				contactIds.add(contact.Id);
				if(contactMap.containsKey(contact.ReportsToId)) contactMap.get(contact.ReportsToId).add(contact);
				else contactMap.put(contact.ReportsToId, new List<Contact>{contact});
			}
		}
		Set<String> reportIds = contactMap.keySet();


		// populate contact map
		/* Set<Id> contactIds = new Set<Id>();
		for(Contact contact : newContacts) {
			if(contact.ReportsToId != null) {
				contactIds.add(contact.Id);
				if(contactMap.containsKey(contact.ReportsToId)) contactMap.get(contact.ReportsToId).add(contact);
				else contactMap.put(contact.ReportsToId, new List<Contact>{contact});
			}
		}

		 */

		// get records from hierarchy with child

		List<Contact> contacts = [
				SELECT
						Id,
						ReportsToId,
						ChildCount__c
				FROM
						Contact
				WHERE
						ReportsToId IN :reportIds
		];

		for(Contact contact : contacts) {

		}

	}

	public static List<Contact> sortContacts(List<Contact> newContacts) {
		List<Contact> contacts = new List<Contact>();

		for(Contact contact : newContacts)
			if(contact.ReportsToId != null)
				contacts.add(contact);

		return contacts;
	}

	public static List<Contact> populateExistingContacts(List<Contact> newContacts) {
		for(Contact contact : newContacts) {
			Integer count = 0;

			for(Contact innerContact : newContacts) {
				if(contact.Id == innerContact.ReportsToId) {
					count++;
				}
			}

			contact.ChildCount__c = count;
		}

		return newContacts;
	}

	public static Set<Id> findHighestReportToIds(List<Contact> contacts) {
		Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();

		Set<Id> contactIds = new Set<Id>();

		for(Contact contact : contacts) {
			if(contact.ReportsToId != null) {
				contactIds.add(contact.Id);
				if(contactMap.containsKey(contact.ReportsToId)) contactMap.get(contact.ReportsToId).add(contact);
				else contactMap.put(contact.ReportsToId, new List<Contact>{contact});
			}
		}

		return null;
	}

	public class Hierarchy {
		List<Hierarchy> hierarchyChild = new List<Hierarchy>();
		String selfId;
		String parentId;
		Integer countChild = 0;

		public Hierarchy(String selfId, String parentId) {
			this.selfId = selfId;
			this.parentId = parentId;
		}

		public void addChild(Hierarchy hierarchyChild) {
			this.hierarchyChild.add(hierarchyChild);
		}

		public void addChilds(List<Hierarchy> hierarchyChilds) {
			this.hierarchyChild.addAll(hierarchyChilds);
		}
	}

	public static void beforeUpdate(Map<Id, Contact> oldContact, Map<Id, Contact> newContact) {
		if(IS_ALLOW_AFTER_UPDATE == false) {
			return;
		}

		IS_ALLOW_AFTER_UPDATE = false;

		beforeUpdateMethod(oldContact, newContact);

		IS_ALLOW_AFTER_UPDATE = true;
	}

	static void beforeUpdateChangedContacts(Map<Id, Contact> oldContact, Map<Id, Contact> newContact) {
		//❗️we can use pattern strategy here
		// case when value change to another
		Map<Id, Contact> changedContacts = new Map<Id, Contact>();
		Map<Id, Integer> removedMap = new Map<Id, Integer>();
		Map<Id, Integer> addedMap = new Map<Id, Integer>();
		for(Id contactId : newContact.keySet()){
			System.debug('oldContact.get(contactId) = ' + oldContact.get(contactId) + '>>><<< newContact.get(contactId) = ' + newContact.get(contactId));
			if(oldContact.get(contactId).Parent_Contact__c != newContact.get(contactId).Parent_Contact__c && oldContact.get(contactId).Parent_Contact__c != null){
				changedContacts.put(contactId, newContact.get(contactId));

				if(removedMap.containsKey(oldContact.get(contactId).Parent_Contact__c)) {
					removedMap.put(oldContact.get(contactId).Parent_Contact__c, removedMap.get(contactId) + 1);
				} else {
					removedMap.put(oldContact.get(contactId).Parent_Contact__c, 1);
				}

				if(addedMap.containsKey(newContact.get(contactId).Parent_Contact__c)) {
					addedMap.put(newContact.get(contactId).Parent_Contact__c, addedMap.get(contactId) + 1);
				} else {
					addedMap.put(newContact.get(contactId).Parent_Contact__c, 1);
				}

			}
		}

		if(changedContacts.isEmpty()) {
			return;
		}

		// add validation
//		List<Contact> contactsForUpdate = [SELECT Id, ChildCount__c FROM Contact WHERE Id IN: changedContacts.keySet()];

		for(Contact contact : changedContacts.values()) {
			if(addedMap.containsKey(contact.Id)) {
				contact.ChildCount__c += addedMap.get(contact.Id);
			}

			if(removedMap.containsKey(contact.Id)) {
				contact.ChildCount__c -= removedMap.get(contact.Id);
			}
		}

//		update contactsForUpdate;
	}
 /*
	static void beforeUpdateChangedContactsUsingWrapper(Map<Id, Contact> oldContact, Map<Id, Contact> newContact) {
		Set<Id> highestParents = getHighestParents(newContact.values());

		Map<Id, Contact> contactMap = getContactMap(highestParents);

		List<Map<Id, Contact>> multiHierarchyList = new List<Map<Id, Contact>>();

		for(Integer hierarchyLevel = 1; hierarchyLevel < 6; hierarchyLevel++) {
			String parentField = getParentField(hierarchyLevel);
			Map<Id, Contact> hierarchyContactMap = new Map<Id, Contact>();

			for(Contact contact : contactMap.values()) {
				if(contact.get(parentField) != null) {
					hierarchyContactMap.put((Id) contact.get(parentField), contact);
				}
			}
		}
	}
*/
	static String getParentField(Integer hierarchyLevel) {
		String parentField = '';

		for(Integer j = 1; j < hierarchyLevel; j++) {
			parentField += 'Parent_Contact__r.';
		}

		parentField += 'Id';

		return parentField;
	}

	static Set<Id> getHighestParents(List<Contact> contacts) {
		Set<Id> ids = new Set<Id>();

		for(Contact contact : contacts)
			System.debug(contact);

		for(Contact contact : contacts) {
			if(contact.Highest_Parent__c != null) {
				ids.add(contact.Highest_Parent__c);
			}
		}

		System.debug(ids);
		return ids;
	}

	static Map<Id, Contact> getContactMap(Set<String> ids) {
		return new Map<Id, Contact>([
				SELECT
						Id,
						Name,
						Parent_Contact__c,
						Highest_Parent__c,
						Parent_Contact__r.Id,
						Parent_Contact__r.Parent_Contact__r.Id,
						Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Id,
						Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Id,
						Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Parent_Contact__r.Id
				FROM
						Contact
				WHERE
						Id IN :ids
							OR
						Highest_Parent__c IN :ids
		]);
	}

	static Set<String> getShortedIds(Set<Id> ids) {
		Set<String> clonedIds = (Set<String>)JSON.deserialize(JSON.serialize(ids), Set<String>.class);

		Set<String> shortedIds = new Set<String>();
		System.debug(clonedIds);
		for(String strId : clonedIds) {
			System.debug(strId);
			System.debug(strId.substring(0, 15));
			shortedIds.add(String.valueOf(strId).substring(0, 15));
		}

		return shortedIds;
	}


	static void beforeUpdateChangedFromNull(Map<Id, Contact> oldContact, Map<Id, Contact> newContact) {
		// case when value changed from null ...
		// get changed contacts
		Map<Id, Contact> sortedContacts = new Map<Id, Contact>();

		for(Id contactId : newContact.keySet())
			if(oldContact.get(contactId).ReportsToId != newContact.get(contactId).ReportsToId && oldContact.get(contactId).ReportsToId == null)
				sortedContacts.put(contactId, newContact.get(contactId));

		if(sortedContacts.isEmpty()) {
			return;
		}

		// get reportToId Map hierarchy (2 lvl)
		Map<Id, List<Contact>> reportContactMap = new Map<Id, List<Contact>>();
		for(Contact contact : sortedContacts.values()) {
			if(contact.ReportsToId != null) {
				if(reportContactMap.containsKey(contact.ReportsToId)) reportContactMap.get(contact.ReportsToId).add(contact);
				else reportContactMap.put(contact.ReportsToId, new List<Contact>{contact});
			}
		}

		Map<Id, Integer> reportChilds = new Map<Id, Integer>();
		//calculate for each level
	}

	static void beforeUpdateMethod(Map<Id, Contact> oldContact, Map<Id, Contact> newContact) {
		System.debug('before error');
		Set<Id> highestParents = getHighestParents(newContact.values());

		System.debug(highestParents);

		Set<String> shortedIds = getShortedIds(highestParents);

		Map<Id, Contact> contactMap = getContactMap(shortedIds);

		System.debug(contactMap);

		System.debug([
				SELECT
						Id,
						Name,
						Parent_Contact__c,
						Highest_Parent__c
				FROM
						Contact
		]);

		List<Map<Id, Contact>> multiHierarchyList = new List<Map<Id, Contact>>();

		Map<String, Hierarchy> hierarchyMap = new Map<String, Hierarchy>();

		for(Contact contact : contactMap.values()) {
			String selfId = contact.Id;
			String parentId = contact.Parent_Contact__c;
			hierarchyMap.put(selfId, new Hierarchy(selfId, parentId));
		}

		System.debug(hierarchyMap);

		for(Hierarchy hierarchyParent : hierarchyMap.values()) {
			for(Hierarchy hierarchyChild: hierarchyMap.values()) {
				if(hierarchyParent.selfId == hierarchyChild.parentId) {
					hierarchyParent.addChild(hierarchyChild);
					hierarchyMap.remove(hierarchyChild.selfId);
				}
			}
		}

		System.debug(hierarchyMap);

		List<Hierarchy> hierarchies = setChild(hierarchyMap.values());
		List<Contact> contactsForUpdate = new List<Contact>();

		for(Hierarchy hierarchy : hierarchies) {
			contactsForUpdate.addAll(infoChild(hierarchy, new List<Contact>()));
		}

		update contactsForUpdate;
	}

	static List<Hierarchy> setChild(List<Hierarchy> hierarchies) {
		for(Hierarchy hierarchy : hierarchies) {
			hierarchy.countChild = deepValues(hierarchy);
			System.debug(hierarchy);
		}

		return hierarchies;
	}

	static Integer deepValues(Hierarchy hierarchy){
		if(hierarchy.hierarchyChild.isEmpty()) {
			return 0;
		} else {
			Integer count = 1;

			for(Hierarchy hierarchy2 : hierarchy.hierarchyChild) {
				hierarchy2.countChild = deepValues(hierarchy2);
				if(hierarchy2.countChild == 0) {
					count += 1;
				} else {
					count += hierarchy2.countChild;

				}
			}

			return count;
		}
	}

	static List<Contact> infoChild(Hierarchy hierarchy, List<Contact> contacts){
		if(hierarchy.hierarchyChild.isEmpty()) {
			contacts.add(createContactForUpdate(hierarchy));
		} else {
			for(Hierarchy hierarchy2 : hierarchy.hierarchyChild) {
				infoChild(hierarchy2, contacts);
			}

			contacts.add(createContactForUpdate(hierarchy));
		}

		return contacts;
	}

	static Contact createContactForUpdate(Hierarchy hierarchy) {
		return new Contact(
				Id = hierarchy.selfId,
				ChildCount__c = setCountChild(hierarchy.countChild)
		);
	}

	static Integer setCountChild(Integer countChild) {
		return countChild == 0 ? 0 : countChild - 1;
	}

}