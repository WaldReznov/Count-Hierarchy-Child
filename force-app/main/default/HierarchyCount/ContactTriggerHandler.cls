/**
 * Created by Uladzislau Yarshou on 30.09.21
**/

public with sharing class ContactTriggerHandler {
	@TestVisible public static Boolean IS_ALLOW_AFTER_CREATE = true;
	@TestVisible public static Boolean IS_ALLOW_AFTER_UPDATE = true;
	@TestVisible public static Boolean IS_ALLOW_AFTER_DELETE = true;

	public static void afterInsert(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
		if(IS_ALLOW_AFTER_CREATE == false) {
			return;
		}
		setAllowsToFalse();

		beforeUpdateMethod(newContactMap);

		setAllowsToTrue();
	}

	public static void afterUpdate(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
		if(IS_ALLOW_AFTER_UPDATE == false) {
			return;
		}

		setAllowsToFalse();

		beforeUpdateMethod(newContactMap);

		setAllowsToTrue();
	}

	public static void afterDelete(Map<Id, Contact> oldContactMap, Map<Id, Contact> newContactMap) {
		if(IS_ALLOW_AFTER_DELETE == false) {
			return;
		}
		setAllowsToFalse();

		beforeUpdateMethod(newContactMap);

		setAllowsToTrue();
	}

	static void setAllowsToFalse() {
		IS_ALLOW_AFTER_CREATE = false;
		IS_ALLOW_AFTER_UPDATE = false;
		IS_ALLOW_AFTER_DELETE = false;
	}

	static void setAllowsToTrue() {
		IS_ALLOW_AFTER_CREATE = true;
		IS_ALLOW_AFTER_UPDATE = true;
		IS_ALLOW_AFTER_DELETE = true;
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

	}

	static Set<Id> getHighestParents(List<Contact> contacts) {
		Set<Id> ids = new Set<Id>();

		for(Contact contact : contacts) {
			if(contact.Highest_Parent__c != null) {
				ids.add(contact.Highest_Parent__c);
			}
		}

		return ids;
	}

	static Map<Id, Contact> getContactMap(Set<String> ids) {
		return new Map<Id, Contact>([
				SELECT
						Id,
						Name,
						Parent_Contact__c,
						Highest_Parent__c
				FROM
						Contact
				WHERE
						Id IN :ids
							OR
						Highest_Parent__c IN :ids
		]);
	}

	static Set<String> getShortedIds(Set<Id> ids) {
		Set<String> shortedIds = new Set<String>();

		for(Id recordId : ids) {
			shortedIds.add(String.valueOf(recordId).substring(0, 15));
		}

		return shortedIds;
	}

	static void beforeUpdateMethod(Map<Id, Contact> contactMap) {
		Set<Id> highestParents = getHighestParents(contactMap.values());

		Set<String> shortedIds = getShortedIds(highestParents);

		Map<Id, Contact> selectedContactMap = getContactMap(shortedIds);
		
		Map<String, Hierarchy> hierarchyMap = new Map<String, Hierarchy>();

		for(Contact contact : selectedContactMap.values()) {
			String selfId = contact.Id;
			String parentId = contact.Parent_Contact__c;
			hierarchyMap.put(selfId, new Hierarchy(selfId, parentId));
		}

		for(Hierarchy hierarchyParent : hierarchyMap.values()) {
			for(Hierarchy hierarchyChild: hierarchyMap.values()) {
				if(hierarchyParent.selfId == hierarchyChild.parentId) {
					hierarchyParent.addChild(hierarchyChild);
					hierarchyMap.remove(hierarchyChild.selfId);
				}
			}
		}

		List<Hierarchy> hierarchies = countChildForHierarchy(hierarchyMap.values());
		List<Contact> contactsForUpdate = new List<Contact>();

		for(Hierarchy hierarchy : hierarchies) {
			contactsForUpdate.addAll(getContactsFromHierarchy(hierarchy, new List<Contact>()));
		}

		update contactsForUpdate;
	}

	static List<Hierarchy> countChildForHierarchy(List<Hierarchy> hierarchies) {
		for(Hierarchy hierarchy : hierarchies) {
			hierarchy.countChild = deepValues(hierarchy);
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

	static List<Contact> getContactsFromHierarchy(Hierarchy hierarchy, List<Contact> contacts){
		if(hierarchy.hierarchyChild.isEmpty()) {
			contacts.add(createContactForUpdate(hierarchy));
		} else {
			for(Hierarchy hierarchy2 : hierarchy.hierarchyChild) {
				getContactsFromHierarchy(hierarchy2, contacts);
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