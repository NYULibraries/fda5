package org.dspace.frontlist;

import org.apache.log4j.Logger;

import java.util.*;

import org.dspace.authorize.AuthorizeManager;
import org.dspace.authorize.ResourcePolicy;
import org.dspace.content.DSpaceObject;
import org.dspace.core.Constants;
import org.dspace.content.Collection;
import org.dspace.core.Context;
import org.dspace.event.Consumer;
import org.dspace.event.Event;
import org.dspace.content.Community;
import org.dspace.content.Item;
import org.dspace.eperson.EPerson;
import org.dspace.eperson.Group;


public class FrontListEventConsumer implements Consumer {
        /**
         * log4j logger
         */
        private static Logger log = Logger.getLogger(FrontListEventConsumer.class);



        public void initialize() throws Exception {

        }

        /**
         * We do not want to show  private and empty collections to non-admin users.
         * Only those users who can administrate private or empty collection or can submitte to those collections, will see them.
         * It has proved to be too resource intensive to calculate on the fly which communities and collection to show to a specific user
         * To reduce the amount of calculations we do most calculations on the application startup
         * On the start up we initialize 4 static ConcurrentHashMaps objects:
         * Map of communities and collections for site admins colMapAdmin,comMapAdmin
         * Map of communities and collections for all non-admin users colMapAnon,comMapAnon
         * Each entry in maps for collections has community id as a key and array of those community collections as a value
         * < Parent Community ID, [array of collections]>
         * Each entry in maps for communities has parent community id as a key and array of those community subcommunties as a value
         * < Parent Community ID, [array of subcommunties]>
         * As we have a limited number of  users who can get access to private ans empty collections,
         * for those users we will add communities and collections on the fly.
         * On the application start up we pre-calculate the list of those users and keep them in 2 static CopyOnWriteArrayLists (we use this type to
         * avoid concurrency issues) - colAuthorizedUsers and commAuthorizedUsers.
         * Each item in colAuthorizedUsers is an object of custom type AuthorizedCollectionUsers. It keep the triple <eperson ID, group ID, collection ID>
         * Each item in commAuthorizedUsers is an object of custom type AuthorizedCollectionUsers. It keep the triple <eperson ID, group ID, community ID>
         * Also we pre-calculate 4 objects of CopyOnWriteArrayLists - nyuOnly, gallatinOnly, emptyCollections, privateCollections
         * All those objects are used By Classes
         * ListCommunitiesSiteProcessor to generate site home page (objects will be passed to home.jsp as attributes)
         * ListCommunitiescomminityProcessor to generate community home page (objects will be passed to community-home.jsp as attributes)
         * ComminityListServlet to generate communities and collection lists (objects will be passed to community-list.jsp as attributes)
         * As we make all initial calculations when the application starts we need to update the objects  when the following changes are made:
         * when items are added to empty collection,
         * when all items are removed from collection,
         * when new admins or submitters are added or removed for private or empty collections,
         * when collection permissions are modified,
         * when collections and communities are added or removed
         * when collection and community metadata is modified
         * We use this class to consume the information of the event listed above and trigger the appropriate calculations.
         * More information about Dspace event processing system here - https://wiki.lyrasis.org/display/DSPACE/EventSystemPrototype
         * @param ctx   DSpace context
         * @param event Content event
         */
        public void consume(Context ctx, Event event) throws Exception {

                int  st= event.getSubjectType();
                int et= event.getEventType();

                //check that we only get  events we need
                if (st != Constants.COLLECTION && st!= Constants.GROUP && st!= Constants.COMMUNITY
                        && st!= Constants.SITE && st != Constants.ITEM ) {
                        log
                                .warn("FrontListConsumer should not have been given this kind of Subject in an event, skipping: "
                                        + event.toString());
                        return;
                }
                //remove top level community
                if(st==Constants.SITE ) {
                        if(event.getObjectID()!=-1 && et == Event.REMOVE) {
                                int objectID = event.getObjectID();
                                log.debug(" processing removing top community");
                                processRemoveTopCommunityID(objectID);
                        }

                }
                //community related events, e.g. when community is a subject and some action is performed over community element, e.g. object
                //any event has subject and action but some like "COMMUNITY DELETE " might not have object
                if(st==Constants.COMMUNITY ) {
                        if(event.getSubject(ctx)!=null) {
                                int subjectID = event.getSubjectID();
                                if(event.getObjectID()!=-1) {
                                        int objectID = event.getObjectID();
                                        //add or remove collection to the community, the event is issued AFTER collection is added/removed to/from the community
                                        if (event.getObjectType() == Constants.COLLECTION) {

                                                if (et == Event.ADD) {
                                                        if (event.getObject(ctx) != null) {
                                                                log.debug(" processing adding collection");
                                                                Collection o = (Collection) event.getObject(ctx);
                                                                processAddCollection(o);
                                                        }
                                                }
                                                if (et == Event.REMOVE ) {
                                                        log.debug(" processing removing collection");
                                                        processRemoveCollection(subjectID, objectID);

                                                }

                                        }
                                        //Removes subcommunity from the community
                                        if (event.getObjectType() == Constants.COMMUNITY) {

                                                if (et == Event.REMOVE) {
                                                        log.debug(" processing removing subcommunity");
                                                        processRemoveSubCommunity(subjectID, objectID);

                                                }
                                        }
                                //we work on community itself not on it's elements
                                } else {
                                        Community s = (Community) event.getSubject(ctx);
                                        if (et == Event.MODIFY_METADATA) {
                                                log.debug(" processing updating  community metadata ");
                                                processUpdateCommunity(s);
                                        }
                                        if (et == Event.CREATE) {
                                                log.debug(" processing adding community");
                                                processAddCommunity(s);
                                        }


                                }
                        }
                }
                //colection related events, e.g. when collection is an event  subject and some action is performed over collection element, e.g. object
                //any event has subject and action but some like "COLECCTION MODIFY_METADATA " might not have object
                //NOTE:remove and add collection events are processed on community level so are not mentioned here
                if(st==Constants.COLLECTION ) {
                        Collection s = (Collection) event.getSubject(ctx);
                        if(s!=null) {
                                log.debug(" processing removing item "+ event.getDetail());
                                if (et == Event.REMOVE ) {
                                        if (s.countItems() == 0) {
                                                log.debug(" processing removing last item from collection "+s.getName());
                                                processRemoveItem(s);

                                        }
                                }
                                if (et == Event.ADD) {
                                        if (event.getObject(ctx) != null && event.getObjectType() == Constants.ITEM) {
                                                if (ListUserCommunities.emptyCollections != null &&
                                                        ListUserCommunities.emptyCollections.contains(s)) {
                                                        log.debug(" processing adding item for previously empty collection "+s.getName());
                                                        processAddItem(s);
                                                }


                                        }
                                }
                                if (et == Event.MODIFY_METADATA) {
                                        log.warn(" processing updating collection metadata");
                                        processUpdateCollection(s);
                                }

                        }

                }

                //most item related events are processed on collection level. The only event we are processing for an item  is when
                //last item in the collection is withdrawn.
                if (st==Constants.ITEM && et == Event.MODIFY && event.getDetail().equals("WITHDRAW")) {
                        Item s = (Item) event.getSubject(ctx);
                        Collection[] cols =s.getCollections();
                        for (Collection col:cols) {
                                if (col.countItems() == 0){
                                        log.warn(" processing removing item");
                                        processRemoveItem(col);

                                }
                        }
                }

                //group related events, e.g. when an eperson is added or removed from the group or when group is deleted
                if(st==Constants.GROUP ) {
                        if(event.getObject(ctx)!=null && event.getObjectType()==Constants.EPERSON) {
                                processModifyGroup(ctx, (EPerson) event.getObject(ctx), (Group) event.getSubject(ctx), et);
                        }
                        if(event.getEventType()==Event.DELETE) {
                                processDeleteGroup( event.getSubjectID());
                        }
                }


        }



        /**
         * Process sets of objects to add, update, and delete in index. Correct for
         * interactions between the sets -- e.g. objects which were deleted do not\
         *
         * need to be added or updated, new objects don't also need an update, etc.
         */
        public void end(Context ctx) throws Exception {


        }

        public void finish(Context ctx) throws Exception {
            // No-op

        }
        //Processes removing top level community and it's children elements from maps.
        //The event is issued after community and it's children objects are already deleted
        //We are just modifying maps. We use java objects which support concurrency so all operations are threadsafe
        private void processRemoveTopCommunityID(  int communityID ) throws java.sql.SQLException {

                //remove children collection and subcommunity from the non-admin map
                ListUserCommunities.removeChildrenCommunityFromAnnonListID(communityID);

                //remove children collection and subcommunity from the admin map
                ListUserCommunities.removeChildrenCommunityFromAdminListID(communityID);
        }

        //Processes removing subcommunity and it's children elements from maps.
        //Also removes the subcommunity from the list of subcommunities in the maps entry for it's parent community
        //The event is issued after subcommunity and it's children objects are already deleted
        //We are just modifying maps. We use java objects which support concurrency so all operations are threadsafe
        private void processRemoveSubCommunity( int parentCommID, int communityID ) throws java.sql.SQLException {

                //Modifies the array of subcommunities in the non-admin map entry for the parent comminity
                // to remove deleted subcommunity
                ListUserCommunities.removeSubcommunityFromParentAnnonListID(parentCommID,communityID);

                //Modifies the array of subcommunities in the non-admin map entry for the parent comminity
                // to remove deleted subcommunity
                ListUserCommunities.removeSubcommunityFromParentAdminListID(parentCommID,communityID);

                //Removes entries for children collection and subcommunity from the non-admin map
                ListUserCommunities.removeChildrenCommunityFromAnnonListID(communityID);

                //Removes entries for children collection and subcommunity from the admin map
                ListUserCommunities.removeChildrenCommunityFromAdminListID(communityID);

        }

        //If an item is added to an empty collection and this collection is not private we add this collection to non-admin list
        private void processAddItem( Collection col ) throws java.sql.SQLException {
             if(ListUserCommunities.emptyCollections!=null
                                && ListUserCommunities.emptyCollections.contains(col)) {
                                ListUserCommunities.removeCollectionFromEmptyListID(col.getID());
                                if(!col.isPrivate()) {
                                        ListUserCommunities.addCollectionToAnonMap(col);
                                }

             }
        }

        //If the last item is removed or withdrawn from a public collection, the collection is removed from non-admin list
        //It will now only will be visible to site admin, parent community admins and collection admins
        private void processRemoveItem( Collection col ) throws java.sql.SQLException {
                             ListUserCommunities.addCollectionToEmptyListID(col.getID());
                                if( !ListUserCommunities.privateCollections.contains(col)) {
                                        if(col.getParentObject()!=null) {
                                                int parentCommID = col.getParentObject().getID();
                                                ListUserCommunities.removeCollectionFromAnonMapByID(parentCommID,col.getID());
                                        }
                                }

        }
        //Add newly created collection to the admin list. As after creation it is empty, add it to the empty list
        // If it is private, nyuonly or gallatin only add it to the appropriate list
        //The collection will be visible to only to site admin and community admin users
        private void processAddCollection( Collection col ) throws java.sql.SQLException {
                log.debug("We adding collection to Admin list");
                ListUserCommunities.addCollectionToAdminMap(col);

                if(col.isPrivate()) {
                                ListUserCommunities.addCollectionToPrivateListID(col.getID());
                }
                if(col.isNYUOnly()) {
                                ListUserCommunities.addCollectionToNyuOnlyListID(col.getID());
                }
                if(col.isGallatin()) {
                                ListUserCommunities.addCollectionToGallatinOnlyListID(col.getID());
                }
        }
        //Adds community to admin map after creation. As community is empty when created it will only withible to admins
        private void processAddCommunity( Community comm ) throws java.sql.SQLException {
                ListUserCommunities.addCommunityToAdminMap(comm);
        }
        //Process removal of collection from the repository. In that case collection needs to be removed from all maps and lists
        //It admins needs to be removed from admin list
        private void processRemoveCollection( int parentCommID, int collectionID ) throws java.sql.SQLException {

                ListUserCommunities.removeCollectionFromAnonMapByID(parentCommID,collectionID);
                ListUserCommunities.removeCollectionFromAdminMapByID(parentCommID,collectionID);
                ListUserCommunities.removeCollectionFromEmptyListID(collectionID);
                ListUserCommunities.removeCollectionFromPrivateListID(collectionID);
                ListUserCommunities.removeCollectionFromNyuOnlyListID(collectionID);
                ListUserCommunities.removeCollectionFromGallatinOnlyListID(collectionID);

        }

        //If collection metadata is updated we need to update collection object in the collection maps
        private void processUpdateCollection(Collection col) throws java.sql.SQLException {
                ListUserCommunities.updateCollectionMetadata(col);
        }
        //If community metadata is updated we need to update community object in the subcommunities maps
        private void processUpdateCommunity(Community comm) throws java.sql.SQLException {
                ListUserCommunities.updateCommunityMetadata(comm);
        }
        private void processModifyGroup( Context context, EPerson eperson, Group group, int eventType ) throws java.sql.SQLException {
                List<ResourcePolicy> rps= AuthorizeManager.getPoliciesForGroup(context, group);
                for (ResourcePolicy rp:rps) {
                        int resourceID = rp.getResourceID();
                        int resourceType = rp.getResourceType();

                       /* if(resourceType== Constants.COLLECTION) {
                                Collection  col =(Collection) DSpaceObject.find(context, resourceType, resourceID );
                                if((ListUserCommunities.privateCollections!=null && ListUserCommunities.privateCollections.contains(col) )||
                                        (ListUserCommunities.emptyCollections!=null && ListUserCommunities.emptyCollections.contains(col)) ) {

                                        if(eventType==Event.ADD) {
                                                ListUserCommunities.addAuthorizedUser(col, eperson);
                                        }
                                        if(eventType==Event.REMOVE) {
                                                ListUserCommunities.removeAuthorizedUser(col, eperson);
                                        }
                                }
                        }
                        if(resourceType== Constants.COMMUNITY) {
                                Community  com =(Community) DSpaceObject.find(context, resourceType, resourceID );
                                if(com.getAllCollections().length==0) {

                                        if(eventType==Event.ADD) {
                                                ListUserCommunities.addAuthorizedUser(com, eperson);
                                        }
                                        if(eventType==Event.REMOVE) {
                                                ListUserCommunities.removeAuthorizedUser(com, eperson);
                                        }
                                }
                        }
                        if(resourceType== Constants.GROUP) {
                                Group  parentGroup =(Group) DSpaceObject.find(context, resourceType, resourceID );
                                processModifyGroup(context, eperson, parentGroup, eventType);
                        }*/
                }
        }
        private void processDeleteGroup(  int groupID) throws java.sql.SQLException {

                }
        }
}
