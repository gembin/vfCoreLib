package com.visfleet.core.collections {
import flash.events.IEventDispatcher;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.core.IMXMLObject;
import mx.events.CollectionEvent;
import mx.events.CollectionEventKind;
import mx.events.PropertyChangeEvent;

/**
	 * Indexes an iList by the named property.
	 * 
	 * @author Jeremy Allen, Rasheed Abdul-Aziz
     * @copyright 2007 Visfleet Ltd
	 */
	public class ListIndex implements IMXMLObject {

        public function ListIndex( collection:IList = null, propertyName:String = null ) {
            this.collection = collection;
            this.propertyName = propertyName;

            refreshIndex();
        }

		private var _index:Dictionary = new Dictionary();

        /**
         * Provides access to a clone of the index.
         * @return Dictionary clone of the index.
         */
		public function cloneIndex():Dictionary {
			var clone:Dictionary = new Dictionary();
			for (var name:String in _index) {
				clone[name] = _index[name];
			}
			
			return clone;
		}

        /**
         * The collection to be indexed.
         * @param value any IList that you want to index.
         */
		[Bindable]
		[Inspectable]
		public function set collection(value:IList):void {
			if (_collection != value) {
				_collection = value;
				_collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange, false, 0, true);
				refreshIndex();
			}
		}
		
		public function get collection():IList {
			return _collection;
		}
		
		protected var _collection:IList;

        /**
         * The name of the field in the collection that you want to index on.
         * @param value
         */
		[Bindable]
		[Inspectable]
		public function set propertyName(value:String):void {
			if (_propertyName != value) {
				_propertyName = value;
				refreshIndex();
			}
		}
		
		public function get propertyName():String {
			return _propertyName;
		}
		
		protected var _propertyName:String;

        public function initialized(document:Object, id:String):void {
		}

        protected function emptyIndex():ArrayCollection {
            var collection:ArrayCollection;

            for each (collection in _index) {
                collection.removeAll();
            }
        }

        protected function emitResetPerIndex():void {
            for each (var collection:ArrayCollection in _index) {
                collection.dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, true, CollectionEventKind.RESET, -1, -1, []));
            }
        }

        protected function propertiesValid():Boolean {
            return (_propertyName != null) && (_collection != null);
        }

        public function refreshIndex():void {
            emptyIndex();

            if (!propertiesValid()) {
				return;
            }

            var item:Object;
            var itemIndex:int;

            for (itemIndex = 0; itemIndex < _collection.length; itemIndex++) {
                item = _collection.getItemAt(itemIndex);
                processAdd(item);
            }

            emitResetPerIndex();
        }
		
		public function getIndexedItems(indexValue:*):ArrayCollection {
			var result:ArrayCollection = _index[indexValue] as ArrayCollection;
			if (!result) {
				result = _index[indexValue] = new ArrayCollection();
			}
			return result;
		}

        /**
         * Returns the first indexed record for a particular index. Use this
         * when you trust that the index field is unique.
         * @param indexValue
         * @return Object the indexed record
         */
		public function getFirstIndexedItem(indexValue:*):* {
			var result:ArrayCollection = getIndexedItems(indexValue);

			if (result.length < 1) {
				return null;
			}

            return result.getItemAt(0);
		}

		protected function onCollectionChange(event:CollectionEvent):void {
			var item:Object;
			var propertyChangeEvent:PropertyChangeEvent

			switch (event.kind) {
				case CollectionEventKind.ADD:
					for each (item in event.items) {
						processAdd(item);
					}
					break;
				case CollectionEventKind.REMOVE:
					for each (item in event.items) {
						processRemove(item);
					}
					break;
				case CollectionEventKind.UPDATE:
					// we don't update here, we update if the item itself dispatches a propertyChange
					break;
                // These are heavy handed, be aware that a collection that is refreshed/reset often will be non-performant
				case CollectionEventKind.RESET:
				case CollectionEventKind.REFRESH:
					refreshIndex();
					break;
				case CollectionEventKind.MOVE:
					break;
				default:
					throw new Error ("Index was not expecting to receive this event: "+event.kind, 497412806396);
			}
		}
		
		private function processAdd(item:Object,firstAdd:Boolean = true):void {

			var indexedItems:ArrayCollection = _index[item[_propertyName]] as ArrayCollection;

			if (!indexedItems) {
 				indexedItems = new ArrayCollection();
				_index[item[_propertyName]] = indexedItems;
			}

 			indexedItems.addItem(item);

 			if (firstAdd && (item is IEventDispatcher)) {
 				(item as IEventDispatcher).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,processUpdate,false,0,true);
 			}
 			
		}
		
		private function processRemove(item:Object):void {
			var indexedItems:ArrayCollection = _index[item[_propertyName]] as ArrayCollection;

			if (_index[item[_propertyName]]) {
				indexedItems.removeItemAt(indexedItems.getItemIndex(item));
			}

 			if (item is IEventDispatcher) {
 				(item as IEventDispatcher).removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE,processUpdate);
 			}
		}
		
		private function processUpdate(event:PropertyChangeEvent):void { 
			if (event.property == _propertyName) {
				var oldIndexedItems:ArrayCollection = _index[event.oldValue] as ArrayCollection;
				if (oldIndexedItems) {
					oldIndexedItems.removeItemAt(oldIndexedItems.getItemIndex(event.target));
					processAdd(event.target,false);
				} else {
					processAdd(event.target,true);
				}
			}
		}
		
	}
	
}